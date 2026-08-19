--!strict

local Types = require(script.Parent.RobloxGuiInteractionTypes)

local Metadata = {}
local allowed = table.freeze({
	role = true,
	label = true,
	description = true,
	focusable = true,
	actionId = true,
	disabled = true,
	selectionOrder = true,
})

local function optionalText(value: any, limit: number): boolean
	return value == nil or (type(value) == "string" and value ~= "" and #value <= limit)
end

function Metadata.validate(className: string, value: any): (boolean, string?)
	if type(value) ~= "table" then
		return false, Types.FailureType.InvalidAccessibilityMetadata
	end
	for key in pairs(value) do
		if type(key) ~= "string" or not allowed[key] then
			return false, Types.FailureType.InvalidAccessibilityMetadata .. ":unknown-field"
		end
	end
	if not optionalText(value.role, 64) then
		return false, Types.FailureType.InvalidAccessibilityMetadata .. ":role"
	end
	if not optionalText(value.label, Types.Limits.maxLabelLength) then
		return false, Types.FailureType.InvalidAccessibilityMetadata .. ":label"
	end
	if not optionalText(value.description, Types.Limits.maxDescriptionLength) then
		return false, Types.FailureType.InvalidAccessibilityMetadata .. ":description"
	end
	if value.focusable ~= nil and type(value.focusable) ~= "boolean" then
		return false, Types.FailureType.InvalidAccessibilityMetadata .. ":focusable"
	end
	if value.disabled ~= nil and type(value.disabled) ~= "boolean" then
		return false, Types.FailureType.InvalidAccessibilityMetadata .. ":disabled"
	end
	if
		value.selectionOrder ~= nil
		and (type(value.selectionOrder) ~= "number" or value.selectionOrder % 1 ~= 0)
	then
		return false, Types.FailureType.InvalidAccessibilityMetadata .. ":selection-order"
	end
	local interactive = className == "TextButton" or className == "ImageButton"
	if value.actionId ~= nil then
		if not interactive then
			return false, Types.FailureType.NonInteractiveAction
		end
		if
			type(value.actionId) ~= "string"
			or value.actionId == ""
			or #value.actionId > Types.Limits.maxActionIdLength
		then
			return false, Types.FailureType.InvalidActionId
		end
	end
	if interactive and (value.label == nil or value.focusable ~= true) then
		return false, Types.FailureType.InvalidAccessibilityMetadata .. ":interactive-obligations"
	end
	return true
end

function Metadata.describe(value: any): string
	local label = type(value.label) == "string" and value.label or ""
	local description = type(value.description) == "string" and value.description or ""
	if description == "" then
		return label
	end
	return label .. ". " .. description
end

return table.freeze(Metadata)
