--!strict
--[[
	Scare metadata registry.

	Owns structured definitions for possible scare opportunities: category,
	intensity, cooldowns, phase gates, tags, requirements, and repeat limits.

	Does not own scare execution, client presentation, Monster AI, chapter
	geometry, or audio/visual assets. These entries are hook definitions only.

	Future systems should add metadata here before implementing presentation so
	the Director can reason about pacing and fairness first.

	Edge case: requirements may intentionally block future systems, such as
	MonsterOpportunity or MajorClimax, until those systems exist.
]]

local Types = require(script.Parent.HorrorDirectorTypes)

local ScareRegistry = {}

type ScareDefinition = Types.ScareDefinition

local validCategories = {
	Ambient = true,
	Psychological = true,
	Visual = true,
	Audio = true,
	Environmental = true,
	MonsterOpportunity = true,
	MajorClimax = true,
}

local validTensionStates = {
	Calm = true,
	Uneasy = true,
	Tense = true,
	Dread = true,
	Panic = true,
	Release = true,
}

local validChapterPhases = {
	Lobby = true,
	Opening = true,
	Exploration = true,
	Puzzle = true,
	Threat = true,
	Climax = true,
	Escape = true,
}

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

local function copyArray(values: { string }): { string }
	local copied = {}

	for _, value in ipairs(values) do
		table.insert(copied, value)
	end

	return copied
end

local function copyScare(scare: ScareDefinition): ScareDefinition
	return {
		id = scare.id,
		displayName = scare.displayName,
		category = scare.category,
		intensity = scare.intensity,
		baseWeight = scare.baseWeight,
		cooldownSeconds = scare.cooldownSeconds,
		categoryCooldownSeconds = scare.categoryCooldownSeconds,
		maxRepeats = scare.maxRepeats,
		supportsSolo = scare.supportsSolo,
		supportsGroup = scare.supportsGroup,
		allowedTension = copyArray(scare.allowedTension),
		allowedPhases = copyArray(scare.allowedPhases),
		tags = copyArray(scare.tags),
		requirements = copyArray(scare.requirements),
	}
end

function ScareRegistry.getAll(): { ScareDefinition }
	local copied = {}

	for _, scare in ipairs(scares) do
		table.insert(copied, copyScare(scare))
	end

	return copied
end

function ScareRegistry.findById(scareId: string): ScareDefinition?
	for _, scare in ipairs(scares) do
		if scare.id == scareId then
			return copyScare(scare)
		end
	end

	return nil
end

function ScareRegistry.validate(): (boolean, string?)
	local ids = {}

	for _, scare in ipairs(scares) do
		if scare.id == "" then
			return false, "Scare id cannot be empty"
		end

		if ids[scare.id] then
			return false, "Duplicate scare id: " .. scare.id
		end

		if scare.displayName == "" then
			return false, "Scare display name cannot be empty: " .. scare.id
		end

		if not validCategories[scare.category] then
			return false, "Invalid scare category: " .. scare.id
		end

		if scare.intensity < 0 or scare.intensity > 100 then
			return false, "Scare intensity out of range: " .. scare.id
		end

		if scare.baseWeight < 0 then
			return false, "Scare base weight cannot be negative: " .. scare.id
		end

		if scare.cooldownSeconds < 0 or scare.categoryCooldownSeconds < 0 then
			return false, "Scare cooldown cannot be negative: " .. scare.id
		end

		if scare.maxRepeats < 0 then
			return false, "Scare maxRepeats cannot be negative: " .. scare.id
		end

		if #scare.allowedTension == 0 then
			return false, "Scare must allow at least one tension state: " .. scare.id
		end

		for _, tensionState in ipairs(scare.allowedTension) do
			if not validTensionStates[tensionState] then
				return false, "Scare has invalid tension state: " .. scare.id
			end
		end

		if #scare.allowedPhases == 0 then
			return false, "Scare must allow at least one chapter phase: " .. scare.id
		end

		for _, phase in ipairs(scare.allowedPhases) do
			if not validChapterPhases[phase] then
				return false, "Scare has invalid chapter phase: " .. scare.id
			end
		end

		ids[scare.id] = true
	end

	return true, nil
end

return ScareRegistry
