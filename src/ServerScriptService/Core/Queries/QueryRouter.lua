--!strict

local Evidence = require(script.Parent.QueryEvidence)
local Serialization = require(script.Parent.QuerySerialization)

local Router = {}

function Router.route(query: any, definition: any, handler: any?)
	local plan = {
		queryId = query.queryId,
		queryType = query.queryType,
		namespace = definition.namespace,
		ownerRuntime = definition.ownerRuntime,
		schemaVersion = definition.schemaVersion,
		handlerId = if handler ~= nil then handler.handlerId else nil,
		handlerRuntime = if handler ~= nil then handler.runtimeId else nil,
		missingRoute = handler == nil,
		execute = if handler ~= nil then handler.execute else nil,
	}
	Evidence.record(
		"query routed",
		{ queryId = query.queryId, queryType = query.queryType, handlerId = plan.handlerId }
	)
	return Serialization.deepCopy(plan)
end

return Router
