--!strict

local Layout = require(script.Parent.VisualLayoutModel)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Normalizer = {}

function Normalizer.normalizeDefinition(definition: any)
	local copy = Serialization.deepCopy(definition)
	table.sort(copy.nodes, function(left, right)
		if tostring(left.parentNodeId) == tostring(right.parentNodeId) then
			if (left.order or 0) == (right.order or 0) then
				return left.nodeId < right.nodeId
			end
			return (left.order or 0) < (right.order or 0)
		end
		return tostring(left.parentNodeId) < tostring(right.parentNodeId)
	end)
	for index, node in ipairs(copy.nodes) do
		node.order = node.order or index
		node.layout = Layout.normalize(node.layout)
		node.visibility = node.visibility or Types.VisualVisibilityState.Visible
		node.states = node.states or { Default = {} }
	end
	return copy
end

return Normalizer
