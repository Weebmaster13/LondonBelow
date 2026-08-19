--!strict

local AccessibilityMetadata = require(script.Parent.RobloxGuiAccessibilityMetadata)
local Catalog = require(script.Parent.RobloxGuiRenderingCatalog)
local InteractionTypes = require(script.Parent.RobloxGuiInteractionTypes)
local Types = require(script.Parent.RobloxGuiRenderingTypes)

local Validator = {}

local contractFields = table.freeze({
	schemaVersion = true,
	contractId = true,
	targetRevision = true,
	rootNodeId = true,
	nodes = true,
})
local nodeFields = table.freeze({
	nodeId = true,
	className = true,
	parentNodeId = true,
	properties = true,
	accessibility = true,
	responsive = true,
	tags = true,
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

local function validMetadata(node: any): boolean
	if node.accessibility ~= nil and type(node.accessibility) ~= "table" then
		return false
	end
	if node.responsive ~= nil and type(node.responsive) ~= "table" then
		return false
	end
	if node.tags ~= nil then
		if type(node.tags) ~= "table" or #node.tags > Types.Limits.maxTagsPerNode then
			return false
		end
		local seen = {}
		for _, tag in ipairs(node.tags) do
			if
				type(tag) ~= "string"
				or tag == ""
				or #tag > Types.Limits.maxTagLength
				or seen[tag]
			then
				return false
			end
			seen[tag] = true
		end
	end
	return true
end

local function measure(value: any, seen: { [any]: boolean }): (number, boolean)
	local valueType = type(value)
	if valueType == "string" then
		return #value, true
	elseif valueType ~= "table" then
		return 16, true
	elseif seen[value] then
		return 0, false
	end
	seen[value] = true
	local size = 2
	for key, child in pairs(value) do
		local keySize, keyOk = measure(key, seen)
		local childSize, childOk = measure(child, seen)
		if not keyOk or not childOk then
			return size, false
		end
		size += keySize + childSize
		if size > Types.Limits.maxContractBytes then
			return size, false
		end
	end
	seen[value] = nil
	return size, true
end

function Validator.validate(contract: any): (boolean, string?, { any }?)
	if type(contract) ~= "table" then
		return false, Types.FailureType.InvalidContract
	end
	if not exactFields(contract, contractFields) then
		return false, Types.FailureType.InvalidContract
	end
	local _, sizeOk = measure(contract, {})
	if not sizeOk then
		return false, Types.FailureType.ContractTooLarge
	end
	if contract.schemaVersion ~= Types.SchemaVersion then
		return false, Types.FailureType.UnsupportedSchemaVersion
	end
	if not validText(contract.contractId) then
		return false, Types.FailureType.InvalidContract
	end
	if
		type(contract.targetRevision) ~= "number"
		or contract.targetRevision < 0
		or contract.targetRevision % 1 ~= 0
	then
		return false, Types.FailureType.InvalidContract
	end
	if
		type(contract.nodes) ~= "table"
		or #contract.nodes == 0
		or #contract.nodes > Types.Limits.maxNodes
	then
		return false, Types.FailureType.BudgetExceeded
	end
	local byId = {}
	local focusableCount = 0
	for _, node in ipairs(contract.nodes) do
		if type(node) ~= "table" or not exactFields(node, nodeFields) then
			return false, Types.FailureType.InvalidContract
		end
		if not validText(node.nodeId) or byId[node.nodeId] then
			return false, Types.FailureType.DuplicateNode
		end
		if type(node.className) ~= "string" or not Catalog.supportsClass(node.className) then
			return false, Types.FailureType.UnsupportedClass
		end
		if type(node.properties) ~= "table" then
			return false, Types.FailureType.InvalidContract
		end
		if not validText(node.parentNodeId) or not validMetadata(node) then
			return false, Types.FailureType.InvalidMetadata
		end
		local accessible, accessibilityReason =
			AccessibilityMetadata.validate(node.className, node.accessibility or {})
		if not accessible then
			return false, accessibilityReason or Types.FailureType.InvalidMetadata
		end
		if type(node.accessibility) == "table" and node.accessibility.focusable == true then
			focusableCount += 1
			if focusableCount > InteractionTypes.Limits.maxControls then
				return false, Types.FailureType.BudgetExceeded
			end
		end
		local propertyCount = 0
		for propertyName in pairs(node.properties) do
			propertyCount += 1
			if not Catalog.supportsProperty(node.className, propertyName) then
				return false, Types.FailureType.UnsupportedProperty .. ":" .. propertyName
			end
		end
		if propertyCount > Types.Limits.maxPropertiesPerNode then
			return false, Types.FailureType.BudgetExceeded
		end
		byId[node.nodeId] = node
	end
	local root = byId[contract.rootNodeId]
	if not root or root.className ~= "ScreenGui" or root.parentNodeId ~= "PlayerGui" then
		return false, Types.FailureType.InvalidContract
	end
	for _, node in ipairs(contract.nodes) do
		if node.nodeId ~= contract.rootNodeId and node.parentNodeId == "PlayerGui" then
			return false, Types.FailureType.OwnershipViolation
		end
		if node.nodeId ~= contract.rootNodeId and byId[node.parentNodeId] == nil then
			return false, Types.FailureType.MissingParent
		end
	end
	local ordered = {}
	local resolved = {}
	while #ordered < #contract.nodes do
		local progressed = false
		for _, node in ipairs(contract.nodes) do
			if
				not resolved[node.nodeId]
				and (node.parentNodeId == "PlayerGui" or resolved[node.parentNodeId])
			then
				resolved[node.nodeId] = true
				ordered[#ordered + 1] = node
				progressed = true
			end
		end
		if not progressed then
			return false, Types.FailureType.HierarchyCycle
		end
	end
	local depths = {}
	for _, node in ipairs(ordered) do
		local depth = node.parentNodeId == "PlayerGui" and 0 or (depths[node.parentNodeId] or 0) + 1
		if depth > Types.Limits.maxDepth then
			return false, Types.FailureType.BudgetExceeded
		end
		depths[node.nodeId] = depth
	end
	return true, nil, ordered
end

return table.freeze(Validator)
