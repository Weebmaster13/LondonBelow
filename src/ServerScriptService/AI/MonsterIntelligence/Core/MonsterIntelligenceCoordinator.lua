--!strict
--[[
	Phase 15 Monster Intelligence Coordinator.

	Owns monster knowledge, memory, interest, patience, curiosity, territory,
	claimed investigations, shared facts, and intent decisions.

	It does not own Monster AI execution, navigation, pathfinding, NPC creation,
	attacks, damage, animations, client presentation, sounds, Lighting, or
	Workspace mutation.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)

local Config = require(script.Parent.MonsterConfig)
local Group = require(script.Parent.Parent.Group.MonsterGroupCoordinator)
local Memory = require(script.Parent.MonsterMemory)
local Mind = require(script.Parent.MonsterMind)
local Knowledge = require(script.Parent.MonsterKnowledge)
local MonsterDiagnostics = require(script.Parent.MonsterDiagnostics)
local Registry = require(script.Parent.MonsterRegistry)
local Signals = require(script.Parent.MonsterSignals)
local State = require(script.Parent.MonsterState)
local Types = require(script.Parent.MonsterTypes)
local Validator = require(script.Parent.MonsterValidator)
local MonsterSelfChecks = require(script.Parent.Parent.Simulation.MonsterSelfChecks)

local MonsterIntelligenceCoordinator = {}

local log = Logger.scope("MonsterIntelligence")
local initialized = false
local started = false
local cleanupHandle: Scheduler.TaskHandle? = nil
local lastSelfChecks: any = nil

local function now(): number
	return os.clock()
end

local function publishValidationFailure(reason: string, payload: any?)
	State.increment("validationFailures")
	EventBus.publishDeferred(Signals.ValidationFailed, {
		reason = reason,
		payload = payload,
		createdAt = now(),
	})
end

function MonsterIntelligenceCoordinator.registerMonster(definition: any)
	local ok, reason = Registry.register(definition)
	if not ok then
		publishValidationFailure(reason or "monster registration rejected", definition)
		return {
			ok = false,
			code = if reason == "duplicate monster ID"
				then Types.ResultCode.DuplicateMonster
				else Types.ResultCode.InvalidRequest,
			message = reason,
		}
	end

	State.registerMonster(definition.monsterId)
	EventBus.publishDeferred(Signals.MonsterRegistered, {
		monsterId = definition.monsterId,
		archetype = definition.archetype,
	})
	return {
		ok = true,
		code = Types.ResultCode.Ok,
		message = "monster intelligence record registered",
	}
end

function MonsterIntelligenceCoordinator.recordMemory(entry: any)
	if not Registry.exists(entry.monsterId) then
		return false, "unknown monster"
	end
	local ok, reason = Memory.remember(entry)
	if not ok then
		publishValidationFailure(reason or "memory rejected", entry)
		return false, reason
	end
	EventBus.publishDeferred(Signals.MemoryRecorded, entry)
	return true, nil
end

function MonsterIntelligenceCoordinator.updateKnowledge(entry: any)
	if not Registry.exists(entry.monsterId) then
		return false, "unknown monster"
	end
	local ok, reason = Knowledge.update(entry)
	if not ok then
		publishValidationFailure(reason or "knowledge rejected", entry)
		return false, reason
	end
	EventBus.publishDeferred(Signals.KnowledgeUpdated, entry)
	return true, nil
end

function MonsterIntelligenceCoordinator.addInterest(signal: any)
	if not Registry.exists(signal.monsterId) then
		return false, "unknown monster"
	end
	local ok, reason = State.addInterest(signal)
	if not ok then
		publishValidationFailure(reason or "interest rejected", signal)
		return false, reason
	end
	EventBus.publishDeferred(Signals.InterestUpdated, signal)
	return true, nil
end

function MonsterIntelligenceCoordinator.requestIntent(monsterId: string, context: any)
	if not Registry.exists(monsterId) then
		return {
			ok = false,
			code = Types.ResultCode.UnknownMonster,
			message = "unknown monster",
		}
	end

	local safe, unsafeReason = Validator.validateNoUnsafeExecution(context)
	if not safe then
		publishValidationFailure(unsafeReason or "unsafe monster intent request", context)
		return {
			ok = false,
			code = Types.ResultCode.UnsafeRequest,
			message = unsafeReason,
		}
	end

	EventBus.publishDeferred(Signals.IntentRequested, {
		monsterId = monsterId,
		context = context,
	})

	local intent, reason = Mind.decide(monsterId, context or {})
	if intent == nil then
		publishValidationFailure(reason or "intent rejected", context)
		return {
			ok = false,
			code = Types.ResultCode.InvalidRequest,
			message = reason,
		}
	end

	State.recordDecision(intent)
	if intent.kind == "Investigate" or intent.kind == "Search" then
		local targetId = intent.targetZoneId or intent.targetPlayerId
		if targetId ~= nil then
			Group.claimInvestigation(monsterId, targetId, "intent:" .. intent.kind)
		end
	end

	EventBus.publishDeferred(Signals.IntentDecided, intent)
	return {
		ok = true,
		code = Types.ResultCode.Ok,
		intent = intent,
	}
end

function MonsterIntelligenceCoordinator.transitionState(monsterId: string, nextState: string)
	if not Registry.exists(monsterId) then
		return false, "unknown monster"
	end
	local ok, reason = State.transition(monsterId, nextState)
	if not ok then
		publishValidationFailure(reason or "state transition rejected", {
			monsterId = monsterId,
			nextState = nextState,
		})
		return false, reason
	end
	EventBus.publishDeferred(Signals.MonsterStateChanged, {
		monsterId = monsterId,
		state = nextState,
	})
	return true, nil
end

function MonsterIntelligenceCoordinator.decay(monsterId: string, deltaSeconds: number)
	Memory.decay(monsterId, deltaSeconds)
	State.decayInterest(monsterId, deltaSeconds)
end

local function cleanup()
	local expiredClaims = Group.cleanup()
	if expiredClaims > 0 then
		EventBus.publishDeferred(Signals.ClaimExpired, {
			count = expiredClaims,
		})
	end
end

function MonsterIntelligenceCoordinator.initialize()
	if initialized then
		return
	end

	local valid, reason = MonsterIntelligenceCoordinator.validate()
	if not valid then
		error("MonsterIntelligence validation failed: " .. tostring(reason), 0)
	end

	Diagnostics.registerSampler("MonsterIntelligence", MonsterIntelligenceCoordinator.inspect)
	SnapshotManager.registerProvider("monsterIntelligence", MonsterIntelligenceCoordinator.inspect)

	initialized = true
	log.success("Monster Intelligence initialized")
end

function MonsterIntelligenceCoordinator.start()
	if started then
		return
	end
	if not initialized then
		MonsterIntelligenceCoordinator.initialize()
	end
	cleanupHandle = Scheduler.interval(
		5,
		cleanup,
		"MonsterIntelligenceCleanup",
		"MonsterIntelligence",
		{ "AI", "MonsterIntelligence" }
	)
	started = true
end

function MonsterIntelligenceCoordinator.shutdown()
	if cleanupHandle ~= nil then
		Scheduler.cancel(cleanupHandle)
		cleanupHandle = nil
	end
	Registry.clear()
	State.clear()
	Memory.clear()
	Knowledge.clear()
	Group.clear()
	started = false
	initialized = false
end

function MonsterIntelligenceCoordinator.inspect()
	return MonsterDiagnostics.capture({
		initialized = initialized,
		started = started,
		mode = Config.DecisionMode,
		lastSelfChecks = lastSelfChecks,
	}, {
		Registry = Registry,
		State = State,
		Memory = Memory,
		Knowledge = Knowledge,
		Group = Group,
	})
end

function MonsterIntelligenceCoordinator.validate(): (boolean, string?)
	return MonsterDiagnostics.validate({
		Registry = Registry,
		Config = Config,
		Validator = Validator,
	})
end

function MonsterIntelligenceCoordinator.runSelfChecks()
	lastSelfChecks = MonsterSelfChecks.run({
		Config = Config,
		Registry = Registry,
		State = State,
		Memory = Memory,
		Knowledge = Knowledge,
		Group = Group,
		Validator = Validator,
	})
	return lastSelfChecks
end

return MonsterIntelligenceCoordinator
