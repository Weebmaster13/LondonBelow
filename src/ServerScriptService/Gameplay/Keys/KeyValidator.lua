--!strict

local KeyValidator = {}

function KeyValidator.validateDefinition(definition: any): (boolean, string?)
	if type(definition.id) ~= "string" or definition.id == "" then
		return false, "key id is required"
	end
	if type(definition.displayName) ~= "string" or definition.displayName == "" then
		return false, "key display name is required"
	end
	if definition.singleUse == true and definition.reusable == true then
		return false, "key cannot be both single-use and reusable"
	end
	if type(definition.unlocks) ~= "table" then
		return false, "key unlock list is required"
	end
	return true, nil
end

function KeyValidator.validate(): (boolean, string?)
	return true, nil
end

return KeyValidator
