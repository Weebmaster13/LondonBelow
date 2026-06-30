--!strict
--[[
	Safe runtime tuning for the Observation Engine.

	Owns memory limits, metadata size limits, validation bounds, profiling
	thresholds, and pattern thresholds.

	Does not own observation definitions, gameplay interpretation, or final
	chapter balance. These values are conservative foundation defaults.
]]

local ObservationConfig = {}

ObservationConfig.MaxMetadataKeys = 24
ObservationConfig.MaxStringLength = 160
ObservationConfig.MaxArrayItems = 32
ObservationConfig.MaxObservationAmount = 300
ObservationConfig.MaxFutureTimestampSeconds = 5
ObservationConfig.MaxPastTimestampSeconds = 600
ObservationConfig.TimelineLimit = 6000
ObservationConfig.PlayerTimelineLimit = 1200
ObservationConfig.HighPriorityLimit = 40
ObservationConfig.PatternLimit = 120
ObservationConfig.PersonalityDecayPerMinute = 0.015
ObservationConfig.ProfileIntervalSeconds = 30
ObservationConfig.ProfilerSlowObservationMs = 4

ObservationConfig.PatternThresholds = {
	RepeatedLookBehind = 6,
	DarknessAvoidance = 4,
	DarknessComfort = 5,
	DoorHesitation = 4,
	RoomLooping = 4,
	FrequentHiding = 4,
	WindowWatching = 3,
	PartySeparation = 3,
	ObjectiveRushing = 5,
	PatientExploration = 5,
}

function ObservationConfig.validate(): (boolean, string?)
	for key, value in pairs(ObservationConfig) do
		if type(value) == "number" and (value ~= value or value < 0) then
			return false, "ObservationConfig numeric value is invalid: " .. key
		end
	end

	if ObservationConfig.TimelineLimit < ObservationConfig.PlayerTimelineLimit then
		return false, "ObservationConfig.TimelineLimit must cover player timeline limit"
	end

	return true, nil
end

return ObservationConfig
