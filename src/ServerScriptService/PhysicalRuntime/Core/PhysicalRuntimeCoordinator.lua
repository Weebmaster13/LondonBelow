--!strict
--[[
	Phase 21 Physical Runtime Coordinator.

	This service owns server-authoritative physical object schemas only. It
	never stores Roblox Instances, mutates Workspace, executes physics,
	performs movement, creates remotes, or owns gameplay systems.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local LifecycleRuntime = require(script.Parent.PhysicalLifecycleRuntime)
local ObjectRuntime = require(script.Parent.PhysicalObjectRuntime)
local OwnershipRuntime = require(script.Parent.PhysicalOwnershipRuntime)
local PhysicalDiagnostics = require(script.Parent.PhysicalDiagnostics)
local RegistrationRuntime = require(script.Parent.PhysicalRegistrationRuntime)
local ReservationRuntime = require(script.Parent.PhysicalReservationRuntime)
local SelfChecks = require(script.Parent.PhysicalSelfChecks)
local Serialization = require(script.Parent.PhysicalSerialization)
local Signals = require(script.Parent.PhysicalSignals)
local Snapshots = require(script.Parent.PhysicalSnapshots)
local StateRuntime = require(script.Parent.PhysicalStateRuntime)
local TransformRuntime = require(script.Parent.PhysicalTransformRuntime)
local Types = require(script.Parent.PhysicalTypes)
local Validation = require(script.Parent.PhysicalValidation)

local PhysicalRuntimeCoordinator = {}

local log = Logger.scope("PhysicalRuntime")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	State = ObjectRuntime,
	Validation = Validation,
}

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

local function codeFor(reason: string?): string
	if reason == "duplicate physicalObjectId" then
		return Types.ResultCode.DuplicateObject
	elseif reason == "unknown physicalObjectId" then
		return Types.ResultCode.UnknownObject
	elseif reason == "duplicate reservationId" then
		return Types.ResultCode.DuplicateReservation
	elseif reason ~= nil and string.find(reason, "ownerSystem", 1, true) then
		return Types.ResultCode.InvalidOwnership
	elseif
		reason ~= nil
		and (
			string.find(reason, "payload", 1, true)
			or string.find(reason, "forbidden field", 1, true)
			or string.find(reason, "unsafe runtime", 1, true)
			or string.find(reason, "cyclic", 1, true)
		)
	then
		return Types.ResultCode.UnsafePayload
	end
	return Types.ResultCode.InvalidRequest
end

local function recordFailure(reason: string, payload: any?)
	ObjectRuntime.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

function PhysicalRuntimeCoordinator.registerObject(schema: any)
	local ok, reason = RegistrationRuntime.register(ObjectRuntime, schema)
	if not ok then
		recordFailure(reason or "physical object rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ObjectRegistered, {
		physicalObjectId = schema.physicalObjectId,
	})
	return result(true, Types.ResultCode.Ok, "physical object registered")
end

function PhysicalRuntimeCoordinator.removeObject(physicalObjectId: string)
	if not Validation.id(physicalObjectId) then
		recordFailure("physicalObjectId is required", { physicalObjectId = physicalObjectId })
		return result(false, Types.ResultCode.InvalidRequest, "physicalObjectId is required")
	end
	if not ObjectRuntime.exists(physicalObjectId) then
		recordFailure("unknown physicalObjectId", { physicalObjectId = physicalObjectId })
		return result(false, Types.ResultCode.UnknownObject, "unknown physicalObjectId")
	end
	ObjectRuntime.remove(physicalObjectId)
	EventBus.publishDeferred(Signals.ObjectRemoved, { physicalObjectId = physicalObjectId })
	return result(true, Types.ResultCode.Ok, "physical object removed")
end

function PhysicalRuntimeCoordinator.assignOwnership(physicalObjectId: string, ownerSystem: string)
	local ok, reason = OwnershipRuntime.assign(ObjectRuntime, physicalObjectId, ownerSystem)
	if not ok then
		recordFailure(reason or "ownership rejected", {
			physicalObjectId = physicalObjectId,
			ownerSystem = ownerSystem,
		})
		return result(false, codeFor(reason), reason)
	end
	return result(true, Types.ResultCode.Ok, "ownership assigned")
end

function PhysicalRuntimeCoordinator.reserveObject(
	physicalObjectId: string,
	reservationId: string,
	ownerSystem: string
)
	local ok, reason =
		ReservationRuntime.reserve(ObjectRuntime, physicalObjectId, reservationId, ownerSystem)
	if not ok then
		recordFailure(reason or "reservation rejected", {
			physicalObjectId = physicalObjectId,
			reservationId = reservationId,
			ownerSystem = ownerSystem,
		})
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ReservationCreated, {
		physicalObjectId = physicalObjectId,
		reservationId = reservationId,
	})
	return result(true, Types.ResultCode.Ok, "reservation created")
end

function PhysicalRuntimeCoordinator.releaseReservation(reservationId: string)
	local ok, reason = ReservationRuntime.release(ObjectRuntime, reservationId)
	if not ok then
		recordFailure(reason or "reservation release rejected", { reservationId = reservationId })
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ReservationReleased, { reservationId = reservationId })
	return result(true, Types.ResultCode.Ok, "reservation released")
end

function PhysicalRuntimeCoordinator.setObjectState(physicalObjectId: string, objectState: any)
	local ok, reason = StateRuntime.setState(ObjectRuntime, physicalObjectId, objectState)
	if not ok then
		recordFailure(reason or "state update rejected", {
			physicalObjectId = physicalObjectId,
			state = objectState,
		})
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.StateChanged, { physicalObjectId = physicalObjectId })
	return result(true, Types.ResultCode.Ok, "state schema updated")
end

function PhysicalRuntimeCoordinator.setLifecycle(physicalObjectId: string, lifecycleState: string)
	local ok, reason =
		LifecycleRuntime.setLifecycle(ObjectRuntime, physicalObjectId, lifecycleState)
	if not ok then
		recordFailure(reason or "lifecycle update rejected", {
			physicalObjectId = physicalObjectId,
			lifecycleState = lifecycleState,
		})
		return result(false, codeFor(reason), reason)
	end
	return result(true, Types.ResultCode.Ok, "lifecycle schema updated")
end

function PhysicalRuntimeCoordinator.setTransform(physicalObjectId: string, transformSchema: any)
	local ok, reason =
		TransformRuntime.setTransform(ObjectRuntime, physicalObjectId, transformSchema)
	if not ok then
		recordFailure(reason or "transform update rejected", {
			physicalObjectId = physicalObjectId,
			transformSchema = transformSchema,
		})
		return result(false, codeFor(reason), reason)
	end
	return result(true, Types.ResultCode.Ok, "transform schema updated")
end

function PhysicalRuntimeCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = PhysicalRuntimeCoordinator.validate()
	if not valid then
		error("PhysicalRuntimeCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("PhysicalRuntime", PhysicalRuntimeCoordinator.inspect)
	SnapshotManager.registerProvider("physicalRuntime", PhysicalRuntimeCoordinator.getSnapshot)
	initialized = true
	log.success("Physical Runtime initialized")
end

function PhysicalRuntimeCoordinator.start()
	if started then
		return
	end
	if not initialized then
		PhysicalRuntimeCoordinator.initialize()
	end
	started = true
end

function PhysicalRuntimeCoordinator.shutdown()
	ObjectRuntime.clear()
	started = false
	initialized = false
end

function PhysicalRuntimeCoordinator.inspect()
	return PhysicalDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function PhysicalRuntimeCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(ObjectRuntime)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function PhysicalRuntimeCoordinator.validate(): (boolean, string?)
	return PhysicalDiagnostics.validate(dependencies)
end

function PhysicalRuntimeCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Physical Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = PhysicalRuntimeCoordinator })
	return lastSelfChecks
end

return PhysicalRuntimeCoordinator
