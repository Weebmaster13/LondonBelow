--!strict

local Accessibility = {}

function Accessibility.validate(className: string, metadata: any): (boolean, string?)
	if type(metadata) ~= "table" then return false, "AccessibilityMetadataRequired" end
	if className == "TextButton" or className == "ImageButton" then
		if type(metadata.label) ~= "string" or metadata.label == "" then return false, "InteractiveLabelRequired" end
		if metadata.focusable ~= true then return false, "InteractiveFocusRequired" end
	end
	return true
end

return table.freeze(Accessibility)
