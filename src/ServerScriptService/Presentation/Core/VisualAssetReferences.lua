--!strict

local AssetReferences = {}

function AssetReferences.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "string" or not string.match(value, "^asset%.[%w%.%-_]+$") then
		return false, "invalid asset reference"
	end
	return true, nil
end

return AssetReferences
