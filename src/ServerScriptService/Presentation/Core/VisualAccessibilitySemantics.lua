--!strict

local Accessibility = {}

function Accessibility.validate(value: any): (boolean, string?)
	if value == nil then
		return true, nil
	end
	if type(value) ~= "table" then
		return false, "accessibility metadata must be a table"
	end
	for _, field in ipairs({ "screenReaderToken", "alternateTextToken", "focusIntent" }) do
		local entry = value[field]
		if entry ~= nil and type(entry) ~= "string" then
			return false, "invalid accessibility field " .. field
		end
	end
	return true, nil
end

return Accessibility
