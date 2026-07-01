--!strict

local PuzzleGraph = {}

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
	for _, completionNodeId in ipairs(definition.completionNodeIds or {}) do
		if nodeMap[completionNodeId] == nil then
			return false, "completion node is missing"
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
	for _, dependencyId in ipairs(node.dependencies or {}) do
		if completedNodes[dependencyId] ~= true then
			return false, "puzzle node dependency is incomplete"
		end
	end
	return true, nil
end

return PuzzleGraph
