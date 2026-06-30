--!strict

local Types = require(script.Parent.SimulationTypes)

local SimulatedZoneModel = {}

type SimulatedZone = Types.SimulatedZone

local zones: { [string]: SimulatedZone } = {
	street = {
		zoneId = "sim.street.fog",
		zoneKind = "Street",
		tags = { "exterior", "fog" },
	},
	hallway = {
		zoneId = "sim.building.hallway",
		zoneKind = "Hallway",
		tags = { "interior" },
	},
	puzzleRoom = {
		zoneId = "sim.puzzle.room",
		zoneKind = "PuzzleRoom",
		tags = { "puzzle" },
	},
	safeRoom = {
		zoneId = "sim.safe.room",
		zoneKind = "SafeRoom",
		tags = { "safe" },
	},
	chaseRoute = {
		zoneId = "sim.chase.route",
		zoneKind = "ChaseRoute",
		tags = { "chase" },
	},
}

local function copyZone(zone: SimulatedZone): SimulatedZone
	return {
		zoneId = zone.zoneId,
		zoneKind = zone.zoneKind,
		tags = table.clone(zone.tags),
	}
end

function SimulatedZoneModel.get(name: string): SimulatedZone
	local zone = zones[name]

	assert(zone ~= nil, "Unknown simulated zone: " .. name)

	return copyZone(zone :: SimulatedZone)
end

function SimulatedZoneModel.getMany(names: { string }): { SimulatedZone }
	local copied = {}

	for _, name in ipairs(names) do
		table.insert(copied, SimulatedZoneModel.get(name))
	end

	return copied
end

return SimulatedZoneModel
