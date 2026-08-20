--!strict

local Types = require(script.Parent.RobloxGuiResponsiveLocalizationTypes)

local Formatter = {}

function Formatter.format(template: any, arguments: any): (boolean, string?, string?)
	if type(template) ~= "string" or #template > Types.Limits.maxTextLength then
		return false, nil, Types.FailureType.MalformedTemplate
	end
	local stripped = string.gsub(template, "{[%w_]+}", "")
	if string.find(stripped, "{", 1, true) or string.find(stripped, "}", 1, true) then
		return false, nil, Types.FailureType.MalformedTemplate
	end
	local seen = 0
	local invalid = false
	local output = string.gsub(template, "{([%w_]+)}", function(name)
		seen += 1
		if
			seen > Types.Limits.maxPlaceholders
			or type(arguments) ~= "table"
			or arguments[name] == nil
		then
			invalid = true
			return ""
		end
		local value = arguments[name]
		if type(value) ~= "string" and type(value) ~= "number" then
			invalid = true
			return ""
		end
		return tostring(value)
	end)
	if invalid or #output > Types.Limits.maxTextLength then
		return false, nil, Types.FailureType.InvalidPlaceholder
	end
	return true, output, nil
end

return table.freeze(Formatter)
