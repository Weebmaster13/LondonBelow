--!strict

local Config = {}

Config.ChapterId = "blackwater_descent"
Config.DisplayName = "The Blackwater Descent"
Config.RuntimeVersion = "196.0.0"
Config.RootName = "LondonBelow_Phase196_BlackwaterDescent"
Config.StartCFrame = CFrame.new(0, 5, 72)
Config.InteractionDistance = 12
Config.RespawnDelaySeconds = 2
Config.Objectives = table.freeze({
	{ id = "ignite_lantern", text = "Light the abandoned watchman's lantern", phase = "Opening" },
	{ id = "read_ledger", text = "Find the missing constable's ledger", phase = "Exploration" },
	{ id = "take_seal", text = "Recover the brass Blackwater seal", phase = "Exploration" },
	{ id = "ward_west", text = "Turn the western ward", phase = "Puzzle" },
	{ id = "ward_east", text = "Turn the eastern ward", phase = "Puzzle" },
	{ id = "ward_crypt", text = "Turn the ward beneath the stairs", phase = "Threat" },
	{ id = "open_archive", text = "Use the seal to open the forbidden archive", phase = "Threat" },
	{ id = "take_heart", text = "Take the glass heart from its reliquary", phase = "Climax" },
	{ id = "escape_gate", text = "Escape Blackwater House before it wakes", phase = "Escape" },
})
Config.Checkpoints = table.freeze({
	entrance = CFrame.new(0, 4, 20),
	archive = CFrame.new(0, 4, -66),
	ritual = CFrame.new(0, 4, -118),
})
Config.BeatNarrative = table.freeze({
	ignite_lantern = "The flame leans toward Blackwater House, though there is no wind.",
	read_ledger = "The final entry names you—written forty-seven years before your birth.",
	take_seal = "The brass seal is warm. Somewhere below, three locks answer.",
	ward_west = "The western ward turns. Something crosses the gallery behind you.",
	ward_east = "The eastern ward opens an eye carved into the wall.",
	ward_crypt = "The buried ward breaks the silence. The house begins to breathe.",
	open_archive = "The archive yields. Every shelf contains the same missing-person case.",
	take_heart = "The Glass Heart beats once in your hands—and every gaslight dies.",
	escape_gate = "Dawn reaches the street. Your reflection remains inside the house.",
})
Config.PhaseThreat = table.freeze({
	Opening = "QUIET",
	Exploration = "WATCHED",
	Puzzle = "UNSTABLE",
	Threat = "HUNTED",
	Climax = "AWAKENED",
	Escape = "RUN",
})

return table.freeze(Config)
