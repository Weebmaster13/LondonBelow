--!strict

local RenderingCatalog = require(script.Parent.RobloxGuiRenderingCatalog)
local RenderingTypes = require(script.Parent.RobloxGuiRenderingTypes)
local Types = require(script.Parent.RobloxGuiComponentTypes)

local Validator = {}

local compositionFields = table.freeze({
	schemaVersion = true,
	compositionId = true,
	targetRevision = true,
	rootComponentId = true,
	components = true,
})
local componentFields = table.freeze({
	componentId = true,
	kind = true,
	parentComponentId = true,
	props = true,
	accessibility = true,
	responsive = true,
	tags = true,
})
local kindToClass = table.freeze({
	Screen = "ScreenGui",
	Panel = "Frame",
	Stack = "Frame",
	Grid = "Frame",
	Text = "TextLabel",
	Button = "TextButton",
	Image = "ImageLabel",
	Scroll = "ScrollingFrame",
})

local function exactFields(value: { [any]: any }, allowed: { [string]: boolean }): boolean
	for key in pairs(value) do
		if type(key) ~= "string" or not allowed[key] then
			return false
		end
	end
	return true
end

local function validText(value: any, allowEmpty: boolean?): boolean
	return type(value) == "string"
		and (allowEmpty or value ~= "")
		and #value <= Types.Limits.maxStringLength
end

local function validateTags(tags: any): boolean
	if tags == nil then
		return true
	end
	if type(tags) ~= "table" or #tags > Types.Limits.maxTagsPerComponent then
		return false
	end
	local seen = {}
	for _, tag in ipairs(tags) do
		if type(tag) ~= "string" or tag == "" or seen[tag] then
			return false
		end
		seen[tag] = true
	end
	return true
end

local function buildNode(component: any, rootComponentId: string): any
	local className = kindToClass[component.kind]
	local node = {
		nodeId = component.componentId,
		className = className,
		parentNodeId = component.componentId == rootComponentId and "PlayerGui"
			or component.parentComponentId,
		properties = table.clone(component.props),
		accessibility = component.accessibility or {},
		responsive = component.responsive,
		tags = component.tags,
	}
	if component.kind == Types.ComponentKind.Stack then
		node.properties.AutomaticSize = node.properties.AutomaticSize or Enum.AutomaticSize.Y
	elseif component.kind == Types.ComponentKind.Grid then
		node.properties.AutomaticSize = node.properties.AutomaticSize or Enum.AutomaticSize.None
	end
	return node
end

function Validator.validate(composition: any): (boolean, string?, any?)
	if type(composition) ~= "table" or not exactFields(composition, compositionFields) then
		return false, Types.FailureType.InvalidComposition
	end
	if composition.schemaVersion ~= Types.SchemaVersion then
		return false, Types.FailureType.UnsupportedSchemaVersion
	end
	if not validText(composition.compositionId) or not validText(composition.rootComponentId) then
		return false, Types.FailureType.InvalidComposition
	end
	if
		type(composition.targetRevision) ~= "number"
		or composition.targetRevision < 0
		or composition.targetRevision % 1 ~= 0
	then
		return false, Types.FailureType.InvalidComposition
	end
	if
		type(composition.components) ~= "table"
		or #composition.components == 0
		or #composition.components > Types.Limits.maxComponents
	then
		return false, Types.FailureType.BudgetExceeded
	end
	local byId = {}
	for _, component in ipairs(composition.components) do
		if type(component) ~= "table" or not exactFields(component, componentFields) then
			return false, Types.FailureType.InvalidComposition
		end
		if not validText(component.componentId) or byId[component.componentId] then
			return false, Types.FailureType.DuplicateComponent
		end
		if not validText(component.parentComponentId) then
			return false, Types.FailureType.MissingParent
		end
		local className = kindToClass[component.kind]
		if type(component.kind) ~= "string" or not className then
			return false, Types.FailureType.UnsupportedKind
		end
		if type(component.props) ~= "table" or not validateTags(component.tags) then
			return false, Types.FailureType.InvalidProps
		end
		local propertyCount = 0
		for propertyName in pairs(component.props) do
			propertyCount += 1
			if
				propertyCount > Types.Limits.maxPropsPerComponent
				or not RenderingCatalog.supportsProperty(className, propertyName)
			then
				return false, Types.FailureType.InvalidProps
			end
		end
		byId[component.componentId] = component
	end
	local root = byId[composition.rootComponentId]
	if
		not root
		or root.kind ~= Types.ComponentKind.Screen
		or root.parentComponentId ~= "PlayerGui"
	then
		return false, Types.FailureType.InvalidComposition
	end
	local ordered = {}
	local resolved = {}
	while #ordered < #composition.components do
		local progressed = false
		for _, component in ipairs(composition.components) do
			if
				not resolved[component.componentId]
				and (
					component.parentComponentId == "PlayerGui"
					or resolved[component.parentComponentId]
				)
			then
				resolved[component.componentId] = true
				ordered[#ordered + 1] = component
				progressed = true
			end
		end
		if not progressed then
			return false, Types.FailureType.HierarchyCycle
		end
	end
	local nodes = {}
	local depths = {}
	for _, component in ipairs(ordered) do
		local depth = component.parentComponentId == "PlayerGui" and 0
			or (depths[component.parentComponentId] or 0) + 1
		if depth > Types.Limits.maxDepth then
			return false, Types.FailureType.BudgetExceeded
		end
		depths[component.componentId] = depth
		nodes[#nodes + 1] = buildNode(component, composition.rootComponentId)
	end
	return true,
		nil,
		table.freeze({
			schemaVersion = RenderingTypes.SchemaVersion,
			contractId = composition.compositionId,
			targetRevision = composition.targetRevision,
			rootNodeId = composition.rootComponentId,
			nodes = nodes,
		})
end

function Validator.kindToClass(kind: string): string?
	return kindToClass[kind]
end

return table.freeze(Validator)
