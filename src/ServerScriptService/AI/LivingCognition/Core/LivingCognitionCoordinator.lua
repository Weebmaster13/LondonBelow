--!strict
--[[
	Living Cognition lifecycle coordinator.

	The coordinator owns lifecycle and subsystem coordination only. It does not
	reason by itself and never transforms understanding into gameplay.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)

local Config = require(script.Parent.LivingCognitionConfiguration)
local CognitivePipeline = require(script.Parent.CognitivePipeline)
local LivingCognitionDiagnostics = require(script.Parent.LivingCognitionDiagnostics)
local Registry = require(script.Parent.LivingCognitionRegistry)
local SelfChecks = require(script.Parent.LivingCognitionSelfChecks)
local Signals = require(script.Parent.LivingCognitionSignals)
local Snapshots = require(script.Parent.LivingCognitionSnapshots)
local State = require(script.Parent.LivingCognitionState)
local Types = require(script.Parent.LivingCognitionTypes)
local Validation = require(script.Parent.LivingCognitionValidation)

local Coordinator = {}

local log = Logger.scope("LivingCognition")
local initialized = false
local started = false
local lastSelfChecks: any = nil
local cleanupHandle: Scheduler.TaskHandle? = nil

local function publishFailure(reason: string, payload: any?)
	State.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, {
		reason = reason,
		payload = payload,
		createdAt = os.clock(),
	})
end

function Coordinator.registerEntity(definition: any)
	local ok, reason = Registry.register(definition)
	if not ok then
		publishFailure(reason or "entity registration rejected", definition)
		return {
			ok = false,
			code = if reason == "duplicate entityId"
				then Types.ResultCode.DuplicateId
				else Types.ResultCode.InvalidRequest,
			message = reason,
		}
	end
	EventBus.publishDeferred(Signals.EntityRegistered, {
		entityId = definition.entityId,
		entityKind = definition.entityKind,
	})
	return {
		ok = true,
		code = Types.ResultCode.Ok,
		message = "cognitive entity registered",
	}
end

function Coordinator.acceptObservation(rawObservation: any)
	local result, reason = CognitivePipeline.process(rawObservation, {
		Registry = Registry,
		State = State,
	})
	if result == nil then
		publishFailure(reason or "observation rejected", rawObservation)
		EventBus.publishDeferred(Signals.ObservationRejected, {
			reason = reason,
		})
		return {
			ok = false,
			code = if reason == "unknown cognitive entity"
				then Types.ResultCode.UnknownEntity
				elseif
					reason ~= nil
					and string.find(reason, "forbidden execution field", 1, true) ~= nil
				then Types.ResultCode.RejectedExecutionLeakage
				else Types.ResultCode.InvalidRequest,
			message = reason,
		}
	end
	EventBus.publishDeferred(Signals.ObservationAccepted, { observation = result.observation })
	EventBus.publishDeferred(Signals.EvidenceCreated, { evidence = result.evidence })
	for _, hypothesis in ipairs(result.hypotheses) do
		EventBus.publishDeferred(Signals.HypothesisCreated, { hypothesis = hypothesis })
	end
	for _, thought in ipairs(result.thoughts) do
		EventBus.publishDeferred(Signals.ThoughtPromoted, { thought = thought })
	end
	for _, belief in ipairs(result.beliefs) do
		EventBus.publishDeferred(Signals.BeliefUpdated, { belief = belief })
	end
	return {
		ok = true,
		code = Types.ResultCode.Ok,
		result = result,
	}
end

function Coordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = Coordinator.validate()
	if not valid then
		error("LivingCognition validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("LivingCognition", Coordinator.inspect)
	SnapshotManager.registerProvider("livingCognition", Coordinator.inspect)
	initialized = true
	log.success("Living Cognition initialized")
end

function Coordinator.start()
	if started then
		return
	end
	if not initialized then
		Coordinator.initialize()
	end
	cleanupHandle = Scheduler.interval(10, function()
		State.cleanup(os.clock())
	end, "LivingCognitionCleanup", "LivingCognition", { "AI", "LivingCognition" })
	started = true
end

function Coordinator.shutdown()
	if cleanupHandle ~= nil then
		Scheduler.cancel(cleanupHandle)
		cleanupHandle = nil
	end
	Registry.clear()
	State.clear()
	started = false
	initialized = false
end

function Coordinator.inspect()
	local captured = LivingCognitionDiagnostics.capture({
		initialized = initialized,
		started = started,
		mode = Config.Mode,
		lastSelfChecks = lastSelfChecks,
	}, {
		Registry = Registry,
		State = State,
	})
	State.recordDiagnosticsSnapshot({
		createdAt = os.clock(),
		counts = captured.counts,
		health = captured.health,
	})
	return captured
end

function Coordinator.getSnapshot()
	local snapshot = Snapshots.capture(State, Registry)
	EventBus.publishDeferred(Signals.SnapshotCaptured, { snapshot = snapshot })
	return snapshot
end

function Coordinator.validate(): (boolean, string?)
	return LivingCognitionDiagnostics.validate({
		Validation = Validation,
	})
end

function Coordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Living Cognition self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({
		Config = Config,
		Registry = Registry,
		State = State,
		Pipeline = CognitivePipeline,
		Snapshots = Snapshots,
	})
	return lastSelfChecks
end

return Coordinator
