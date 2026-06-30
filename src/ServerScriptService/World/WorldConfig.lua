--!strict
--[[
	Conservative defaults for World Intelligence contracts.

	Defaults are intentionally safe: unknown zones do not allow monsters,
	chases, major interruptions, blackouts, or final scares. Future chapter
	authors must explicitly opt a zone into higher-pressure behavior.
]]

local WorldConfig = {}

WorldConfig.DefaultZoneId = "unknown"
WorldConfig.DefaultZoneKind = "Unknown"
WorldConfig.DefaultAtmosphereProfileId = "Unknown"
WorldConfig.DefaultRoomPersonalityId = "Unknown"
WorldConfig.MaxProfiles = 512
WorldConfig.MaxRecentContexts = 80

WorldConfig.DefaultLightingPolicy = {
	minBrightness = 0.35,
	maxBrightness = 1,
	allowsBlackout = false,
	allowsFlicker = false,
	allowsDirectionalMislead = false,
}

WorldConfig.DefaultAudioPolicy = {
	allowsWhispers = false,
	allowsFakeSounds = false,
	allowsHeartbeat = false,
	allowsBreathing = false,
	allowsSilenceDrop = false,
	allowedSoundTags = {},
}

WorldConfig.DefaultMonsterPolicy = {
	allowsMainMonsterPresence = false,
	allowsMainMonsterReveal = false,
	allowsCrawlerPresence = false,
	allowsChaseStart = false,
	allowsChaseContinuation = false,
	requiresDirectorApproval = true,
}

WorldConfig.DefaultPuzzleProtection = {
	protectsActivePuzzle = false,
	allowsSubtlePressure = true,
	allowsMajorInterruptions = false,
	reason = "Default world profile prevents unfair pressure unless a zone opts in.",
}

return WorldConfig
