--!strict

local Guard = {}

function Guard.verify(tree: any, activeContract: any, activeValues: any): (boolean, string?)
	if not activeContract then
		return next(activeValues) == nil, next(activeValues) == nil and nil or "OrphanThemeValues"
	end
	if
		not tree
		or tree.contractId ~= activeContract.contractId
		or tree.revision ~= activeContract.targetRevision
	then
		return false, "ThemeTreeRevisionMismatch"
	end
	for key, record in pairs(activeValues) do
		if type(key) ~= "string" or not record.instance or record.instance.Parent == nil then
			return false, "ThemeTargetMissing:" .. tostring(key)
		end
		if record.instance:GetAttribute("LondonEngineContractId") ~= tree.contractId then
			return false, "ThemeOwnershipMismatch:" .. key
		end
		local ok, value = pcall(function()
			return (record.instance :: any)[record.propertyName]
		end)
		if not ok or value ~= record.expected then
			return false, "ThemeValueDrift:" .. key
		end
	end
	return true, nil
end

return Guard
