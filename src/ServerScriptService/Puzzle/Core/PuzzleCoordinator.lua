--!strict
--[[
	Phase 24 Puzzle Runtime Coordinator.

	Server-authoritative puzzle schema foundation. It records puzzle structure,
	graphs, conditions, dependencies, and progress schemas without solving
	puzzles or executing gameplay.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local DefinitionRuntime = require(script.Parent.PuzzleDefinitionRuntime)
local PuzzleDiagnostics = require(script.Parent.PuzzleDiagnostics)
local ProgressRuntime = require(script.Parent.PuzzleProgressRuntime)
local SelfChecks = require(script.Parent.PuzzleSelfChecks)
local Serialization = require(script.Parent.PuzzleSerialization)
local Signals = require(script.Parent.PuzzleSignals)
local Snapshots = require(script.Parent.PuzzleSnapshots)
local Types = require(script.Parent.PuzzleTypes)
local Validation = require(script.Parent.PuzzleValidation)

local PuzzleCoordinator = {}

local log = Logger.scope("PuzzleRuntime")
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
	if reason == "duplicate puzzleId" then
		return Types.ResultCode.DuplicatePuzzle
	elseif reason == "unknown puzzleId" then
		return Types.ResultCode.UnknownPuzzle
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

function PuzzleCoordinator.registerPuzzle(schema: any)
	local ok, reason = DefinitionRuntime.register(schema)
	if not ok then
		recordFailure(reason or "puzzle schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.PuzzleRegistered, { puzzleId = schema.puzzleId })
	return result(true, Types.ResultCode.Ok, "puzzle schema registered")
end

function PuzzleCoordinator.recordProgress(record: any)
	local ok, reason = ProgressRuntime.record(DefinitionRuntime, record)
	if not ok then
		recordFailure(reason or "puzzle progress rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ProgressRecorded, { progressId = record.progressId })
	return result(true, Types.ResultCode.Ok, "puzzle progress recorded")
end

function PuzzleCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = PuzzleCoordinator.validate()
	if not valid then
		error("PuzzleCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("PuzzleRuntime", PuzzleCoordinator.inspect)
	SnapshotManager.registerProvider("puzzleRuntime", PuzzleCoordinator.getSnapshot)
	initialized = true
	log.success("Puzzle Runtime initialized")
end

function PuzzleCoordinator.start()
	if started then
		return
	end
	if not initialized then
		PuzzleCoordinator.initialize()
	end
	started = true
end

function PuzzleCoordinator.shutdown()
	DefinitionRuntime.clear()
	started = false
	initialized = false
end

function PuzzleCoordinator.inspect()
	return PuzzleDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function PuzzleCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(DefinitionRuntime)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function PuzzleCoordinator.validate(): (boolean, string?)
	return PuzzleDiagnostics.validate(dependencies)
end

function PuzzleCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Puzzle Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = PuzzleCoordinator })
	return lastSelfChecks
end

return PuzzleCoordinator
