--!strict

local Catalog = require(script.Parent.RobloxGuiInstanceCatalog)
local Accessibility = require(script.Parent.RobloxGuiInstanceContractAccessibility)
local Responsive = require(script.Parent.RobloxGuiInstanceContractResponsive)
local Security = require(script.Parent.RobloxGuiInstanceContractSecurity)
local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.RobloxGuiInstanceContractTypes)

local Validation = {}
local rootFields = {
	contractId = true,
	schemaVersion = true,
	sourcePatchId = true,
	targetRevision = true,
	rootNodeId = true,
	nodes = true,
	metadata = true,
}
local nodeFields = {
	nodeId = true,
	className = true,
	parentNodeId = true,
	properties = true,
	references = true,
	tags = true,
	accessibility = true,
	responsive = true,
}

local function exactFields(value, allowed, required)
	for key in pairs(value) do
		if not allowed[key] then
			return false, Types.FailureType.UnknownField .. ":" .. tostring(key)
		end
	end
	for _, key in ipairs(required) do
		if value[key] == nil then
			return false, Types.FailureType.MissingField .. ":" .. key
		end
	end
	return true
end

local function validateProperty(kind: string, value: any): boolean
	if kind == Types.ValueKind.Boolean then
		return type(value) == "boolean"
	end
	if kind == Types.ValueKind.Number then
		return type(value) == "number"
			and value == value
			and value ~= math.huge
			and value ~= -math.huge
	end
	if kind == Types.ValueKind.String or kind == Types.ValueKind.Enum then
		return type(value) == "string" and value ~= ""
	end
	if kind == Types.ValueKind.AssetReference then
		return type(value) == "table"
			and type(value.assetId) == "string"
			and type(value.assetKind) == "string"
	end
	return type(value) == "table"
end

function Validation.validate(contract: any): (boolean, string?)
	if type(contract) ~= "table" then
		return false, Types.FailureType.InvalidSchema
	end
	local serializable, reason = Serialization.validateSerializable(contract)
	if not serializable then
		return false, reason or Types.FailureType.UnsafePayload
	end
	local ok, fieldReason = exactFields(contract, rootFields, {
		"contractId",
		"schemaVersion",
		"sourcePatchId",
		"targetRevision",
		"rootNodeId",
		"nodes",
		"metadata",
	})
	if not ok then
		return false, fieldReason
	end
	if type(contract.contractId) ~= "string" or contract.contractId == "" then
		return false, "InvalidContractId"
	end
	if contract.schemaVersion ~= Types.SchemaVersion then
		return false, Types.FailureType.UnsupportedVersion
	end
	if type(contract.sourcePatchId) ~= "string" or contract.sourcePatchId == "" then
		return false, "InvalidSourcePatchId"
	end
	if
		type(contract.targetRevision) ~= "number"
		or contract.targetRevision < 0
		or contract.targetRevision % 1 ~= 0
	then
		return false, "InvalidTargetRevision"
	end
	if
		type(contract.nodes) ~= "table"
		or #contract.nodes == 0
		or #contract.nodes > Types.Limits.maxNodesPerContract
	then
		return false, Types.FailureType.BudgetExceeded
	end
	local seen = {}
	for _, node in ipairs(contract.nodes) do
		local nodeOk, nodeReason = exactFields(node, nodeFields, {
			"nodeId",
			"className",
			"parentNodeId",
			"properties",
			"references",
			"tags",
			"accessibility",
			"responsive",
		})
		if not nodeOk then
			return false, nodeReason
		end
		if type(node.nodeId) ~= "string" or node.nodeId == "" or seen[node.nodeId] then
			return false, Types.FailureType.DuplicateNode
		end
		seen[node.nodeId] = node
		if Catalog.isForbidden(node.className) then
			return false, Types.FailureType.ForbiddenClass
		end
		local definition = Catalog.get(node.className)
		if not definition then
			return false, Types.FailureType.UnsupportedClass
		end
		local secure, securityReason = Security.evaluate(node.className, node.properties)
		if not secure then
			return false, securityReason
		end
		if type(node.references) ~= "table" or type(node.tags) ~= "table" then
			return false, Types.FailureType.InvalidSchema
		end
		local accessible, accessibilityReason =
			Accessibility.validate(node.className, node.accessibility)
		if not accessible then
			return false, accessibilityReason
		end
		local responsive, responsiveReason = Responsive.validate(node.responsive)
		if not responsive then
			return false, responsiveReason
		end
		local propertyCount = 0
		for propertyName, value in pairs(node.properties) do
			propertyCount += 1
			local kind = definition.properties[propertyName]
			if not kind then
				return false, Types.FailureType.UnsupportedProperty .. ":" .. propertyName
			end
			if not validateProperty(kind, value) then
				return false, Types.FailureType.InvalidPropertyValue .. ":" .. propertyName
			end
		end
		if
			propertyCount > Types.Limits.maxPropertiesPerNode
			or #node.tags > Types.Limits.maxTagsPerNode
		then
			return false, Types.FailureType.BudgetExceeded
		end
	end
	if not seen[contract.rootNodeId] or seen[contract.rootNodeId].parentNodeId ~= "PlayerGui" then
		return false, Types.FailureType.InvalidHierarchy .. ":root"
	end
	for _, node in ipairs(contract.nodes) do
		if node.nodeId ~= contract.rootNodeId and not seen[node.parentNodeId] then
			return false, Types.FailureType.InvalidReference .. ":parent"
		end
		if node.nodeId ~= contract.rootNodeId then
			local parent = seen[node.parentNodeId]
			local definition = Catalog.get(node.className)
			local parentAllowed = definition.parents[parent.className] == true
				or (definition.parents.GuiObject == true and parent.className ~= "ScreenGui")
			if not parentAllowed then
				return false, Types.FailureType.InvalidHierarchy .. ":class-parent"
			end
		end
		local depth, cursor, visited = 0, node, {}
		while cursor.parentNodeId ~= "PlayerGui" do
			if visited[cursor.nodeId] then
				return false, Types.FailureType.InvalidHierarchy .. ":cycle"
			end
			visited[cursor.nodeId] = true
			depth += 1
			if depth > Types.Limits.maxDepth then
				return false, Types.FailureType.BudgetExceeded .. ":depth"
			end
			cursor = seen[cursor.parentNodeId]
			if not cursor then
				return false, Types.FailureType.InvalidReference .. ":ancestor"
			end
		end
	end
	return true
end

return table.freeze(Validation)
