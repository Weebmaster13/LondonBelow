--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local SaveSessionDiagnostics = require(script.Parent.SaveSessionDiagnostics)
local SaveSessionRuntime = require(script.Parent.SaveSessionRuntime)
local SaveSessionSelfChecks = require(script.Parent.SaveSessionSelfChecks)
local SaveSessionSerialization = require(script.Parent.SaveSessionSerialization)
local SaveSessionSignals = require(script.Parent.SaveSessionSignals)
local SaveSessionSnapshots = require(script.Parent.SaveSessionSnapshots)
local SaveSessionTypes = require(script.Parent.SaveSessionTypes)

local Coordinator = {}

local log = Logger.scope("SaveSessionCoordinator")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

function Coordinator.openSession(definition: any)
	local ok, reason, session = SaveSessionRuntime.openSession(definition)
	if not ok then
		EventBus.publishDeferred(SaveSessionSignals.ValidationFailed, { reason = reason })
		return result(false, SaveSessionTypes.ResultCode.InvalidSession, reason)
	end
	EventBus.publishDeferred(SaveSessionSignals.SessionOpened, { sessionId = definition.sessionId })
	return result(
		true,
		SaveSessionTypes.ResultCode.Ok,
		"save session opened",
		{ session = session }
	)
end

function Coordinator.closeSession(sessionId: string)
	local ok, reason = SaveSessionRuntime.closeSession(sessionId)
	if not ok then
		return result(false, SaveSessionTypes.ResultCode.InvalidTransition, reason)
	end
	EventBus.publishDeferred(SaveSessionSignals.SessionClosed, { sessionId = sessionId })
	return result(true, SaveSessionTypes.ResultCode.Ok, "save session closed")
end

function Coordinator.acquireLock(sessionId: string, owner: string)
	local ok, reason = SaveSessionRuntime.acquireLock(sessionId, owner)
	return result(
		ok,
		if ok then SaveSessionTypes.ResultCode.Ok else SaveSessionTypes.ResultCode.LockRejected,
		reason
	)
end

function Coordinator.releaseLock(sessionId: string, owner: string)
	local ok, reason = SaveSessionRuntime.releaseLock(sessionId, owner)
	return result(
		ok,
		if ok then SaveSessionTypes.ResultCode.Ok else SaveSessionTypes.ResultCode.LockRejected,
		reason
	)
end

function Coordinator.beginTransaction(sessionId: string, transactionId: string)
	local ok, reason = SaveSessionRuntime.beginTransaction(sessionId, transactionId)
	return result(
		ok,
		if ok
			then SaveSessionTypes.ResultCode.Ok
			else SaveSessionTypes.ResultCode.TransactionRejected,
		reason
	)
end

function Coordinator.commitTransaction(sessionId: string)
	local ok, reason = SaveSessionRuntime.commitTransaction(sessionId)
	return result(
		ok,
		if ok
			then SaveSessionTypes.ResultCode.Ok
			else SaveSessionTypes.ResultCode.TransactionRejected,
		reason
	)
end

function Coordinator.rollbackTransaction(sessionId: string)
	local ok, reason = SaveSessionRuntime.rollbackTransaction(sessionId)
	return result(
		ok,
		if ok
			then SaveSessionTypes.ResultCode.Ok
			else SaveSessionTypes.ResultCode.TransactionRejected,
		reason
	)
end

function Coordinator.cancelTransaction(sessionId: string)
	local ok, reason = SaveSessionRuntime.cancelTransaction(sessionId)
	return result(
		ok,
		if ok
			then SaveSessionTypes.ResultCode.Ok
			else SaveSessionTypes.ResultCode.TransactionRejected,
		reason
	)
end

function Coordinator.markDirty(sessionId: string)
	local ok, reason = SaveSessionRuntime.markDirty(sessionId)
	return result(
		ok,
		if ok then SaveSessionTypes.ResultCode.Ok else SaveSessionTypes.ResultCode.InvalidSession,
		reason
	)
end

function Coordinator.markClean(sessionId: string)
	local ok, reason = SaveSessionRuntime.markClean(sessionId)
	return result(
		ok,
		if ok then SaveSessionTypes.ResultCode.Ok else SaveSessionTypes.ResultCode.InvalidSession,
		reason
	)
end

function Coordinator.cancelSession(sessionId: string)
	local ok, reason = SaveSessionRuntime.cancelSession(sessionId)
	return result(
		ok,
		if ok then SaveSessionTypes.ResultCode.Ok else SaveSessionTypes.ResultCode.Cancelled,
		reason
	)
end

function Coordinator.recoverSession(sessionId: string)
	local ok, reason = SaveSessionRuntime.recoverSession(sessionId)
	return result(
		ok,
		if ok then SaveSessionTypes.ResultCode.Ok else SaveSessionTypes.ResultCode.RecoveryFailed,
		reason
	)
end

function Coordinator.initialize()
	if initialized then
		return
	end
	local ok, reason = Coordinator.validate()
	if not ok then
		error("SaveSessionCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler(SaveSessionTypes.ProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(SaveSessionTypes.ProviderName, Coordinator.getSnapshot)
	initialized = true
	log.success("Save Session Runtime initialized")
end

function Coordinator.start()
	if started then
		return
	end
	if not initialized then
		Coordinator.initialize()
	end
	started = true
end

function Coordinator.shutdown()
	SaveSessionRuntime.shutdown()
	started = false
	initialized = false
end

function Coordinator.inspect()
	return SaveSessionDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, SaveSessionRuntime)
end

function Coordinator.getSnapshot()
	local snapshot = SaveSessionSnapshots.capture(SaveSessionRuntime)
	EventBus.publishDeferred(SaveSessionSignals.ShutdownCompleted, {
		snapshot = SaveSessionSerialization.deepCopy(snapshot),
	})
	return snapshot
end

function Coordinator.validate(): (boolean, string?)
	return SaveSessionDiagnostics.validate()
end

function Coordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Save Session self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SaveSessionSelfChecks.run({ Service = Coordinator })
	return lastSelfChecks
end

return Coordinator
