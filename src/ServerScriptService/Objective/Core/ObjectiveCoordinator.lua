--!strict
--[[
	Phase 27 Objective Runtime Coordinator.

	Server-authoritative objective schema foundation. It records objective,
	task, requirement, dependency, state, and progress schemas. It does not
	complete objectives, execute quests, run gameplay, present UI, persist saves,
	own Narrative/Horror pacing, mutate Workspace, or create remotes.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local DefinitionRuntime = require(script.Parent.ObjectiveDefinitionRuntime)
local ObjectiveDiagnostics = require(script.Parent.ObjectiveDiagnostics)
local ProgressRuntime = require(script.Parent.ObjectiveProgressRuntime)
local SelfChecks = require(script.Parent.ObjectiveSelfChecks)
local Serialization = require(script.Parent.ObjectiveSerialization)
local Signals = require(script.Parent.ObjectiveSignals)
local Snapshots = require(script.Parent.ObjectiveSnapshots)
local Types = require(script.Parent.ObjectiveTypes)
local Validation = require(script.Parent.ObjectiveValidation)

local ObjectiveCoordinator = {}

local log = Logger.scope("ObjectiveRuntime")
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
	if reason == "duplicate objectiveId" then
		return Types.ResultCode.DuplicateObjective
	elseif reason == "unknown objective progress" then
		return Types.ResultCode.UnknownObjective
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

function ObjectiveCoordinator.registerObjective(schema: any)
	local ok, reason = DefinitionRuntime.register(schema)
	if not ok then
		recordFailure(reason or "objective schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ObjectiveRegistered, { objectiveId = schema.objectiveId })
	return result(true, Types.ResultCode.Ok, "objective schema registered")
end

function ObjectiveCoordinator.recordProgress(record: any)
	local ok, reason = ProgressRuntime.record(DefinitionRuntime, record)
	if not ok then
		recordFailure(reason or "objective progress rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ProgressRecorded, { progressId = record.progressId })
	return result(true, Types.ResultCode.Ok, "objective progress recorded")
end

function ObjectiveCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = ObjectiveCoordinator.validate()
	if not valid then
		error("ObjectiveCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("ObjectiveRuntime", ObjectiveCoordinator.inspect)
	SnapshotManager.registerProvider("objectiveRuntime", ObjectiveCoordinator.getSnapshot)
	initialized = true
	log.success("Objective Runtime initialized")
end

function ObjectiveCoordinator.start()
	if started then
		return
	end
	if not initialized then
		ObjectiveCoordinator.initialize()
	end
	started = true
end

function ObjectiveCoordinator.shutdown()
	DefinitionRuntime.clear()
	started = false
	initialized = false
end

function ObjectiveCoordinator.inspect()
	return ObjectiveDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function ObjectiveCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(DefinitionRuntime)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function ObjectiveCoordinator.validate(): (boolean, string?)
	return ObjectiveDiagnostics.validate(dependencies)
end

function ObjectiveCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Objective Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = ObjectiveCoordinator })
	return lastSelfChecks
end

return ObjectiveCoordinator
