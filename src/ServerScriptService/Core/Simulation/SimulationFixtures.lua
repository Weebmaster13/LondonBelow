--!strict

local Players = require(script.Parent.SimulatedPlayerProfiles)
local Zones = require(script.Parent.SimulatedZoneModel)
local Types = require(script.Parent.SimulationTypes)

local SimulationFixtures = {}

type SimulationObservation = Types.SimulationObservation

local function observation(
	id: string,
	playerUserId: number?,
	zone: Types.SimulatedZone,
	amount: number?,
	metadata: { [string]: any }?
): SimulationObservation
	local payload = metadata or {}
	payload.zoneId = payload.zoneId or zone.zoneId
	payload.zoneKind = payload.zoneKind or zone.zoneKind
	payload.roomId = payload.roomId or zone.zoneId
	payload.areaId = payload.areaId or zone.zoneId
	payload.tags = payload.tags or zone.tags

	return {
		id = id,
		amount = amount,
		playerUserId = playerUserId,
		metadata = payload,
		expectAccepted = true,
	}
end

function SimulationFixtures.idleSilence(): Types.SimulationScenario
	return {
		id = "IdleSilence",
		displayName = "Idle Silence",
		description = "No observations should produce no execution and no pressure growth.",
		players = Players.getMany({ "soloCareful" }),
		zones = Zones.getMany({ "hallway" }),
		observations = {},
		actions = {},
	}
end

function SimulationFixtures.speedrunnerPressure(): Types.SimulationScenario
	local player = Players.get("speedrunner")
	local zone = Zones.get("street")

	return {
		id = "SpeedrunnerPressure",
		displayName = "Speedrunner Pressure",
		description = "Repeated sprint/exploration observations should raise bounded pressure.",
		players = { player },
		zones = { zone },
		observations = {
			observation("Movement.StartSprint", player.userId, zone, 1, {}),
			observation("Movement.Walk", player.userId, zone, 2, { distance = 40 }),
			observation("Environment.EnterFog", player.userId, zone, 1, {}),
		},
		actions = { "RequestFogPressure" },
	}
end

function SimulationFixtures.lanternOveruse(): Types.SimulationScenario
	local player = Players.get("lanternUser")
	local zone = Zones.get("hallway")

	return {
		id = "LanternOveruse",
		displayName = "Lantern Overuse",
		description = "Lantern overuse should create pressure without forcing a scare.",
		players = { player },
		zones = { zone },
		observations = {
			observation("Lantern.On", player.userId, zone, 1, {}),
			observation("Lantern.On", player.userId, zone, 1, {}),
			observation("Lantern.Flicker", player.userId, zone, 1, {}),
		},
		actions = { "RequestRoomPressure" },
	}
end

function SimulationFixtures.noteIgnorer(): Types.SimulationScenario
	local player = Players.get("noteIgnorer")
	local zone = Zones.get("puzzleRoom")

	return {
		id = "NoteIgnorer",
		displayName = "Note Ignorer",
		description = "Puzzle-room pressure must not obstruct future clue fairness.",
		players = { player },
		zones = { zone },
		observations = {
			observation("Interaction.ReadNote", player.userId, zone, 1, { noteId = "sim.note" }),
			observation("Camera.LookAway", player.userId, zone, 1, { targetId = "sim.note" }),
		},
		actions = { "RequestPuzzlePressure" },
	}
end

function SimulationFixtures.partySplit(): Types.SimulationScenario
	local leader = Players.get("partyLeader")
	local separated = Players.get("partySeparated")
	local street = Zones.get("street")

	return {
		id = "PartySplit",
		displayName = "Party Split",
		description = "Separated party pressure should allow fair fog/street pressure.",
		players = { leader, separated },
		zones = { street },
		observations = {
			observation("Social.PartySeparated", separated.userId, street, 1, { distance = 80 }),
			observation("Environment.EnterFog", separated.userId, street, 1, {}),
		},
		actions = { "RequestFogPressure" },
	}
end

function SimulationFixtures.executionBridgeFailure(): Types.SimulationScenario
	return {
		id = "ExecutionBridgeFailure",
		displayName = "Execution Bridge Failure",
		description = "Unsafe bridge payloads must fail without cooldown state.",
		players = Players.getMany({ "soloCareful" }),
		zones = Zones.getMany({ "hallway" }),
		observations = {},
		actions = { "InvalidBridgePayload" },
	}
end

function SimulationFixtures.invalidObservation(): Types.SimulationScenario
	return {
		id = "InvalidObservation",
		displayName = "Invalid Observation",
		description = "Unknown observations must be rejected by observation validation.",
		players = Players.getMany({ "soloCareful" }),
		zones = Zones.getMany({ "hallway" }),
		observations = {
			{
				id = "Simulation.DoesNotExist",
				amount = 1,
				playerUserId = nil,
				metadata = {},
				expectAccepted = false,
			},
		},
		actions = {},
	}
end

function SimulationFixtures.staleZoneCleanup(): Types.SimulationScenario
	return {
		id = "StaleZoneCleanup",
		displayName = "Stale Zone Cleanup",
		description = "Old synthetic zone pressure must prune cleanly.",
		players = Players.getMany({ "soloCareful" }),
		zones = Zones.getMany({ "street" }),
		observations = {},
		actions = { "StaleZoneCleanup" },
	}
end

return SimulationFixtures
