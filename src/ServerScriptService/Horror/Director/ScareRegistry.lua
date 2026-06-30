--!strict
-- Scare metadata registry. These are hook definitions, not final scare scripts.

local Types = require(script.Parent.HorrorDirectorTypes)

local ScareRegistry = {}

type ScareDefinition = Types.ScareDefinition

local scares: { ScareDefinition } = {
	{
		id = "ambient_london_bells",
		displayName = "Distant London Bells",
		category = "Ambient",
		intensity = 12,
		baseWeight = 0.9,
		cooldownSeconds = 45,
		categoryCooldownSeconds = 35,
		maxRepeats = 4,
		supportsSolo = true,
		supportsGroup = true,
		allowedTension = { "Calm", "Uneasy", "Release" },
		allowedPhases = { "Opening", "Exploration", "Puzzle" },
		tags = { "sound", "distance", "victorian" },
		requirements = {},
	},
	{
		id = "psych_fake_footsteps",
		displayName = "Fake Footsteps",
		category = "Psychological",
		intensity = 28,
		baseWeight = 1.1,
		cooldownSeconds = 70,
		categoryCooldownSeconds = 45,
		maxRepeats = 3,
		supportsSolo = true,
		supportsGroup = false,
		allowedTension = { "Uneasy", "Tense", "Dread" },
		allowedPhases = { "Exploration", "Puzzle", "Threat" },
		tags = { "footsteps", "deception", "behind" },
		requirements = { "isolatedOrCautious" },
	},
	{
		id = "visual_window_figure",
		displayName = "Window Figure",
		category = "Visual",
		intensity = 35,
		baseWeight = 0.95,
		cooldownSeconds = 95,
		categoryCooldownSeconds = 60,
		maxRepeats = 2,
		supportsSolo = true,
		supportsGroup = true,
		allowedTension = { "Uneasy", "Tense", "Dread" },
		allowedPhases = { "Exploration", "Puzzle" },
		tags = { "sightline", "figure", "misdirection" },
		requirements = { "notOverwhelmed" },
	},
	{
		id = "audio_breathing_nearby",
		displayName = "Nearby Breathing",
		category = "Audio",
		intensity = 42,
		baseWeight = 1,
		cooldownSeconds = 100,
		categoryCooldownSeconds = 60,
		maxRepeats = 2,
		supportsSolo = true,
		supportsGroup = false,
		allowedTension = { "Tense", "Dread" },
		allowedPhases = { "Exploration", "Threat" },
		tags = { "breathing", "close", "intimate" },
		requirements = { "darknessOrHiding" },
	},
	{
		id = "environment_lantern_flicker",
		displayName = "Lantern Flicker",
		category = "Environmental",
		intensity = 25,
		baseWeight = 1.2,
		cooldownSeconds = 55,
		categoryCooldownSeconds = 40,
		maxRepeats = 4,
		supportsSolo = true,
		supportsGroup = true,
		allowedTension = { "Uneasy", "Tense", "Dread" },
		allowedPhases = { "Exploration", "Puzzle", "Threat" },
		tags = { "lantern", "light", "uncertainty" },
		requirements = { "lanternDependent" },
	},
	{
		id = "monster_opportunity_watch",
		displayName = "Future Monster Watch Opportunity",
		category = "MonsterOpportunity",
		intensity = 50,
		baseWeight = 0.75,
		cooldownSeconds = 140,
		categoryCooldownSeconds = 90,
		maxRepeats = 2,
		supportsSolo = true,
		supportsGroup = true,
		allowedTension = { "Tense", "Dread" },
		allowedPhases = { "Threat", "Climax" },
		tags = { "future-monster", "watch", "no-chase" },
		requirements = { "futureMonsterSystem" },
	},
	{
		id = "major_carriage_panic",
		displayName = "Future Carriage Panic",
		category = "MajorClimax",
		intensity = 85,
		baseWeight = 0.25,
		cooldownSeconds = 300,
		categoryCooldownSeconds = 240,
		maxRepeats = 1,
		supportsSolo = true,
		supportsGroup = true,
		allowedTension = { "Dread", "Panic" },
		allowedPhases = { "Climax", "Escape" },
		tags = { "major", "transition", "carriage" },
		requirements = { "chapterClimax" },
	},
}

function ScareRegistry.getAll(): { ScareDefinition }
	return scares
end

function ScareRegistry.findById(scareId: string): ScareDefinition?
	for _, scare in ipairs(scares) do
		if scare.id == scareId then
			return scare
		end
	end

	return nil
end

function ScareRegistry.validate(): (boolean, string?)
	local ids = {}

	for _, scare in ipairs(scares) do
		if ids[scare.id] then
			return false, "Duplicate scare id: " .. scare.id
		end

		if scare.intensity < 0 or scare.intensity > 100 then
			return false, "Scare intensity out of range: " .. scare.id
		end

		ids[scare.id] = true
	end

	return true, nil
end

return ScareRegistry
