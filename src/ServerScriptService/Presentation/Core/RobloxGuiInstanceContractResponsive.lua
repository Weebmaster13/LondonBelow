--!strict

local Responsive = {}
local policies = { Fixed = true, Scale = true, Reflow = true, SafeArea = true, AdaptiveText = true }

function Responsive.validate(metadata: any): (boolean, string?)
	if type(metadata) ~= "table" or not policies[metadata.policy] then
		return false, "UnsupportedResponsivePolicy"
	end
	return true
end

return table.freeze(Responsive)
