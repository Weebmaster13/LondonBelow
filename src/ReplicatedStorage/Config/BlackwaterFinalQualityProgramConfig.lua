--!strict

local Config = {}

Config.SchemaVersion = "220.0.0"
Config.ProgramName = "Blackwater Descent Final Quality Program"
Config.CertificationState = "productionCandidate"

Config.Phases = table.freeze({
	{ phase = 209, name = "Final Audible World", evidence = "assetUploadBlocked" },
	{ phase = 210, name = "Production Environment Art", evidence = "proxyArtBlocked" },
	{ phase = 211, name = "Exploration and Interaction", evidence = "sourceIntegrated" },
	{ phase = 212, name = "Puzzle Production", evidence = "sourceIntegrated" },
	{ phase = 213, name = "Narrative and Cinematics", evidence = "sourceIntegrated" },
	{ phase = 214, name = "Horror Direction", evidence = "sourceIntegrated" },
	{ phase = 215, name = "Multiplayer Horror", evidence = "policyIntegrated" },
	{ phase = 216, name = "Accessibility and UX", evidence = "sourceIntegrated" },
	{ phase = 217, name = "Replayability", evidence = "sourceIntegrated" },
	{ phase = 218, name = "Performance and Stability", evidence = "measurementBlocked" },
	{ phase = 219, name = "Human Playtesting", evidence = "humanPlaytestRequired" },
	{ phase = 220, name = "Release Candidate", evidence = "releaseCandidateBlocked" },
})

Config.QualityPillars = table.freeze({
	"The World Remembers",
	"The Street Listens",
	"Authority Has Become Monstrous",
	"Knowledge Has a Cost",
	"Dawn Is Not Safety",
})

Config.AudibleWorld = table.freeze({
	{
		id = "street_rain_close",
		family = "exterior_world",
		priority = 4,
		caption = "Rain taps close to the player's shoulder.",
	},
	{
		id = "street_rain_far",
		family = "exterior_world",
		priority = 2,
		caption = "Distant rain softens the street.",
	},
	{
		id = "wet_cobble_walk",
		family = "player_footsteps",
		priority = 6,
		caption = "Wet cobblestone footstep.",
	},
	{
		id = "mud_drag",
		family = "player_footsteps",
		priority = 6,
		caption = "Mud pulls at a boot.",
	},
	{
		id = "timber_creak",
		family = "player_footsteps",
		priority = 6,
		caption = "Old timber complains under weight.",
	},
	{
		id = "bailiff_boot_formal",
		family = "bailiff_movement",
		priority = 9,
		caption = "A measured official step.",
	},
	{
		id = "bailiff_chain_still",
		family = "bailiff_movement",
		priority = 8,
		caption = "A chain becomes still.",
	},
	{
		id = "bailiff_tool_lift",
		family = "bailiff_movement",
		priority = 10,
		caption = "A heavy tool rises.",
	},
	{
		id = "door_latch_debt",
		family = "doors_interactions",
		priority = 7,
		caption = "A latch clicks like a stamp.",
	},
	{
		id = "ledger_page_wet",
		family = "doors_interactions",
		priority = 7,
		caption = "Wet paper turns without a hand.",
	},
	{
		id = "ward_low_tone",
		family = "wards_glass_heart",
		priority = 8,
		caption = "A ward hums below the floor.",
	},
	{
		id = "heart_bent_tone",
		family = "wards_glass_heart",
		priority = 8,
		caption = "Sound bends toward the Glass Heart.",
	},
	{
		id = "wrong_bell_final",
		family = "signature_events",
		priority = 9,
		caption = "A bell answers from the wrong room.",
	},
	{
		id = "blackout_air_cut",
		family = "signature_events",
		priority = 10,
		caption = "The air cuts out.",
	},
	{
		id = "dawn_bird_wrong",
		family = "signature_events",
		priority = 6,
		caption = "A dawn bird calls once, then stops.",
	},
	{
		id = "ui_threat_caption",
		family = "accessibility",
		priority = 10,
		caption = "Threat caption available.",
	},
})

Config.EnvironmentLayers = table.freeze({
	{
		id = "street_memory_mud",
		room = "victorian_street",
		layer = "recent",
		response = "records party movement",
		position = Vector3.new(-10, 0.35, 72),
		color = Color3.fromRGB(31, 28, 25),
	},
	{
		id = "gate_receipt_archive",
		room = "front_steps",
		layer = "historical",
		response = "connects Bailiff to legal debt",
		position = Vector3.new(0, 3, 22),
		color = Color3.fromRGB(113, 84, 47),
	},
	{
		id = "foyer_breath_wall",
		room = "foyer",
		layer = "supernatural",
		response = "marks house breathing moment",
		position = Vector3.new(-12, 5, -5),
		color = Color3.fromRGB(41, 37, 35),
	},
	{
		id = "archive_erased_names",
		room = "forbidden_archive",
		layer = "functional",
		response = "shows recordkeeping as threat",
		position = Vector3.new(8, 5, -84),
		color = Color3.fromRGB(72, 54, 36),
	},
	{
		id = "ward_countermark",
		room = "ward_chambers",
		layer = "supernatural",
		response = "reveals protection has a cost",
		position = Vector3.new(-8, 1, -72),
		color = Color3.fromRGB(112, 108, 88),
	},
	{
		id = "blackout_route_scrape",
		room = "escape_route",
		layer = "recent",
		response = "shows route changed during blackout",
		position = Vector3.new(18, 1, 112),
		color = Color3.fromRGB(52, 52, 48),
	},
	{
		id = "dawn_impossible_receipt",
		room = "escape_route",
		layer = "supernatural",
		response = "Dawn is not safety",
		position = Vector3.new(-18, 2, 120),
		color = Color3.fromRGB(132, 104, 64),
	},
})

Config.ExplorationSecrets = table.freeze({
	{
		id = "secret_receipt_lintel",
		method = "visual inconsistency",
		reward = "ending implication",
		requiredKnowledge = "look above threshold",
		missable = true,
	},
	{
		id = "secret_ward_countermark",
		method = "environmental pattern",
		reward = "puzzle assistance",
		requiredKnowledge = "compare ward symbols",
		missable = false,
	},
	{
		id = "secret_bailiff_route",
		method = "hidden observation",
		reward = "Bailiff patrol knowledge",
		requiredKnowledge = "wait in safe observation point",
		missable = true,
	},
	{
		id = "secret_heart_echo",
		method = "audio clue with caption equivalent",
		reward = "Glass Heart interpretation",
		requiredKnowledge = "read caption shift",
		missable = true,
	},
})

Config.PuzzleProduction = table.freeze({
	{
		id = "ledger_order",
		hintLevels = { "environmental", "contextual", "direct" },
		failureRecovery = "no hard reset",
	},
	{
		id = "ward_route",
		hintLevels = { "chalk route", "symbol relationship", "ordered action" },
		failureRecovery = "state preserved",
	},
	{
		id = "glass_heart_choice",
		hintLevels = { "reflection", "evidence relation", "ending consequence" },
		failureRecovery = "choice confirmation",
	},
})

Config.NarrativeBeats = table.freeze({
	{
		id = "arrival_question",
		essential = true,
		text = "Why did the street empty before anyone could testify?",
	},
	{
		id = "ledger_revelation",
		essential = true,
		text = "The records were changed after the disappearances.",
	},
	{
		id = "ward_reinterpretation",
		essential = true,
		text = "The wards protected testimony, not bodies.",
	},
	{
		id = "heart_truth",
		essential = true,
		text = "The Glass Heart remembers what the court erased.",
	},
	{
		id = "dawn_consequence",
		essential = true,
		text = "The party escapes, but one official receipt remains dry.",
	},
})

Config.HorrorPacing = table.freeze({
	{
		segment = "0-5",
		density = { "observation", "first_goal", "street_listens" },
		maxIntensity = 0.35,
	},
	{
		segment = "5-15",
		density = { "interaction", "threshold", "optional_clue" },
		maxIntensity = 0.5,
	},
	{
		segment = "15-30",
		density = { "Bailiff evidence", "puzzle", "search" },
		maxIntensity = 0.72,
	},
	{
		segment = "30-55",
		density = { "archive hunt", "ward pressure", "route decision" },
		maxIntensity = 0.82,
	},
	{
		segment = "55-80",
		density = { "Glass Heart", "blackout pursuit", "dawn release" },
		maxIntensity = 0.95,
	},
})

Config.MultiplayerRules = table.freeze({
	{ id = "objective_authority", scope = "per-party", rule = "server-owned progress only" },
	{
		id = "bailiff_targeting",
		scope = "server-authoritative",
		rule = "recent target cooldown prevents oscillation",
	},
	{
		id = "major_cinematics",
		scope = "per-player presentation",
		rule = "no forced global camera ownership",
	},
	{ id = "secret_discovery", scope = "shared party fact", rule = "case file updates once" },
	{
		id = "resource_use",
		scope = "shared visible consequence",
		rule = "lantern stability reports cost",
	},
})

Config.AccessibilityEquivalents = table.freeze({
	{
		cue = "Bailiff detection",
		text = "Bailiff is listening",
		visual = "HUD threat state",
		audio = "Bailiff cue",
		reducedMotion = "no shake",
	},
	{
		cue = "Attack anticipation",
		text = "Attack telegraph",
		visual = "state label",
		audio = "tool lift",
		reducedMotion = "no flash",
	},
	{
		cue = "Ward response",
		text = "Ward changed",
		visual = "objective feedback",
		audio = "ward tone",
		reducedMotion = "steady pulse",
	},
	{
		cue = "Blackout transition",
		text = "Blackout route changed",
		visual = "route label",
		audio = "air cut",
		reducedMotion = "fade",
	},
	{
		cue = "Escape direction",
		text = "Dawn route open",
		visual = "objective marker",
		audio = "dawn cue",
		reducedMotion = "static indicator",
	},
})

Config.ReplayVariations = table.freeze({
	{ id = "receipt_survives_dawn", category = "ending", trigger = "secret_receipt_lintel" },
	{ id = "bailiff_search_route_shift", category = "Bailiff", trigger = "secret_bailiff_route" },
	{ id = "ward_cost_revealed", category = "puzzle", trigger = "secret_ward_countermark" },
	{ id = "heart_echo_changes_caption", category = "narrative", trigger = "secret_heart_echo" },
})

Config.PerformanceBudgets = table.freeze({
	maxQualityParts = 48,
	maxRuntimeConnections = 32,
	maxPersistentLoops = 0,
	maxActivePrompts = 12,
	maxRuntimeSoundsWithoutApprovedAssets = 0,
	maxRemoteSurfaces = 0,
	maxDataStoreWrites = 0,
})

Config.PlaytestProtocol = table.freeze({
	"Where did you first understand Blackwater was listening?",
	"What did you believe the Bailiff could perceive?",
	"Which room was most distinctive?",
	"Which objective was least clear?",
	"What did you remember after escape?",
	"Did any scare feel unfair?",
	"Would you replay to see a different consequence?",
})

Config.ReleaseCandidateGates = table.freeze({
	staticValidation = true,
	sourceIntegration = true,
	studioRoute = false,
	humanPlaytest = false,
	performanceMeasured = false,
	finalAssets = false,
	zeroKnownSourceP0 = true,
	zeroKnownSourceP1 = true,
})

return table.freeze(Config)
