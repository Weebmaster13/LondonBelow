--!strict
--[[
	Safe tuning defaults for the Psychological Horror Director.

	Owns pacing intervals, cooldown defaults, tension thresholds, behavior
	observation weights, and memory limits.

	Does not own live runtime state, authored chapter scare content, or final
	balancing for shipped chapters.

	Future chapter configs may layer on top of these values, but should not
	bypass cooldowns, release, or silence. Defaults should bias toward restraint:
	too much pressure creates noise, and chapter-specific observations can always
	raise tension later.
]]

local HorrorDirectorConfig = {}

HorrorDirectorConfig.EvaluationIntervalSeconds = 6
HorrorDirectorConfig.MinimumSecondsBetweenScares = 18
HorrorDirectorConfig.MinimumPlayerSecondsBetweenScares = 24
HorrorDirectorConfig.MinimumCategorySecondsBetweenScares = 35
HorrorDirectorConfig.SilenceChance = 0.28
HorrorDirectorConfig.OverwhelmSilenceChance = 0.75
HorrorDirectorConfig.CalmTooLongSeconds = 90
HorrorDirectorConfig.RecentScareMemoryLimit = 12
HorrorDirectorConfig.RecentDecisionLimit = 25
HorrorDirectorConfig.RouteMemoryLimit = 12
HorrorDirectorConfig.HidingSpotMemoryLimit = 8
HorrorDirectorConfig.MaxTensionScore = 100
HorrorDirectorConfig.ReleaseDecayPerEvaluation = 8
HorrorDirectorConfig.PanicSoftCap = 88
HorrorDirectorConfig.MaxObservationAmount = 120

HorrorDirectorConfig.TensionThresholds = {
	Release = 12,
	Calm = 24,
	Uneasy = 44,
	Tense = 64,
	Dread = 82,
	Panic = 100,
}

HorrorDirectorConfig.ObservationWeights = {
	TimeAlone = 0.9,
	TimeWithParty = -0.25,
	Sprint = 2.5,
	Hide = 3,
	LanternUse = 1.25,
	Darkness = 1.5,
	LookBehind = 1.2,
	DoorHesitation = 2,
	PuzzleProgress = 0.4,
	ObjectiveProgress = 0.5,
	Exploration = 0.35,
	RepeatedRoute = 2,
	RepeatedHidingSpot = 2.25,
	RecentScareRelief = -10,
	RecentChaseRelief = -16,
}

function HorrorDirectorConfig.validate(): (boolean, string?)
	local numericFields = {
		"EvaluationIntervalSeconds",
		"MinimumSecondsBetweenScares",
		"MinimumPlayerSecondsBetweenScares",
		"MinimumCategorySecondsBetweenScares",
		"CalmTooLongSeconds",
		"RecentScareMemoryLimit",
		"RecentDecisionLimit",
		"RouteMemoryLimit",
		"HidingSpotMemoryLimit",
		"MaxTensionScore",
		"ReleaseDecayPerEvaluation",
		"PanicSoftCap",
		"MaxObservationAmount",
	}

	for _, field in ipairs(numericFields) do
		local value = HorrorDirectorConfig[field]

		if type(value) ~= "number" or value ~= value or value < 0 then
			return false, "Invalid HorrorDirectorConfig numeric field: " .. field
		end
	end

	if HorrorDirectorConfig.EvaluationIntervalSeconds <= 0 then
		return false, "HorrorDirectorConfig.EvaluationIntervalSeconds must be positive"
	end

	if HorrorDirectorConfig.SilenceChance < 0 or HorrorDirectorConfig.SilenceChance > 1 then
		return false, "HorrorDirectorConfig.SilenceChance must be between 0 and 1"
	end

	if
		HorrorDirectorConfig.OverwhelmSilenceChance < 0
		or HorrorDirectorConfig.OverwhelmSilenceChance > 1
	then
		return false, "HorrorDirectorConfig.OverwhelmSilenceChance must be between 0 and 1"
	end

	local thresholds = HorrorDirectorConfig.TensionThresholds

	if
		thresholds.Release > thresholds.Calm
		or thresholds.Calm > thresholds.Uneasy
		or thresholds.Uneasy > thresholds.Tense
		or thresholds.Tense > thresholds.Dread
		or thresholds.Dread > thresholds.Panic
	then
		return false, "HorrorDirectorConfig.TensionThresholds must be ascending"
	end

	if thresholds.Panic > HorrorDirectorConfig.MaxTensionScore then
		return false, "HorrorDirectorConfig.Panic threshold cannot exceed MaxTensionScore"
	end

	for weightName, weight in pairs(HorrorDirectorConfig.ObservationWeights) do
		if type(weightName) ~= "string" or weightName == "" then
			return false, "HorrorDirectorConfig observation weight name is invalid"
		end

		if type(weight) ~= "number" or weight ~= weight then
			return false, "HorrorDirectorConfig observation weight is invalid: " .. weightName
		end
	end

	return true, nil
end

return HorrorDirectorConfig
