--!strict
--[[
	Phase 17 Monster AI execution foundation.

	Consumes approved intent/context only and turns it into dry-run execution
	records for future physical Monster AI systems. It does not decide intent,
	horror pacing, story reveals, movement, pathfinding, damage, animation,
	jumpscares, Workspace mutation, client remotes, audio, lighting, or UI.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local BehaviorExecutorFoundation = require(script.Parent.BehaviorExecutorFoundation)
local IntentConsumer = require(script.Parent.IntentConsumer)
local MonsterAIDiagnostics = require(script.Parent.MonsterAIDiagnostics)
local Registry = require(script.Parent.MonsterAIRegistry)
local SelfChecks = require(script.Parent.MonsterAISelfChecks)
local Signals = require(script.Parent.MonsterAISignals)
local Snapshots = require(script.Parent.MonsterAISnapshots)
local State = require(script.Parent.MonsterAIState)
local Types = require(script.Parent.MonsterAITypes)
local Validator = require(script.Parent.MonsterAIValidator)

local MonsterAIService = {}

local log = Logger.scope("MonsterAI")
local initialized = false
local started = false
local lastSelfChecks: any = nil
local observationService: any = nil
local selfCheckActive = false

local function publishFailure(reason: string, payload: any?)
	State.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, {
		reason = reason,
		payload = payload,
		createdAt = os.clock(),
	})
end

local function observeStateChange(intent: any, record: any)
	if
		selfCheckActive
		or observationService == nil
		or type(observationService.observe) ~= "function"
	then
		return
	end
	local ok = observationService.observe({
		id = "Monster.Ignored",
		source = "MonsterAIService",
		metadata = {
			monsterId = intent.monsterId,
			intentId = intent.intentId,
			intentKind = intent.intentKind,
			executionKind = record.executionKind,
			status = record.status,
			dryRun = true,
		},
	})
	if ok then
		State.increment("observationsEmitted")
	end
end

function MonsterAIService.setObservationService(service: any)
	observationService = service
end

function MonsterAIService.registerMonster(definition: any)
	local ok, reason = Registry.register(definition)
	if not ok then
		publishFailure(reason or "monster AI registration rejected", definition)
		return {
			ok = false,
			code = if reason == "duplicate monsterId"
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
		message = "Monster AI dry-run record registered",
	}
end

function MonsterAIService.consumeApprovedIntent(rawIntent: any)
	local intent, reason = IntentConsumer.normalize(rawIntent)
	if intent == nil then
		publishFailure(reason or "intent rejected", rawIntent)
		EventBus.publishDeferred(Signals.IntentRejected, { reason = reason })
		local unsafeReason = reason ~= nil
			and (
				string.find(reason, "forbidden execution field", 1, true) ~= nil
				or string.find(reason, "payload", 1, true) ~= nil
				or string.find(reason, "Roblox Instances", 1, true) ~= nil
				or string.find(reason, "cyclic", 1, true) ~= nil
				or string.find(reason, "unsafe runtime", 1, true) ~= nil
			)
		return {
			ok = false,
			code = if reason == "Director approval is required"
				then Types.ResultCode.MissingApproval
				elseif reason == "intent is expired" then Types.ResultCode.ExpiredIntent
				elseif
					reason == "intentKind is not supported"
				then Types.ResultCode.UnsupportedIntent
				elseif unsafeReason then Types.ResultCode.UnsafePayload
				else Types.ResultCode.InvalidRequest,
			message = reason,
		}
	end
	if not Registry.exists(intent.monsterId) then
		publishFailure("unknown monster", intent)
		return {
			ok = false,
			code = Types.ResultCode.UnknownMonster,
			message = "unknown monster",
		}
	end
	if State.hasIntent(intent.intentId) then
		State.recordIntent(intent, Types.IntentStatus.Rejected, "duplicate intentId")
		EventBus.publishDeferred(
			Signals.IntentRejected,
			{ reason = "duplicate intentId", intentId = intent.intentId }
		)
		return {
			ok = false,
			code = Types.ResultCode.DuplicateIntent,
			message = "duplicate intentId",
		}
	end

	State.recordIntent(intent, Types.IntentStatus.Accepted, "approved intent accepted")
	EventBus.publishDeferred(Signals.IntentAccepted, intent)

	local plan, planReason = BehaviorExecutorFoundation.plan(intent)
	if plan == nil then
		State.recordIntent(intent, Types.IntentStatus.Deferred, planReason)
		return {
			ok = false,
			code = Types.ResultCode.UnsupportedIntent,
			message = planReason,
		}
	end
	State.recordExecution(plan)
	EventBus.publishDeferred(Signals.IntentPlanned, plan)

	local dryRun = BehaviorExecutorFoundation.applyDryRun(plan)
	State.recordExecution(dryRun)
	EventBus.publishDeferred(Signals.IntentDryRunApplied, dryRun)
	observeStateChange(intent, dryRun)

	return {
		ok = true,
		code = Types.ResultCode.Ok,
		message = "approved Monster AI intent recorded as dry-run execution",
		record = dryRun,
	}
end

function MonsterAIService.initialize()
	if initialized then
		return
	end
	local valid, reason = MonsterAIService.validate()
	if not valid then
		error("MonsterAIService validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("MonsterAIService", MonsterAIService.inspect)
	SnapshotManager.registerProvider("monsterAIExecution", MonsterAIService.getSnapshot)
	initialized = true
	log.success("Monster AI execution foundation initialized")
end

function MonsterAIService.start()
	if started then
		return
	end
	if not initialized then
		MonsterAIService.initialize()
	end
	started = true
end

function MonsterAIService.shutdown()
	Registry.clear()
	State.clear()
	started = false
	initialized = false
end

function MonsterAIService.inspect()
	return MonsterAIDiagnostics.capture({
		initialized = initialized,
		started = started,
		mode = Types.ExecutionMode,
		lastSelfChecks = lastSelfChecks,
	}, {
		Registry = Registry,
		State = State,
	})
end

function MonsterAIService.getSnapshot()
	local snapshot = Snapshots.capture(Registry, State)
	State.recordSnapshot({
		capturedAt = snapshot.capturedAt,
		monsterCount = snapshot.registry.monsterCount,
		intentCount = #snapshot.state.intentRecords,
		executionRecordCount = #snapshot.state.executionRecords,
	})
	EventBus.publishDeferred(Signals.SnapshotCaptured, { snapshot = snapshot })
	return snapshot
end

function MonsterAIService.validate(): (boolean, string?)
	return MonsterAIDiagnostics.validate({
		Registry = Registry,
		State = State,
		Validator = Validator,
	})
end

function MonsterAIService.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Monster AI self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	selfCheckActive = true
	local ok, result = pcall(function()
		return SelfChecks.run({
			Registry = Registry,
			State = State,
			Service = MonsterAIService,
			Snapshots = Snapshots,
		})
	end)
	selfCheckActive = false
	lastSelfChecks = if ok then result else { ok = false, reason = tostring(result) }
	return lastSelfChecks
end

return MonsterAIService
