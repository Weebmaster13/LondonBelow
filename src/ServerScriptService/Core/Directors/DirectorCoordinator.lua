--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Diagnostics = require(script.Parent.Parent.Diagnostics)
local EventBus = require(script.Parent.Parent.EventBus)
local Logger = require(script.Parent.Parent.Logger)
local Scheduler = require(script.Parent.Parent.Scheduler)
local SnapshotManager = require(script.Parent.Parent.SnapshotManager)

local ObservationSignals = require(ServerScriptService.Horror.Observation.ObservationSignals)

local DirectorApproval = require(script.Parent.DirectorApproval)
local DirectorCapabilities = require(script.Parent.DirectorCapabilities)
local DirectorConfig = require(script.Parent.DirectorConfig)
local DirectorConflictResolver = require(script.Parent.DirectorConflictResolver)
local DirectorContract = require(script.Parent.DirectorContract)
local DirectorDecisionTrace = require(script.Parent.DirectorDecisionTrace)
local DirectorDiagnostics = require(script.Parent.DirectorDiagnostics)
local DirectorHealth = require(script.Parent.DirectorHealth)
local DirectorRegistry = require(script.Parent.DirectorRegistry)
local DirectorRequest = require(script.Parent.DirectorRequest)
local DirectorRouter = require(script.Parent.DirectorRouter)
local DirectorSignals = require(script.Parent.DirectorSignals)
local Types = require(script.Parent.DirectorTypes)

local DirectorCoordinator = {}

type Director = Types.Director
type DirectorRequestType = Types.DirectorRequest
type DirectorApprovalType = Types.DirectorApproval

local log = Logger.scope("DirectorCoordinator")
local initialized = false
local started = false
local directorsByName: { [string]: Director } = {}
local registrationOrder: { string } = {}
local pendingRequests: { [string]: DirectorRequestType } = {}
local recentApprovals: { DirectorApprovalType } = {}
local failures: { any } = {}
local busDisconnects: { () -> () } = {}
local expirationHandle: Scheduler.TaskHandle? = nil
local counters = {
	submitted = 0,
	approved = 0,
	rejected = 0,
	deferred = 0,
	modified = 0,
	expired = 0,
	cancelled = 0,
	totalRequestTime = 0,
}

local function rememberApproval(approval: DirectorApprovalType, duration: number)
	table.insert(recentApprovals, approval)
	counters.totalRequestTime += duration

	while #recentApprovals > DirectorConfig.RecentApprovalLimit do
		table.remove(recentApprovals, 1)
	end

	if approval.status == "Approved" then
		counters.approved += 1
	elseif approval.status == "Rejected" then
		counters.rejected += 1
	elseif approval.status == "Deferred" then
		counters.deferred += 1
	elseif approval.status == "Modified" then
		counters.modified += 1
	elseif approval.status == "Expired" then
		counters.expired += 1
	elseif approval.status == "Cancelled" then
		counters.cancelled += 1
	end
end

local function recordFailure(directorName: string, err: string)
	table.insert(failures, {
		at = os.clock(),
		directorName = directorName,
		error = err,
	})

	while #failures > 50 do
		table.remove(failures, 1)
	end

	EventBus.publishDeferred(DirectorSignals.DirectorFailed, {
		directorName = directorName,
		error = err,
	})
end

local function sweepExpired()
	local now = os.clock()

	for requestId, request in pairs(pendingRequests) do
		if now > request.expiresAt then
			pendingRequests[requestId] = nil
			local approval = DirectorApproval.create(
				requestId,
				"Expired",
				"Pending request expired.",
				"DirectorCoordinator",
				nil,
				{}
			)
			DirectorDecisionTrace.cancelled(requestId, "Expired")
			rememberApproval(approval, 0)
			EventBus.publishDeferred(DirectorSignals.RequestExpired, { approval = approval })
		end
	end
end

function DirectorCoordinator.registerDirector(director: Director)
	local ok, err = DirectorContract.validate(director)

	if not ok then
		error("Invalid Director: " .. tostring(err), 2)
	end

	local description = director:describe()

	if directorsByName[description.name] == nil then
		table.insert(registrationOrder, description.name)
	end

	directorsByName[description.name] = director
	DirectorCapabilities.register(description.name, description.capabilities)

	EventBus.publishDeferred(DirectorSignals.DirectorRegistered, {
		director = description,
	})
end

function DirectorCoordinator.submitRequest(request: any): DirectorApprovalType
	local startedAt = os.clock()
	local requestId = if type(request) == "table" and type(request.requestId) == "string"
		then request.requestId
		else nil
	counters.submitted += 1

	if requestId ~= nil then
		pendingRequests[requestId] = request
	end

	EventBus.publishDeferred(DirectorSignals.RequestSubmitted, { request = request })

	local approval = DirectorRouter.route(request, directorsByName)

	if requestId ~= nil then
		pendingRequests[requestId] = nil
	end

	rememberApproval(approval, os.clock() - startedAt)
	EventBus.publishDeferred(DirectorSignals.RequestResolved, { approval = approval })

	return approval
end

function DirectorCoordinator.cancelRequest(requestId: string, reason: string?): DirectorApprovalType
	pendingRequests[requestId] = nil
	local approval = DirectorApproval.create(
		requestId,
		"Cancelled",
		reason or "Request cancelled.",
		"DirectorCoordinator",
		nil,
		{}
	)
	DirectorDecisionTrace.cancelled(requestId, approval.reason)
	rememberApproval(approval, 0)
	return approval
end

function DirectorCoordinator.routeObservation(observation: any)
	for _, directorName in ipairs(registrationOrder) do
		local director = directorsByName[directorName]

		if director ~= nil then
			local ok, err = pcall(function()
				director:observe(observation)
			end)

			if not ok then
				recordFailure(directorName, tostring(err))
			end
		end
	end

	EventBus.publishDeferred(DirectorSignals.ObservationRouted, { observation = observation })
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

	for _, directorName in ipairs(registrationOrder) do
		local director = directorsByName[directorName]

		if director ~= nil then
			local ok, err = pcall(function()
				director:initialize()
				director:start()
			end)

			if not ok then
				recordFailure(directorName, tostring(err))
			end
		end
	end

	expirationHandle = Scheduler.interval(
		DirectorConfig.ExpirationSweepSeconds,
		sweepExpired,
		"DirectorRequestExpiration",
		"DirectorCoordinator",
		{ "Directors" }
	)
	started = true
	EventBus.publishDeferred(
		DirectorSignals.CoordinatorReady,
		{ directors = table.clone(registrationOrder) }
	)
	log.success("DirectorCoordinator started")
end

function DirectorCoordinator.shutdown()
	if expirationHandle ~= nil then
		Scheduler.cancel(expirationHandle)
		expirationHandle = nil
	end

	for index = #registrationOrder, 1, -1 do
		local director = directorsByName[registrationOrder[index]]

		if director ~= nil then
			pcall(function()
				director:shutdown()
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

function DirectorCoordinator.runSelfChecks()
	local mock = {
		initialize = function() end,
		start = function() end,
		shutdown = function() end,
		observe = function() end,
		requestApproval = function(_, request)
			return DirectorApproval.create(
				request.requestId,
				"Approved",
				"Mock approved.",
				"Mock",
				nil,
				{}
			)
		end,
		cancelRequest = function(_, requestId, reason)
			return DirectorApproval.create(
				requestId,
				"Cancelled",
				reason or "Cancelled.",
				"Mock",
				nil,
				{}
			)
		end,
		getCapabilities = function()
			return {
				{
					id = "Mock.Approve",
					description = "Mock approval.",
					requestKinds = { "RequestMock" },
				},
			}
		end,
		getHealth = function()
			return {
				name = "Mock",
				status = "Running",
				healthy = true,
				message = nil,
				uptime = 0,
				lastError = nil,
			}
		end,
		getSnapshot = function()
			return {}
		end,
		getDiagnostics = function()
			return {}
		end,
		validate = function()
			return true, nil
		end,
		describe = function()
			return {
				name = "Mock",
				displayName = "Mock Director",
				responsibilities = { "self check" },
				doesNotOwn = { "gameplay" },
				capabilities = {
					{
						id = "Mock.Approve",
						description = "Mock approval.",
						requestKinds = { "RequestMock" },
					},
				},
			}
		end,
	}

	local testDirectors = table.clone(directorsByName)
	testDirectors.Mock = mock :: any

	local validRequest = DirectorRequest.create({
		sourceDirector = "PsychologicalHorror",
		targetDirector = "Mock",
		requestKind = "RequestMock",
		reason = "Self check",
	})
	local validApproval = DirectorRouter.route(validRequest, testDirectors)
	local unknown = DirectorRouter.route(
		DirectorRequest.create({
			sourceDirector = "PsychologicalHorror",
			targetDirector = "Unknown",
			requestKind = "RequestMock",
			reason = "Self check",
		}),
		testDirectors
	)
	local expired = DirectorRouter.route(
		DirectorRequest.create({
			sourceDirector = "PsychologicalHorror",
			targetDirector = "Mock",
			requestKind = "RequestMock",
			reason = "Self check",
			expiresIn = -1,
		}),
		testDirectors
	)
	local cancel = DirectorCoordinator.cancelRequest("self-check-cancel", "Self check cancellation")
	local diagnosticsSnapshot = DirectorCoordinator.inspect()

	return {
		ok = validApproval.status == "Approved"
			and unknown.status == "Rejected"
			and expired.status == "Expired"
			and cancel.status == "Cancelled"
			and #diagnosticsSnapshot.traces > 0,
		validApproval = validApproval.status,
		unknown = unknown.status,
		expired = expired.status,
		cancel = cancel.status,
	}
end

function DirectorCoordinator.inspect()
	return DirectorDiagnostics.capture({
		initialized = initialized,
		started = started,
	}, {
		directorsByName = directorsByName,
		registrationOrder = registrationOrder,
		pendingRequestCount = function()
			local count = 0
			for _ in pairs(pendingRequests) do
				count += 1
			end
			return count
		end,
		recentApprovals = function()
			return table.clone(recentApprovals)
		end,
		metrics = function()
			return {
				submitted = counters.submitted,
				approved = counters.approved,
				rejected = counters.rejected,
				deferred = counters.deferred,
				modified = counters.modified,
				expired = counters.expired,
				cancelled = counters.cancelled,
				averageRequestTime = if counters.submitted > 0
					then counters.totalRequestTime / counters.submitted
					else 0,
			}
		end,
		recentFailures = function()
			return table.clone(failures)
		end,
		DirectorCapabilities = DirectorCapabilities,
		DirectorHealth = DirectorHealth,
		DirectorDecisionTrace = DirectorDecisionTrace,
		DirectorConflictResolver = DirectorConflictResolver,
	})
end

function DirectorCoordinator.validate(): (boolean, string?)
	return DirectorDiagnostics.validate({
		directorsByName = directorsByName,
	})
end

return DirectorCoordinator
