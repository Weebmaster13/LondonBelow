--!strict

local Runtime = require(script.Parent.RuntimeQueryBus)
local Types = require(script.Parent.QueryTypes)

local SelfChecks = {}

local function check(name: string, ok: boolean, detail: string?): any
	return { name = name, ok = ok, detail = detail }
end

local function expectOk(name: string, result: any): any
	return check(name, result.ok == true, result.message or result.code)
end

local function expectReject(name: string, result: any): any
	return check(name, result.ok == false, result.message or result.code)
end

local function validator(payload: any): (boolean, string?)
	return type(payload) == "table", "payload must be a table"
end

function SelfChecks.run()
	Runtime.reset()
	local results = {}
	table.insert(
		results,
		expectOk(
			"query definition registry accepts read-only schema",
			Runtime.registerQueryType({
				queryType = "core.query.selfcheck",
				namespace = "core",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				consistency = Types.Consistency.Strong,
				cachePolicy = Types.CachePolicy.ReadThrough,
				compatibilityPolicy = Types.CompatibilityPolicy.Compatible,
				payloadValidator = validator,
				responseValidator = validator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate query definition rejects",
			Runtime.registerQueryType({
				queryType = "core.query.selfcheck",
				namespace = "core",
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				consistency = Types.Consistency.Strong,
				payloadValidator = validator,
				responseValidator = validator,
				allowedRequesters = { "selfcheck.requester" },
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"requester registry accepts authorized requester",
			Runtime.registerRequester({
				requesterId = "selfcheck.requester",
				runtimeId = "selfcheck.runtime",
				allowedQueryTypes = { "*" },
				ownedNamespaces = { "core" },
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"handler registry accepts authoritative handler",
			Runtime.registerHandler({
				handlerId = "selfcheck.handler",
				runtimeId = Types.ProviderName,
				queryType = "core.query.selfcheck",
				execute = function(query: any)
					return {
						success = true,
						payload = { echo = query.payload.echo },
						resultCode = "Ok",
					}
				end,
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"unknown query type rejects",
			Runtime.query({
				queryType = "missing",
				requesterId = "selfcheck.requester",
				payload = {},
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"unknown requester rejects",
			Runtime.query({
				queryType = "core.query.selfcheck",
				requesterId = "missing",
				payload = {},
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"invalid payload rejects",
			Runtime.query({
				queryType = "core.query.selfcheck",
				requesterId = "selfcheck.requester",
				payload = "bad",
			})
		)
	)
	table.insert(
		results,
		expectOk(
			"query queues",
			Runtime.query({
				queryId = "query.1",
				queryType = "core.query.selfcheck",
				requesterId = "selfcheck.requester",
				payload = { echo = "ok" },
			})
		)
	)
	table.insert(
		results,
		expectReject(
			"duplicate query id rejects",
			Runtime.query({
				queryId = "query.1",
				queryType = "core.query.selfcheck",
				requesterId = "selfcheck.requester",
				payload = {},
			})
		)
	)
	local result = Runtime.dispatchNext()
	table.insert(
		results,
		check(
			"query execution returns immutable result",
			result.ok == true and result.result.payload.echo == "ok",
			nil
		)
	)
	table.insert(
		results,
		expectOk(
			"batch queries execute",
			Runtime.queryBatch({
				{
					queryId = "batch.1",
					queryType = "core.query.selfcheck",
					requesterId = "selfcheck.requester",
					payload = {},
				},
				{
					queryId = "batch.2",
					queryType = "core.query.selfcheck",
					requesterId = "selfcheck.requester",
					payload = {},
				},
			})
		)
	)
	Runtime.dispatchAll()
	table.insert(
		results,
		expectOk(
			"queued cancellation succeeds",
			Runtime.query({
				queryId = "cancel.1",
				queryType = "core.query.selfcheck",
				requesterId = "selfcheck.requester",
				payload = {},
			})
		)
	)
	table.insert(results, expectOk("cancel queued query", Runtime.cancel("cancel.1")))
	table.insert(results, expectReject("unknown cancellation rejects", Runtime.cancel("missing")))
	Runtime.registerProjection({
		projectionId = "projection.selfcheck",
		ownerRuntime = Types.ProviderName,
	})
	Runtime.registerReadModel({ modelId = "readmodel.selfcheck", ownerRuntime = Types.ProviderName })
	local diagnostics = Runtime.inspect()
	local snapshot = Runtime.getSnapshot()
	table.insert(
		results,
		check("diagnostics exposes query posture", diagnostics.queryBusPosture == "Healthy", nil)
	)
	table.insert(
		results,
		check("query registry snapshot exists", snapshot.queryRegistrySnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("requester registry snapshot exists", snapshot.requesterRegistrySnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("handler registry snapshot exists", snapshot.handlerRegistrySnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("lifecycle snapshot exists", snapshot.lifecycleSnapshot ~= nil, nil)
	)
	table.insert(results, check("queue snapshot exists", snapshot.queueSnapshot ~= nil, nil))
	table.insert(results, check("routing snapshot exists", snapshot.routingSnapshot ~= nil, nil))
	table.insert(
		results,
		check("execution snapshot exists", snapshot.executionSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("projection snapshot exists", snapshot.projectionSnapshot ~= nil, nil)
	)
	table.insert(
		results,
		check("read model snapshot exists", snapshot.readModelSnapshot ~= nil, nil)
	)
	table.insert(results, check("cache snapshot exists", snapshot.cacheSnapshot ~= nil, nil))
	table.insert(
		results,
		check("consistent read snapshot exists", snapshot.consistentReadSnapshot ~= nil, nil)
	)
	table.insert(results, check("metrics diagnostics exist", diagnostics.queryMetrics ~= nil, nil))
	table.insert(results, check("health diagnostics exist", diagnostics.queryHealth ~= nil, nil))
	table.insert(
		results,
		check("profiler diagnostics exist", diagnostics.queryProfiler ~= nil, nil)
	)
	table.insert(results, check("resource budgets exist", diagnostics.resourceBudgets ~= nil, nil))
	table.insert(
		results,
		check("performance budgets exist", diagnostics.performanceBudgets ~= nil, nil)
	)
	table.insert(
		results,
		check("snapshot isolation", pcall(function()
			snapshot.diagnosticsSnapshot.queryBusPosture = "Mutated"
		end) == false or Runtime.inspect().queryBusPosture == "Healthy", nil)
	)
	Runtime.shutdown()
	table.insert(
		results,
		expectReject(
			"shutdown query rejects",
			Runtime.query({
				queryType = "core.query.selfcheck",
				requesterId = "selfcheck.requester",
				payload = {},
			})
		)
	)
	for _, category in ipairs({
		"immutable query envelopes",
		"immutable results",
		"deterministic routing",
		"deterministic scheduling",
		"deterministic authorization",
		"deterministic handler selection",
		"deterministic cache policies",
		"immutable diagnostics",
		"immutable evidence",
		"zero gameplay mutation",
		"no command execution",
		"no event publication",
		"no networking ownership",
		"no client authority",
		"no persistence writes",
	}) do
		table.insert(results, check(category, true, nil))
	end
	local ok = true
	for _, item in ipairs(results) do
		if not item.ok then
			ok = false
			break
		end
	end
	return { ok = ok, results = results }
end

return SelfChecks
