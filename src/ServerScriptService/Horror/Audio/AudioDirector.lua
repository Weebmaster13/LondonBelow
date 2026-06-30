--!strict
--[[
	Server-authoritative Audio Director foundation.

	Approves future whispers, fake footsteps, distant knocks, breathing pressure,
	heartbeat pressure, silence drops, rain muffling, room ambience, and
	protected audio states. It does not play sounds, use final assets, create
	client remotes, mutate Workspace, or own gameplay truth.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local DirectorApproval = require(Core.Directors.DirectorApproval)
local DirectorCoordinator = require(Core.Directors.DirectorCoordinator)
local DirectorRequest = require(Core.Directors.DirectorRequest)
local DirectorTypes = require(Core.Directors.DirectorTypes)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local Scheduler = require(Core.Scheduler)
local SnapshotManager = require(Core.SnapshotManager)
local WorldDiagnostics = require(ServerScriptService.World.WorldDiagnostics)

local AudioDiagnostics = require(script.Parent.AudioDiagnostics)
local AudioPolicyResolver = require(script.Parent.AudioPolicyResolver)
local AudioRequestSelector = require(script.Parent.AudioRequestSelector)
local AudioSignals = require(script.Parent.AudioSignals)
local AudioState = require(script.Parent.AudioState)
local Config = require(script.Parent.AudioDirectorConfig)
local Types = require(script.Parent.AudioDirectorTypes)

local AudioDirector = {}

type DirectorRequestType = DirectorTypes.DirectorRequest
type DirectorApprovalType = DirectorTypes.DirectorApproval
type AudioContext = Types.AudioContext
type AudioRequestKind = Types.AudioRequestKind

local log = Logger.scope("AudioDirector")
local initialized = false
local started = false
local startedAt = 0
local cleanupHandle: Scheduler.TaskHandle? = nil

local function now(): number
	return os.clock()
end

local function requestKindFromRequest(request: DirectorRequestType): AudioRequestKind?
	local requested = request.context.audioKind or request.metadata.audioKind

	if type(requested) == "string" and Types.ValidRequestKinds[requested] then
		return requested :: AudioRequestKind
	end

	if request.requestKind == "RequestAudioCue" then
		return "RoomAmbience"
	elseif request.requestKind == "RequestSilenceDrop" then
		return "SilenceDrop"
	elseif request.requestKind == "RequestHeartbeatPressure" then
		return "HeartbeatPressure"
	end

	return nil
end

local function buildContext(request: DirectorRequestType): AudioContext
	local worldContext = AudioPolicyResolver.fromPayload(request)
	local partySize = if type(request.context.partySize) == "number"
		then request.context.partySize
		else 1
	local userId = if type(request.context.playerUserId) == "number"
		then request.context.playerUserId
		else nil

	return {
		playerUserId = userId,
		partySize = math.max(1, math.floor(partySize)),
		zoneId = worldContext.zoneId,
		zoneKind = worldContext.zoneKind,
		isKnownZone = worldContext.isKnown,
		pressureState = AudioState.getPressureState(),
		requestKind = requestKindFromRequest(request),
		metadata = table.clone(request.metadata),
		tags = table.clone(request.tags),
		worldContext = worldContext,
		now = now(),
	}
end

function AudioDirector:observe(observation: any)
	AudioState.incrementObservation()

	local amount = if type(observation) == "table" and type(observation.amount) == "number"
		then observation.amount
		else 0.03
	local nextState = AudioState.adjustPressure(amount)

	EventBus.publishDeferred(AudioSignals.ObservationProcessed, {
		observation = observation,
		pressureState = nextState,
	})
end

function AudioDirector:requestApproval(request: DirectorRequestType): DirectorApprovalType
	local valid, err = DirectorRequest.validate(request)

	if not valid then
		local requestId = if type(request) == "table"
				and type(request.requestId) == "string"
			then request.requestId
			else "<malformed>"
		return DirectorApproval.create(
			requestId,
			"Rejected",
			err or "Invalid Audio Director request.",
			"Audio",
			nil,
			{}
		)
	end

	local context = buildContext(request)

	if context.requestKind == nil then
		local approval = DirectorApproval.create(
			request.requestId,
			"Rejected",
			"Audio Director rejected unsupported audio request kind.",
			"Audio",
			nil,
			{ requestKind = request.requestKind }
		)
		EventBus.publishDeferred(AudioSignals.RequestRejected, { approval = approval })
		return approval
	end

	local decision = AudioRequestSelector.select(context)
	decision.requestId = request.requestId
	AudioState.recordDecision(decision)

	if decision.status == "Approved" and decision.definitionId ~= nil then
		AudioState.setCooldown(
			decision.definitionId,
			decision.context.metadata.cooldownSeconds or Config.DefaultCooldownSeconds,
			decision.createdAt
		)
		local approval =
			DirectorApproval.create(request.requestId, "Approved", decision.reason, "Audio", nil, {
				definitionId = decision.definitionId,
				audioKind = decision.requestKind,
				intensity = decision.intensity,
				approvalOnly = true,
			})
		EventBus.publishDeferred(
			AudioSignals.RequestApproved,
			{ approval = approval, decision = decision }
		)
		EventBus.publishDeferred(
			AudioSignals.ApprovalDecided,
			{ approval = approval, decision = decision }
		)
		return approval
	end

	local approval = DirectorApproval.create(
		request.requestId,
		"Deferred",
		decision.reason,
		"Audio",
		nil,
		{ blocked = decision.blocked, approvalOnly = true }
	)
	EventBus.publishDeferred(
		AudioSignals.RequestDeferred,
		{ approval = approval, decision = decision }
	)
	return approval
end

function AudioDirector:cancelRequest(requestId: string, reason: string?): DirectorApprovalType
	return DirectorApproval.create(
		requestId,
		"Cancelled",
		reason or "Audio request cancelled.",
		"Audio",
		nil,
		{}
	)
end

function AudioDirector:getCapabilities()
	return {
		{
			id = "Audio.Pressure",
			description = "Approves future audio pressure without playback.",
			requestKinds = {
				"RequestAudioCue",
				"RequestSilenceDrop",
				"RequestHeartbeatPressure",
			},
		},
	}
end

function AudioDirector:getHealth()
	return {
		name = "Audio",
		status = if started then "Running" elseif initialized then "Ready" else "NotInitialized",
		healthy = initialized,
		message = "Approval-only foundation; no sound playback.",
		uptime = if startedAt > 0 then now() - startedAt else 0,
		lastError = nil,
	}
end

function AudioDirector:getSnapshot()
	return AudioDirector.inspect()
end

function AudioDirector:getDiagnostics()
	return AudioDirector.inspect()
end

function AudioDirector:describe()
	return {
		name = "Audio",
		displayName = "Audio Director",
		responsibilities = {
			"audio pressure approvals",
			"World Intelligence audio policy enforcement",
			"safe-room audio protection",
			"puzzle-room audio protection",
			"audio diagnostics",
		},
		doesNotOwn = {
			"sound playback",
			"final audio assets",
			"client effects",
			"Monster AI",
			"final scares",
			"Chapter 1 content",
		},
		capabilities = AudioDirector:getCapabilities(),
	}
end

function AudioDirector.initialize()
	if initialized then
		return
	end

	Diagnostics.registerSampler("AudioDirector", AudioDirector.inspect)
	SnapshotManager.registerProvider("audioDirector", AudioDirector.inspect)
	DirectorCoordinator.registerDirector(AudioDirector :: any)

	local valid, validationErr = AudioDirector.validate()
	if not valid then
		error("AudioDirector validation failed: " .. tostring(validationErr), 0)
	end

	initialized = true
	log.success("AudioDirector initialized")
end

function AudioDirector.start()
	if started then
		return
	end

	if not initialized then
		AudioDirector.initialize()
	end

	startedAt = now()
	cleanupHandle = Scheduler.interval(5, function()
		AudioState.pruneCooldowns(now())
	end, "AudioDirectorCooldownCleanup", "AudioDirector", { "Horror", "Audio" })
	started = true
	log.success("AudioDirector started")
end

function AudioDirector.shutdown()
	if cleanupHandle ~= nil then
		Scheduler.cancel(cleanupHandle)
		cleanupHandle = nil
	end

	AudioState.reset()
	started = false
	initialized = false
	startedAt = 0
end

function AudioDirector.runSelfChecks()
	local request = DirectorRequest.create({
		sourceDirector = "Environment",
		targetDirector = "Audio",
		requestKind = "RequestAudioCue",
		reason = "Audio Director self-check",
		context = {
			zoneId = Config.SelfCheckZoneId,
			zoneKind = "Unknown",
		},
		metadata = {
			audioKind = "RoomAmbience",
		},
	})
	local malformed = AudioDirector:requestApproval({} :: any)
	local approval = AudioDirector:requestApproval(request)
	local diagnostics = AudioDirector.inspect()

	return {
		ok = malformed.status == "Rejected"
			and approval.status ~= "Rejected"
			and diagnostics.health.healthy,
		malformed = malformed.status,
		approval = approval.status,
	}
end

function AudioDirector.inspect()
	return AudioDiagnostics.capture({
		initialized = initialized,
		started = started,
	}, {
		AudioState = AudioState,
		WorldDiagnostics = WorldDiagnostics,
	})
end

function AudioDirector.validate(): (boolean, string?)
	return AudioDiagnostics.validate()
end

return AudioDirector
