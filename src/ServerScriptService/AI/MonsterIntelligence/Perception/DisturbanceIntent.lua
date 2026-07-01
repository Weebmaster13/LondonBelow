--!strict
-- Converts world disturbance facts into curiosity context.

local DisturbanceIntent = {}

function DisturbanceIntent.fromObservation(observation: any)
	local metadata = if type(observation) == "table"
			and type(observation.metadata) == "table"
		then observation.metadata
		else {}
	return {
		source = "Disturbance",
		signals = {
			door = if metadata.doorChanged == true then 1 else 0,
			light = if metadata.lightChanged == true then 1 else 0,
			objective = if metadata.objectiveChanged == true then 0.7 else 0,
		},
		novelty = {
			openedDoor = metadata.doorChanged == true,
			missingObject = metadata.objectMissing == true,
			unexpectedPlayerBehavior = metadata.unexpected == true,
		},
		targetZoneId = if type(observation) == "table" then observation.zoneId else nil,
		reason = "disturbance observation changed local curiosity",
	}
end

return DisturbanceIntent
