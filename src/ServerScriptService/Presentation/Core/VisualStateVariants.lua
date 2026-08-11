--!strict

local Types = require(script.Parent.PresentationTypes)

local StateVariants = {}

function StateVariants.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "table" then
		return false, "state variants must be a table"
	end
	local count = 0
	for state in pairs(value) do
		count += 1
		if count > Types.VisualCompositionLimits.MaxStateVariantsPerNode then
			return false, "state variant limit exceeded"
		end
		if type(state) ~= "string" or not Types.isVisualNodeState(state) then
			return false, "invalid node state"
		end
	end
	return true, nil
end

return StateVariants
