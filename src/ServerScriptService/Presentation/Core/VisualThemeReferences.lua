--!strict

local Theme = {}

function Theme.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "string" or not string.match(value, "^theme%.[%w%.%-_]+$") then
		return false, "invalid theme reference"
	end
	return true, nil
end

return Theme
