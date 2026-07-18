--!strict

local Dependency = require(script.Parent.Dependency)
local Node = require(script.Parent.Node)
local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)

local Graph = {}

local function sortNodes(nodes: { any })
	table.sort(nodes, function(left, right)
		if left.orderingKey == right.orderingKey then
			return left.nodeId < right.nodeId
		end
		return left.orderingKey < right.orderingKey
	end)
end

function Graph.build(input: any): (boolean, any, string?)
	local rawNodes = if type(input) == "table" and type(input.nodes) == "table"
		then input.nodes
		else {}
	local dependencies = if type(input) == "table" and type(input.dependencies) == "table"
		then input.dependencies
		else {}
	if #rawNodes > Types.Limits.MaxNodes then
		return false, nil, Types.ResultCode.InvalidSchema .. ": node limit exceeded"
	end
	local nodes = {}
	local nodesById = {}
	for _, rawNode in ipairs(rawNodes) do
		local ok, nodeOrReason = Node.create(rawNode)
		if not ok then
			return false, nil, nodeOrReason
		end
		if nodesById[nodeOrReason.nodeId] then
			return false, nil, Types.ResultCode.DuplicateNode .. ": " .. nodeOrReason.nodeId
		end
		nodesById[nodeOrReason.nodeId] = nodeOrReason
		table.insert(nodes, nodeOrReason)
	end
	local dependenciesOk, dependencyReason = Dependency.validate(nodesById, dependencies)
	if not dependenciesOk then
		return false, nil, dependencyReason
	end
	sortNodes(nodes)
	local graph = {
		graphId = if type(input.graphId) == "string"
			then input.graphId
			else "executionPlanning.graph",
		nodes = nodes,
		dependencies = Serialization.deepCopy(dependencies),
		nodesById = nodesById,
	}
	graph.graphHash = Serialization.deterministicHash({
		nodes = graph.nodes,
		dependencies = graph.dependencies,
	})
	return true, graph, nil
end

return Graph
