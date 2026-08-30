--!strict

local Types = require(script.Parent.RobloxGuiThemeTypes)
local Validator = {}

function Validator.validate(contract: any, theme: any, tree: any): (boolean, string?, { any }?)
	if type(contract) ~= "table" or contract.schemaVersion ~= Types.SchemaVersion then return false, Types.FailureType.InvalidContract end
	if contract.themeId ~= theme.themeId or contract.themeRevision ~= theme.revision then return false, Types.FailureType.InvalidRevision end
	if contract.targetRevision ~= tree.revision or contract.contractId ~= tree.contractId then return false, Types.FailureType.InvalidRevision end
	if type(contract.nodes) ~= "table" or #contract.nodes > Types.Limits.maxNodeStyles then return false, Types.FailureType.BudgetExceeded end
	local seen = {}; local ordered = {}
	for _, node in ipairs(contract.nodes) do
		if type(node) ~= "table" or type(node.nodeId) ~= "string" or seen[node.nodeId] or type(node.styles) ~= "table" then return false, Types.FailureType.InvalidContract end
		seen[node.nodeId] = true
		local instance = tree.instances and tree.instances[node.nodeId]
		if not instance or instance:GetAttribute("LondonEngineContractId") ~= tree.contractId then return false, Types.FailureType.InvalidTarget end
		local styles = {}; local propertyCount = 0
		for propertyName, tokenName in pairs(node.styles) do
			local expected = Types.AllowedProperties[propertyName]
			if not expected then return false, Types.FailureType.UnsupportedProperty end
			local value = theme.tokens[tokenName]
			if value == nil or typeof(value) ~= expected then return false, Types.FailureType.InvalidToken end
			propertyCount += 1; if propertyCount > Types.Limits.maxPropertiesPerNode then return false, Types.FailureType.BudgetExceeded end
			styles[propertyName] = value
		end
		ordered[#ordered + 1] = { nodeId = node.nodeId, instance = instance, styles = styles }
	end
	table.sort(ordered, function(a, b) return a.nodeId < b.nodeId end)
	return true, nil, ordered
end

return Validator
