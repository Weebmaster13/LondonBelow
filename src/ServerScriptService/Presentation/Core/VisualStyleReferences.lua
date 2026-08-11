--!strict

local References = {}

function References.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "string" or not string.match(value, "^[%w%.%-_]+$") then
		return false, "invalid style reference"
	end
	return true, nil
end

return References
