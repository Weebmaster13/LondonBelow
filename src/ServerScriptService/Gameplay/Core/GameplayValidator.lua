--!strict

local GameplayValidator = {}

function GameplayValidator.validateDependencyIds(
	ids: { string },
	exists: (string) -> boolean
): (boolean, string?)
	local seen = {}
	for _, id in ipairs(ids) do
		if type(id) ~= "string" or id == "" then
			return false, "dependency ids must be non-empty strings"
		end
		if seen[id] then
			return false, "duplicate dependency id"
		end
		seen[id] = true
		if not exists(id) then
			return false, "missing dependency: " .. id
		end
	end
	return true, nil
end

function GameplayValidator.validate(): (boolean, string?)
	return true, nil
end

return GameplayValidator
