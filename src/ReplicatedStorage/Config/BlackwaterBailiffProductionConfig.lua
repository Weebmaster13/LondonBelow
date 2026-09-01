--!strict

local Config = {}

Config.SchemaVersion = "208.0.0"
Config.PhaseName = "Blackwater Descent Bailiff Production Encounter Execution and Studio Evidence"
Config.CertificationState = "productionCandidate"

Config.DesignBiography = table.freeze({
	officialRole = "Borough bailiff and debt officer",
	grantedAuthorityBy = "Blackwater civil court and parish records",
	enforced = "debts, warrants, seizures, tenancy judgments, and missing-person dismissals",
	blackwaterPreservation = "The house preserved his authority after the records became more powerful than the truth.",
	playerAccusation = "The player is treated as an unrecorded witness who must be entered into the ledger.",
	searchReason = "He searches because every judgment requires evidence before sentence.",
	ledgerRelationship = "The ledger is his remaining court; altered pages change his confidence.",
	wardRelationship = "The wards interrupt his authority by forcing the house to testify against itself.",
	glassHeartRelationship = "The Glass Heart reflects the testimony he cannot destroy.",
	humanRemainder = "He still pauses before doors and listens like a man trained to serve papers in hostile rooms.",
	symbolicLayer = "Authority continues after justice has died.",
})

Config.VisualProductionSheet = table.freeze({
	frontSilhouette = "tall narrow coat, brass cheek-plate, ledger chain hanging at right side",
	sideSilhouette = "forward-leaning head, squared shoulders, long coat tail trailing behind boots",
	backSilhouette = "split coat seam, receipt chain crossing the spine, damaged court badge",
	distantSilhouette = "single vertical black figure broken by one brass line",
	lanternLitSilhouette = "brass mask and wet gloves read first; weapon remains low",
	blackoutSilhouette = "coat mass and receipt chain only; no glowing-eye dependency",
	attackSilhouette = "shoulder rotates first, tool lags, active window remains readable",
	recoverySilhouette = "weight falls through forward boot before he resets posture",
	colorPalette = "soot black coat, tarnished brass, wet leather, muted court red",
	materialPalette = "wool, brass, cracked leather, soaked paper, dull iron",
	damageProgression = "creases and torn legal papers increase after ward interruption",
	equipmentPlacement = "ledger chain at hip, judgment tool carried low, badge partly hidden",
	hands = "wet gloved hands, one index finger stained with ink",
	boots = "heavy leather boots with asymmetric drag",
	coatMovement = "controlled sway in patrol, violent delayed follow-through in pursuit",
	authorityInsignia = "damaged borough badge and court ribbon under the coat lapel",
	blackwaterCorruption = "receipts stitched into lining and water moving upward through fabric",
	readabilityLowGraphics = "brass line, coat block, and boot cadence remain readable without fine detail",
})

Config.AnimationStates = table.freeze({
	{ id = "controlled_idle", mode = "ControlledAuthority", duration = 2.4, hitbox = "inactive" },
	{ id = "formal_walk", mode = "ControlledAuthority", duration = 1.2, hitbox = "inactive" },
	{ id = "door_formal_pause", mode = "ControlledAuthority", duration = 1.1, hitbox = "inactive" },
	{ id = "room_scan_left", mode = "ControlledAuthority", duration = 1.6, hitbox = "inactive" },
	{ id = "room_scan_right", mode = "ControlledAuthority", duration = 1.6, hitbox = "inactive" },
	{ id = "listen_head_lead", mode = "Suspicion", duration = 1.3, hitbox = "inactive" },
	{ id = "listen_body_catchup", mode = "Suspicion", duration = 0.9, hitbox = "inactive" },
	{ id = "evidence_kneel", mode = "Suspicion", duration = 1.8, hitbox = "inactive" },
	{ id = "hiding_place_check_high", mode = "Searching", duration = 1.7, hitbox = "inactive" },
	{ id = "hiding_place_check_low", mode = "Searching", duration = 1.5, hitbox = "inactive" },
	{ id = "search_turn_broken", mode = "Searching", duration = 1.0, hitbox = "inactive" },
	{ id = "pursuit_stride_break", mode = "Pursuit", duration = 0.8, hitbox = "inactive" },
	{ id = "pursuit_turn_wide", mode = "Pursuit", duration = 0.7, hitbox = "inactive" },
	{ id = "attack_anticipation", mode = "Attack", duration = 1.15, hitbox = "telegraph" },
	{ id = "attack_active_sweep", mode = "Attack", duration = 0.42, hitbox = "active" },
	{ id = "attack_miss_weight", mode = "Recovery", duration = 0.8, hitbox = "inactive" },
	{ id = "recovery_tool_followthrough", mode = "Recovery", duration = 1.1, hitbox = "inactive" },
	{ id = "disengage_recompose", mode = "Recovery", duration = 1.4, hitbox = "inactive" },
	{ id = "scripted_withdrawal", mode = "Scripted", duration = 2.0, hitbox = "inactive" },
	{ id = "checkpoint_cleanup", mode = "Cleanup", duration = 0.6, hitbox = "inactive" },
})

Config.AIStates = table.freeze({
	{ id = "Dormant", maxDuration = 999, speed = 0, perceptionPolicy = "ignore" },
	{ id = "DistantPresence", maxDuration = 12, speed = 0, perceptionPolicy = "foreshadow" },
	{ id = "Patrol", maxDuration = 45, speed = 8, perceptionPolicy = "ambientEvidence" },
	{ id = "Pause", maxDuration = 6, speed = 0, perceptionPolicy = "listen" },
	{ id = "Listening", maxDuration = 7, speed = 0, perceptionPolicy = "soundEvidence" },
	{ id = "Suspicious", maxDuration = 15, speed = 6, perceptionPolicy = "rankEvidence" },
	{ id = "Investigating", maxDuration = 18, speed = 7, perceptionPolicy = "lastKnown" },
	{ id = "Searching", maxDuration = 22, speed = 5, perceptionPolicy = "hidingAndEnvironment" },
	{ id = "ConfirmedSight", maxDuration = 4, speed = 8, perceptionPolicy = "specificPlayer" },
	{ id = "Pursuit", maxDuration = 42, speed = 14, perceptionPolicy = "specificPlayer" },
	{
		id = "AttackAnticipation",
		maxDuration = 1.15,
		speed = 0,
		perceptionPolicy = "lockedTelegraph",
	},
	{ id = "AttackActive", maxDuration = 0.42, speed = 0, perceptionPolicy = "lockedHitbox" },
	{ id = "Miss", maxDuration = 0.8, speed = 0, perceptionPolicy = "none" },
	{ id = "Recovery", maxDuration = 1.4, speed = 0, perceptionPolicy = "none" },
	{ id = "LostTarget", maxDuration = 6, speed = 5, perceptionPolicy = "confidenceDecay" },
	{ id = "ExpandedSearch", maxDuration = 18, speed = 5, perceptionPolicy = "nearbyRooms" },
	{ id = "Disengagement", maxDuration = 10, speed = 6, perceptionPolicy = "cooldown" },
	{ id = "ScriptedWithdrawal", maxDuration = 8, speed = 7, perceptionPolicy = "authoredExit" },
	{ id = "Interrupted", maxDuration = 5, speed = 0, perceptionPolicy = "wardBreak" },
	{ id = "CheckpointCleanup", maxDuration = 2, speed = 0, perceptionPolicy = "cleanupOnly" },
})

Config.PerceptionEvidenceTypes = table.freeze({
	"directSight",
	"partialSight",
	"movementAtDistance",
	"playerGeneratedSound",
	"movingInteractiveObject",
	"doorMovement",
	"lanternActivation",
	"wardDisturbance",
	"teammateNoise",
	"scriptedNarrativeTrigger",
	"recentlyOccupiedHidingLocation",
	"lastKnownPosition",
	"suspiciousEnvironmentalChange",
})

Config.Encounters = table.freeze({
	{
		id = "street_sighting",
		purpose = "establish existence",
		state = "DistantPresence",
		attackAllowed = false,
	},
	{
		id = "front_threshold_shadow",
		purpose = "memorable threshold",
		state = "Pause",
		attackAllowed = false,
	},
	{
		id = "first_house_search",
		purpose = "teach sound and hiding",
		state = "Searching",
		attackAllowed = false,
	},
	{
		id = "gallery_partial_presence",
		purpose = "partial silhouette reward",
		state = "Patrol",
		attackAllowed = false,
	},
	{
		id = "archive_hunt",
		purpose = "combine puzzle pressure and patrol prediction",
		state = "Suspicious",
		attackAllowed = true,
	},
	{
		id = "ward_interruption",
		purpose = "choice between progress and hiding",
		state = "Interrupted",
		attackAllowed = false,
	},
	{
		id = "cellar_lost_target",
		purpose = "teach last-known search",
		state = "LostTarget",
		attackAllowed = true,
	},
	{
		id = "blackout_pursuit",
		purpose = "test learned rules during escape",
		state = "Pursuit",
		attackAllowed = true,
	},
})

Config.SearchPatterns = table.freeze({
	{
		id = "formal_room_sweep",
		checks = { "entry", "center", "primary_hiding" },
		recovery = "door_exit",
	},
	{
		id = "ledger_spiral",
		checks = { "evidence", "last_known", "secondary_hiding" },
		recovery = "confidence_decay",
	},
	{
		id = "broken_blackout_cutoff",
		checks = { "route_a", "route_b", "noise_origin" },
		recovery = "scripted_withdrawal",
	},
})

Config.HidingSpaceTypes = table.freeze({
	{ id = "wardrobe", readableCue = "door gap shadow", searchRisk = 0.22 },
	{ id = "under_table", readableCue = "cloth edge movement", searchRisk = 0.32 },
	{ id = "shadow_alcove", readableCue = "safe darkness silhouette", searchRisk = 0.42 },
})

Config.Distractions = table.freeze({
	{ id = "service_bell", evidenceType = "movingInteractiveObject", cost = "noise spike" },
	{ id = "ledger_drawer", evidenceType = "playerGeneratedSound", cost = "archive suspicion" },
	{ id = "lantern_shutter", evidenceType = "lanternActivation", cost = "lantern stability" },
})

Config.NavigationRecoveryTests = table.freeze({
	"path_to_archive",
	"path_to_foyer",
	"path_to_cellar",
	"path_to_escape",
	"blocked_door_recover",
	"checkpoint_cleanup_recover",
})

Config.AttackDistanceScenarios = table.freeze({
	{ id = "too_far", distance = 13, expected = "miss" },
	{ id = "edge_range", distance = 8, expected = "telegraphOnly" },
	{ id = "valid_front", distance = 5, expected = "hitIfUnblocked" },
	{ id = "obstructed", distance = 4, expected = "blockedMiss" },
	{ id = "recovery_window", distance = 3, expected = "noRepeatAttack" },
})

Config.MultiplayerTargetSwitchTests = table.freeze({
	"noise_owner_priority",
	"recent_target_cooldown",
	"dead_player_excluded",
	"late_join_protection",
})

Config.ChaseRouteAlternatives = table.freeze({
	archive_hunt = { "foyer_loop", "service_cutthrough" },
	blackout_pursuit = { "street_escape", "gallery_drop" },
})

return table.freeze(Config)
