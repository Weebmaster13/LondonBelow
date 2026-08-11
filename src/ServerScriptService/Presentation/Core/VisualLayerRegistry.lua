--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Layers = {}

function Layers.extract(nodes: { any })
	local layers = {}
	for _, node in ipairs(nodes) do
		if node.nodeKind == Types.VisualNodeKind.Layer then
			layers[#layers + 1] = {
				layerId = node.layerId or node.nodeId,
				layerKind = node.layerKind or node.semanticRole,
				layerPriority = node.layerPriority or node.order or 0,
				blockingPolicy = node.blockingPolicy or "NonBlocking",
				visibilityPolicy = node.visibility or Types.VisualVisibilityState.Visible,
				inputIntent = node.inputIntent or "None",
				compositionOwnership = node.compositionOwnership or "CompositionRuntime",
			}
		end
	end
	table.sort(layers, function(left, right)
		if left.layerPriority == right.layerPriority then
			return left.layerId < right.layerId
		end
		return left.layerPriority < right.layerPriority
	end)
	return layers
end

function Layers.validate(nodes: { any }): (boolean, string?)
	local count = 0
	for _, node in ipairs(nodes) do
		if node.nodeKind == Types.VisualNodeKind.Layer then
			count += 1
			local layerKind = node.layerKind or node.semanticRole
			if layerKind ~= nil and not Types.isVisualLayerKind(layerKind) then
				return false, "invalid layer kind"
			end
		end
	end
	if count > Types.VisualCompositionLimits.MaxLayersPerComposition then
		return false, "layer limit exceeded"
	end
	return true, nil
end

function Layers.copy(layers: any)
	return Serialization.deepCopy(layers)
end

return Layers
