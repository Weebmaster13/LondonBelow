--!strict

local Layers = require(script.Parent.VisualLayerRegistry)
local NodeRegistry = require(script.Parent.VisualCompositionNodeRegistry)
local Normalizer = require(script.Parent.VisualCompositionNormalizer)
local Regions = require(script.Parent.VisualRegionRegistry)
local Serialization = require(script.Parent.PresentationSerialization)

local Compiler = {}

function Compiler.compile(definition: any, composition: any, binding: any, revision: number)
	local normalized = Normalizer.normalizeDefinition(definition)
	local orderedNodes = NodeRegistry.ordered(normalized.nodes)
	return {
		compositionInstanceId = composition.compositionInstanceId,
		compositionId = definition.compositionId,
		revision = revision,
		rootNodeId = normalized.rootNodeId,
		orderedNodes = orderedNodes,
		layers = Layers.extract(orderedNodes),
		regions = Regions.extract(orderedNodes),
		resolvedLayoutIntent = Serialization.deepCopy(composition.layoutIntent or {}),
		state = Serialization.deepCopy(composition.stateVariants or {}),
		bindings = Serialization.deepCopy(binding or {}),
		accessibility = Serialization.deepCopy(composition.accessibility or {}),
		references = {
			theme = definition.defaultThemeReference,
			style = "composition." .. definition.compositionKind,
		},
	}
end

return Compiler
