--!strict
-- Converts trusted audio/noise observations into intent context, not sound playback.

local HearingIntent = {}

function HearingIntent.fromObservation(observation: any)
	local intensity = if type(observation) == "table"
			and type(observation.intensity) == "number"
		then math.clamp(observation.intensity, 0, 1)
		else 0.4
	return {
		source = "Hearing",
		signals = { noise = intensity },
		targetPlayerId = if type(observation) == "table" then observation.playerId else nil,
		targetZoneId = if type(observation) == "table" then observation.zoneId else nil,
		reason = "hearing observation suggested investigation",
	}
end

return HearingIntent
