--!strict

local Types = require(script.Parent.RobloxGuiResponsiveLocalizationTypes)

local Validator = {}

function Validator.normalize(value: any): (boolean, string?)
	if type(value) ~= "string" or value == "" or #value > Types.Limits.maxLocaleLength then
		return false, nil
	end
	local normalized = string.lower(string.gsub(value, "_", "-"))
	if string.find(normalized, "--", 1, true) then
		return false, nil
	end
	local parts = string.split(normalized, "-")
	if #parts < 1 or #parts > 4 or not string.match(parts[1], "^[a-z][a-z][a-z]?$") then
		return false, nil
	end
	for index = 2, #parts do
		local part = parts[index]
		local valid = string.match(part, "^[a-z][a-z]$")
			or string.match(part, "^[a-z][a-z][a-z][a-z]$")
			or string.match(part, "^%d%d%d$")
			or (#part >= 5 and #part <= 8 and string.match(part, "^[a-z0-9]+$"))
		if not valid then
			return false, nil
		end
	end
	return true, normalized
end

function Validator.language(locale: string): string
	return string.match(locale, "^([a-z]+)") or locale
end

return table.freeze(Validator)
