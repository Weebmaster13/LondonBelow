--!strict

local Localization = {}

function Localization.validate(slot: any, token: any): (boolean, string?)
	if slot ~= nil and (type(slot) ~= "string" or not string.match(slot, "^[%w%.%-_]+$")) then
		return false, "invalid localization slot"
	end
	if token ~= nil and (type(token) ~= "string" or not string.match(token, "^[%w%.%-_]+$")) then
		return false, "invalid localization token"
	end
	return true, nil
end

return Localization
