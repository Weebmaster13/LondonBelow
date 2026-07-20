--!strict
--[[
	Chapter 0 Gameplay Flow Runtime coordinator.

	This runtime owns objective sequencing and checkpoint eligibility only. It
	consumes authoritative events from existing runtimes and does not validate
	interactions, mutate environmental objects, execute presentation, create
	remotes, persist saves, or grant client authority.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local DiagnosticsRuntime = require(script.Parent.GameplayFlowDiagnostics)
local Evidence = require(script.Parent.GameplayFlowEvidence)
local Runtime = require(script.Parent.GameplayFlowRuntime)
local SelfChecks = require(script.Parent.GameplayFlowSelfChecks)
local Serialization = require(script.Parent.GameplayFlowSerialization)
local Signals = require(script.Parent.GameplayFlowSignals)
local Snapshots = require(script.Parent.GameplayFlowObjectiveSnapshots)
local Types = require(script.Parent.GameplayFlowTypes)

local GameplayFlowCoordinator = {}

local log = Logger.scope(Types.RuntimeName)
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

function GameplayFlowCoordinator.initialize()
	if initialized then
		return
	end
	local registered = Runtime.registerChapter0Objectives()
	if not registered.ok then
		error("GameplayFlowCoordinator initialization failed: " .. tostring(registered.message), 0)
	end
	local valid, reason = GameplayFlowCoordinator.validate()
	if not valid then
		error("GameplayFlowCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler(Types.ProviderName, GameplayFlowCoordinator.inspect)
	SnapshotManager.registerProvider(Types.ProviderName, GameplayFlowCoordinator.getSnapshot)
	initialized = true
	EventBus.publishDeferred(Signals.RuntimeInitialized, { providerName = Types.ProviderName })
	log.success("Gameplay Flow Runtime initialized")
end

function GameplayFlowCoordinator.start()
	if started then
		return
	end
	if not initialized then
		GameplayFlowCoordinator.initialize()
	end
	started = true
	EventBus.publishDeferred(Signals.RuntimeStarted, { providerName = Types.ProviderName })
end

function GameplayFlowCoordinator.shutdown()
	Runtime.clear()
	Snapshots.clear()
	started = false
	initialized = false
	EventBus.publishDeferred(Signals.RuntimeShutdown, { providerName = Types.ProviderName })
end

function GameplayFlowCoordinator.recordGameplayEvent(event: any)
	if not initialized then
		return result(
			false,
			Types.ResultCode.RuntimeUnavailable,
			"Gameplay Flow Runtime is not initialized"
		)
	end
	local recorded = Runtime.recordEvent(event)
	if not recorded.ok then
		EventBus.publishDeferred(Signals.ValidationFailed, {
			reason = recorded.message,
		})
		return recorded
	end
	local activeObjective = Runtime.getActiveObjective()
	EventBus.publishDeferred(Signals.GameplayEvent, Serialization.deepCopy(event))
	EventBus.publishDeferred(Signals.ObjectiveChanged, {
		activeObjective = activeObjective,
	})
	EventBus.publishDeferred(Signals.ProgressUpdated, {
		activeObjective = activeObjective,
	})
	if Runtime.inspect().checkpointEligible == true then
		EventBus.publishDeferred(Signals.CheckpointUnlocked, {
			activeObjective = activeObjective,
		})
	end
	return recorded
end

function GameplayFlowCoordinator.evaluateObjectives(reason: string?)
	if not initialized then
		return result(
			false,
			Types.ResultCode.RuntimeUnavailable,
			"Gameplay Flow Runtime is not initialized"
		)
	end
	return Runtime.evaluate(reason)
end

function GameplayFlowCoordinator.getActiveObjective(): string?
	return Runtime.getActiveObjective()
end

function GameplayFlowCoordinator.inspect()
	return DiagnosticsRuntime.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, Runtime.Registry, Runtime.State, Evidence)
end

function GameplayFlowCoordinator.getSnapshot()
	local diagnostics = GameplayFlowCoordinator.inspect()
	local snapshot = Snapshots.capture(Runtime.Registry, Runtime.State, Evidence, diagnostics)
	EventBus.publishDeferred(Signals.SnapshotCaptured, {
		snapshot = Serialization.deepCopy(snapshot),
	})
	return snapshot
end

function GameplayFlowCoordinator.validate(): (boolean, string?)
	return DiagnosticsRuntime.validate(Runtime.Registry)
end

function GameplayFlowCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Gameplay Flow Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	local wasInitialized = initialized
	Runtime.clear()
	lastSelfChecks = SelfChecks.run()
	Runtime.clear()
	if wasInitialized then
		Runtime.registerChapter0Objectives()
	end
	return lastSelfChecks
end

return GameplayFlowCoordinator
