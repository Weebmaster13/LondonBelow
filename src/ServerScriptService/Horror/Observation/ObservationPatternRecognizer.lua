--!strict
--[[
	Pattern and personality recognition for Observation Engine.

	Owns translating repeated observations into behavior patterns and evolving
	multi-trait personality confidence scores.

	Does not own scare execution, Monster AI, final fear math, or permanent
	player profiling. Personality is run-local and decays over time.
]]

local ObservationConfig = require(script.Parent.ObservationConfig)
local Types = require(script.Parent.ObservationTypes)

local ObservationPatternRecognizer = {}

type Observation = Types.Observation
type Pattern = Types.Pattern
type PersonalitySnapshot = Types.PersonalitySnapshot

local countsByPlayer: { [number]: { [string]: number } } = {}
local patterns: { Pattern } = {}
local personalities: { [number]: PersonalitySnapshot } = {}

local traitWeights = {
	["Exploration.NewArea"] = { Explorer = 0.08, Curious = 0.05 },
	["Interaction.ReadNote"] = { Investigator = 0.08, Methodical = 0.04 },
	["Camera.LookAtPortrait"] = { Observer = 0.07, Curious = 0.04 },
	["Camera.LookAtWindow"] = { Observer = 0.08, Paranoid = 0.03 },
	["Camera.LookBehind"] = { Paranoid = 0.08, Survivor = 0.03 },
	["Social.PartySeparated"] = { LoneWolf = 0.07, RiskTaker = 0.03 },
	["Social.Regrouped"] = { Follower = 0.06, Patient = 0.03 },
	["Movement.StartSprint"] = { Impulsive = 0.06, RiskTaker = 0.04 },
	["Movement.Walk"] = { Patient = 0.03, Methodical = 0.03 },
	["Interaction.DoorHesitation"] = { Reserved = 0.06, Fearful = 0.04 },
	["Environment.EnterDarkness"] = { RiskTaker = 0.05, Adaptive = 0.03 },
	["Lantern.On"] = { Survivor = 0.04, Methodical = 0.03 },
	["Puzzle.Progress"] = { Persistent = 0.05, Investigator = 0.04 },
	["Puzzle.Fail"] = { Persistent = 0.04, Adaptive = 0.03 },
}

local function getCounts(userId: number): { [string]: number }
	local counts = countsByPlayer[userId]

	if counts == nil then
		counts = {}
		countsByPlayer[userId] = counts
	end

	return counts
end

local function getPersonality(userId: number, currentTime: number): PersonalitySnapshot
	local snapshot = personalities[userId]

	if snapshot == nil then
		snapshot = {
			userId = userId,
			traits = {},
			updatedAt = currentTime,
		}
		personalities[userId] = snapshot
	end

	local elapsedMinutes = math.max(0, currentTime - snapshot.updatedAt) / 60
	local decay = elapsedMinutes * ObservationConfig.PersonalityDecayPerMinute

	for trait, confidence in pairs(snapshot.traits) do
		snapshot.traits[trait] = math.max(0, confidence - decay)
	end

	snapshot.updatedAt = currentTime

	return snapshot
end

local function addPattern(pattern: Pattern): Pattern
	table.insert(patterns, pattern)

	while #patterns > ObservationConfig.PatternLimit do
		table.remove(patterns, 1)
	end

	return pattern
end

local function applyTraits(observation: Observation)
	if observation.userId == nil then
		return
	end

	local weights = traitWeights[observation.id]

	if weights == nil then
		return
	end

	local personality = getPersonality(observation.userId, observation.at)

	for trait, amount in pairs(weights) do
		personality.traits[trait] = math.clamp((personality.traits[trait] or 0) + amount, 0, 1)
	end
end

local function recognizeCountPattern(
	observation: Observation,
	counts: { [string]: number },
	observationId: string,
	threshold: number,
	patternId: string,
	description: string
): Pattern?
	if observation.id ~= observationId or counts[observationId] < threshold then
		return nil
	end

	return addPattern({
		id = patternId,
		userId = observation.userId,
		confidence = math.clamp(counts[observationId] / (threshold + 4), 0.1, 1),
		description = description,
		observations = { observationId },
		at = observation.at,
		expiresAt = observation.at + 300,
	})
end

function ObservationPatternRecognizer.record(observation: Observation): { Pattern }
	applyTraits(observation)

	if observation.userId == nil then
		return {}
	end

	local counts = getCounts(observation.userId)
	counts[observation.id] = (counts[observation.id] or 0) + 1

	local detected = {}
	local thresholds = ObservationConfig.PatternThresholds

	local function collect(pattern: Pattern?)
		if pattern ~= nil then
			table.insert(detected, pattern)
		end
	end

	collect(
		recognizeCountPattern(
			observation,
			counts,
			"Camera.LookBehind",
			thresholds.RepeatedLookBehind,
			"Player.RepeatedLookBehind",
			"Player repeatedly checks behind."
		)
	)
	collect(
		recognizeCountPattern(
			observation,
			counts,
			"Environment.EnterDarkness",
			thresholds.DarknessComfort,
			"Player.DarknessComfort",
			"Player keeps entering darkness."
		)
	)
	collect(
		recognizeCountPattern(
			observation,
			counts,
			"Interaction.DoorHesitation",
			thresholds.DoorHesitation,
			"Player.DoorHesitation",
			"Player hesitates before doors."
		)
	)
	collect(
		recognizeCountPattern(
			observation,
			counts,
			"Exploration.ReturnRoom",
			thresholds.RoomLooping,
			"Player.RoomLooping",
			"Player circles or returns to the same room."
		)
	)
	collect(
		recognizeCountPattern(
			observation,
			counts,
			"Camera.LookAtWindow",
			thresholds.WindowWatching,
			"Player.WindowWatching",
			"Player watches windows."
		)
	)
	collect(
		recognizeCountPattern(
			observation,
			counts,
			"Social.PartySeparated",
			thresholds.PartySeparation,
			"Player.SeparatesOften",
			"Player separates from the party often."
		)
	)
	collect(
		recognizeCountPattern(
			observation,
			counts,
			"Story.ObjectiveCompleted",
			thresholds.ObjectiveRushing,
			"Player.ObjectiveRushing",
			"Player rushes objectives."
		)
	)

	return detected
end

function ObservationPatternRecognizer.removePlayer(userId: number)
	countsByPlayer[userId] = nil
	personalities[userId] = nil
end

function ObservationPatternRecognizer.clear()
	table.clear(countsByPlayer)
	table.clear(patterns)
	table.clear(personalities)
end

function ObservationPatternRecognizer.inspect()
	return {
		patterns = table.clone(patterns),
		personalities = table.clone(personalities),
		playerCount = (function()
			local count = 0

			for _ in pairs(personalities) do
				count += 1
			end

			return count
		end)(),
	}
end

function ObservationPatternRecognizer.validate(): (boolean, string?)
	if #patterns > ObservationConfig.PatternLimit then
		return false, "ObservationPatternRecognizer exceeded pattern limit"
	end

	return true, nil
end

return ObservationPatternRecognizer
