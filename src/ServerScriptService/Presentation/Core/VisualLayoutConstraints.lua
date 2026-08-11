--!strict

local Constraints = {}

local function nonNegative(value: any): boolean
	return value == nil or (type(value) == "number" and value >= 0)
end

function Constraints.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "table" then
		return false, "constraints must be a table"
	end
	if not nonNegative(value.minimumWidth) or not nonNegative(value.maximumWidth) then
		return false, "invalid width constraint"
	end
	if not nonNegative(value.minimumHeight) or not nonNegative(value.maximumHeight) then
		return false, "invalid height constraint"
	end
	if
		value.minimumWidth ~= nil
		and value.maximumWidth ~= nil
		and value.minimumWidth > value.maximumWidth
	then
		return false, "minimum width cannot exceed maximum width"
	end
	if
		value.minimumHeight ~= nil
		and value.maximumHeight ~= nil
		and value.minimumHeight > value.maximumHeight
	then
		return false, "minimum height cannot exceed maximum height"
	end
	if
		value.aspectRatio ~= nil and (type(value.aspectRatio) ~= "number" or value.aspectRatio <= 0)
	then
		return false, "invalid aspect ratio"
	end
	return true, nil
end

return Constraints
