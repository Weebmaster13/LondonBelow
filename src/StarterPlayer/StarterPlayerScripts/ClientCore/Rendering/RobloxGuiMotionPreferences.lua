--!strict

local Types = require(script.Parent.RobloxGuiAnimationTypes)

local Preferences = {}
local current = Types.MotionPreference.Full

function Preferences.set(value: any): (boolean, string?)
	if type(value) ~= "string" or (Types.MotionPreference :: any)[value] == nil then return false, Types.FailureType.InvalidMotionPreference end
	current = value
	return true
end

function Preferences.get(): string
	return current
end

function Preferences.reset()
	current = Types.MotionPreference.Full
end

return Preferences
