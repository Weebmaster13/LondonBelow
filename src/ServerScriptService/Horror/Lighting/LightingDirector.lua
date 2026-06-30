--!strict
--[[
	Server-authoritative Lighting Director foundation.

	Approves future dimming, flicker, shadow pressure, visibility pressure,
	safe-room protection, puzzle-room protection, chase-support lighting, and
	release lighting. It does not mutate Roblox Lighting, Workspace, final art,
	audio, remotes, or client-owned truth.
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

local Config = require(script.Parent.LightingDirectorConfig)
local LightingDiagnostics = require(script.Parent.LightingDiagnostics)
local LightingPolicyResolver = require(script.Parent.LightingPolicyResolver)
local LightingRequestSelector = require(script.Parent.LightingRequestSelector)
local LightingSignals = require(script.Parent.LightingSignals)
local LightingState = require(script.Parent.LightingState)
local Types = require(script.Parent.LightingDirectorTypes)

local LightingDirector = {}

type DirectorRequestType = DirectorTypes.DirectorRequest
type DirectorApprovalType = DirectorTypes.DirectorApproval
type LightingContext = Types.LightingContext
type LightingRequestKind = Types.LightingRequestKind

local log = Logger.scope("LightingDirector")
local initialized = false
local started = false
local startedAt = 0
local cleanupHandle: Scheduler.TaskHandle? = nil

local function now(): number
	return os.clock()
end

local function requestKindFromRequest(request: DirectorRequestType): LightingRequestKind?
	local requested = request.context.lightingKind or request.metadata.lightingKind

	if type(requested) == "string" and Types.ValidRequestKinds[requested] then
		return requested :: LightingRequestKind
	end

	if request.requestKind == "RequestLightingChange" then
		return "Dim"
	elseif request.requestKind == "RequestChaseSupport" then
		return "ChaseSupport"
	elseif request.requestKind == "RequestReleaseLighting" then
		return "ReleaseLighting"
	end

	return nil
end

local function buildContext(request: DirectorRequestType): LightingContext
	local worldContext = LightingPolicyResolver.fromPayload(request)
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
		pressureState = LightingState.getPressureState(),
		requestKind = requestKindFromRequest(request),
		metadata = table.clone(request.metadata),
		tags = table.clone(request.tags),
		worldContext = worldContext,
		now = now(),
	}
end

function LightingDirector:observe(observation: any)
	LightingState.incrementObservation()

	local amount = if type(observation) == "table" and type(observation.amount) == "number"
		then observation.amount
		else 0.03
	local nextState = LightingState.adjustPressure(amount)

	EventBus.publishDeferred(LightingSignals.ObservationProcessed, {
		observation = observation,
		pressureState = nextState,
	})
end

function LightingDirector:requestApproval(request: DirectorRequestType): DirectorApprovalType
	local valid, err = DirectorRequest.validate(request)

	if not valid then
		local requestId = if type(request) == "table"
				and type(request.requestId) == "string"
			then request.requestId
			else "<malformed>"
		return DirectorApproval.create(
			requestId,
			"Rejected",
			err or "Invalid Lighting Director request.",
			"Lighting",
			nil,
			{}
		)
	end

	local context = buildContext(request)

	if context.requestKind == nil then
		local approval = DirectorApproval.create(
			request.requestId,
			"Rejected",
			"Lighting Director rejected unsupported lighting request kind.",
			"Lighting",
			nil,
			{ requestKind = request.requestKind }
		)
		EventBus.publishDeferred(LightingSignals.RequestRejected, { approval = approval })
		return approval
	end

	local decision = LightingRequestSelector.select(context)
	decision.requestId = request.requestId
	LightingState.recordDecision(decision)

	if decision.status == "Approved" and decision.definitionId ~= nil then
		LightingState.setCooldown(
			decision.definitionId,
			decision.context.metadata.cooldownSeconds or Config.DefaultCooldownSeconds,
			decision.createdAt
		)
		local approval = DirectorApproval.create(
			request.requestId,
			"Approved",
			decision.reason,
			"Lighting",
			nil,
			{
				definitionId = decision.definitionId,
				lightingKind = decision.requestKind,
				intensity = decision.intensity,
				approvalOnly = true,
			}
		)
		EventBus.publishDeferred(
			LightingSignals.RequestApproved,
			{ approval = approval, decision = decision }
		)
		EventBus.publishDeferred(
			LightingSignals.ApprovalDecided,
			{ approval = approval, decision = decision }
		)
		return approval
	end

	local approval = DirectorApproval.create(
		request.requestId,
		"Deferred",
		decision.reason,
		"Lighting",
		nil,
		{ blocked = decision.blocked, approvalOnly = true }
	)
	EventBus.publishDeferred(
		LightingSignals.RequestDeferred,
		{ approval = approval, decision = decision }
	)
	return approval
end

function LightingDirector:cancelRequest(requestId: string, reason: string?): DirectorApprovalType
	return DirectorApproval.create(
		requestId,
		"Cancelled",
		reason or "Lighting request cancelled.",
		"Lighting",
		nil,
		{}
	)
end

function LightingDirector:getCapabilities()
	return {
		{
			id = "Lighting.VisibilityPressure",
			description = "Approves future lighting pressure without physical mutation.",
			requestKinds = {
				"RequestLightingChange",
				"RequestChaseSupport",
				"RequestReleaseLighting",
			},
		},
	}
end

function LightingDirector:getHealth()
	return {
		name = "Lighting",
		status = if started then "Running" elseif initialized then "Ready" else "NotInitialized",
		healthy = initialized,
		message = "Approval-only foundation; no physical Lighting mutation.",
		uptime = if startedAt > 0 then now() - startedAt else 0,
		lastError = nil,
	}
end

function LightingDirector:getSnapshot()
	return LightingDirector.inspect()
end

function LightingDirector:getDiagnostics()
	return LightingDirector.inspect()
end

function LightingDirector:describe()
	return {
		name = "Lighting",
		displayName = "Lighting Director",
		responsibilities = {
			"lighting pressure approvals",
			"World Intelligence lighting policy enforcement",
			"safe-room lighting protection",
			"puzzle-room lighting protection",
			"lighting diagnostics",
		},
		doesNotOwn = {
			"Roblox Lighting mutation",
			"Workspace mutation",
			"client effects",
			"Monster AI",
			"final scares",
			"Chapter 1 content",
		},
		capabilities = LightingDirector:getCapabilities(),
	}
end

function LightingDirector.initialize()
	if initialized then
		return
	end

	Diagnostics.registerSampler("LightingDirector", LightingDirector.inspect)
	SnapshotManager.registerProvider("lightingDirector", LightingDirector.inspect)
	DirectorCoordinator.registerDirector(LightingDirector :: any)

	local valid, validationErr = LightingDirector.validate()
	if not valid then
		error("LightingDirector validation failed: " .. tostring(validationErr), 0)
	end

	initialized = true
	log.success("LightingDirector initialized")
end

function LightingDirector.start()
	if started then
		return
	end

	if not initialized then
		LightingDirector.initialize()
	end

	startedAt = now()
	cleanupHandle = Scheduler.interval(5, function()
		LightingState.pruneCooldowns(now())
	end, "LightingDirectorCooldownCleanup", "LightingDirector", { "Horror", "Lighting" })
	started = true
	log.success("LightingDirector started")
end

function LightingDirector.shutdown()
	if cleanupHandle ~= nil then
		Scheduler.cancel(cleanupHandle)
		cleanupHandle = nil
	end

	LightingState.reset()
	started = false
	initialized = false
	startedAt = 0
end

function LightingDirector.runSelfChecks()
	local request = DirectorRequest.create({
		sourceDirector = "Environment",
		targetDirector = "Lighting",
		requestKind = "RequestLightingChange",
		reason = "Lighting Director self-check",
		context = {
			zoneId = Config.SelfCheckZoneId,
			zoneKind = "Unknown",
		},
		metadata = {
			lightingKind = "ReleaseLighting",
		},
	})
	local malformed = LightingDirector:requestApproval({} :: any)
	local approval = LightingDirector:requestApproval(request)
	local diagnostics = LightingDirector.inspect()

	return {
		ok = malformed.status == "Rejected"
			and approval.status ~= "Rejected"
			and diagnostics.health.healthy,
		malformed = malformed.status,
		approval = approval.status,
	}
end

function LightingDirector.inspect()
	return LightingDiagnostics.capture({
		initialized = initialized,
		started = started,
	}, {
		LightingState = LightingState,
		WorldDiagnostics = WorldDiagnostics,
	})
end

function LightingDirector.validate(): (boolean, string?)
	return LightingDiagnostics.validate()
end

return LightingDirector
