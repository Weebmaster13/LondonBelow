--!strict

local Catalog = require(script.Parent.RobloxGuiRenderingCatalog)
local Types = require(script.Parent.RobloxGuiRenderingTypes)

local Validator = {}

function Validator.validate(contract: any): (boolean, string?, { any }?)
	if type(contract) ~= "table" then
		return false, Types.FailureType.InvalidContract
	end
	if contract.schemaVersion ~= Types.SchemaVersion then
		return false, Types.FailureType.UnsupportedSchemaVersion
	end
	if type(contract.contractId) ~= "string" or contract.contractId == "" then
		return false, Types.FailureType.InvalidContract
	end
	if type(contract.targetRevision) ~= "number" or contract.targetRevision < 0 then
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
	for _, node in ipairs(contract.nodes) do
		if type(node.nodeId) ~= "string" or node.nodeId == "" or byId[node.nodeId] then
			return false, Types.FailureType.DuplicateNode
		end
		if type(node.className) ~= "string" or not Catalog.supportsClass(node.className) then
			return false, Types.FailureType.UnsupportedClass
		end
		if type(node.properties) ~= "table" then
			return false, Types.FailureType.InvalidContract
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
