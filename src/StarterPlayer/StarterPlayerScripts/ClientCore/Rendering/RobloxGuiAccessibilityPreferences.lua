--!strict

local Preferences = {}
local allowed = table.freeze({
	autoFocusMode = true,
	announceFocus = true,
	announceDisabled = true,
	announceLiveRegions = true,
})
local modes = table.freeze({ Always = true, PreserveOnly = true, Never = true })
local current = table.freeze({
	autoFocusMode = "Always",
	announceFocus = true,
	announceDisabled = true,
	announceLiveRegions = true,
})

local function choose(value: any, fallback: any): any
	if value == nil then
		return fallback
	end
	return value
end

function Preferences.validate(value: any): (boolean, string?)
	if type(value) ~= "table" then
		return false, "preferences-not-table"
	end
	for key in pairs(value) do
		if type(key) ~= "string" or not allowed[key] then
			return false, "unknown-preference"
		end
	end
	if
		value.autoFocusMode ~= nil
		and (type(value.autoFocusMode) ~= "string" or not modes[value.autoFocusMode])
	then
		return false, "invalid-autofocus-mode"
	end
	if value.announceFocus ~= nil and type(value.announceFocus) ~= "boolean" then
		return false, "invalid-announce-focus"
	end
	if value.announceDisabled ~= nil and type(value.announceDisabled) ~= "boolean" then
		return false, "invalid-announce-disabled"
	end
	if value.announceLiveRegions ~= nil and type(value.announceLiveRegions) ~= "boolean" then
		return false, "invalid-announce-live-regions"
	end
	return true
end

function Preferences.set(value: any): (boolean, string?)
	local valid, reason = Preferences.validate(value)
	if not valid then
		return false, reason
	end
	current = table.freeze({
		autoFocusMode = value.autoFocusMode or current.autoFocusMode,
		announceFocus = choose(value.announceFocus, current.announceFocus),
		announceDisabled = choose(value.announceDisabled, current.announceDisabled),
		announceLiveRegions = choose(value.announceLiveRegions, current.announceLiveRegions),
	})
	return true
end

function Preferences.get()
	return current
end

function Preferences.reset()
	current = table.freeze({
		autoFocusMode = "Always",
		announceFocus = true,
		announceDisabled = true,
		announceLiveRegions = true,
	})
end

return Preferences
