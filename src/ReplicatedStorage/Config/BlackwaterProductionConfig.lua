--!strict

local Config = {}

Config.ProgramVersion = "204.0.0"
Config.ProgramName = "Blackwater Descent Production Program"
Config.RunSeed = 196204

Config.Rooms = table.freeze({
	{
		id = "victorian_street",
		displayName = "Rain-Darkened Street",
		zone = "Exterior",
		center = Vector3.new(0, 0, 76),
		size = Vector3.new(78, 1, 116),
		story = "The street has been emptied by weather and rumor; every lit window faces away from Blackwater House.",
		mechanic = "arrival, regroup, escape return",
		safe = true,
		checkpoint = "entrance",
	},
	{
		id = "front_steps",
		displayName = "Blackwater Steps",
		zone = "Threshold",
		center = Vector3.new(0, 2, 18),
		size = Vector3.new(28, 4, 16),
		story = "Boot scrapes and rainwater point inward, but no tracks lead out.",
		mechanic = "house reveal and lantern read",
		safe = true,
	},
	{
		id = "foyer",
		displayName = "Foyer",
		zone = "House",
		center = Vector3.new(0, 0, -5),
		size = Vector3.new(38, 14, 34),
		story = "Portraits have been turned toward the door, as if awaiting a verdict.",
		mechanic = "first interior orientation",
		safe = false,
	},
	{
		id = "west_wing",
		displayName = "West Wing",
		zone = "House",
		center = Vector3.new(-30, 0, -37),
		size = Vector3.new(26, 14, 34),
		story = "The family record room is scratched with dates that have not happened yet.",
		mechanic = "ledger clue and optional evidence",
		safe = false,
	},
	{
		id = "east_wing",
		displayName = "East Wing",
		zone = "House",
		center = Vector3.new(30, 0, -37),
		size = Vector3.new(26, 14, 34),
		story = "The drawing room is set for guests whose names match the party.",
		mechanic = "shortcut unlock and hiding tutorial",
		safe = false,
	},
	{
		id = "upper_gallery",
		displayName = "Upper Gallery",
		zone = "House",
		center = Vector3.new(0, 14, -38),
		size = Vector3.new(48, 1, 30),
		story = "A balcony frames the foyer like a courtroom viewing box.",
		mechanic = "Bailiff sightline reveal",
		safe = false,
	},
	{
		id = "constable_room",
		displayName = "Constable Room",
		zone = "Investigation",
		center = Vector3.new(-31, 0, -66),
		size = Vector3.new(24, 12, 24),
		story = "Constable Vale's final board connects the house to disappearances across three generations.",
		mechanic = "deduction evidence",
		safe = true,
		checkpoint = "archive",
	},
	{
		id = "servants_corridor",
		displayName = "Servants' Corridor",
		zone = "Service",
		center = Vector3.new(31, 0, -66),
		size = Vector3.new(20, 12, 38),
		story = "Service bells are labeled with rooms that do not exist on the floor plan.",
		mechanic = "risk detour and noise lesson",
		safe = false,
	},
	{
		id = "kitchen",
		displayName = "Service Kitchen",
		zone = "Service",
		center = Vector3.new(31, 0, -96),
		size = Vector3.new(24, 12, 24),
		story = "Cold plates are still warm under the silver covers.",
		mechanic = "secret evidence and hiding",
		safe = false,
	},
	{
		id = "cellar",
		displayName = "Cellar",
		zone = "Below",
		center = Vector3.new(0, -7, -104),
		size = Vector3.new(30, 10, 30),
		story = "The house's foundations are braced like ribs around a sunken door.",
		mechanic = "third ward and first sustained threat",
		safe = false,
	},
	{
		id = "crypt_access",
		displayName = "Crypt Access",
		zone = "Below",
		center = Vector3.new(-28, -7, -112),
		size = Vector3.new(20, 10, 22),
		story = "Blackwater names are carved twice: once for death, once for return.",
		mechanic = "optional lore and chase loop",
		safe = false,
	},
	{
		id = "ward_chambers",
		displayName = "Ward Chambers",
		zone = "Puzzle",
		center = Vector3.new(0, 0, -72),
		size = Vector3.new(40, 14, 34),
		story = "The wards were not built to keep evil out; they were built to keep the house from testifying.",
		mechanic = "multi-stage ward deduction",
		safe = false,
	},
	{
		id = "forbidden_archive",
		displayName = "Forbidden Archive",
		zone = "Archive",
		center = Vector3.new(0, 0, -84),
		size = Vector3.new(40, 14, 36),
		story = "Every case file ends with the same handwriting: dismissed by order of the Bailiff.",
		mechanic = "archive opening and narrative turn",
		safe = true,
		checkpoint = "archive",
	},
	{
		id = "ritual_chamber",
		displayName = "Ritual Chamber",
		zone = "Climax",
		center = Vector3.new(0, -10, -138),
		size = Vector3.new(44, 16, 36),
		story = "The Glass Heart preserves the last honest memory of Blackwater House.",
		mechanic = "ending choice and blackout start",
		safe = false,
		checkpoint = "ritual",
	},
	{
		id = "escape_route",
		displayName = "Blackout Escape Route",
		zone = "Escape",
		center = Vector3.new(0, 0, 112),
		size = Vector3.new(66, 1, 32),
		story = "Dawn arrives only after the party decides what truth leaves with them.",
		mechanic = "final chase and dawn transition",
		safe = false,
	},
})

Config.Shortcuts = table.freeze({
	{
		id = "east_gallery_latch",
		from = "east_wing",
		to = "upper_gallery",
		unlockObjective = "read_ledger",
	},
	{ id = "service_cellar_lift", from = "kitchen", to = "cellar", unlockObjective = "ward_east" },
	{
		id = "archive_street_return",
		from = "forbidden_archive",
		to = "victorian_street",
		unlockObjective = "take_heart",
	},
})

Config.OptionalEvidence = table.freeze({
	{
		id = "vale_raincoat",
		roomId = "constable_room",
		clue = "Constable Vale came prepared for rain inside the house.",
	},
	{
		id = "wrong_portrait",
		roomId = "foyer",
		clue = "The youngest Blackwater is painted older than her parents.",
	},
	{
		id = "service_bell_blackwater",
		roomId = "servants_corridor",
		clue = "A bell marked Reliquary rings without a wire.",
	},
	{
		id = "kitchen_place_setting",
		roomId = "kitchen",
		clue = "A fresh place is set for each player.",
	},
	{
		id = "crypt_second_names",
		roomId = "crypt_access",
		clue = "The family names repeat with impossible return dates.",
	},
	{
		id = "heart_reflection",
		roomId = "ritual_chamber",
		clue = "The Heart reflects the street at dawn before dawn exists.",
	},
})

Config.WardSeeds = table.freeze({
	{
		seed = 196204,
		order = { "ward_west", "ward_east", "ward_crypt" },
		symbols = { "lamp", "seal", "river" },
		clueRooms = { "west_wing", "constable_room", "kitchen" },
	},
	{
		seed = 196205,
		order = { "ward_east", "ward_west", "ward_crypt" },
		symbols = { "mirror", "ledger", "bell" },
		clueRooms = { "east_wing", "foyer", "servants_corridor" },
	},
})

Config.Bailiff = table.freeze({
	id = "the_bailiff",
	displayName = "The Bailiff",
	origin = "A civic judgment bound into Blackwater House after the family hid its crimes behind legal process.",
	visualSilhouette = "tall coat, wet gloves, brass mask-fragment, long receipt chain",
	audioSignature = "wet ledger pages, distant gavel knock, slow boot drag",
	states = {
		"Unspawned",
		"Dormant",
		"Foreshadow",
		"Patrol",
		"Stalk",
		"Observe",
		"Investigate",
		"Suspicious",
		"Hunt",
		"Search",
		"Ambush",
		"DoorPressure",
		"Recover",
		"Retreat",
		"Climax",
		"Disabled",
		"Shutdown",
	},
	fairness = {
		reactionWindow = 1.4,
		maxHuntSeconds = 42,
		targetCooldown = 18,
		checkpointProtection = 8,
		lateJoinProtection = 10,
	},
})

Config.HidingTypes = table.freeze({
	{ id = "wardrobe", capacity = 1, searchRisk = 0.22, noiseOnEnter = 0.12 },
	{ id = "under_table", capacity = 1, searchRisk = 0.32, noiseOnEnter = 0.08 },
	{ id = "shadow_alcove", capacity = 2, searchRisk = 0.42, noiseOnEnter = 0.04 },
	{ id = "service_cupboard", capacity = 1, searchRisk = 0.28, noiseOnEnter = 0.16 },
	{ id = "emergency_concealment", capacity = 1, searchRisk = 0.55, noiseOnEnter = 0.2 },
})

Config.Difficulty = table.freeze({
	Story = { chaseIntensity = 0.45, staminaForgiveness = 1.35, hintStrength = 3 },
	Standard = { chaseIntensity = 0.7, staminaForgiveness = 1, hintStrength = 2 },
	Investigator = { chaseIntensity = 0.86, staminaForgiveness = 0.86, hintStrength = 1 },
	Nightmare = { chaseIntensity = 1, staminaForgiveness = 0.72, hintStrength = 0 },
})

Config.Endings = table.freeze({
	{
		id = "escape_with_heart",
		title = "The Heart Leaves",
		requirement = "Glass Heart carried through dawn gate",
		consequence = "Blackwater House remembers the party and follows in reflection.",
	},
	{
		id = "seal_the_heart",
		title = "The House Testifies",
		requirement = "Glass Heart returned after archive truth is found",
		consequence = "The house remains sealed, but Constable Vale's evidence survives.",
	},
	{
		id = "free_the_presence",
		title = "A Name Returned",
		requirement = "All optional evidence found before escape",
		consequence = "A trapped witness escapes the house at the cost of the brass seal.",
	},
})

Config.Audio = table.freeze({
	buses = {
		"Master",
		"Music",
		"Ambience",
		"Environment",
		"Monster",
		"Interaction",
		"Dialogue",
		"UI",
		"Accessibility",
	},
	zones = {
		street = "muffled rain, distant wheels, gas hiss",
		foyer = "wet stone drip, room-tone pressure, faint portrait wood creak",
		gallery = "distant pages, upper-floor settling, withheld breath",
		cellar = "water slap, low brick resonance, chain ticks",
		archive = "paper scrape, impossible shelf movement, courtroom hush",
		ritual = "glass pulse, reversed rain, buried choir without words",
		escape = "blackout roar, footsteps behind walls, first birds at dawn",
	},
})

Config.AssetManifest = table.freeze({
	{
		id = "blackwater_house_procedural",
		category = "Production-ready procedural/runtime construction",
		replacement = "Final bespoke model required before certification",
	},
	{
		id = "bailiff_proxy_silhouette",
		category = "Acceptable temporary asset",
		replacement = "Final rig, animation, and approved audio required",
	},
	{
		id = "glass_heart_proxy",
		category = "Acceptable temporary asset",
		replacement = "Final relic mesh/material required",
	},
	{
		id = "gaslight_runtime_parts",
		category = "Production-ready procedural/runtime construction",
		replacement = "Artist-authored gaslamp variants recommended",
	},
	{
		id = "audio_slots",
		category = "Blocked by missing external asset",
		replacement = "Approved music, ambience, foley, captions, and loop metadata required",
	},
})

return table.freeze(Config)
