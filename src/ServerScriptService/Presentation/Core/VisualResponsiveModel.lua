--!strict

local Types = require(script.Parent.PresentationTypes)

local Responsive = {}

function Responsive.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "table" then
		return false, "responsive variants must be a table"
	end
	local count = 0
	for key in pairs(value) do
		count += 1
		if count > Types.VisualCompositionLimits.MaxResponsiveVariants then
			return false, "responsive variant limit exceeded"
		end
		if type(key) ~= "string" or not Types.isVisualResponsiveClass(key) then
			return false, "invalid responsive variant"
		end
	end
	return true, nil
end

return Responsive
