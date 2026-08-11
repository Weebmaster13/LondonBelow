--!strict

local Types = require(script.Parent.PresentationTypes)

local Visibility = {}

function Visibility.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "string" or not Types.isVisualVisibilityState(value) then
		return false, "invalid visibility state"
	end
	return true, nil
end

return Visibility
