--!strict
--[[
	Horror Orchestration Framework.

	Coordinates approved horror pressure across Directors, Monster Intelligence,
	gameplay foundations, and future narrative/presentation systems.

	It never executes horror: no Workspace mutation, no monster movement, no
	pathfinding, no sounds, no Lighting changes, no client remotes, no final UI,
	no final scares, and no Chapter content.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)

local Config = require(script.Parent.HorrorOrchestrationConfig)
local HorrorOrchestrationDiagnostics = require(script.Parent.HorrorOrchestrationDiagnostics)
local Signals = require(script.Parent.HorrorOrchestrationSignals)
local State = require(script.Parent.HorrorOrchestrationState)
local Types = require(script.Parent.HorrorOrchestrationTypes)
local Validator = require(script.Parent.HorrorOrchestrationValidator)

local EmotionalBeatModel = require(script.Parent.Parent.Models.EmotionalBeatModel)
local EscalationModel = require(script.Parent.Parent.Models.EscalationModel)
local PressureBudgetModel = require(script.Parent.Parent.Models.PressureBudgetModel)
local ReleaseDecisionModel = require(script.Parent.Parent.Models.ReleaseDecisionModel)
local ScareEligibilityModel = require(script.Parent.Parent.Models.ScareEligibilityModel)
local SilenceDecisionModel = require(script.Parent.Parent.Models.SilenceDecisionModel)
local ChasePreparationModel = require(script.Parent.Parent.Models.ChasePreparationModel)

local EnvironmentCoordination = require(script.Parent.Parent.Coordination.EnvironmentCoordination)
local GameplayCoordination = require(script.Parent.Parent.Coordination.GameplayCoordination)
local MonsterCoordination = require(script.Parent.Parent.Coordination.MonsterCoordination)
local NarrativeCoordination = require(script.Parent.Parent.Coordination.NarrativeCoordination)
local SensoryCoordination = require(script.Parent.Parent.Coordination.SensoryCoordination)

local HorrorPressureQueue = require(script.Parent.Parent.Requests.HorrorPressureQueue)
local HorrorPressureRequest = require(script.Parent.Parent.Requests.HorrorPressureRequest)
local HorrorPressureRouter = require(script.Parent.Parent.Requests.HorrorPressureRouter)
local HorrorPressureValidator = require(script.Parent.Parent.Requests.HorrorPressureValidator)
local HorrorOrchestrationSelfChecks =
	require(script.Parent.Parent.Simulation.HorrorOrchestrationSelfChecks)

local HorrorOrchestrator = {}

local log = Logger.scope("HorrorOrchestrator")
local initialized = false
local started = false
local cleanupHandle: Scheduler.TaskHandle? = nil
local lastSelfChecks: any = nil

local function now(): number
	return os.clock()
end

local function reject(request: any, reason: string)
	State.increment("rejected")
	State.increment("validationFailures")
	EventBus.publishDeferred(Signals.RequestRejected, {
		request = request,
		reason = reason,
	})
	return {
		ok = false,
		code = if reason == "duplicate requestId"
			then Types.ResultCode.DuplicateRequest
			elseif reason == "pressure request is expired" then Types.ResultCode.Expired
			else Types.ResultCode.InvalidRequest,
		message = reason,
	}
end

local function expireQueued()
	for _, request in ipairs(HorrorPressureQueue.expire(now())) do
		State.increment("expired")
		EventBus.publishDeferred(Signals.RequestExpired, {
			request = request,
			reason = "pressure request expired in queue",
		})
	end
end

local function combineRequests(action: string, request: any)
	local combined = {}
	for _, group in ipairs({
		SensoryCoordination.build(action, request),
		EnvironmentCoordination.build(action, request),
		MonsterCoordination.build(action, request),
		GameplayCoordination.build(action, request),
		NarrativeCoordination.build(action, request),
	}) do
		for _, item in ipairs(group) do
			table.insert(combined, item)
		end
	end
	return combined
end

local function decide(request: any)
	local previousBudget = State.getPressureBudget()
	local budget = PressureBudgetModel.fromRequest(previousBudget, request)
	State.applyLoads(budget.sensoryLoad, budget.emotionalLoad, budget.multiplayerLoad)
	State.updatePressure(
		budget.currentPressure - previousBudget.currentPressure,
		"request:" .. request.requestKind
	)

	local reasons = {}
	local protectedBeat, beatReasons = EmotionalBeatModel.evaluate(request)
	for _, reason in ipairs(beatReasons) do
		table.insert(reasons, reason)
	end

	local scareEligible, scareReasons = ScareEligibilityModel.evaluate(budget, request)
	local release, releaseReasons = ReleaseDecisionModel.evaluate(budget, request)
	local silence, silenceReasons = SilenceDecisionModel.evaluate(budget, request)
	local escalate, escalationReasons = EscalationModel.evaluate(budget, request)
	local chasePrepare, chaseReasons = ChasePreparationModel.evaluate(budget, request)

	local action = "NoAction"
	if protectedBeat or silence then
		action = "Silence"
	elseif release then
		action = "Release"
	elseif not scareEligible and request.requestKind == "ScareCandidate" then
		action = "Suppress"
	elseif chasePrepare and request.requestKind == "ChasePreparation" then
		action = "PrepareChase"
	elseif escalate then
		action = "Escalate"
	elseif request.requestKind == "MonsterIntent" then
		action = "CoordinateMonster"
	elseif request.requestKind == "DirectorPressure" then
		action = "CoordinateSensory"
	end

	for _, list in ipairs({
		scareReasons,
		releaseReasons,
		silenceReasons,
		escalationReasons,
		chaseReasons,
	}) do
		for _, reason in ipairs(list) do
			table.insert(reasons, reason)
		end
	end
	if #reasons == 0 then
		table.insert(reasons, "no horror action is currently the best action")
	end

	local bundle, bundleReason = HorrorPressureRouter.createBundle(
		action,
		request,
		reasons,
		combineRequests(action, request),
		{
			pressureBudget = budget,
			scareEligible = scareEligible,
			release = release,
			silence = silence,
			escalate = escalate,
			chasePrepare = chasePrepare,
		}
	)

	if bundle == nil then
		return nil, bundleReason
	end

	State.recordDecision(bundle)
	EventBus.publishDeferred(Signals.DecisionMade, { bundle = bundle })
	if bundle.suppressed then
		EventBus.publishDeferred(Signals.DecisionSuppressed, { bundle = bundle })
	end
	if bundle.releasePlanned then
		EventBus.publishDeferred(Signals.ReleasePlanned, { bundle = bundle })
	end
	EventBus.publishDeferred(Signals.BundleCreated, { bundle = bundle })
	return bundle, nil
end

function HorrorOrchestrator.submitPressureRequest(rawRequest: any)
	local request = HorrorPressureRequest.create(rawRequest)
	local currentTime = now()

	if type(request.requestId) == "string" and State.hasRequest(request.requestId) then
		State.increment("duplicates")
		return reject(request, "duplicate requestId")
	end

	local valid, reason = HorrorPressureValidator.validate(request, currentTime)
	if not valid then
		return reject(request, reason or "pressure request rejected")
	end

	State.markRequest(request.requestId)
	State.increment("submitted")
	local queued, queueReason = HorrorPressureQueue.enqueue(request)
	if not queued then
		return reject(request, queueReason or "pressure queue rejected request")
	end
	EventBus.publishDeferred(Signals.RequestSubmitted, { request = request })
	return {
		ok = true,
		code = Types.ResultCode.Queued,
		message = "pressure request queued",
	}
end

function HorrorOrchestrator.processNext(): boolean
	expireQueued()
	local request = HorrorPressureQueue.dequeue()
	if request == nil then
		return false
	end
	local bundle, reason = decide(request)
	if bundle == nil then
		reject(request, reason or "orchestration decision rejected")
	end
	return true
end

function HorrorOrchestrator.processAll(maxCount: number?): number
	local processed = 0
	local limit = maxCount or 20
	while processed < limit and HorrorOrchestrator.processNext() do
		processed += 1
	end
	return processed
end

function HorrorOrchestrator.initialize()
	if initialized then
		return
	end
	local valid, reason = HorrorOrchestrator.validate()
	if not valid then
		error("HorrorOrchestrator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("HorrorOrchestrator", HorrorOrchestrator.inspect)
	SnapshotManager.registerProvider("horrorOrchestration", HorrorOrchestrator.inspect)
	initialized = true
	log.success("Horror Orchestration initialized")
end

function HorrorOrchestrator.start()
	if started then
		return
	end
	if not initialized then
		HorrorOrchestrator.initialize()
	end
	cleanupHandle = Scheduler.interval(
		Config.CleanupIntervalSeconds,
		expireQueued,
		"HorrorOrchestrationCleanup",
		"HorrorOrchestrator",
		{ "Horror", "Orchestration" }
	)
	started = true
end

function HorrorOrchestrator.shutdown()
	if cleanupHandle ~= nil then
		Scheduler.cancel(cleanupHandle)
		cleanupHandle = nil
	end
	HorrorPressureQueue.clear()
	State.clear()
	started = false
	initialized = false
end

function HorrorOrchestrator.inspect()
	return HorrorOrchestrationDiagnostics.capture({
		initialized = initialized,
		started = started,
		mode = Config.DefaultMode,
		lastSelfChecks = lastSelfChecks,
	}, {
		State = State,
		Queue = HorrorPressureQueue,
	})
end

function HorrorOrchestrator.validate(): (boolean, string?)
	return HorrorOrchestrationDiagnostics.validate({
		Validator = Validator,
	})
end

function HorrorOrchestrator.runSelfChecks()
	lastSelfChecks = HorrorOrchestrationSelfChecks.run(HorrorOrchestrator)
	return lastSelfChecks
end

return HorrorOrchestrator
