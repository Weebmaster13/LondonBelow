--!strict

local Budgets = require(script.Parent.QueryBudgets)
local Cache = require(script.Parent.QueryCacheRuntime)
local Diagnostics = require(script.Parent.QueryDiagnostics)
local Evidence = require(script.Parent.QueryEvidence)
local Execution = require(script.Parent.QueryExecutionRuntime)
local HandlerRegistry = require(script.Parent.QueryHandlerRegistry)
local Health = require(script.Parent.QueryHealth)
local Lifecycle = require(script.Parent.QueryLifecycle)
local Metrics = require(script.Parent.QueryMetrics)
local Profiler = require(script.Parent.QueryProfiler)
local ProjectionRuntime = require(script.Parent.QueryProjectionRuntime)
local QueryRegistry = require(script.Parent.QueryRegistry)
local Queue = require(script.Parent.QueryQueue)
local ReadModels = require(script.Parent.QueryReadModels)
local RequesterRegistry = require(script.Parent.QueryRequesterRegistry)
local Router = require(script.Parent.QueryRouter)
local Serialization = require(script.Parent.QuerySerialization)
local SnapshotRuntime = require(script.Parent.QuerySnapshotRuntime)
local Types = require(script.Parent.QueryTypes)
local Validation = require(script.Parent.QueryValidation)

local Runtime = {}

Runtime.Responsibilities = {
	"query definitions",
	"query registration",
	"query routing",
	"query authorization",
	"snapshot access",
	"read-only retrieval",
}

local sequence = 0
local shutdown = false
local routingHistory: { any } = {}
local seenQueryIds: { [string]: boolean } = {}
local counters = {
	dispatched = 0,
	executing = 0,
	completed = 0,
	cancelled = 0,
	rejected = 0,
	failed = 0,
	authorizationFailures = 0,
	lastQueryId = nil :: string?,
	lastFailure = nil :: any?,
}

local function nextSequence(): number
	sequence += 1
	return sequence
end

local function defaultValidator(payload: any): (boolean, string?)
	return Validation.payload(payload)
end

local function requesterAllowed(definition: any, requesterId: string): boolean
	for _, allowed in ipairs(definition.allowedRequesters) do
		if allowed == "*" or allowed == requesterId then
			return true
		end
	end
	return false
end

local function fail(code: string, stage: string, reason: string, query: any?)
	local failure = {
		failureType = code,
		stage = stage,
		reason = reason,
		queryId = if query ~= nil then query.queryId else nil,
		queryType = if query ~= nil then query.queryType else nil,
	}
	counters.lastFailure = Serialization.deepCopy(failure)
	Evidence.record("query rejected", failure)
	return failure
end

local function registerCoreDefaults()
	if not QueryRegistry.has(Types.CoreQueryTypes.Test) then
		QueryRegistry.register({
			queryType = Types.CoreQueryTypes.Test,
			namespace = "core",
			schemaVersion = "1",
			ownerRuntime = Types.ProviderName,
			defaultPriority = Types.Priority.Normal,
			consistency = Types.Consistency.Snapshot,
			cachePolicy = Types.CachePolicy.NoCache,
			compatibilityPolicy = Types.CompatibilityPolicy.Compatible,
			payloadValidator = defaultValidator,
			responseValidator = defaultValidator,
			allowedRequesters = { Types.ProviderName },
		})
	end
	if not RequesterRegistry.has(Types.ProviderName) then
		RequesterRegistry.register({
			requesterId = Types.ProviderName,
			runtimeId = Types.ProviderName,
			allowedQueryTypes = { "*" },
			ownedNamespaces = { "core" },
		})
	end
end

local function createQuery(request: any, definition: any)
	local queryId = request.queryId or string.format("qry.%06d", sequence + 1)
	local query = {
		queryId = queryId,
		queryType = request.queryType,
		schemaVersion = request.schemaVersion or definition.schemaVersion,
		requesterId = request.requesterId,
		correlationId = request.correlationId or queryId,
		causationId = request.causationId or "root",
		ownerRuntime = definition.ownerRuntime,
		namespace = definition.namespace,
		priority = request.priority or definition.defaultPriority,
		createdTimestamp = request.createdTimestamp or os.clock(),
		deadline = request.deadline,
		cancellationToken = request.cancellationToken,
		metadata = request.metadata or {},
		payload = request.payload or {},
		consistency = definition.consistency,
		cachePolicy = definition.cachePolicy or Types.CachePolicy.NoCache,
		status = Types.Status.Created,
		sequence = nextSequence(),
		timeline = {},
	}
	counters.lastQueryId = query.queryId
	return Serialization.deepCopy(query)
end

function Runtime.registerQueryType(definition: any)
	return QueryRegistry.register(definition)
end

function Runtime.registerRequester(requester: any)
	return RequesterRegistry.register(requester)
end

function Runtime.registerHandler(handler: any)
	return HandlerRegistry.register(handler, QueryRegistry.has)
end

function Runtime.registerProjection(projection: any)
	return ProjectionRuntime.register(projection)
end

function Runtime.registerReadModel(model: any)
	return ReadModels.register(model)
end

function Runtime.query(request: any)
	if shutdown then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ShutdownRejected,
			failure = fail(
				Types.FailureType.ShutdownRejected,
				"submission",
				"runtime is shut down",
				request
			),
		}
	end
	if type(request) ~= "table" then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			failure = fail(
				Types.FailureType.ValidationFailure,
				"submission",
				"request must be a table",
				nil
			),
		}
	end
	local definition = QueryRegistry.get(request.queryType)
	if definition == nil then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.UnknownQueryType,
			failure = fail(
				Types.FailureType.UnknownQueryType,
				"query type",
				"unknown query type",
				request
			),
		}
	end
	local query = createQuery(request, definition)
	if seenQueryIds[query.queryId] then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.DuplicateQueryId,
			failure = fail(
				Types.FailureType.DuplicateQueryId,
				"identity",
				"duplicate query id",
				query
			),
		}
	end
	local payloadOk, payloadReason = definition.payloadValidator(query.payload)
	if not payloadOk then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.SchemaFailure,
			failure = fail(
				Types.FailureType.SchemaFailure,
				"payload validation",
				tostring(payloadReason),
				query
			),
		}
	end
	local validated = Lifecycle.transition(query, Types.Status.Validated, "validatedTimestamp")
	if validated == nil then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			failure = fail(
				Types.FailureType.ValidationFailure,
				"lifecycle",
				"validation transition failed",
				query
			),
		}
	end
	if
		not RequesterRegistry.has(validated.requesterId)
		or not RequesterRegistry.canRequest(validated.requesterId, validated.queryType)
		or not requesterAllowed(definition, validated.requesterId)
	then
		counters.authorizationFailures += 1
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.AuthorizationFailure,
			failure = fail(
				Types.FailureType.AuthorizationFailure,
				"authorization",
				"requester cannot issue query",
				validated
			),
		}
	end
	local handler = HandlerRegistry.resolve(validated.queryType)
	if handler == nil then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.RoutingFailure,
			failure = fail(
				Types.FailureType.RoutingFailure,
				"handler",
				"no authoritative handler registered",
				validated
			),
		}
	end
	local authorized =
		Lifecycle.transition(validated, Types.Status.Authorized, "authorizedTimestamp")
	if authorized == nil or not Validation.isValidPriority(validated.priority) then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.InvalidPriority,
			failure = fail(
				Types.FailureType.InvalidPriority,
				"priority",
				"invalid priority",
				validated
			),
		}
	end
	seenQueryIds[authorized.queryId] = true
	SnapshotRuntime.record(authorized)
	local queued = Queue.enqueue(authorized)
	if not queued.ok then
		counters.rejected += 1
		return {
			ok = false,
			code = queued.code,
			failure = fail(queued.code, "queue", queued.message, authorized),
		}
	end
	return Serialization.deepCopy({
		ok = true,
		code = "Ok",
		queryId = authorized.queryId,
		queryType = authorized.queryType,
		status = Types.Status.Queued,
		queued = true,
		correlationId = authorized.correlationId,
		causationId = authorized.causationId,
	})
end

function Runtime.queryBatch(requests: { any })
	if type(requests) ~= "table" or #requests > Types.Limits.MaxBatchSize then
		return { ok = false, code = Types.FailureType.ValidationFailure, message = "invalid batch" }
	end
	local results = {}
	for _, request in ipairs(requests) do
		table.insert(results, Runtime.query(request))
	end
	return { ok = true, code = "Ok", results = Serialization.copyArray(results) }
end

function Runtime.cancel(queryId: string)
	local result = Queue.cancel(queryId)
	if result.ok then
		counters.cancelled += 1
	else
		counters.rejected += 1
	end
	return result
end

function Runtime.dispatchNext()
	local query = Queue.dequeue()
	if query == nil then
		return { ok = true, code = "Empty" }
	end
	local definition = QueryRegistry.get(query.queryType)
	if definition == nil then
		counters.failed += 1
		return { ok = false, code = Types.FailureType.UnknownQueryType, queryId = query.queryId }
	end
	local handler = HandlerRegistry.resolve(query.queryType)
	local plan = Router.route(query, definition, handler)
	table.insert(routingHistory, Serialization.deepCopy(plan))
	while #routingHistory > Types.Limits.MaxExecutionHistory do
		table.remove(routingHistory, 1)
	end
	counters.dispatched += 1
	counters.executing += 1
	local result = Execution.execute(query, plan)
	Cache.record(query, result)
	Metrics.record(result)
	Profiler.record(query, result)
	if result.ok then
		counters.completed += 1
	else
		counters.failed += 1
	end
	return result
end

function Runtime.dispatchAll()
	local results = {}
	while Queue.getDepth() > 0 do
		table.insert(results, Runtime.dispatchNext())
	end
	return { ok = true, code = "Ok", results = Serialization.copyArray(results) }
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return require(script.Parent.QuerySnapshots).capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return true, nil
end

function Runtime.shutdown()
	shutdown = true
	Queue.clear()
	Execution.clear()
	Evidence.clear()
	Cache.clear()
	SnapshotRuntime.clear()
	ProjectionRuntime.clear()
	ReadModels.clear()
	Metrics.clear()
	Profiler.clear()
end

function Runtime.reset()
	shutdown = false
	sequence = 0
	table.clear(routingHistory)
	table.clear(seenQueryIds)
	for key in pairs(counters) do
		if key == "lastQueryId" or key == "lastFailure" then
			counters[key] = nil
		else
			counters[key] = 0
		end
	end
	QueryRegistry.clear()
	RequesterRegistry.clear()
	HandlerRegistry.clear()
	Queue.clear()
	Execution.clear()
	Evidence.clear()
	Cache.clear()
	SnapshotRuntime.clear()
	ProjectionRuntime.clear()
	ReadModels.clear()
	Metrics.clear()
	Profiler.clear()
	registerCoreDefaults()
end

function Runtime.isShutdown(): boolean
	return shutdown
end

function Runtime.getRoutingHistory()
	return Serialization.copyArray(routingHistory)
end

local function mapCount(map: any): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

function Runtime.getCounters()
	local queryTypes = QueryRegistry.inspect()
	local requesters = RequesterRegistry.inspect()
	local handlers = HandlerRegistry.inspect()
	local projections = ProjectionRuntime.inspect()
	local readModels = ReadModels.inspect()
	local metrics = Metrics.inspect()
	return {
		queryTypes = #Serialization.sortedKeys(queryTypes),
		requesters = #Serialization.sortedKeys(requesters),
		handlers = mapCount(handlers),
		queued = Queue.getDepth(),
		dispatched = counters.dispatched,
		executing = counters.executing,
		completed = counters.completed,
		cancelled = counters.cancelled,
		rejected = counters.rejected,
		failed = counters.failed,
		authorizationFailures = counters.authorizationFailures,
		cacheBehavior = Cache.inspect(),
		projectionCount = mapCount(projections),
		readModelCount = mapCount(readModels),
		metrics = metrics,
		health = Health.calculate({
			queued = Queue.getDepth(),
			failed = counters.failed,
			authorizationFailures = counters.authorizationFailures,
		}),
		profiler = Profiler.inspect(),
		budgets = Budgets.inspect(),
		lastQueryId = counters.lastQueryId,
		lastFailure = counters.lastFailure,
	}
end

Runtime.reset()

return Runtime
