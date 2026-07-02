--!strict
--[[
	Phase 28 Session Runtime Coordinator.

	Server-authoritative session schema foundation. It records sessions, player
	session records, party session schemas, readiness, lifecycle, and join/leave
	records. It does not execute matchmaking, teleporting, lobby UI, party
	gameplay, save persistence, Workspace mutation, remotes, or client authority.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local DefinitionRuntime = require(script.Parent.SessionDefinitionRuntime)
local LifecycleRuntime = require(script.Parent.SessionLifecycleRuntime)
local PartyRuntime = require(script.Parent.SessionPartyRuntime)
local PlayerRuntime = require(script.Parent.SessionPlayerRuntime)
local ReadinessRuntime = require(script.Parent.SessionReadinessRuntime)
local SelfChecks = require(script.Parent.SessionSelfChecks)
local Serialization = require(script.Parent.SessionSerialization)
local SessionDiagnostics = require(script.Parent.SessionDiagnostics)
local Signals = require(script.Parent.SessionSignals)
local Snapshots = require(script.Parent.SessionSnapshots)
local Types = require(script.Parent.SessionTypes)
local Validation = require(script.Parent.SessionValidation)

local SessionCoordinator = {}

local log = Logger.scope("SessionRuntime")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	State = DefinitionRuntime,
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
	if reason == "duplicate sessionId" then
		return Types.ResultCode.DuplicateSession
	elseif reason == "duplicate playerSessionId" then
		return Types.ResultCode.DuplicatePlayerSession
	elseif reason == "duplicate partyId" then
		return Types.ResultCode.DuplicateParty
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
	DefinitionRuntime.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

function SessionCoordinator.registerSession(schema: any)
	local ok, reason = DefinitionRuntime.registerSession(schema)
	if not ok then
		recordFailure(reason or "session schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.SessionRegistered, { sessionId = schema.sessionId })
	return result(true, Types.ResultCode.Ok, "session schema registered")
end

function SessionCoordinator.registerPlayerSession(record: any)
	local ok, reason = PlayerRuntime.register(DefinitionRuntime, record)
	if not ok then
		recordFailure(reason or "player session rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.PlayerSessionRegistered,
		{ playerSessionId = record.playerSessionId }
	)
	return result(true, Types.ResultCode.Ok, "player session registered")
end

function SessionCoordinator.registerParty(schema: any)
	local ok, reason = PartyRuntime.register(DefinitionRuntime, schema)
	if not ok then
		recordFailure(reason or "party session rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.PartyRegistered, { partyId = schema.partyId })
	return result(true, Types.ResultCode.Ok, "party session schema registered")
end

function SessionCoordinator.recordReadiness(record: any)
	local ok, reason = ReadinessRuntime.record(DefinitionRuntime, record)
	if not ok then
		recordFailure(reason or "readiness record rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ReadinessRecorded, { readinessId = record.readinessId })
	return result(true, Types.ResultCode.Ok, "readiness record stored")
end

function SessionCoordinator.recordLifecycle(record: any)
	local ok, reason = LifecycleRuntime.recordLifecycle(DefinitionRuntime, record)
	if not ok then
		recordFailure(reason or "lifecycle record rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.LifecycleRecorded, { lifecycleId = record.lifecycleId })
	return result(true, Types.ResultCode.Ok, "lifecycle record stored")
end

function SessionCoordinator.recordJoinLeave(record: any)
	local ok, reason = LifecycleRuntime.recordJoinLeave(DefinitionRuntime, record)
	if not ok then
		recordFailure(reason or "join/leave record rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.JoinLeaveRecorded, { joinLeaveId = record.joinLeaveId })
	return result(true, Types.ResultCode.Ok, "join/leave record stored")
end

function SessionCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = SessionCoordinator.validate()
	if not valid then
		error("SessionCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("SessionRuntime", SessionCoordinator.inspect)
	SnapshotManager.registerProvider("sessionRuntime", SessionCoordinator.getSnapshot)
	initialized = true
	log.success("Session Runtime initialized")
end

function SessionCoordinator.start()
	if started then
		return
	end
	if not initialized then
		SessionCoordinator.initialize()
	end
	started = true
end

function SessionCoordinator.shutdown()
	DefinitionRuntime.clear()
	started = false
	initialized = false
end

function SessionCoordinator.inspect()
	return SessionDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function SessionCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(DefinitionRuntime)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function SessionCoordinator.validate(): (boolean, string?)
	return SessionDiagnostics.validate(dependencies)
end

function SessionCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Session Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = SessionCoordinator })
	return lastSelfChecks
end

return SessionCoordinator
