--!strict
-- Converts trusted visual observations into intent context, not sight rays.

local VisionIntent = {}

function VisionIntent.fromObservation(observation: any)
	local confidence = if type(observation) == "table"
			and type(observation.confidence) == "number"
		then math.clamp(observation.confidence, 0, 1)
		else 0.5
	return {
		source = "Vision",
		signals = { movement = confidence, identity = confidence * 0.4 },
		targetPlayerId = if type(observation) == "table" then observation.playerId else nil,
		targetZoneId = if type(observation) == "table" then observation.zoneId else nil,
		reason = "vision observation suggested attention",
	}
end

return VisionIntent
