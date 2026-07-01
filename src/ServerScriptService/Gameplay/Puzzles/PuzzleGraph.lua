--!strict

local PuzzleGraph = {}
local Config = require(script.Parent.Parent.Core.GameplayConfig)

local function buildNodeMap(nodes: { any })
	local map = {}
	for _, node in ipairs(nodes) do
		if map[node.id] ~= nil then
			return nil, "duplicate puzzle node id"
		end
		map[node.id] = node
	end
	return map, nil
end

local function visit(
	id: string,
	nodeMap: { [string]: any },
	visiting: { [string]: boolean },
	visited: { [string]: boolean }
): (boolean, string?)
	if visiting[id] then
		return false, "puzzle graph contains a cycle"
	end
	if visited[id] then
		return true, nil
	end
	local node = nodeMap[id]
	if node == nil then
		return false, "puzzle graph references missing node: " .. id
	end
	visiting[id] = true
	for _, dependencyId in ipairs(node.dependencies or {}) do
		local ok, reason = visit(dependencyId, nodeMap, visiting, visited)
		if not ok then
			return false, reason
		end
	end
	visiting[id] = nil
	visited[id] = true
	return true, nil
end

function PuzzleGraph.validate(definition: any): (boolean, string?)
	if type(definition.nodes) ~= "table" or #definition.nodes == 0 then
		return false, "puzzle requires at least one node"
	end
	if #definition.nodes > Config.MaxPuzzleNodes then
		return false, "puzzle has too many nodes"
	end
	local nodeMap, mapErr = buildNodeMap(definition.nodes)
	if nodeMap == nil then
		return false, mapErr
	end
	for _, node in ipairs(definition.nodes) do
		if type(node.id) ~= "string" or node.id == "" then
			return false, "puzzle node id is required"
		end
		local ok, reason = visit(node.id, nodeMap, {}, {})
		if not ok then
			return false, reason
		end
	end
	if type(definition.completionNodeIds) ~= "table" or #definition.completionNodeIds == 0 then
		return false, "puzzle requires at least one completion node"
	end
	for _, completionNodeId in ipairs(definition.completionNodeIds or {}) do
		if nodeMap[completionNodeId] == nil then
			return false, "completion node is missing"
		end
	end
	local reachesCompletion = {}
	local function markAncestors(nodeId: string)
		if reachesCompletion[nodeId] then
			return
		end
		reachesCompletion[nodeId] = true
		local node = nodeMap[nodeId]
		if node == nil then
			return
		end
		for _, dependencyId in ipairs(node.dependencies or {}) do
			markAncestors(dependencyId)
		end
	end
	for _, completionNodeId in ipairs(definition.completionNodeIds) do
		markAncestors(completionNodeId)
	end
	for _, node in ipairs(definition.nodes) do
		if reachesCompletion[node.id] ~= true then
			return false, "puzzle graph contains orphan node outside completion path"
		end
	end
	return true, nil
end

function PuzzleGraph.canCompleteNode(
	definition: any,
	completedNodes: { [string]: boolean },
	nodeId: string
): (boolean, string?)
	local nodeMap, mapErr = buildNodeMap(definition.nodes)
	if nodeMap == nil then
		return false, mapErr
	end
	local node = nodeMap[nodeId]
	if node == nil then
		return false, "unknown puzzle node"
	end
	if completedNodes[nodeId] == true then
		return false, "puzzle node is already complete"
	end
	for _, dependencyId in ipairs(node.dependencies or {}) do
		if completedNodes[dependencyId] ~= true then
			return false, "puzzle node dependency is incomplete"
		end
	end
	return true, nil
end

return PuzzleGraph
