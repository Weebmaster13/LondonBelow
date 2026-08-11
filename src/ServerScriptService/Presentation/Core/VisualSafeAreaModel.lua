--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local VisualSafeAreaModel = {}

function VisualSafeAreaModel.normalize(value: any)
	return Serialization.deepCopy(value or {
		display = "Default",
		hud = "Default",
		subtitle = "Default",
		touch = "Default",
	})
end

function VisualSafeAreaModel.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "table" then
		return false, "safe area metadata must be a table"
	end
	return true, nil
end

return VisualSafeAreaModel
