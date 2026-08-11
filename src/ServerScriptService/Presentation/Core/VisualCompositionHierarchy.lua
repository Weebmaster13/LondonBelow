--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Hierarchy = {}

function Hierarchy.childrenByParent(nodes: { any })
	local children = {}
	for _, node in ipairs(nodes) do
		local parent = node.parentNodeId or "__root__"
		children[parent] = children[parent] or {}
		children[parent][#children[parent] + 1] = Serialization.deepCopy(node)
	end
	for _, list in pairs(children) do
		table.sort(list, function(left, right)
			if (left.order or 0) == (right.order or 0) then
				return left.nodeId < right.nodeId
			end
			return (left.order or 0) < (right.order or 0)
		end)
	end
	return children
end

function Hierarchy.depthFrom(
	rootId: string,
	nodesById: { [string]: any },
	children: { [string]: any },
	limit: number
)
	local maxDepth = 0
	local function visit(nodeId: string, depth: number): (boolean, string?)
		if depth > limit then
			return false, "composition depth limit exceeded"
		end
		if depth > maxDepth then
			maxDepth = depth
		end
		for _, child in ipairs(children[nodeId] or {}) do
			if nodesById[child.nodeId] == nil then
				return false, "unknown child"
			end
			local ok, reason = visit(child.nodeId, depth + 1)
			if not ok then
				return false, reason
			end
		end
		return true, nil
	end
	local ok, reason = visit(rootId, 1)
	return ok, reason, maxDepth
end

return Hierarchy
