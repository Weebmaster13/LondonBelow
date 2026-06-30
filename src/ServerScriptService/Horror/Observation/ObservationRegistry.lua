--!strict
--[[
	Canonical registry of every known Observation Engine type.

	Owns stable observation IDs, categories, descriptions, expected metadata,
	weights, priorities, aggregation rules, expiration windows, and optional
	Horror Director compatibility mappings.

	Does not own runtime observations, pattern recognition, gameplay logic, or
	client input. Future systems must import IDs from this registry instead of
	typing magic strings.
]]

local Types = require(script.Parent.ObservationTypes)

local ObservationRegistry = {}

type ObservationDefinition = Types.ObservationDefinition

local definitions: { ObservationDefinition } = {
	{
		id = "Movement.StartSprint",
		category = "Movement",
		description = "Player began sprinting.",
		expectedMetadata = { "roomId", "areaId" },
		weight = 1.1,
		priority = 30,
		aggregation = "Count",
		expiration = "FiveMinutes",
		directorKind = "Sprint",
	},
	{
		id = "Movement.StopSprint",
		category = "Movement",
		description = "Player stopped sprinting.",
		expectedMetadata = { "roomId" },
		weight = 0.4,
		priority = 20,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Movement.Jump",
		category = "Movement",
		description = "Player jumped.",
		expectedMetadata = { "roomId" },
		weight = 0.2,
		priority = 10,
		aggregation = "Count",
		expiration = "OneMinute",
	},
	{
		id = "Movement.Land",
		category = "Movement",
		description = "Player landed after being airborne.",
		expectedMetadata = { "roomId" },
		weight = 0.2,
		priority = 10,
		aggregation = "Count",
		expiration = "OneMinute",
	},
	{
		id = "Movement.Crouch",
		category = "Movement",
		description = "Player crouched.",
		expectedMetadata = { "roomId" },
		weight = 0.6,
		priority = 20,
		aggregation = "Count",
		expiration = "FiveMinutes",
	},
	{
		id = "Movement.Walk",
		category = "Movement",
		description = "Player walked through an area.",
		expectedMetadata = { "roomId", "distance" },
		weight = 0.5,
		priority = 15,
		aggregation = "Duration",
		expiration = "FiveMinutes",
		directorKind = "Exploration",
	},
	{
		id = "Movement.Stop",
		category = "Movement",
		description = "Player stopped moving.",
		expectedMetadata = { "roomId" },
		weight = 0.3,
		priority = 15,
		aggregation = "Latest",
		expiration = "OneMinute",
	},

	{
		id = "Camera.LookBehind",
		category = "Camera",
		description = "Player checked behind them.",
		expectedMetadata = { "roomId" },
		weight = 1.2,
		priority = 35,
		aggregation = "Count",
		expiration = "FiveMinutes",
		directorKind = "LookBehind",
	},
	{
		id = "Camera.LookAtPortrait",
		category = "Camera",
		description = "Player looked at a portrait.",
		expectedMetadata = { "portraitId", "roomId" },
		weight = 0.8,
		priority = 25,
		aggregation = "Count",
		expiration = "FiveMinutes",
	},
	{
		id = "Camera.LookAtWindow",
		category = "Camera",
		description = "Player watched a window.",
		expectedMetadata = { "windowId", "roomId" },
		weight = 0.9,
		priority = 25,
		aggregation = "Count",
		expiration = "FiveMinutes",
	},
	{
		id = "Camera.LookAway",
		category = "Camera",
		description = "Player looked away from a target.",
		expectedMetadata = { "targetId" },
		weight = 0.4,
		priority = 15,
		aggregation = "Latest",
		expiration = "OneMinute",
	},

	{
		id = "Interaction.OpenDoor",
		category = "Interaction",
		description = "Player opened a door.",
		expectedMetadata = { "doorId", "roomId" },
		weight = 0.8,
		priority = 30,
		aggregation = "Count",
		expiration = "TenMinutes",
	},
	{
		id = "Interaction.Begin",
		category = "Interaction",
		description = "Player began a validated interaction attempt.",
		expectedMetadata = { "interactionId", "interactionKind" },
		weight = 0.2,
		priority = 15,
		aggregation = "Count",
		expiration = "OneMinute",
	},
	{
		id = "Interaction.Complete",
		category = "Interaction",
		description = "Player completed a server-approved interaction.",
		expectedMetadata = { "interactionId", "interactionKind" },
		weight = 0.5,
		priority = 25,
		aggregation = "Count",
		expiration = "FiveMinutes",
	},
	{
		id = "Interaction.Cancel",
		category = "Interaction",
		description = "Player cancelled or lost an interaction in progress.",
		expectedMetadata = { "interactionId" },
		weight = 0.2,
		priority = 15,
		aggregation = "Count",
		expiration = "OneMinute",
	},
	{
		id = "Interaction.Fail",
		category = "Interaction",
		description = "Server rejected or failed an interaction request.",
		expectedMetadata = { "interactionId", "code" },
		weight = 0.3,
		priority = 20,
		aggregation = "Count",
		expiration = "OneMinute",
	},
	{
		id = "Interaction.CloseDoor",
		category = "Interaction",
		description = "Player closed a door.",
		expectedMetadata = { "doorId", "roomId" },
		weight = 0.5,
		priority = 20,
		aggregation = "Count",
		expiration = "FiveMinutes",
	},
	{
		id = "Interaction.PullLever",
		category = "Interaction",
		description = "Player pulled a lever.",
		expectedMetadata = { "leverId" },
		weight = 1.0,
		priority = 35,
		aggregation = "Count",
		expiration = "Chapter",
	},
	{
		id = "Interaction.OpenDrawer",
		category = "Interaction",
		description = "Player opened or closed a drawer.",
		expectedMetadata = { "drawerId", "roomId" },
		weight = 0.5,
		priority = 20,
		aggregation = "Count",
		expiration = "FiveMinutes",
	},
	{
		id = "Interaction.OpenCabinet",
		category = "Interaction",
		description = "Player opened or closed a cabinet.",
		expectedMetadata = { "cabinetId", "roomId" },
		weight = 0.6,
		priority = 25,
		aggregation = "Count",
		expiration = "FiveMinutes",
	},
	{
		id = "Interaction.ToggleSwitch",
		category = "Interaction",
		description = "Player toggled a switch.",
		expectedMetadata = { "switchId", "roomId" },
		weight = 0.8,
		priority = 35,
		aggregation = "Count",
		expiration = "Chapter",
	},
	{
		id = "Interaction.CollectibleFound",
		category = "Interaction",
		description = "Player collected a chapter-safe collectible object.",
		expectedMetadata = { "collectibleId", "roomId" },
		weight = 0.7,
		priority = 30,
		aggregation = "Unique",
		expiration = "Chapter",
	},
	{
		id = "Interaction.ReadNote",
		category = "Interaction",
		description = "Player read a note.",
		expectedMetadata = { "noteId", "roomId" },
		weight = 0.7,
		priority = 25,
		aggregation = "Unique",
		expiration = "Chapter",
	},
	{
		id = "Interaction.PickupKey",
		category = "Interaction",
		description = "Player picked up a key.",
		expectedMetadata = { "keyId" },
		weight = 1.0,
		priority = 45,
		aggregation = "Unique",
		expiration = "Chapter",
	},
	{
		id = "Interaction.DoorHesitation",
		category = "Interaction",
		description = "Player hesitated near a door.",
		expectedMetadata = { "doorId", "duration" },
		weight = 1.2,
		priority = 35,
		aggregation = "Count",
		expiration = "FiveMinutes",
		directorKind = "DoorHesitation",
	},

	{
		id = "Puzzle.Begin",
		category = "Puzzle",
		description = "Player began puzzle interaction.",
		expectedMetadata = { "puzzleId" },
		weight = 0.7,
		priority = 30,
		aggregation = "Latest",
		expiration = "Chapter",
	},
	{
		id = "Puzzle.Progress",
		category = "Puzzle",
		description = "Player made puzzle progress.",
		expectedMetadata = { "puzzleId", "progress" },
		weight = 0.8,
		priority = 35,
		aggregation = "Latest",
		expiration = "Chapter",
		directorKind = "PuzzleProgress",
	},
	{
		id = "Puzzle.Fail",
		category = "Puzzle",
		description = "Player failed a puzzle step.",
		expectedMetadata = { "puzzleId" },
		weight = 1.1,
		priority = 35,
		aggregation = "Count",
		expiration = "TenMinutes",
	},
	{
		id = "Puzzle.Complete",
		category = "Puzzle",
		description = "Player completed a puzzle.",
		expectedMetadata = { "puzzleId" },
		weight = 1.0,
		priority = 50,
		aggregation = "Unique",
		expiration = "Chapter",
		directorKind = "PuzzleProgress",
	},

	{
		id = "Lantern.On",
		category = "Lantern",
		description = "Player turned lantern on.",
		expectedMetadata = { "roomId" },
		weight = 0.8,
		priority = 30,
		aggregation = "Count",
		expiration = "FiveMinutes",
		directorKind = "LanternUse",
	},
	{
		id = "Lantern.Off",
		category = "Lantern",
		description = "Player turned lantern off.",
		expectedMetadata = { "roomId" },
		weight = 0.5,
		priority = 20,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Lantern.Equipped",
		category = "Lantern",
		description = "Server equipped the player's lantern.",
		expectedMetadata = { "roomId", "zoneId" },
		weight = 0.4,
		priority = 20,
		aggregation = "Latest",
		expiration = "FiveMinutes",
	},
	{
		id = "Lantern.Unequipped",
		category = "Lantern",
		description = "Server unequipped the player's lantern.",
		expectedMetadata = { "roomId", "zoneId" },
		weight = 0.4,
		priority = 20,
		aggregation = "Latest",
		expiration = "FiveMinutes",
	},
	{
		id = "Lantern.TurnedOn",
		category = "Lantern",
		description = "Player requested and server accepted lantern on state.",
		expectedMetadata = { "roomId", "zoneId", "battery" },
		weight = 0.8,
		priority = 30,
		aggregation = "Count",
		expiration = "FiveMinutes",
		directorKind = "LanternUse",
	},
	{
		id = "Lantern.TurnedOff",
		category = "Lantern",
		description = "Player requested and server accepted lantern off state.",
		expectedMetadata = { "roomId", "zoneId", "battery" },
		weight = 0.5,
		priority = 20,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Lantern.Overused",
		category = "Lantern",
		description = "Player overused lantern enough to become an observation signal.",
		expectedMetadata = { "roomId", "zoneId", "overuseScore" },
		weight = 1.2,
		priority = 45,
		aggregation = "Count",
		expiration = "FiveMinutes",
		directorKind = "LanternUse",
	},
	{
		id = "Lantern.LowBattery",
		category = "Lantern",
		description = "Lantern battery became low.",
		expectedMetadata = { "level" },
		weight = 1.3,
		priority = 50,
		aggregation = "Latest",
		expiration = "FiveMinutes",
	},
	{
		id = "Lantern.Flicker",
		category = "Lantern",
		description = "Lantern flickered.",
		expectedMetadata = { "roomId" },
		weight = 0.9,
		priority = 35,
		aggregation = "Count",
		expiration = "OneMinute",
	},

	{
		id = "Environment.EnterFog",
		category = "Environment",
		description = "Player entered fog.",
		expectedMetadata = { "areaId" },
		weight = 0.8,
		priority = 25,
		aggregation = "Duration",
		expiration = "FiveMinutes",
	},
	{
		id = "Environment.ExitFog",
		category = "Environment",
		description = "Player exited fog.",
		expectedMetadata = { "areaId" },
		weight = 0.2,
		priority = 15,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Environment.EnterDarkness",
		category = "Environment",
		description = "Player entered darkness.",
		expectedMetadata = { "roomId" },
		weight = 1.1,
		priority = 35,
		aggregation = "Duration",
		expiration = "FiveMinutes",
		directorKind = "Darkness",
	},
	{
		id = "Environment.ExitDarkness",
		category = "Environment",
		description = "Player exited darkness.",
		expectedMetadata = { "roomId" },
		weight = 0.2,
		priority = 15,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Darkness.Entered",
		category = "Environment",
		description = "Server-authoritative player darkness exposure began.",
		expectedMetadata = { "roomId", "zoneId", "exposure" },
		weight = 1.1,
		priority = 35,
		aggregation = "Duration",
		expiration = "FiveMinutes",
		directorKind = "Darkness",
	},
	{
		id = "Darkness.Exited",
		category = "Environment",
		description = "Server-authoritative player darkness exposure ended.",
		expectedMetadata = { "roomId", "zoneId", "exposure" },
		weight = 0.2,
		priority = 15,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Darkness.ExposureIncreased",
		category = "Environment",
		description = "Server-authoritative darkness exposure increased.",
		expectedMetadata = { "roomId", "zoneId", "exposure", "intensity" },
		weight = 1.0,
		priority = 35,
		aggregation = "Duration",
		expiration = "FiveMinutes",
		directorKind = "Darkness",
	},
	{
		id = "Darkness.ProtectedZone",
		category = "Environment",
		description = "Darkness pressure was suppressed by unknown, safe-room, or puzzle protection.",
		expectedMetadata = { "roomId", "zoneId", "protected" },
		weight = -0.2,
		priority = 20,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Environment.RainStarted",
		category = "Environment",
		description = "Rain started.",
		expectedMetadata = { "areaId" },
		weight = 0.6,
		priority = 30,
		aggregation = "Latest",
		expiration = "TenMinutes",
	},
	{
		id = "Environment.LightFlicker",
		category = "Environment",
		description = "Environmental light flickered.",
		expectedMetadata = { "lightId", "roomId" },
		weight = 0.8,
		priority = 35,
		aggregation = "Count",
		expiration = "FiveMinutes",
	},

	{
		id = "Monster.Sighted",
		category = "Monster",
		description = "A monster was sighted.",
		expectedMetadata = { "monsterId", "roomId" },
		weight = 2.0,
		priority = 80,
		aggregation = "Count",
		expiration = "TenMinutes",
		directorKind = "ScareSeen",
	},
	{
		id = "Monster.Lost",
		category = "Monster",
		description = "Monster was lost from sight.",
		expectedMetadata = { "monsterId" },
		weight = 0.5,
		priority = 30,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Monster.Ignored",
		category = "Monster",
		description = "Player ignored a monster cue.",
		expectedMetadata = { "monsterId" },
		weight = 1.2,
		priority = 45,
		aggregation = "Count",
		expiration = "FiveMinutes",
	},
	{
		id = "Monster.ChaseStarted",
		category = "Monster",
		description = "Monster chase started.",
		expectedMetadata = { "monsterId" },
		weight = 2.0,
		priority = 90,
		aggregation = "Latest",
		expiration = "TenMinutes",
		directorKind = "ChaseSeen",
	},
	{
		id = "Monster.ChaseEnded",
		category = "Monster",
		description = "Monster chase ended.",
		expectedMetadata = { "monsterId", "result" },
		weight = 1.0,
		priority = 70,
		aggregation = "Latest",
		expiration = "FiveMinutes",
	},

	{
		id = "Social.PartySeparated",
		category = "Social",
		description = "Party became separated.",
		expectedMetadata = { "distance" },
		weight = 1.4,
		priority = 50,
		aggregation = "Duration",
		expiration = "FiveMinutes",
		directorKind = "TimeAlone",
	},
	{
		id = "Social.Regrouped",
		category = "Social",
		description = "Party regrouped.",
		expectedMetadata = { "distance" },
		weight = -0.4,
		priority = 35,
		aggregation = "Latest",
		expiration = "OneMinute",
		directorKind = "TimeWithParty",
	},

	{
		id = "Fear.BreathingHeavy",
		category = "Fear",
		description = "Player breathing became heavy.",
		expectedMetadata = { "level" },
		weight = 1.0,
		priority = 45,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Fear.HeartbeatRaised",
		category = "Fear",
		description = "Player heartbeat pressure rose.",
		expectedMetadata = { "level" },
		weight = 1.2,
		priority = 45,
		aggregation = "Latest",
		expiration = "OneMinute",
	},
	{
		id = "Fear.Panic",
		category = "Fear",
		description = "Player entered panic presentation state.",
		expectedMetadata = { "reason" },
		weight = 1.7,
		priority = 75,
		aggregation = "Latest",
		expiration = "FiveMinutes",
	},

	{
		id = "Exploration.EnterRoom",
		category = "Exploration",
		description = "Player entered a room.",
		expectedMetadata = { "roomId" },
		weight = 0.8,
		priority = 30,
		aggregation = "Route",
		expiration = "TenMinutes",
		directorKind = "Exploration",
	},
	{
		id = "Exploration.ExitRoom",
		category = "Exploration",
		description = "Player exited a room.",
		expectedMetadata = { "roomId" },
		weight = 0.2,
		priority = 15,
		aggregation = "Route",
		expiration = "OneMinute",
	},
	{
		id = "Exploration.ReturnRoom",
		category = "Exploration",
		description = "Player returned to a known room.",
		expectedMetadata = { "roomId" },
		weight = 1.1,
		priority = 35,
		aggregation = "Count",
		expiration = "TenMinutes",
		directorKind = "RepeatedRoute",
	},
	{
		id = "Exploration.NewArea",
		category = "Exploration",
		description = "Player entered a new area.",
		expectedMetadata = { "areaId" },
		weight = 0.9,
		priority = 35,
		aggregation = "Unique",
		expiration = "Chapter",
		directorKind = "Exploration",
	},

	{
		id = "Story.ObjectiveStarted",
		category = "Story",
		description = "Objective started.",
		expectedMetadata = { "objectiveId" },
		weight = 0.6,
		priority = 40,
		aggregation = "Latest",
		expiration = "Chapter",
	},
	{
		id = "Story.ObjectiveCompleted",
		category = "Story",
		description = "Objective completed.",
		expectedMetadata = { "objectiveId", "progress" },
		weight = 1.0,
		priority = 60,
		aggregation = "Unique",
		expiration = "Chapter",
		directorKind = "ObjectiveProgress",
	},

	{
		id = "Time.SafeTooLong",
		category = "Time",
		description = "Players have been safe for too long.",
		expectedMetadata = { "duration" },
		weight = 1.4,
		priority = 55,
		aggregation = "Duration",
		expiration = "OneMinute",
	},
	{
		id = "Time.AloneTooLong",
		category = "Time",
		description = "Player has been alone too long.",
		expectedMetadata = { "duration" },
		weight = 1.5,
		priority = 60,
		aggregation = "Duration",
		expiration = "OneMinute",
		directorKind = "TimeAlone",
	},
}

local definitionsById: { [string]: ObservationDefinition } = {}
local ids = {}

for _, definition in ipairs(definitions) do
	definitionsById[definition.id] = definition
	table.insert(ids, definition.id)
end

table.sort(ids)

local function copyArray(values: { string }): { string }
	return table.clone(values)
end

local function copyDefinition(definition: ObservationDefinition): ObservationDefinition
	return {
		id = definition.id,
		category = definition.category,
		description = definition.description,
		expectedMetadata = copyArray(definition.expectedMetadata),
		weight = definition.weight,
		priority = definition.priority,
		aggregation = definition.aggregation,
		expiration = definition.expiration,
		directorKind = definition.directorKind,
	}
end

function ObservationRegistry.get(id: string): ObservationDefinition?
	local definition = definitionsById[id]

	if definition == nil then
		return nil
	end

	return copyDefinition(definition)
end

function ObservationRegistry.getUnsafe(id: string): ObservationDefinition?
	return definitionsById[id]
end

function ObservationRegistry.getAll(): { ObservationDefinition }
	local copied = {}

	for _, definition in ipairs(definitions) do
		table.insert(copied, copyDefinition(definition))
	end

	return copied
end

function ObservationRegistry.ids(): { string }
	return table.clone(ids)
end

function ObservationRegistry.validate(): (boolean, string?)
	local seen = {}

	for _, definition in ipairs(definitions) do
		if definition.id == "" or string.find(definition.id, "%.") == nil then
			return false, "Observation definition id is invalid"
		end

		if seen[definition.id] then
			return false, "Duplicate observation definition id: " .. definition.id
		end

		if definition.description == "" then
			return false, "Observation description is empty: " .. definition.id
		end

		if definition.weight ~= definition.weight or definition.weight < -5 then
			return false, "Observation weight is invalid: " .. definition.id
		end

		if definition.priority < 0 or definition.priority > 100 then
			return false, "Observation priority out of range: " .. definition.id
		end

		seen[definition.id] = true
	end

	return true, nil
end

return ObservationRegistry
