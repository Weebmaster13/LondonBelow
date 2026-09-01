--!strict

local Config = {}

Config.SchemaVersion = "207.0.0"
Config.PhaseName = "Blackwater Descent Whole-Game Quality Strike"
Config.CertificationState = "productionCandidate"

Config.OpeningBudgets = table.freeze({
	controlSeconds = 10,
	firstGoalSeconds = 30,
	firstInteractionSeconds = 60,
	firstUnsettlingEventSeconds = 180,
	houseEntrySeconds = 480,
	maxForcedCinematicSeconds = 12,
	maxMandatoryWords = 80,
})

Config.EnvironmentArrangements = table.freeze({
	{
		id = "spawn_street_newsstand",
		area = "Spawn street",
		landmark = "collapsed newsstand",
		clue = "Missing notices are pasted over yesterday's weather report.",
		position = Vector3.new(-18, 1.2, 82),
		size = Vector3.new(7, 3, 2),
		material = Enum.Material.Wood,
		color = Color3.fromRGB(72, 52, 36),
	},
	{
		id = "main_approach_wheel_rut",
		area = "Main approach",
		landmark = "water-filled wheel rut",
		clue = "A carriage turned toward Blackwater and never left a return track.",
		position = Vector3.new(8, 0.7, 50),
		size = Vector3.new(10, 0.4, 2),
		material = Enum.Material.Glass,
		color = Color3.fromRGB(35, 45, 50),
	},
	{
		id = "alley_washline",
		area = "Alley",
		landmark = "abandoned washline",
		clue = "Clothes hang soaked and freshly warm.",
		position = Vector3.new(-34, 5, 56),
		size = Vector3.new(1, 3, 10),
		material = Enum.Material.Fabric,
		color = Color3.fromRGB(78, 78, 72),
	},
	{
		id = "blackwater_gate_chain",
		area = "Blackwater gate",
		landmark = "receipt chain",
		clue = "The gate is locked by paperwork, not iron.",
		position = Vector3.new(0, 4, 24),
		size = Vector3.new(20, 0.4, 0.4),
		material = Enum.Material.Metal,
		color = Color3.fromRGB(118, 87, 47),
	},
	{
		id = "front_steps_boots",
		area = "Front steps",
		landmark = "wet boot marks",
		clue = "The prints pause at the threshold and face outward.",
		position = Vector3.new(-4, 1.1, 18),
		size = Vector3.new(6, 0.25, 4),
		material = Enum.Material.Slate,
		color = Color3.fromRGB(20, 22, 24),
	},
	{
		id = "entry_hall_portrait_turn",
		area = "Entry hall",
		landmark = "turned portraits",
		clue = "Every portrait has been turned toward the first visitor.",
		position = Vector3.new(-12, 7, -3),
		size = Vector3.new(0.4, 5, 7),
		material = Enum.Material.Wood,
		color = Color3.fromRGB(54, 38, 29),
	},
	{
		id = "main_corridor_service_bell",
		area = "Main corridor",
		landmark = "unwired service bell",
		clue = "The bell wire ends in a knot of hair.",
		position = Vector3.new(13, 5, -40),
		size = Vector3.new(2, 2, 0.5),
		material = Enum.Material.Metal,
		color = Color3.fromRGB(118, 82, 42),
	},
	{
		id = "archive_case_wall",
		area = "Archive",
		landmark = "case wall",
		clue = "Constable Vale circled one family name again and again.",
		position = Vector3.new(-15, 5, -74),
		size = Vector3.new(0.5, 7, 10),
		material = Enum.Material.Wood,
		color = Color3.fromRGB(86, 64, 42),
	},
	{
		id = "ward_area_chalk_route",
		area = "Ward area",
		landmark = "chalk route",
		clue = "Three symbols form a walking route, not a code.",
		position = Vector3.new(0, 1.2, -71),
		size = Vector3.new(15, 0.25, 5),
		material = Enum.Material.Marble,
		color = Color3.fromRGB(122, 117, 98),
	},
	{
		id = "basement_ledger_crate",
		area = "Basement route",
		landmark = "sealed crate",
		clue = "Blackwater stored tax ledgers below its own dead.",
		position = Vector3.new(11, -5, -108),
		size = Vector3.new(5, 4, 5),
		material = Enum.Material.Wood,
		color = Color3.fromRGB(58, 41, 31),
	},
	{
		id = "heart_chamber_reflection_basin",
		area = "Glass Heart chamber",
		landmark = "reflection basin",
		clue = "The basin reflects dawn before the gate opens.",
		position = Vector3.new(0, -8, -128),
		size = Vector3.new(8, 0.5, 8),
		material = Enum.Material.Glass,
		color = Color3.fromRGB(90, 117, 122),
	},
	{
		id = "escape_route_broken_lamp",
		area = "Escape route",
		landmark = "broken gaslamp",
		clue = "The last lamp points away from Blackwater House.",
		position = Vector3.new(18, 3, 104),
		size = Vector3.new(1, 7, 1),
		material = Enum.Material.Metal,
		color = Color3.fromRGB(120, 92, 54),
	},
})

Config.OptionalDiscoveries = table.freeze({
	{
		id = "microstory_constable_vale",
		label = "Inspect Vale's notice",
		reward = "Vale entered Blackwater to prove the street was being erased.",
		method = "optional prompt",
		replayValue = "explains later notebook motif",
		position = Vector3.new(-20, 2.8, 82),
	},
	{
		id = "microstory_carter_family",
		label = "Read the torn address",
		reward = "The Carter family left dinner set for four and returned as signatures.",
		method = "side-room prompt",
		replayValue = "adds civilian cost to the ward puzzle",
		position = Vector3.new(34, 2.5, 58),
	},
	{
		id = "microstory_bailiff_watch",
		label = "Look through the cracked glass",
		reward = "The Bailiff waits for noise, not for trespass.",
		method = "hidden observation",
		replayValue = "teaches stealth behavior",
		position = Vector3.new(-12, 4, -45),
	},
	{
		id = "secret_archive_order",
		label = "Trace the chalk route",
		reward = "The wards are a route through the house: lamp, seal, river.",
		method = "environmental riddle",
		replayValue = "puzzle assistance",
		position = Vector3.new(0, 1.6, -71),
	},
	{
		id = "secret_dawn_reflection",
		label = "Study the wrong reflection",
		reward = "Dawn arrives only for players who decide what truth leaves with them.",
		method = "Glass Heart clue",
		replayValue = "ending interpretation",
		position = Vector3.new(0, -7.3, -128),
	},
})

Config.SideBranches = table.freeze({
	{
		id = "side_alley_laundry",
		kind = "sideRoom",
		route = "slower safe detour",
		position = Vector3.new(-38, 1, 58),
		size = Vector3.new(12, 8, 18),
		reward = "microstory_carter_family",
	},
	{
		id = "coal_cellar_crawl",
		kind = "sideRoom",
		route = "dangerous fast route",
		position = Vector3.new(22, -4, -110),
		size = Vector3.new(10, 6, 16),
		reward = "shortcut knowledge",
	},
	{
		id = "watch_box_recess",
		kind = "sideRoom",
		route = "alternate safe route",
		position = Vector3.new(-24, 1, 32),
		size = Vector3.new(8, 7, 8),
		reward = "recovery light",
	},
})

Config.ShortcutRules = table.freeze({
	{
		id = "watch_box_to_front_steps",
		label = "Open watch-box latch",
		from = "watch_box_recess",
		to = "front_steps",
		requiresDiscovery = "microstory_constable_vale",
		risk = "low",
	},
	{
		id = "coal_cellar_to_archive",
		label = "Force the coal-cellar lift",
		from = "coal_cellar_crawl",
		to = "forbidden_archive",
		requiresDiscovery = "secret_archive_order",
		risk = "high",
	},
})

Config.ReactiveProps = table.freeze({
	{
		id = "reactive_gaslight_watch",
		trigger = "ignite_lantern",
		reaction = "tilt toward player",
		attribute = "StreetNoticed",
	},
	{
		id = "reactive_bell_wire",
		trigger = "read_ledger",
		reaction = "rings without wire",
		attribute = "WrongBellPrepared",
	},
	{
		id = "reactive_receipt_chain",
		trigger = "take_seal",
		reaction = "tightens across gate",
		attribute = "SealDebtMarked",
	},
	{
		id = "reactive_ward_dust",
		trigger = "ward_west",
		reaction = "reveals chalk route",
		attribute = "WardRouteVisible",
	},
	{
		id = "reactive_dawn_lamp",
		trigger = "escape_gate",
		reaction = "turns toward dawn",
		attribute = "DawnRouteOpen",
	},
})

Config.SignatureMoments = table.freeze({
	"first_sight_blackwater_house",
	"street_notices_you",
	"wrong_bell",
	"impossible_answered_footstep",
	"breathing_house",
	"first_bailiff_anticipation",
	"first_fair_bailiff_encounter",
	"ward_activation",
	"glass_heart_revelation",
	"blackout_escape_dawn",
})

Config.ResourceLoop = table.freeze({
	resource = "lanternStability",
	capacity = 100,
	startingValue = 72,
	costs = {
		safeRoute = 8,
		dangerousFastRoute = 24,
		hidingRecovery = 12,
		revealSecret = 10,
	},
	recoveries = {
		watchBox = 18,
		dawn = 100,
	},
})

return table.freeze(Config)
