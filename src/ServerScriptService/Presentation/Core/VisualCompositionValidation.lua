--!strict

local Accessibility = require(script.Parent.VisualAccessibilitySemantics)
local AssetReferences = require(script.Parent.VisualAssetReferences)
local Constraints = require(script.Parent.VisualLayoutConstraints)
local Graph = require(script.Parent.VisualCompositionGraph)
local Layout = require(script.Parent.VisualLayoutModel)
local Layers = require(script.Parent.VisualLayerRegistry)
local Localization = require(script.Parent.VisualLocalizationSlots)
local Regions = require(script.Parent.VisualRegionRegistry)
local Responsive = require(script.Parent.VisualResponsiveModel)
local Serialization = require(script.Parent.PresentationSerialization)
local StateVariants = require(script.Parent.VisualStateVariants)
local StyleReferences = require(script.Parent.VisualStyleReferences)
local ThemeReferences = require(script.Parent.VisualThemeReferences)
local TypographyReferences = require(script.Parent.VisualTypographyReferences)
local Types = require(script.Parent.PresentationTypes)
local Visibility = require(script.Parent.VisualVisibilityModel)

local Validation = {}

local definitionFields = {
	compositionId = true,
	version = true,
	compositionKind = true,
	rootNodeId = true,
	supportedPresentationKinds = true,
	defaultThemeReference = true,
	nodes = true,
	runtimeMetadata = true,
}

local nodeFields = {
	nodeId = true,
	nodeKind = true,
	semanticRole = true,
	parentNodeId = true,
	order = true,
	layout = true,
	constraints = true,
	responsiveVariants = true,
	styleReference = true,
	themeReference = true,
	typographyReference = true,
	assetReference = true,
	localizationSlot = true,
	tokenReference = true,
	accessibility = true,
	states = true,
	visibility = true,
	layerId = true,
	layerKind = true,
	layerPriority = true,
	blockingPolicy = true,
	inputIntent = true,
	compositionOwnership = true,
	regionId = true,
}

local compositionFields = {
	compositionInstanceId = true,
	compositionId = true,
	robloxRenderingSessionId = true,
	renderingExecutionSessionId = true,
	renderingSessionId = true,
	presentationSessionId = true,
	rendererId = true,
	owner = true,
	layoutIntent = true,
	stateVariants = true,
	accessibility = true,
	runtimeMetadata = true,
}

local function validString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

local function validateFields(input: any, allowed: { [string]: boolean }): (boolean, string?)
	for field in pairs(input) do
		if not allowed[field] then
			return false, "invalid field " .. tostring(field)
		end
	end
	return true, nil
end

local function validateNode(node: any): (boolean, string?)
	if type(node) ~= "table" then
		return false, "node must be a table"
	end
	local fieldsOk, fieldsReason = validateFields(node, nodeFields)
	if not fieldsOk then
		return false, fieldsReason
	end
	if not validString(node.nodeId) then
		return false, "invalid node id"
	end
	if not Types.isVisualNodeKind(node.nodeKind) then
		return false, "invalid node kind"
	end
	if node.semanticRole ~= nil and not Types.isVisualSemanticRole(node.semanticRole) then
		return false, "invalid semantic role"
	end
	if node.nodeKind == Types.VisualNodeKind.SemanticOnly and node.assetReference ~= nil then
		return false, "semantic only node cannot own asset intent"
	end
	if
		node.semanticRole == Types.VisualSemanticRole.SpeakerPortrait
		and node.nodeKind ~= Types.VisualNodeKind.Image
	then
		return false, "speaker portrait must be image metadata"
	end
	local checks = {
		{ Layout.validate(node.layout or {}) },
		{ Constraints.validate(node.constraints) },
		{ Responsive.validate(node.responsiveVariants) },
		{ StyleReferences.validate(node.styleReference) },
		{ ThemeReferences.validate(node.themeReference) },
		{ TypographyReferences.validate(node.typographyReference) },
		{ AssetReferences.validate(node.assetReference) },
		{ Localization.validate(node.localizationSlot, node.tokenReference) },
		{ Accessibility.validate(node.accessibility) },
		{ StateVariants.validate(node.states) },
		{ Visibility.validate(node.visibility) },
	}
	for _, result in ipairs(checks) do
		if not result[1] then
			return false, result[2]
		end
	end
	return true, nil
end

function Validation.validateDefinition(input: any): (boolean, string?)
	if type(input) ~= "table" then
		return false, "definition must be a table"
	end
	local serializable, serialReason = Serialization.validateSerializable(input)
	if not serializable then
		return false, serialReason
	end
	local fieldsOk, fieldsReason = validateFields(input, definitionFields)
	if not fieldsOk then
		return false, fieldsReason
	end
	for _, field in ipairs({ "compositionId", "version", "compositionKind", "rootNodeId" }) do
		if not validString(input[field]) then
			return false, "invalid field " .. field
		end
	end
	if not Types.isVisualCompositionKind(input.compositionKind) then
		return false, "invalid composition kind"
	end
	local themeOk, themeReason = ThemeReferences.validate(input.defaultThemeReference)
	if not themeOk then
		return false, themeReason
	end
	if type(input.nodes) ~= "table" or #input.nodes == 0 then
		return false, "nodes must be a non-empty array"
	end
	for _, node in ipairs(input.nodes) do
		local ok, reason = validateNode(node)
		if not ok then
			return false, reason
		end
	end
	local layerOk, layerReason = Layers.validate(input.nodes)
	if not layerOk then
		return false, layerReason
	end
	local regionOk, regionReason = Regions.validate(input.nodes)
	if not regionOk then
		return false, regionReason
	end
	return Graph.validate(input)
end

function Validation.validateComposition(input: any): (boolean, string?)
	if type(input) ~= "table" then
		return false, "composition must be a table"
	end
	local serializable, serialReason = Serialization.validateSerializable(input)
	if not serializable then
		return false, serialReason
	end
	local fieldsOk, fieldsReason = validateFields(input, compositionFields)
	if not fieldsOk then
		return false, fieldsReason
	end
	for _, field in ipairs({
		"compositionInstanceId",
		"compositionId",
		"robloxRenderingSessionId",
		"renderingExecutionSessionId",
		"renderingSessionId",
		"presentationSessionId",
		"rendererId",
		"owner",
	}) do
		if not validString(input[field]) then
			return false, "invalid field " .. field
		end
	end
	return true, nil
end

function Validation.validateRuntime(definitions: { any }, compositions: { any }): (boolean, string?)
	for _, definition in ipairs(definitions) do
		local ok, reason = Validation.validateDefinition(definition)
		if not ok then
			return false, reason
		end
	end
	for _, composition in ipairs(compositions) do
		if not Types.isVisualCompositionState(composition.lifecycleState) then
			return false, "invalid composition lifecycle"
		end
	end
	return true, nil
end

return Validation
