--!strict
--[[
	Complete foundation Director hierarchy for London Engine.
]]

local FoundationDirector = require(script.Parent.FoundationDirector)
local Types = require(script.Parent.DirectorTypes)

local DirectorRegistry = {}

type DirectorDescription = Types.DirectorDescription

local descriptions: { DirectorDescription } = {
	{
		name = "PsychologicalHorror",
		displayName = "Psychological Horror Director",
		responsibilities = { "fear pacing", "tension interpretation", "silence pressure" },
		doesNotOwn = { "monster movement", "final audio playback", "chapter climax" },
		priority = 80,
		capabilities = {
			{
				id = "Horror.Tension",
				description = "Interpret tension and fear pressure.",
				requestKinds = { "RequestHorrorPressure" },
			},
			{
				id = "Horror.Silence",
				description = "Approve silence as pressure.",
				requestKinds = { "RequestSilence" },
			},
		},
	},
	{
		name = "Narrative",
		displayName = "Narrative Director",
		responsibilities = { "dramatic beat gates", "chapter phase interpretation" },
		doesNotOwn = { "lore content", "monster movement", "physical execution" },
		priority = 95,
		capabilities = {
			{
				id = "Narrative.Beat",
				description = "Gate reveals by intended narrative beat.",
				requestKinds = { "RequestNarrativeBeat" },
			},
			{
				id = "Narrative.Climax",
				description = "Declare future climax readiness.",
				requestKinds = { "RequestClimaxReadiness" },
			},
		},
	},
	{
		name = "Story",
		displayName = "Story Director",
		responsibilities = { "lore timing", "dialogue permission", "story clarity" },
		doesNotOwn = { "puzzle validation", "cutscene execution", "UI rendering" },
		priority = 75,
		capabilities = {
			{
				id = "Story.Lore",
				description = "Approve lore and note timing.",
				requestKinds = { "RequestLoreTrigger" },
			},
		},
	},
	{
		name = "Environment",
		displayName = "Environment Director",
		responsibilities = { "world reaction permissions", "fog and building reaction requests" },
		doesNotOwn = { "lighting values", "audio playback", "scare selection" },
		priority = 70,
		capabilities = {
			{
				id = "Environment.Fog",
				description = "Request fog and world reactions.",
				requestKinds = { "RequestEnvironmentReaction" },
			},
		},
	},
	{
		name = "Lighting",
		displayName = "Lighting Director",
		responsibilities = { "visibility pressure", "lighting change permissions" },
		doesNotOwn = { "monster attacks", "story beats", "final client rendering" },
		priority = 65,
		capabilities = {
			{
				id = "Lighting.Brightness",
				description = "Request brightness or darkness pressure.",
				requestKinds = { "RequestLightingChange" },
			},
			{
				id = "Lighting.Flicker",
				description = "Request future flicker pressure.",
				requestKinds = { "RequestLightFlicker" },
			},
		},
	},
	{
		name = "Audio",
		displayName = "Audio Director",
		responsibilities = { "sound pressure", "audio deception permissions" },
		doesNotOwn = { "music score", "monster movement", "client fear truth" },
		priority = 65,
		capabilities = {
			{
				id = "Audio.Whispers",
				description = "Request future whisper pressure.",
				requestKinds = { "RequestAudioCue" },
			},
			{
				id = "Audio.Footsteps",
				description = "Request future footsteps.",
				requestKinds = { "RequestAudioCue" },
			},
		},
	},
	{
		name = "Music",
		displayName = "Music Director",
		responsibilities = { "music state permissions", "silence as score" },
		doesNotOwn = { "audio deception", "chase truth", "monster attacks" },
		priority = 55,
		capabilities = {
			{
				id = "Music.State",
				description = "Request future music state.",
				requestKinds = { "RequestMusicState" },
			},
		},
	},
	{
		name = "Monster",
		displayName = "Monster Director",
		responsibilities = { "monster reveal permission", "stalk and retreat permissions" },
		doesNotOwn = { "pathfinding", "animation state", "horror pacing ownership" },
		priority = 85,
		capabilities = {
			{
				id = "Monster.Reveal",
				description = "Request monster reveal permission.",
				requestKinds = { "RequestMonsterReveal" },
			},
			{
				id = "Monster.Attack",
				description = "Request future attack permission.",
				requestKinds = { "RequestMonsterAttack" },
			},
		},
	},
	{
		name = "Puzzle",
		displayName = "Puzzle Director",
		responsibilities = { "puzzle fairness", "hint pacing permission" },
		doesNotOwn = { "inventory truth", "door animation", "monster movement" },
		priority = 60,
		capabilities = {
			{
				id = "Puzzle.Hint",
				description = "Request future hint permission.",
				requestKinds = { "RequestPuzzleHint" },
			},
		},
	},
	{
		name = "Save",
		displayName = "Save Director",
		responsibilities = { "checkpoint policy", "save safety permissions" },
		doesNotOwn = { "DataStore implementation alone", "objective truth", "UI" },
		priority = 90,
		capabilities = {
			{
				id = "Save.Checkpoint",
				description = "Request checkpoint permission.",
				requestKinds = { "RequestCheckpoint" },
			},
		},
	},
	{
		name = "Difficulty",
		displayName = "Difficulty Director",
		responsibilities = { "adaptive tuning recommendations", "frustration safety rails" },
		doesNotOwn = { "client cheats", "puzzle answers", "save truth" },
		priority = 50,
		capabilities = {
			{
				id = "Difficulty.Adjustment",
				description = "Request difficulty recommendation.",
				requestKinds = { "RequestDifficultyAdjustment" },
			},
		},
	},
	{
		name = "Performance",
		displayName = "Performance Director",
		responsibilities = { "budget protection", "throttle recommendations" },
		doesNotOwn = { "creative pacing", "story truth", "gameplay validation" },
		priority = 100,
		capabilities = {
			{
				id = "Performance.Budget",
				description = "Request performance budget decision.",
				requestKinds = { "RequestPerformanceBudget" },
			},
		},
	},
}

function DirectorRegistry.createAll(): { Types.Director }
	local directors = {}

	for _, description in ipairs(descriptions) do
		table.insert(directors, FoundationDirector.new(description))
	end

	return directors
end

function DirectorRegistry.descriptions(): { DirectorDescription }
	local copied = {}

	for _, description in ipairs(descriptions) do
		table.insert(copied, {
			name = description.name,
			displayName = description.displayName,
			responsibilities = table.clone(description.responsibilities),
			doesNotOwn = table.clone(description.doesNotOwn),
			capabilities = description.capabilities,
			priority = description.priority,
		})
	end

	return copied
end

return DirectorRegistry
