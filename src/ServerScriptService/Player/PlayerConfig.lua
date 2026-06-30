--!strict
--[[
	Server player runtime tuning.

	This module contains safe defaults and future hook identifiers. It does not
	contain chapter-specific movement, injury, fear, or stamina rules.
]]

local PlayerConfig = {}

PlayerConfig.DefaultStamina = 100
PlayerConfig.DefaultFear = 0
PlayerConfig.DefaultInjury = 0
PlayerConfig.MovementObservationThrottleSeconds = 0.75
PlayerConfig.StateSnapshotLimit = 64

PlayerConfig.LockReasons = {
	Interaction = "Interaction",
	Cinematic = "Cinematic",
	Menu = "Menu",
	ChapterTransition = "ChapterTransition",
}

return PlayerConfig
