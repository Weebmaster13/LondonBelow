--!strict
--[[
	Phase 25 Inventory Runtime Coordinator.

	Server-authoritative inventory schema foundation. It records profile, item,
	slot, ownership, capacity, eligibility, and state schemas for future gameplay.
	It does not execute pickup, use, unlock, solve, save persistence, UI, remotes,
	Workspace mutation, or Chapter content.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local InventoryDiagnostics = require(script.Parent.InventoryDiagnostics)
local ItemRuntime = require(script.Parent.InventoryItemRuntime)
local ProfileRuntime = require(script.Parent.InventoryProfileRuntime)
local SelfChecks = require(script.Parent.InventorySelfChecks)
local Serialization = require(script.Parent.InventorySerialization)
local Signals = require(script.Parent.InventorySignals)
local Snapshots = require(script.Parent.InventorySnapshots)
local Types = require(script.Parent.InventoryTypes)
local Validation = require(script.Parent.InventoryValidation)

local InventoryCoordinator = {}

local log = Logger.scope("InventoryRuntime")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	State = ProfileRuntime,
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
	if reason == "duplicate inventoryProfileId" then
		return Types.ResultCode.DuplicateProfile
	elseif reason == "duplicate itemId" then
		return Types.ResultCode.DuplicateItem
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
	ProfileRuntime.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

function InventoryCoordinator.registerProfile(profile: any)
	local ok, reason = ProfileRuntime.registerProfile(profile)
	if not ok then
		recordFailure(reason or "inventory profile rejected", profile)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.ProfileRegistered,
		{ inventoryProfileId = profile.inventoryProfileId }
	)
	return result(true, Types.ResultCode.Ok, "inventory profile registered")
end

function InventoryCoordinator.registerItem(item: any)
	local ok, reason = ItemRuntime.register(ProfileRuntime, item)
	if not ok then
		recordFailure(reason or "inventory item rejected", item)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ItemRegistered, { itemId = item.itemId })
	return result(true, Types.ResultCode.Ok, "inventory item registered")
end

function InventoryCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = InventoryCoordinator.validate()
	if not valid then
		error("InventoryCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("InventoryRuntime", InventoryCoordinator.inspect)
	SnapshotManager.registerProvider("inventoryRuntime", InventoryCoordinator.getSnapshot)
	initialized = true
	log.success("Inventory Runtime initialized")
end

function InventoryCoordinator.start()
	if started then
		return
	end
	if not initialized then
		InventoryCoordinator.initialize()
	end
	started = true
end

function InventoryCoordinator.shutdown()
	ProfileRuntime.clear()
	started = false
	initialized = false
end

function InventoryCoordinator.inspect()
	return InventoryDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function InventoryCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(ProfileRuntime)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function InventoryCoordinator.validate(): (boolean, string?)
	return InventoryDiagnostics.validate(dependencies)
end

function InventoryCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Inventory Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = InventoryCoordinator })
	return lastSelfChecks
end

return InventoryCoordinator
