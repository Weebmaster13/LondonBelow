--!strict
--[[
	Phase 19 Narrative Runtime coordinator.

	Owns server-authoritative narrative schema state, story gates, reveal
	eligibility, and emotional beat protection. It does not write final story,
	dialogue, Chapter content, cutscenes, UI, horror pacing, Monster AI behavior,
	Workspace, Lighting, or Audio effects.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local BeatRuntime = require(script.Parent.NarrativeBeatRuntime)
local EmotionalBeatRuntime = require(script.Parent.EmotionalBeatRuntime)
local NarrativeDiagnostics = require(script.Parent.NarrativeDiagnostics)
local NarrativeSelfChecks = require(script.Parent.NarrativeSelfChecks)
local NarrativeSnapshots = require(script.Parent.NarrativeSnapshots)
local RevealEligibilityRuntime = require(script.Parent.RevealEligibilityRuntime)
local Serialization = require(script.Parent.NarrativeSerialization)
local Signals = require(script.Parent.NarrativeSignals)
local State = require(script.Parent.NarrativeState)
local StoryGateRuntime = require(script.Parent.StoryGateRuntime)
local Types = require(script.Parent.NarrativeTypes)
local Validation = require(script.Parent.NarrativeValidation)

local NarrativeCoordinator = {}

local log = Logger.scope("Narrative")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local function recordFailure(reason: string, payload: any?)
	State.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

local function codeFor(reason: string?): string
	if
		reason ~= nil
		and (
			string.find(reason, "forbidden field", 1, true)
			or string.find(reason, "payload", 1, true)
			or string.find(reason, "unsafe runtime", 1, true)
			or string.find(reason, "cyclic", 1, true)
		)
	then
		return Types.ResultCode.UnsafePayload
	end
	return Types.ResultCode.InvalidRequest
end

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

function NarrativeCoordinator.registerBeat(beat: any)
	local ok, reason = BeatRuntime.register(State, beat)
	if not ok then
		recordFailure(reason or "beat rejected", beat)
		return result(
			false,
			if reason == "duplicate beatId" then Types.ResultCode.DuplicateBeat else codeFor(reason),
			reason
		)
	end
	EventBus.publishDeferred(Signals.BeatRegistered, { beatId = beat.beatId })
	return result(true, Types.ResultCode.Ok, "beat registered")
end

function NarrativeCoordinator.registerStoryGate(gate: any)
	local ok, reason = StoryGateRuntime.register(State, gate)
	if not ok then
		recordFailure(reason or "story gate rejected", gate)
		return result(
			false,
			if reason == "duplicate gateId" then Types.ResultCode.DuplicateGate else codeFor(reason),
			reason
		)
	end
	EventBus.publishDeferred(Signals.StoryGateRegistered, { gateId = gate.gateId })
	return result(true, Types.ResultCode.Ok, "story gate registered")
end

function NarrativeCoordinator.grantRevealEligibility(reveal: any)
	local ok, reason = RevealEligibilityRuntime.grant(State, reveal)
	if not ok then
		recordFailure(reason or "reveal eligibility rejected", reveal)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.RevealEligibilityGranted, { revealId = reveal.revealId })
	return result(true, Types.ResultCode.Ok, "reveal eligibility granted")
end

function NarrativeCoordinator.registerEmotionalProtection(beat: any)
	local ok, reason = EmotionalBeatRuntime.registerProtection(State, beat)
	if not ok then
		recordFailure(reason or "emotional beat rejected", beat)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.EmotionalProtectionRegistered,
		{ emotionalBeatId = beat.emotionalBeatId }
	)
	return result(true, Types.ResultCode.Ok, "emotional protection registered")
end

function NarrativeCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = NarrativeCoordinator.validate()
	if not valid then
		error("NarrativeCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("NarrativeRuntime", NarrativeCoordinator.inspect)
	SnapshotManager.registerProvider("narrativeRuntime", NarrativeCoordinator.getSnapshot)
	initialized = true
	log.success("Narrative Runtime initialized")
end

function NarrativeCoordinator.start()
	if started then
		return
	end
	if not initialized then
		NarrativeCoordinator.initialize()
	end
	started = true
end

function NarrativeCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function NarrativeCoordinator.inspect()
	return NarrativeDiagnostics.capture({
		initialized = initialized,
		started = started,
		mode = Types.Mode,
		lastSelfChecks = lastSelfChecks,
	}, { State = State })
end

function NarrativeCoordinator.getSnapshot()
	local snapshot = NarrativeSnapshots.capture(State)
	State.recordSnapshot({
		capturedAt = snapshot.capturedAt,
		beatCount = snapshot.state.beatCount,
		gateCount = snapshot.state.gateCount,
	})
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function NarrativeCoordinator.validate(): (boolean, string?)
	return NarrativeDiagnostics.validate({ Validation = Validation })
end

function NarrativeCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Narrative self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = NarrativeSelfChecks.run({ Service = NarrativeCoordinator })
	return lastSelfChecks
end

return NarrativeCoordinator
