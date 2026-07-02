--!strict
--[[
	Phase 23 Interaction Runtime Coordinator.

	Server-authoritative schema foundation for future interactable objects. It
	does not execute doors, drawers, pickups, inventory, UI prompts, animation,
	audio, lighting, Workspace mutation, remotes, or client-owned truth.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local CooldownRuntime = require(script.Parent.InteractionCooldownRuntime)
local IntentRuntime = require(script.Parent.InteractionIntentRuntime)
local InteractionDiagnostics = require(script.Parent.InteractionDiagnostics)
local LockRuntime = require(script.Parent.InteractionLockRuntime)
local ObjectRuntime = require(script.Parent.InteractionObjectRuntime)
local RegistrationRuntime = require(script.Parent.InteractionRegistrationRuntime)
local SelfChecks = require(script.Parent.InteractionSelfChecks)
local Serialization = require(script.Parent.InteractionSerialization)
local Signals = require(script.Parent.InteractionSignals)
local Snapshots = require(script.Parent.InteractionSnapshots)
local Types = require(script.Parent.InteractionTypes)
local Validation = require(script.Parent.InteractionValidation)

local InteractionCoordinator = {}

local log = Logger.scope("InteractionRuntime")
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
	if reason == "duplicate interactionId" then
		return Types.ResultCode.DuplicateInteraction
	elseif reason == "unknown interactionId" then
		return Types.ResultCode.UnknownInteraction
	elseif reason ~= nil and string.find(reason, "cooldown", 1, true) then
		return Types.ResultCode.InvalidCooldown
	elseif reason ~= nil and string.find(reason, "lock", 1, true) then
		return Types.ResultCode.InvalidLock
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

function InteractionCoordinator.registerInteraction(schema: any)
	local ok, reason = RegistrationRuntime.register(ObjectRuntime, schema)
	if not ok then
		recordFailure(reason or "interaction schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.InteractionRegistered, {
		interactionId = schema.interactionId,
	})
	return result(true, Types.ResultCode.Ok, "interaction schema registered")
end

function InteractionCoordinator.recordIntent(intent: any)
	local ok, reason = IntentRuntime.record(ObjectRuntime, intent)
	if not ok then
		recordFailure(reason or "interaction intent rejected", intent)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.IntentRecorded, { intentId = intent.intentId })
	return result(true, Types.ResultCode.Ok, "interaction intent recorded")
end

function InteractionCoordinator.recordLock(interactionId: string, lockState: any)
	local ok, reason = LockRuntime.record(ObjectRuntime, interactionId, lockState)
	if not ok then
		recordFailure(reason or "interaction lock rejected", {
			interactionId = interactionId,
			lockState = lockState,
		})
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.LockRecorded, { interactionId = interactionId })
	return result(true, Types.ResultCode.Ok, "interaction lock recorded")
end

function InteractionCoordinator.recordCooldown(interactionId: string, cooldown: any)
	local ok, reason = CooldownRuntime.record(ObjectRuntime, interactionId, cooldown)
	if not ok then
		recordFailure(reason or "interaction cooldown rejected", {
			interactionId = interactionId,
			cooldown = cooldown,
		})
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.CooldownRecorded, { interactionId = interactionId })
	return result(true, Types.ResultCode.Ok, "interaction cooldown recorded")
end

function InteractionCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = InteractionCoordinator.validate()
	if not valid then
		error("InteractionCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("InteractionRuntime", InteractionCoordinator.inspect)
	SnapshotManager.registerProvider("interactionRuntime", InteractionCoordinator.getSnapshot)
	initialized = true
	log.success("Interaction Runtime initialized")
end

function InteractionCoordinator.start()
	if started then
		return
	end
	if not initialized then
		InteractionCoordinator.initialize()
	end
	started = true
end

function InteractionCoordinator.shutdown()
	ObjectRuntime.clear()
	started = false
	initialized = false
end

function InteractionCoordinator.inspect()
	return InteractionDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function InteractionCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(ObjectRuntime)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function InteractionCoordinator.validate(): (boolean, string?)
	return InteractionDiagnostics.validate(dependencies)
end

function InteractionCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Interaction Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = InteractionCoordinator })
	return lastSelfChecks
end

return InteractionCoordinator
