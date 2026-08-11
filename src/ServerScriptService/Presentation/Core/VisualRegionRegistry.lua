--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Regions = {}

function Regions.extract(nodes: { any })
	local regions = {}
	for _, node in ipairs(nodes) do
		if node.nodeKind == Types.VisualNodeKind.Region then
			regions[#regions + 1] = {
				regionId = node.regionId or node.nodeId,
				semanticRole = node.semanticRole,
				parentNodeId = node.parentNodeId,
				layout = Serialization.deepCopy(node.layout or {}),
			}
		end
	end
	return regions
end

function Regions.validate(nodes: { any }): (boolean, string?)
	local count = 0
	for _, node in ipairs(nodes) do
		if node.nodeKind == Types.VisualNodeKind.Region then
			count += 1
		end
	end
	if count > Types.VisualCompositionLimits.MaxRegionsPerComposition then
		return false, "region limit exceeded"
	end
	return true, nil
end

return Regions
