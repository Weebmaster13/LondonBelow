--!strict

local Typography = {}

function Typography.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "string" or not string.match(value, "^type%.[%w%.%-_]+$") then
		return false, "invalid typography reference"
	end
	return true, nil
end

return Typography
