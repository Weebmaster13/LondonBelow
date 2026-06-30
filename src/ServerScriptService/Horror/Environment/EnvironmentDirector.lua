--!strict
--[[
	Environment Director for London Engine.

	Owns server-authoritative approval of environmental reactions: fog, rain,
	wind, door pressure, prop pressure, room pressure, street pressure, building
	attention, release support, chase support, puzzle fairness support, and safe
	room protection.

	Does not mutate Workspace, change Lighting, play audio, move monsters,
	control puzzles, own story canon, trust clients, or create Chapter 1 content.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)

local DirectorApproval = require(Core.Directors.DirectorApproval)
local DirectorCoordinator = require(Core.Directors.DirectorCoordinator)
local DirectorRequest = require(Core.Directors.DirectorRequest)
local DirectorTypes = require(Core.Directors.DirectorTypes)
local ObservationSignals = require(ServerScriptService.Horror.Observation.ObservationSignals)

local Config = require(script.Parent.EnvironmentDirectorConfig)
local EnvironmentDiagnostics = require(script.Parent.EnvironmentDiagnostics)
local EnvironmentExecutionBridge = require(script.Parent.EnvironmentExecutionBridge)
local EnvironmentMemory = require(script.Parent.EnvironmentMemory)
local EnvironmentPressureModel = require(script.Parent.EnvironmentPressureModel)
local EnvironmentReactionRegistry = require(script.Parent.EnvironmentReactionRegistry)
local EnvironmentReactionSelector = require(script.Parent.EnvironmentReactionSelector)
local EnvironmentSignals = require(script.Parent.EnvironmentSignals)
local EnvironmentState = require(script.Parent.EnvironmentState)
local EnvironmentZoneContext = require(script.Parent.EnvironmentZoneContext)
local Types = require(script.Parent.EnvironmentDirectorTypes)

local EnvironmentDirector = {}

type DirectorRequestType = DirectorTypes.DirectorRequest
type DirectorApprovalType = DirectorTypes.DirectorApproval
type SelectionContext = Types.SelectionContext
type ReactionDecision = Types.ReactionDecision

local log = Logger.scope("EnvironmentDirector")
local initialized = false
local started = false
local busDisconnects: { () -> () } = {}
local cleanupHandle: Scheduler.TaskHandle? = nil
local observationCount = 0
local approvalCount = 0
local rejectedCount = 0
local deferredCount = 0
local cancelledCount = 0
local pressureScore = 0
local lastSelection: ReactionDecision? = nil

local function now(): number
	return os.clock()
end

local function preferredCategoryFromRequest(request: DirectorRequestType): Types.ReactionCategory?
	local category = request.context.preferredCategory or request.metadata.preferredCategory

	if type(category) == "string" and Types.ValidReactionCategories[category] then
		return category :: Types.ReactionCategory
	end

	if request.requestKind == "RequestEnvironmentReaction" then
		return nil
	elseif request.requestKind == "RequestLightingChange" then
		return "RoomPressure"
	elseif request.requestKind == "RequestMonsterReveal" then
		return "BuildingAttention"
	end

	return nil
end

local function buildContextFromRequest(request: DirectorRequestType): SelectionContext
	local zone = EnvironmentZoneContext.fromPayload(request)
	local pressureState =
		EnvironmentPressureModel.fromRequest(request, EnvironmentState.getPressureState())
	local partySize = if type(request.context.partySize) == "number"
		then request.context.partySize
		else 1
	local userId = if type(request.context.playerUserId) == "number"
		then request.context.playerUserId
		else nil

	return {
		playerUserId = userId,
		partySize = math.max(1, math.floor(partySize)),
		zoneId = zone.zoneId,
		zoneKind = zone.zoneKind,
		pressureState = pressureState,
		requestKind = request.requestKind,
		preferredCategory = preferredCategoryFromRequest(request),
		metadata = table.clone(request.metadata),
		tags = table.clone(request.tags),
		now = now(),
	}
end

local function applySelectedDecision(decision: ReactionDecision)
	lastSelection = decision
	EnvironmentMemory.recordDecision(decision)

	if
		decision.status ~= "Selected"
		or decision.reactionId == nil
		or decision.executionKind == nil
	then
		EnvironmentMemory.recordSuppressed(
			decision.reactionId or "none",
			decision.reason,
			decision.context.zoneId,
			decision.createdAt
		)
		EventBus.publishDeferred(EnvironmentSignals.ReactionDeferred, { decision = decision })
		return
	end

	local definition = EnvironmentReactionRegistry.get(decision.reactionId)

	if definition == nil then
		EnvironmentMemory.recordFailed(
			decision.reactionId,
			"Missing reaction definition",
			decision.context.zoneId,
			decision.createdAt
		)
		EventBus.publishDeferred(EnvironmentSignals.ReactionRejected, { decision = decision })
		return
	end

	local executionOk, executionErr = EnvironmentExecutionBridge.request({
		executionKind = definition.executionKind,
		reactionId = definition.id,
		category = definition.category,
		intensity = definition.intensity,
		zoneId = decision.context.zoneId,
		zoneKind = decision.context.zoneKind,
		reason = decision.reason,
		createdAt = decision.createdAt,
		metadata = table.clone(decision.context.metadata),
	})

	if not executionOk then
		EnvironmentMemory.recordFailed(
			definition.id,
			executionErr or "Execution bridge rejected",
			decision.context.zoneId,
			decision.createdAt
		)
		EventBus.publishDeferred(
			EnvironmentSignals.ReactionRejected,
			{ decision = decision, error = executionErr }
		)
		return
	end

	EnvironmentState.setCooldowns(
		definition.id,
		decision.context.zoneId,
		definition.cooldownSeconds,
		definition.zoneCooldownSeconds,
		decision.createdAt
	)
	EnvironmentMemory.recordReaction(
		definition.id,
		definition.category,
		decision.context.zoneId,
		decision.createdAt
	)

	EventBus.publishDeferred(EnvironmentSignals.ReactionSelected, { decision = decision })
end

function EnvironmentDirector.observe(observation: any)
	observationCount += 1

	local nextState, nextScore, reasons =
		EnvironmentPressureModel.fromObservation(observation, pressureScore)
	local previousState = EnvironmentState.getPressureState()
	local transitionOk, transitionErr =
		EnvironmentPressureModel.validateTransition(previousState, nextState)

	if not transitionOk then
		nextState = previousState
		table.insert(reasons, transitionErr or "pressure transition suppressed")
	end

	pressureScore = nextScore

	if EnvironmentState.setPressureState(nextState) and nextState ~= previousState then
		EventBus.publishDeferred(EnvironmentSignals.PressureChanged, {
			previous = previousState,
			current = nextState,
			score = pressureScore,
			reasons = reasons,
		})
	end

	local zone = EnvironmentZoneContext.fromPayload(observation)
	EnvironmentState.setZonePressure(zone.zoneId, nextState, pressureScore, now())
	EventBus.publishDeferred(EnvironmentSignals.ZonePressureChanged, {
		zoneId = zone.zoneId,
		zoneKind = zone.zoneKind,
		pressureState = nextState,
		score = pressureScore,
	})
end

function EnvironmentDirector.requestApproval(request: DirectorRequestType): DirectorApprovalType
	approvalCount += 1

	local valid, err = DirectorRequest.validate(request)

	if not valid then
		rejectedCount += 1
		local requestId = if type(request) == "table"
				and type(request.requestId) == "string"
			then request.requestId
			else "<malformed>"
		return DirectorApproval.create(
			requestId,
			"Rejected",
			err or "Invalid request.",
			"Environment",
			nil,
			{}
		)
	end

	local context = buildContextFromRequest(request)
	local decision = EnvironmentReactionSelector.select(context)
	decision.requestId = request.requestId
	applySelectedDecision(decision)

	if decision.status == "Selected" then
		local approval = DirectorApproval.create(
			request.requestId,
			"Approved",
			decision.reason,
			"Environment",
			nil,
			{
				reactionId = decision.reactionId,
				category = decision.category,
				executionKind = decision.executionKind,
			}
		)
		EventBus.publishDeferred(
			EnvironmentSignals.ApprovalDecided,
			{ approval = approval, decision = decision }
		)
		return approval
	end

	deferredCount += 1
	return DirectorApproval.create(
		request.requestId,
		"Deferred",
		decision.reason,
		"Environment",
		nil,
		{
			blocked = decision.blocked,
		}
	)
end

function EnvironmentDirector.cancelRequest(requestId: string, reason: string?): DirectorApprovalType
	cancelledCount += 1
	local approval = DirectorApproval.create(
		requestId,
		"Cancelled",
		reason or "Environment request cancelled.",
		"Environment",
		nil,
		{}
	)
	EventBus.publishDeferred(EnvironmentSignals.ReactionCancelled, { approval = approval })
	return approval
end

function EnvironmentDirector.getCapabilities()
	return {
		{
			id = "Environment.Reaction",
			description = "Approves subtle world reactions without executing physical changes.",
			requestKinds = {
				"RequestEnvironmentReaction",
				"RequestLightingChange",
				"RequestAudioCue",
				"RequestMonsterReveal",
				"RequestPuzzleHint",
				"RequestPerformanceBudget",
			},
		},
	}
end

function EnvironmentDirector.getHealth()
	return {
		name = "Environment",
		status = if started then "Running" elseif initialized then "Ready" else "NotInitialized",
		healthy = initialized,
		message = nil,
		uptime = 0,
		lastError = nil,
	}
end

function EnvironmentDirector.getSnapshot()
	return EnvironmentDirector.inspect()
end

function EnvironmentDirector.getDiagnostics()
	return EnvironmentDirector.inspect()
end

function EnvironmentDirector.describe()
	return {
		name = "Environment",
		displayName = "Environment Director",
		responsibilities = {
			"environmental reaction approvals",
			"world pressure interpretation",
			"environment memory",
			"execution bridge contracts",
		},
		doesNotOwn = {
			"monster movement",
			"final audio playback",
			"final lighting playback",
			"puzzle truth",
			"story canon",
			"final art",
			"client-owned weather truth",
			"Chapter 1 content",
		},
		capabilities = EnvironmentDirector.getCapabilities(),
	}
end

function EnvironmentDirector.initialize()
	if initialized then
		return
	end

	Diagnostics.registerSampler("EnvironmentDirector", EnvironmentDirector.inspect)
	SnapshotManager.registerProvider("environmentDirector", EnvironmentDirector.inspect)

	DirectorCoordinator.registerDirector(EnvironmentDirector :: any)

	table.insert(
		busDisconnects,
		EventBus.subscribe(ObservationSignals.Accepted, function(event)
			if event.payload ~= nil then
				EnvironmentDirector.observe(event.payload.observation)
			end
		end)
	)

	local valid, err = EnvironmentDirector.validate()

	if not valid then
		error("EnvironmentDirector validation failed: " .. tostring(err), 0)
	end

	initialized = true
	log.success("EnvironmentDirector initialized")
end

function EnvironmentDirector.start()
	if started then
		return
	end

	if not initialized then
		EnvironmentDirector.initialize()
	end

	cleanupHandle = Scheduler.interval(5, function()
		EnvironmentState.pruneCooldowns(now())
		EnvironmentState.pruneZonePressure(now())
	end, "EnvironmentCooldownCleanup", "EnvironmentDirector", { "Horror", "Environment" })

	started = true
	log.success("EnvironmentDirector started")
end

function EnvironmentDirector.shutdown()
	if cleanupHandle ~= nil then
		Scheduler.cancel(cleanupHandle)
		cleanupHandle = nil
	end

	for _, disconnect in ipairs(busDisconnects) do
		disconnect()
	end

	table.clear(busDisconnects)
	EnvironmentState.reset()
	EnvironmentMemory.reset()
	EnvironmentZoneContext.reset()
	EnvironmentExecutionBridge.reset()
	lastSelection = nil
	started = false
	initialized = false
end

function EnvironmentDirector.runSelfChecks()
	local registryOk = EnvironmentReactionRegistry.validate()
	local request = DirectorRequest.create({
		sourceDirector = "PsychologicalHorror",
		targetDirector = "Environment",
		requestKind = "RequestEnvironmentReaction",
		reason = "Environment Director self-check",
		context = {
			zoneId = Config.SelfCheckZoneId,
			zoneKind = "Street",
			partySize = 1,
			pressureState = "Uneasy",
		},
		metadata = {
			preferredCategory = "FogPressure",
		},
	})
	local approval = DirectorCoordinator.submitRequest(request)
	local malformed = EnvironmentDirector.requestApproval({} :: any)
	local secondApproval = DirectorCoordinator.submitRequest(request)
	local bridgeRejected = EnvironmentExecutionBridge.request({
		executionKind = "RequestDoorReaction",
		reactionId = "door.bad_payload",
		category = "DoorReaction",
		intensity = 0.5,
		zoneId = Config.SelfCheckZoneId,
		zoneKind = "Street",
		reason = "Self-check unsafe payload",
		createdAt = now(),
		metadata = {
			unsafe = EnvironmentDirector :: any,
		},
	})
	local diagnostics = EnvironmentDirector.inspect()

	return {
		ok = registryOk
			and approval.status == "Approved"
			and malformed.status == "Rejected"
			and secondApproval.status == "Deferred"
			and bridgeRejected == false
			and diagnostics.registryCount > 0,
		approval = approval.status,
		malformed = malformed.status,
		secondApproval = secondApproval.status,
	}
end

function EnvironmentDirector.inspect()
	return EnvironmentDiagnostics.capture({
		initialized = initialized,
		started = started,
		observationCount = observationCount,
		approvalCount = approvalCount,
		rejectedCount = rejectedCount,
		deferredCount = deferredCount,
		cancelledCount = cancelledCount,
		pressureScore = pressureScore,
	}, {
		EnvironmentState = EnvironmentState,
		EnvironmentMemory = EnvironmentMemory,
		EnvironmentZoneContext = EnvironmentZoneContext,
		EnvironmentExecutionBridge = EnvironmentExecutionBridge,
		EnvironmentReactionRegistry = EnvironmentReactionRegistry,
		lastSelection = function()
			return lastSelection
		end,
	})
end

function EnvironmentDirector.validate(): (boolean, string?)
	return EnvironmentDiagnostics.validate({
		EnvironmentReactionRegistry = EnvironmentReactionRegistry,
	})
end

return EnvironmentDirector
