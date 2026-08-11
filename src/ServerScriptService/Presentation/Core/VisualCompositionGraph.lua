--!strict

local Hierarchy = require(script.Parent.VisualCompositionHierarchy)
local Types = require(script.Parent.PresentationTypes)

local Graph = {}

function Graph.validate(definition: any): (boolean, string?)
	local nodes = definition.nodes
	if type(nodes) ~= "table" or #nodes == 0 then
		return false, "composition must contain nodes"
	end
	if #nodes > Types.VisualCompositionLimits.MaxNodesPerDefinition then
		return false, "node limit exceeded"
	end
	local nodesById = {}
	local roots = {}
	for _, node in ipairs(nodes) do
		if type(node) ~= "table" or type(node.nodeId) ~= "string" or node.nodeId == "" then
			return false, "invalid node"
		end
		if nodesById[node.nodeId] ~= nil then
			return false, "duplicate node"
		end
		nodesById[node.nodeId] = node
		if node.nodeKind == Types.VisualNodeKind.Root then
			roots[#roots + 1] = node
		end
	end
	if #roots == 0 then
		return false, "missing root"
	end
	if #roots > 1 then
		return false, "multiple roots"
	end
	local root = roots[1]
	if root.parentNodeId ~= nil then
		return false, "root cannot have a parent"
	end
	if definition.rootNodeId ~= root.nodeId then
		return false, "root node mismatch"
	end
	for _, node in ipairs(nodes) do
		if node.parentNodeId ~= nil and nodesById[node.parentNodeId] == nil then
			return false, "missing parent"
		end
	end
	local visiting = {}
	local visited = {}
	local function visit(nodeId: string): (boolean, string?)
		if visiting[nodeId] then
			return false, "circular hierarchy"
		end
		if visited[nodeId] then
			return true, nil
		end
		visiting[nodeId] = true
		local node = nodesById[nodeId]
		if node.parentNodeId ~= nil then
			local ok, reason = visit(node.parentNodeId)
			if not ok then
				return false, reason
			end
		end
		visiting[nodeId] = nil
		visited[nodeId] = true
		return true, nil
	end
	for id in pairs(nodesById) do
		local ok, reason = visit(id)
		if not ok then
			return false, reason
		end
	end
	local children = Hierarchy.childrenByParent(nodes)
	local ok, reason = Hierarchy.depthFrom(
		root.nodeId,
		nodesById,
		children,
		Types.VisualCompositionLimits.MaxCompositionDepth
	)
	if not ok then
		return false, reason
	end
	local reachable = {}
	local function mark(nodeId: string)
		reachable[nodeId] = true
		for _, child in ipairs(children[nodeId] or {}) do
			mark(child.nodeId)
		end
	end
	mark(root.nodeId)
	for id in pairs(nodesById) do
		if not reachable[id] then
			return false, "unreachable node"
		end
	end
	return true, nil
end

return Graph
