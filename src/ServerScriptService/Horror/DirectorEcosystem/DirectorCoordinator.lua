--!strict
--[[
	DirectorCoordinator owns the Director Ecosystem lifecycle.

	It discovers Directors, validates their standard contract, routes trusted
	observations, resolves request approvals, records diagnostics, and exposes
	snapshots. It never executes gameplay or presentation.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local ObservationSignals = require(ServerScriptService.Horror.Observation.ObservationSignals)
local DirectorContract = require(script.Parent.DirectorContract)
local DirectorRegistry = require(script.Parent.DirectorRegistry)
local DirectorSignals = require(script.Parent.DirectorSignals)
local Types = require(script.Parent.DirectorTypes)

local DirectorCoordinator = {}

type Director = Types.Director
type DirectorRequest = Types.DirectorRequest
type ApprovalResponse = Types.ApprovalResponse
type DirectorName = Types.DirectorName

local log = Logger.scope("DirectorCoordinator")
local initialized = false
local started = false
local requestSequence = 0
local directorsByName: { [DirectorName]: Director } = {}
local registrationOrder: { DirectorName } = {}
local pendingRequests: { [string]: DirectorRequest } = {}
local resolvedResponses: { ApprovalResponse } = {}
local busDisconnects: { () -> () } = {}
local diagnostics = {
	observationsRouted = 0,
	requestsSubmitted = 0,
	approved = 0,
	rejected = 0,
	deferred = 0,
	modified = 0,
	expired = 0,
	cancelled = 0,
	conflicts = 0,
	totalRequestTime = 0,
}

local function now(): number
	return os.clock()
end

local function nextRequestId(kind: string): string
	requestSequence += 1
	return string.format("%s:%d:%.3f", kind, requestSequence, now())
end

local function recordResponse(response: ApprovalResponse, startedAt: number)
	table.insert(resolvedResponses, response)
	diagnostics.totalRequestTime += now() - startedAt

	if #resolvedResponses > 100 then
		table.remove(resolvedResponses, 1)
	end

	if response.state == "Approved" then
		diagnostics.approved += 1
	elseif response.state == "Rejected" then
		diagnostics.rejected += 1
	elseif response.state == "Deferred" then
		diagnostics.deferred += 1
	elseif response.state == "Modified" then
		diagnostics.modified += 1
	elseif response.state == "Expired" then
		diagnostics.expired += 1
	elseif response.state == "Cancelled" then
		diagnostics.cancelled += 1
	end

	EventBus.publishDeferred(DirectorSignals.RequestResolved, {
		response = response,
	})
end

local function makeResponse(
	request: DirectorRequest,
	state: Types.ApprovalState,
	reason: string
): ApprovalResponse
	return {
		requestId = request.id,
		state = state,
		reason = reason,
		modifications = nil,
		decidedAt = now(),
		decidedBy = "DirectorCoordinator",
	}
end

local function narrativeBeatAllows(request: DirectorRequest): boolean
	local beat = request.context.narrativeBeat
	local requiredBeat = request.context.requiredNarrativeBeat

	return requiredBeat == nil or beat == requiredBeat
end

local function resolveRequest(request: DirectorRequest): ApprovalResponse
	if request.expiresAt ~= nil and now() > request.expiresAt then
		pendingRequests[request.id] = nil
		return makeResponse(request, "Expired", "Request expired before Coordinator approval.")
	end

	if request.kind == "RequestMonsterReveal" and not narrativeBeatAllows(request) then
		diagnostics.conflicts += 1
		return makeResponse(
			request,
			"Deferred",
			"Player has not yet reached intended narrative beat."
		)
	end

	if request.kind == "RequestLightingChange" then
		return makeResponse(
			request,
			"Approved",
			"Lighting pressure is allowed and does not bypass narrative beat."
		)
	end

	local target = directorsByName[request.targetDirector]

	if target == nil then
		return makeResponse(request, "Rejected", "Target Director is not registered.")
	end

	local ok, response = pcall(function()
		return target:RequestApproval(request)
	end)

	if not ok then
		EventBus.publishDeferred(DirectorSignals.DirectorFailed, {
			director = request.targetDirector,
			error = tostring(response),
		})
		return makeResponse(request, "Rejected", "Target Director failed while handling request.")
	end

	return response
end

function DirectorCoordinator.registerDirector(director: Director)
	local ok, err = DirectorContract.validate(director)

	if not ok then
		error("Invalid Director: " .. tostring(err), 2)
	end

	local description = director:Describe()

	if directorsByName[description.name] == nil then
		table.insert(registrationOrder, description.name)
	end

	directorsByName[description.name] = director
	EventBus.publishDeferred(DirectorSignals.DirectorRegistered, {
		director = description,
	})
end

function DirectorCoordinator.submitRequest(request: DirectorRequest): ApprovalResponse
	local startedAt = now()
	diagnostics.requestsSubmitted += 1
	pendingRequests[request.id] = request

	EventBus.publishDeferred(DirectorSignals.RequestSubmitted, {
		request = request,
	})

	local response = resolveRequest(request)
	pendingRequests[request.id] = nil
	recordResponse(response, startedAt)

	return response
end

function DirectorCoordinator.createRequest(
	sourceDirector: DirectorName,
	targetDirector: DirectorName,
	kind: string,
	priority: Types.RequestPriority,
	reason: string,
	context: { [string]: any }?,
	supportingObservations: { any }?
): DirectorRequest
	return {
		id = nextRequestId(kind),
		timestamp = now(),
		sourceDirector = sourceDirector,
		targetDirector = targetDirector,
		kind = kind,
		priority = priority,
		reason = reason,
		supportingObservations = supportingObservations or {},
		context = context or {},
		expiresAt = now() + 30,
		approvalState = "Pending",
	}
end

function DirectorCoordinator.routeObservation(observation: any)
	diagnostics.observationsRouted += 1

	for _, name in ipairs(registrationOrder) do
		local director = directorsByName[name]

		if director ~= nil then
			local ok, err = pcall(function()
				director:Observe(observation)
			end)

			if not ok then
				EventBus.publishDeferred(DirectorSignals.DirectorFailed, {
					director = name,
					error = tostring(err),
				})
			end
		end
	end

	EventBus.publishDeferred(DirectorSignals.ObservationRouted, {
		observation = observation,
	})
end

function DirectorCoordinator.runExampleScenario()
	local observation = {
		id = "Time.AloneTooLong",
		amount = 360,
		context = {
			tension = "High",
			narrativeBeat = "BeforeReveal",
			requiredNarrativeBeat = "RevealReady",
		},
	}

	DirectorCoordinator.routeObservation(observation)

	local lighting = DirectorCoordinator.createRequest(
		"PsychologicalHorror",
		"Lighting",
		"RequestLightingChange",
		"High",
		"Player has been alone for 6 minutes and tension is high.",
		observation.context,
		{ observation }
	)

	local monster = DirectorCoordinator.createRequest(
		"PsychologicalHorror",
		"Monster",
		"RequestMonsterReveal",
		"High",
		"Player has been alone for 6 minutes and tension is high.",
		observation.context,
		{ observation }
	)

	return {
		lighting = DirectorCoordinator.submitRequest(lighting),
		monster = DirectorCoordinator.submitRequest(monster),
	}
end

function DirectorCoordinator.initialize()
	if initialized then
		return
	end

	for _, director in ipairs(DirectorRegistry.createAll()) do
		DirectorCoordinator.registerDirector(director)
	end

	Diagnostics.registerSampler("DirectorCoordinator", DirectorCoordinator.inspect)
	SnapshotManager.registerProvider("directorCoordinator", DirectorCoordinator.inspect)

	table.insert(
		busDisconnects,
		EventBus.subscribe(ObservationSignals.Accepted, function(event)
			if event.payload ~= nil then
				DirectorCoordinator.routeObservation(event.payload.observation)
			end
		end)
	)

	local ok, err = DirectorCoordinator.validate()

	if not ok then
		error("DirectorCoordinator validation failed: " .. tostring(err), 0)
	end

	initialized = true
	log.success("DirectorCoordinator initialized")
end

function DirectorCoordinator.start()
	if started then
		return
	end

	if not initialized then
		DirectorCoordinator.initialize()
	end

	for _, name in ipairs(registrationOrder) do
		local director = directorsByName[name]

		if director ~= nil then
			local ok, err = pcall(function()
				director:Initialize()
				director:Start()
			end)

			if not ok then
				EventBus.publishDeferred(DirectorSignals.DirectorFailed, {
					director = name,
					error = tostring(err),
				})
			end
		end
	end

	started = true
	EventBus.publishDeferred(DirectorSignals.CoordinatorReady, {
		directors = registrationOrder,
	})
	log.success("DirectorCoordinator started")
end

function DirectorCoordinator.shutdown()
	for index = #registrationOrder, 1, -1 do
		local director = directorsByName[registrationOrder[index]]

		if director ~= nil then
			pcall(function()
				director:Shutdown()
			end)
		end
	end

	for _, disconnect in ipairs(busDisconnects) do
		disconnect()
	end

	table.clear(busDisconnects)
	table.clear(pendingRequests)
	started = false
end

function DirectorCoordinator.inspect()
	local health = {}
	local capabilities = {}

	for _, name in ipairs(registrationOrder) do
		local director = directorsByName[name]

		if director ~= nil then
			health[name] = director:GetHealth()
			capabilities[name] = director:GetCapabilities()
		end
	end

	return {
		initialized = initialized,
		started = started,
		registeredDirectors = table.clone(registrationOrder),
		health = health,
		capabilities = capabilities,
		pendingRequests = table.clone(pendingRequests),
		recentResponses = table.clone(resolvedResponses),
		metrics = {
			observationsRouted = diagnostics.observationsRouted,
			requestsSubmitted = diagnostics.requestsSubmitted,
			approved = diagnostics.approved,
			rejected = diagnostics.rejected,
			deferred = diagnostics.deferred,
			modified = diagnostics.modified,
			expired = diagnostics.expired,
			cancelled = diagnostics.cancelled,
			conflicts = diagnostics.conflicts,
			averageRequestTime = if diagnostics.requestsSubmitted > 0
				then diagnostics.totalRequestTime / diagnostics.requestsSubmitted
				else 0,
		},
	}
end

function DirectorCoordinator.validate(): (boolean, string?)
	for _, name in ipairs(registrationOrder) do
		local director = directorsByName[name]

		if director == nil then
			return false, "Registered Director missing: " .. name
		end

		local contractOk, contractErr = DirectorContract.validate(director)

		if not contractOk then
			return false, contractErr
		end

		local directorOk, directorErr = director:Validate()

		if not directorOk then
			return false, directorErr
		end
	end

	return true, nil
end

return DirectorCoordinator
