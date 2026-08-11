--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local NodeRegistry = {}

function NodeRegistry.byId(nodes: { any })
	local result = {}
	for _, node in ipairs(nodes) do
		result[node.nodeId] = Serialization.deepCopy(node)
	end
	return result
end

function NodeRegistry.ordered(nodes: { any })
	local result = Serialization.deepCopy(nodes)
	table.sort(result, function(left, right)
		if left.parentNodeId == right.parentNodeId then
			if (left.order or 0) == (right.order or 0) then
				return left.nodeId < right.nodeId
			end
			return (left.order or 0) < (right.order or 0)
		end
		return tostring(left.parentNodeId) < tostring(right.parentNodeId)
	end)
	return result
end

return NodeRegistry
