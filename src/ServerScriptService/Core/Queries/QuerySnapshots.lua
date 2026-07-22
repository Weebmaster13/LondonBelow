--!strict

local Cache = require(script.Parent.QueryCacheRuntime)
local Evidence = require(script.Parent.QueryEvidence)
local Execution = require(script.Parent.QueryExecutionRuntime)
local HandlerRegistry = require(script.Parent.QueryHandlerRegistry)
local Lifecycle = require(script.Parent.QueryLifecycle)
local ProjectionRuntime = require(script.Parent.QueryProjectionRuntime)
local QueryRegistry = require(script.Parent.QueryRegistry)
local Queue = require(script.Parent.QueryQueue)
local ReadModels = require(script.Parent.QueryReadModels)
local RequesterRegistry = require(script.Parent.QueryRequesterRegistry)
local Serialization = require(script.Parent.QuerySerialization)
local SnapshotRuntime = require(script.Parent.QuerySnapshotRuntime)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		queryRegistrySnapshot = QueryRegistry.inspect(),
		requesterRegistrySnapshot = RequesterRegistry.inspect(),
		handlerRegistrySnapshot = HandlerRegistry.inspect(),
		lifecycleSnapshot = Lifecycle.inspect(),
		queueSnapshot = Queue.inspect(),
		routingSnapshot = runtime.getRoutingHistory(),
		executionSnapshot = Execution.inspect(),
		projectionSnapshot = ProjectionRuntime.inspect(),
		readModelSnapshot = ReadModels.inspect(),
		cacheSnapshot = Cache.inspect(),
		consistentReadSnapshot = SnapshotRuntime.inspect(),
		diagnosticsSnapshot = runtime.inspect(),
		evidenceSnapshot = Evidence.inspect(),
	})
end

return Snapshots
