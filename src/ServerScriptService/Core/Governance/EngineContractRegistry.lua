--!strict
--[[
	Registry of London Engine subsystem contracts.

	Owns contract registration, replacement, lookup, inspection, and the built-in
	contracts for the current major systems.

	Does not validate contract law by itself; validation belongs to
	EngineContractValidator and scoring belongs to EngineScorecard.
]]

local Types = require(script.Parent.EngineContractTypes)

local EngineContractRegistry = {}

type EngineContract = Types.EngineContract

local contracts: { [string]: EngineContract } = {}
local registrationOrder: { string } = {}

local function copyArray<T>(values: { T }): { T }
	return table.clone(values)
end

local function copyObservationRules(values: { Types.ObservationRule }): { Types.ObservationRule }
	local copied = {}

	for _, rule in ipairs(values) do
		table.insert(copied, {
			id = rule.id,
			when = rule.when,
			required = rule.required,
		})
	end

	return copied
end

local function copyApprovalRules(
	values: { Types.DirectorApprovalRule }
): { Types.DirectorApprovalRule }
	local copied = {}

	for _, rule in ipairs(values) do
		table.insert(copied, {
			director = rule.director,
			reason = rule.reason,
			requiredFor = copyArray(rule.requiredFor),
		})
	end

	return copied
end

local function copyExecutionPermissions(
	values: { Types.ExecutionPermission }
): { Types.ExecutionPermission }
	local copied = {}

	for _, permission in ipairs(values) do
		table.insert(copied, {
			action = permission.action,
			requiresApproval = permission.requiresApproval,
			approval = permission.approval,
		})
	end

	return copied
end

local function cloneContract(contract: EngineContract): EngineContract
	return {
		systemName = contract.systemName,
		ownerLayer = contract.ownerLayer,
		status = contract.status,
		responsibilities = copyArray(contract.responsibilities),
		doesNotOwn = copyArray(contract.doesNotOwn),
		dependencies = copyArray(contract.dependencies),
		observationsEmitted = copyObservationRules(contract.observationsEmitted),
		directorApprovalsRequired = copyApprovalRules(contract.directorApprovalsRequired),
		executionPermissions = copyExecutionPermissions(contract.executionPermissions),
		clientPresentation = {
			allowed = contract.clientPresentation.allowed,
			description = contract.clientPresentation.description,
			mustBeServerApproved = contract.clientPresentation.mustBeServerApproved,
		},
		diagnosticsExposed = copyArray(contract.diagnosticsExposed),
		snapshotProviders = copyArray(contract.snapshotProviders),
		cleanupBehavior = copyArray(contract.cleanupBehavior),
		multiplayerGuarantees = copyArray(contract.multiplayerGuarantees),
		failureModes = copyArray(contract.failureModes),
		documentation = copyArray(contract.documentation),
		tags = copyArray(contract.tags),
	}
end

local function registerBuiltIn(contract: EngineContract)
	contracts[contract.systemName] = cloneContract(contract)
	table.insert(registrationOrder, contract.systemName)
end

local builtInContracts: { EngineContract } = {
	{
		systemName = "Core Runtime",
		ownerLayer = "Core",
		status = "Production",
		responsibilities = {
			"Framework lifecycle",
			"runtime observability",
			"inter-service messaging",
			"scheduler ownership",
			"dependency validation",
			"remote definitions and validation",
			"governance",
		},
		doesNotOwn = {
			"chapter gameplay",
			"horror pacing",
			"monster movement",
			"client presentation",
		},
		dependencies = {},
		observationsEmitted = {},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = false,
			description = "Core Runtime is server-only infrastructure.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "Diagnostics", "Logger", "Scheduler", "RemoteManager" },
		snapshotProviders = { "diagnostics", "events", "scheduler", "services", "remotes" },
		cleanupBehavior = { "Framework.shutdown cancels Scheduler and publishes shutdown" },
		multiplayerGuarantees = { "server-authoritative runtime", "no client-owned truth" },
		failureModes = { "refuses startup on required dependency failure" },
		documentation = { "LONDON_ENGINE.md", "ARCHITECTURE.md", "SYSTEMS.md" },
		tags = { "core", "runtime", "server" },
	},
	{
		systemName = "Lobby Runtime",
		ownerLayer = "Lobby",
		status = "Production",
		responsibilities = {
			"party truth",
			"ready state",
			"chapter selection",
			"matchmaking handoff",
			"launch feedback",
		},
		doesNotOwn = {
			"chapter gameplay",
			"horror pacing",
			"teleport place content",
			"client-owned party truth",
		},
		dependencies = { "Core Runtime" },
		observationsEmitted = {},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Clients may display party and launch state only.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = {
			"LobbyService.inspect",
			"PartyService.inspect",
			"MatchmakingService.inspect",
		},
		snapshotProviders = { "lobby" },
		cleanupBehavior = { "disconnect remotes", "remove players from parties on leave" },
		multiplayerGuarantees = {
			"server-owned membership",
			"duplicate party prevention",
			"disconnect handling",
		},
		failureModes = { "structured launch failure", "invalid request rejection" },
		documentation = { "LOBBY_RUNTIME.md", "LOBBY_DESIGN.md" },
		tags = { "lobby", "party", "server" },
	},
	{
		systemName = "Portal Runtime",
		ownerLayer = "Portal",
		status = "Production",
		responsibilities = {
			"portal state",
			"boarding validation",
			"countdown",
			"zone tracking",
			"cinematic hooks",
			"launch handoff",
		},
		doesNotOwn = {
			"final art",
			"chapter gameplay",
			"teleport bypass",
			"monster pressure",
		},
		dependencies = { "Core Runtime", "Lobby Runtime" },
		observationsEmitted = {},
		directorApprovalsRequired = {},
		executionPermissions = {
			{
				action = "request launch through MatchmakingService",
				requiresApproval = false,
				approval = nil,
			},
		},
		clientPresentation = {
			allowed = true,
			description = "Clients may display countdown, fades, and portal debug state.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "PortalService.inspect" },
		snapshotProviders = { "portal runtime state through lobby diagnostics" },
		cleanupBehavior = { "cancel countdowns", "disconnect zones", "recover failed launch" },
		multiplayerGuarantees = {
			"party validation",
			"double-launch prevention",
			"disconnect recovery",
		},
		failureModes = { "failed teleport recovery", "missing zone safe no-op" },
		documentation = { "PORTAL_RUNTIME.md", "PORTAL_REVIEW.md", "PORTAL_STUDIO_SETUP.md" },
		tags = { "portal", "lobby", "execution" },
	},
	{
		systemName = "Observation Engine",
		ownerLayer = "Observation",
		status = "Production",
		responsibilities = {
			"trusted fact intake",
			"validation and enrichment",
			"aggregation and memory",
			"timeline recording",
			"pattern recognition",
			"director forwarding",
		},
		doesNotOwn = {
			"gameplay execution",
			"horror interpretation",
			"monster movement",
			"client presentation",
			"analytics export",
		},
		dependencies = { "Core Runtime" },
		observationsEmitted = {
			{ id = "Observation.Accepted", when = "trusted server fact accepted", required = true },
		},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = false,
			description = "Observation Engine is server-only truth processing.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "ObservationService.inspect", "ObservationProfiler.inspect" },
		snapshotProviders = { "observationEngine" },
		cleanupBehavior = {
			"clear memory",
			"clear timelines",
			"clear pattern state",
			"disconnect EventBus",
		},
		multiplayerGuarantees = {
			"active Player validation",
			"bounded metadata",
			"server-only intake",
		},
		failureModes = { "reject malformed observations", "log validation failures" },
		documentation = { "OBSERVATION_ENGINE.md", "ENGINE_CONSTITUTION.md" },
		tags = { "observation", "truth", "server" },
	},
	{
		systemName = "Psychological Horror Director",
		ownerLayer = "Director",
		status = "Production",
		responsibilities = {
			"fear pacing",
			"tension",
			"silence",
			"scare opportunity selection",
			"cooldowns",
			"pressure rhythm",
		},
		doesNotOwn = {
			"monster movement",
			"chapter climax",
			"story canon",
			"final audio playback",
			"final lighting playback",
			"client presentation",
		},
		dependencies = { "Core Runtime", "Observation Engine" },
		observationsEmitted = {},
		directorApprovalsRequired = {},
		executionPermissions = {
			{ action = "publish scare opportunity", requiresApproval = false, approval = "Horror" },
		},
		clientPresentation = {
			allowed = false,
			description = "Director publishes decisions; presentation systems render later.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "HorrorDirector.inspect" },
		snapshotProviders = { "horrorDirector" },
		cleanupBehavior = {
			"cancel evaluation task",
			"disconnect EventBus",
			"clear profile memory",
		},
		multiplayerGuarantees = {
			"server-owned decisions",
			"round-robin evaluation",
			"cooldown fairness",
		},
		failureModes = {
			"silence instead of unsafe scare",
			"validation refusal on invalid registry",
		},
		documentation = { "HORROR_DIRECTOR.md", "HORROR_DIRECTOR_REVIEW.md" },
		tags = { "director", "horror", "pacing" },
	},
	{
		systemName = "Director Ecosystem Foundation",
		ownerLayer = "Director",
		status = "Production",
		responsibilities = {
			"director discovery",
			"director lifecycle",
			"request approval routing",
			"conflict resolution",
			"capability registry",
			"decision traces",
			"director diagnostics",
		},
		doesNotOwn = {
			"gameplay execution",
			"Monster AI movement",
			"final audio playback",
			"final lighting playback",
			"chapter content",
		},
		dependencies = { "Core Runtime", "Observation Engine" },
		observationsEmitted = {},
		directorApprovalsRequired = {},
		executionPermissions = {
			{
				action = "resolve Director approval requests",
				requiresApproval = false,
				approval = nil,
			},
		},
		clientPresentation = {
			allowed = false,
			description = "Director Ecosystem is server-only interpretation and approval architecture.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "DirectorCoordinator.inspect" },
		snapshotProviders = { "directorCoordinator" },
		cleanupBehavior = {
			"shutdown directors in reverse order",
			"disconnect Observation Engine routing",
			"clear pending requests",
			"cancel expiration sweeps",
		},
		multiplayerGuarantees = {
			"server-only approvals",
			"observations are trusted server facts",
			"failed directors are isolated",
		},
		failureModes = {
			"defer gated requests",
			"reject missing target directors",
			"isolate failing director calls",
		},
		documentation = {
			"DIRECTOR_ECOSYSTEM.md",
			"DIRECTOR_COORDINATOR.md",
			"DIRECTOR_CONTRACTS.md",
			"DIRECTOR_REQUESTS.md",
			"DIRECTOR_APPROVALS.md",
			"DIRECTOR_CAPABILITIES.md",
			"DIRECTOR_FAILURES.md",
		},
		tags = { "director", "coordinator", "architecture" },
	},
	{
		systemName = "Environment Director",
		ownerLayer = "Director",
		status = "Production",
		responsibilities = {
			"environmental reaction approvals",
			"world pressure state",
			"zone pressure context",
			"environment memory",
			"reaction cooldowns",
			"execution bridge contracts",
			"environment diagnostics",
		},
		doesNotOwn = {
			"monster movement",
			"final audio playback",
			"final lighting playback",
			"puzzle truth",
			"story canon",
			"final art",
			"client-owned weather truth",
			"Chapter 1 content",
			"physical object movement without execution bridge approval",
		},
		dependencies = { "Core Runtime", "Observation Engine", "Director Ecosystem Foundation" },
		observationsEmitted = {},
		directorApprovalsRequired = {
			{
				director = "Narrative",
				reason = "Major building attention should respect future narrative beats.",
				requiredFor = {
					"major BuildingAttention reactions",
					"chapter-critical environment pressure",
				},
			},
		},
		executionPermissions = {
			{
				action = "publish server-side environment execution bridge requests",
				requiresApproval = true,
				approval = "Environment",
			},
		},
		clientPresentation = {
			allowed = false,
			description = "Clients may later present approved execution results only; they never own environment truth.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "EnvironmentDirector.inspect" },
		snapshotProviders = { "environmentDirector" },
		cleanupBehavior = {
			"cancel cooldown cleanup task",
			"disconnect EventBus subscriptions",
			"clear environment memory",
			"clear zone context",
			"clear execution bridge diagnostics",
		},
		multiplayerGuarantees = {
			"server-only approvals",
			"group size considered during selection",
			"safe room and puzzle fairness suppression",
			"bounded memory and cooldowns",
		},
		failureModes = {
			"malformed requests are rejected",
			"unfair reactions become silence or deferral",
			"execution bridge failures are recorded without world mutation",
		},
		documentation = {
			"ENVIRONMENT_DIRECTOR.md",
			"ENVIRONMENT_REACTIONS.md",
			"ENVIRONMENT_ZONES.md",
			"ENVIRONMENT_EXECUTION.md",
		},
		tags = { "director", "environment", "horror", "server" },
	},
	{
		systemName = "Lighting Director",
		ownerLayer = "Director",
		status = "Production",
		responsibilities = {
			"lighting pressure approvals",
			"World Intelligence lighting policy enforcement",
			"safe-room lighting protection",
			"puzzle-room lighting protection",
			"lighting diagnostics",
		},
		doesNotOwn = {
			"Roblox Lighting mutation",
			"Workspace mutation",
			"client presentation",
			"final lighting art",
			"monster movement",
			"Chapter 1 content",
		},
		dependencies = {
			"Core Runtime",
			"Director Ecosystem Foundation",
			"Observation Engine",
			"Environment Director",
		},
		observationsEmitted = {},
		directorApprovalsRequired = {
			{
				director = "Environment",
				reason = "Lighting pressure should respect world reaction pressure and environmental fairness.",
				requiredFor = {
					"future physical lighting execution",
					"major visibility pressure",
				},
			},
		},
		executionPermissions = {
			{
				action = "approve future lighting pressure only",
				requiresApproval = true,
				approval = "Lighting",
			},
		},
		clientPresentation = {
			allowed = false,
			description = "Lighting Director approves server-side decisions only; future clients may present approved execution results.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "LightingDirector.inspect" },
		snapshotProviders = { "lightingDirector" },
		cleanupBehavior = {
			"cancel cooldown cleanup task",
			"clear lighting pressure state",
			"clear recent decisions and suppressions",
		},
		multiplayerGuarantees = {
			"server-only approvals",
			"World Intelligence policy enforced",
			"safe-room and puzzle-room suppression",
			"bounded memory and cooldowns",
		},
		failureModes = {
			"malformed requests are rejected",
			"unknown zones deny major lighting pressure",
			"unsafe pressure is deferred with reason",
		},
		documentation = { "LIGHTING_DIRECTOR.md", "SENSORY_DIRECTORS.md" },
		tags = { "director", "lighting", "sensory", "server" },
	},
	{
		systemName = "Audio Director",
		ownerLayer = "Director",
		status = "Production",
		responsibilities = {
			"audio pressure approvals",
			"World Intelligence audio policy enforcement",
			"safe-room audio protection",
			"puzzle-room audio protection",
			"audio diagnostics",
		},
		doesNotOwn = {
			"sound playback",
			"final audio assets",
			"client presentation",
			"music score",
			"monster movement",
			"Chapter 1 content",
		},
		dependencies = {
			"Core Runtime",
			"Director Ecosystem Foundation",
			"Observation Engine",
			"Environment Director",
		},
		observationsEmitted = {},
		directorApprovalsRequired = {
			{
				director = "Environment",
				reason = "Audio pressure should respect environmental pressure and world fairness.",
				requiredFor = {
					"future physical audio execution",
					"major audio pressure",
				},
			},
		},
		executionPermissions = {
			{
				action = "approve future audio pressure only",
				requiresApproval = true,
				approval = "Audio",
			},
		},
		clientPresentation = {
			allowed = false,
			description = "Audio Director approves server-side decisions only; future clients may present approved execution results.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "AudioDirector.inspect" },
		snapshotProviders = { "audioDirector" },
		cleanupBehavior = {
			"cancel cooldown cleanup task",
			"clear audio pressure state",
			"clear recent decisions and suppressions",
		},
		multiplayerGuarantees = {
			"server-only approvals",
			"World Intelligence policy enforced",
			"safe-room and puzzle-room suppression",
			"bounded memory and cooldowns",
		},
		failureModes = {
			"malformed requests are rejected",
			"unknown zones deny major audio pressure",
			"unsafe pressure is deferred with reason",
		},
		documentation = { "AUDIO_DIRECTOR.md", "SENSORY_DIRECTORS.md" },
		tags = { "director", "audio", "sensory", "server" },
	},
	{
		systemName = "Player Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"player lifecycle state",
			"movement state hooks",
			"lock state",
			"room area chapter hooks",
			"player diagnostics",
		},
		doesNotOwn = {
			"client camera presentation",
			"interaction execution",
			"horror pacing",
			"save persistence",
			"Monster AI",
		},
		dependencies = { "Core Runtime", "Observation Engine" },
		observationsEmitted = {
			{ id = "Movement.Walk", when = "server accepts player walking state", required = true },
			{ id = "Movement.StartSprint", when = "server accepts sprint state", required = true },
			{ id = "Movement.StopSprint", when = "server detects sprint release", required = true },
			{ id = "Movement.Jump", when = "server accepts jump state", required = true },
			{ id = "Movement.Land", when = "server detects airborne release", required = true },
			{ id = "Movement.Crouch", when = "server accepts crouch state", required = true },
		},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Clients may request movement intent and render local movement presentation.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "PlayerService.inspect", "PlayerControllerService.inspect" },
		snapshotProviders = { "playerRuntime" },
		cleanupBehavior = {
			"disconnect player lifecycle signals",
			"clear per-player runtime state",
		},
		multiplayerGuarantees = {
			"server-owned lifecycle state",
			"per-player state cleanup on leave",
			"movement requests are validated before observations",
		},
		failureModes = {
			"safe default state for joining players",
			"movement profiles fall back to defaults",
		},
		documentation = { "PLAYER_EXPERIENCE.md", "PLAYER_RUNTIME.md" },
		tags = { "gameplay", "player", "runtime" },
	},
	{
		systemName = "Interaction Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"interaction validation",
			"interactable registration",
			"interaction state",
			"object execution handoff",
			"feedback routing",
		},
		doesNotOwn = {
			"client-owned interaction truth",
			"inventory persistence",
			"puzzle answers",
			"horror pacing",
			"final UI art",
		},
		dependencies = { "Core Runtime", "Observation Engine", "RemoteManager", "Player Runtime" },
		observationsEmitted = {
			{
				id = "Interaction.Begin",
				when = "server accepts interaction attempt",
				required = true,
			},
			{ id = "Interaction.Complete", when = "server completes interaction", required = true },
			{ id = "Interaction.Cancel", when = "interaction is cancelled", required = true },
			{ id = "Interaction.Fail", when = "server rejects interaction", required = true },
			{
				id = "Interaction.OpenDoor",
				when = "server applies door interaction",
				required = true,
			},
			{
				id = "Interaction.ReadNote",
				when = "server accepts note interaction",
				required = true,
			},
		},
		directorApprovalsRequired = {},
		executionPermissions = {
			{
				action = "apply reusable object interaction state after validation",
				requiresApproval = false,
				approval = nil,
			},
		},
		clientPresentation = {
			allowed = true,
			description = "Clients may render prompts and approved feedback instructions only.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "InteractionService.inspect" },
		snapshotProviders = { "playerExperience.interactions" },
		cleanupBehavior = {
			"disconnect CollectionService signals through PlayerExperienceService",
			"clear interaction state and feedback state on shutdown",
		},
		multiplayerGuarantees = {
			"server-authoritative range validation",
			"server-authoritative line-of-sight validation",
			"RemoteManager rate limits",
		},
		failureModes = {
			"reject malformed requests",
			"reject disabled or locked interactions",
			"fail closed when interactable config is invalid",
		},
		documentation = { "INTERACTION_RUNTIME.md", "INTERACTION_FRAMEWORK.md" },
		tags = { "gameplay", "interaction", "runtime" },
	},
	{
		systemName = "Lantern Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"server-owned lantern equipped state",
			"server-owned lantern on/off state",
			"battery and fuel hooks",
			"lantern overuse tracking",
			"lantern observations",
			"presentation-hook remotes",
		},
		doesNotOwn = {
			"final lighting effects",
			"final audio playback",
			"client-owned lantern truth",
			"Chapter 1 content",
			"Monster AI",
		},
		dependencies = {
			"Core Runtime",
			"Observation Engine",
			"Director Ecosystem Foundation",
			"RemoteManager",
			"Lighting Director",
			"Audio Director",
			"World Intelligence",
		},
		observationsEmitted = {
			{ id = "Lantern.Equipped", when = "server equips lantern", required = true },
			{ id = "Lantern.Unequipped", when = "server unequips lantern", required = true },
			{ id = "Lantern.TurnedOn", when = "server accepts lantern on", required = true },
			{ id = "Lantern.TurnedOff", when = "server accepts lantern off", required = true },
			{ id = "Lantern.LowBattery", when = "battery hook crosses threshold", required = true },
			{
				id = "Lantern.Overused",
				when = "lantern overuse crosses threshold",
				required = true,
			},
		},
		directorApprovalsRequired = {
			{
				director = "Lighting",
				reason = "Lantern presentation pressure must be approved before future execution.",
				requiredFor = { "future lantern lighting presentation" },
			},
			{
				director = "Audio",
				reason = "Lantern overuse audio pressure must be approved before future playback.",
				requiredFor = { "future lantern overuse audio presentation" },
			},
		},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Client may request toggle and render server-approved presentation hooks only.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "LanternService.inspect" },
		snapshotProviders = { "lanternService" },
		cleanupBehavior = {
			"disconnect lantern remotes",
			"clear per-player lantern state",
		},
		multiplayerGuarantees = {
			"server-owned lantern truth",
			"RemoteManager rate limits",
			"per-player cleanup on leave",
		},
		failureModes = {
			"malformed toggle requests are rejected",
			"unequipped lantern cannot toggle",
			"Director requests are approval-only",
		},
		documentation = { "LANTERN_SYSTEM.md", "LANTERN_DARKNESS_REVIEW.md" },
		tags = { "gameplay", "lantern", "server" },
	},
	{
		systemName = "Darkness Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"server-owned darkness exposure truth",
			"safe-room darkness protection",
			"puzzle-room readability protection",
			"darkness observations",
			"Director request hooks",
		},
		doesNotOwn = {
			"client-owned darkness truth",
			"final lighting effects",
			"final audio playback",
			"Chapter 1 content",
			"Monster AI",
		},
		dependencies = {
			"Core Runtime",
			"Observation Engine",
			"Director Ecosystem Foundation",
			"Lighting Director",
			"Audio Director",
			"Environment Director",
			"World Intelligence",
		},
		observationsEmitted = {
			{ id = "Darkness.Entered", when = "server detects darkness entry", required = true },
			{ id = "Darkness.Exited", when = "server detects darkness exit", required = true },
			{
				id = "Darkness.ExposureIncreased",
				when = "server exposure score increases",
				required = true,
			},
			{
				id = "Darkness.ProtectedZone",
				when = "unknown, safe, or puzzle zone suppresses darkness pressure",
				required = true,
			},
		},
		directorApprovalsRequired = {
			{
				director = "Lighting",
				reason = "Darkness sensory pressure requires Lighting Director approval.",
				requiredFor = { "future darkness visibility pressure" },
			},
			{
				director = "Audio",
				reason = "Darkness audio pressure requires Audio Director approval.",
				requiredFor = { "future darkness heartbeat or breathing pressure" },
			},
			{
				director = "Environment",
				reason = "Darkness environmental pressure requires Environment Director approval.",
				requiredFor = { "future darkness room pressure" },
			},
		},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Future clients may present server-approved darkness feedback only.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "DarknessService.inspect" },
		snapshotProviders = { "darknessService" },
		cleanupBehavior = {
			"cancel exposure update task",
			"clear per-player exposure state",
		},
		multiplayerGuarantees = {
			"server-owned exposure truth",
			"per-player cleanup on leave",
			"unknown zones fail protected",
		},
		failureModes = {
			"unknown zones suppress hostile pressure",
			"safe rooms suppress hostile pressure",
			"puzzle rooms protect readability",
		},
		documentation = { "DARKNESS_SYSTEM.md", "LANTERN_DARKNESS_REVIEW.md" },
		tags = { "gameplay", "darkness", "server" },
	},
	{
		systemName = "Gameplay Intelligence Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"coordinate reusable gameplay truth modules",
			"expose gameplay diagnostics and snapshots",
			"preserve data-driven gameplay architecture",
			"validate runtime self-checks",
		},
		doesNotOwn = {
			"Chapter 1 content",
			"Monster AI",
			"final UI or art",
			"horror pacing",
			"Workspace mutation",
		},
		dependencies = {
			"Core Runtime",
			"Observation Engine",
			"Director Ecosystem Foundation",
			"World Intelligence",
		},
		observationsEmitted = {
			{
				id = "Gameplay.ObjectInteracted",
				when = "object runtime accepts interaction",
				required = true,
			},
			{
				id = "Gameplay.ObjectStateChanged",
				when = "object runtime changes state",
				required = true,
			},
		},
		directorApprovalsRequired = {
			{
				director = "Environment",
				reason = "Gameplay pressure hooks require Director approval before future execution.",
				requiredFor = { "future object or puzzle pressure presentation" },
			},
		},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Future clients may present server-approved gameplay state only.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "GameplayCoordinator.inspect" },
		snapshotProviders = { "gameplayIntelligence" },
		cleanupBehavior = { "clear all runtime registries, state, and gameplay memory on shutdown" },
		multiplayerGuarantees = {
			"server owns gameplay truth",
			"client cannot create inventory, key, door, objective, or puzzle truth",
			"runtime state is data-only and reusable",
		},
		failureModes = {
			"duplicate ids reject",
			"missing dependencies reject",
			"invalid state transitions reject",
		},
		documentation = { "GAMEPLAY_INTELLIGENCE.md", "GAMEPLAY_DIAGNOSTICS.md" },
		tags = { "gameplay", "intelligence", "server" },
	},
	{
		systemName = "Object Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"register reusable object definitions",
			"track object state truth",
			"validate allowed states",
			"expose object diagnostics",
		},
		doesNotOwn = {
			"physical objects",
			"animations",
			"Chapter 1 object scripts",
			"horror pacing",
		},
		dependencies = { "Gameplay Intelligence Runtime", "Observation Engine" },
		observationsEmitted = {
			{
				id = "Gameplay.ObjectInteracted",
				when = "server records interaction",
				required = true,
			},
			{
				id = "Gameplay.ObjectStateChanged",
				when = "server changes object state",
				required = true,
			},
		},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Future clients may display prompts from server object state.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "ObjectRuntime.inspect" },
		snapshotProviders = { "gameplayIntelligence.objects" },
		cleanupBehavior = { "clear object registry and state on shutdown" },
		multiplayerGuarantees = { "server-owned object state", "duplicate object ids reject" },
		failureModes = { "unknown objects reject", "invalid states reject" },
		documentation = { "OBJECT_RUNTIME.md" },
		tags = { "gameplay", "objects", "server" },
	},
	{
		systemName = "Gameplay Execution Bridge",
		ownerLayer = "Execution",
		status = "Production",
		responsibilities = {
			"validate server-owned execution requests",
			"queue future physical and presentation execution safely",
			"route approved requests to opt-in adapters",
			"enforce dry-run or disabled default mode",
			"expose execution diagnostics and snapshots",
		},
		doesNotOwn = {
			"gameplay truth",
			"client remotes",
			"Chapter 1 content",
			"Monster AI",
			"final UI, art, sounds, or scares",
			"horror pacing decisions",
		},
		dependencies = {
			"Core Runtime",
			"Gameplay Intelligence Runtime",
			"Director Ecosystem Foundation",
		},
		observationsEmitted = {},
		directorApprovalsRequired = {
			{
				director = "Environment",
				reason = "Major future environmental execution requires Director approval metadata before routing.",
				requiredFor = {
					"environmental object response",
					"puzzle panel feedback",
					"objective marker presentation",
				},
			},
		},
		executionPermissions = {
			{
				action = "Route approved gameplay execution hooks to registered adapters only",
				requiresApproval = true,
				approval = "Environment",
			},
		},
		clientPresentation = {
			allowed = false,
			description = "Execution Bridge is server-only and creates no client remotes.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "GameplayExecutionService.inspect" },
		snapshotProviders = { "gameplayExecutionBridge" },
		cleanupBehavior = {
			"cancel cleanup task",
			"clear queue, locks, adapters, and execution records on shutdown",
		},
		multiplayerGuarantees = {
			"per-object lock foundation prevents overlapping execution leases",
			"duplicate execution ids reject",
			"failed or rejected execution does not alter gameplay truth",
		},
		failureModes = {
			"unknown execution kinds reject",
			"missing target objects reject",
			"expired requests reject or expire from queue",
			"missing adapter defers safely unless dry-run applies without mutation",
		},
		documentation = {
			"GAMEPLAY_EXECUTION_BRIDGE.md",
			"EXECUTION_SAFETY.md",
			"EXECUTION_CONTRACTS.md",
		},
		tags = { "gameplay", "execution", "server", "bridge" },
	},
	{
		systemName = "Monster Intelligence Foundation",
		ownerLayer = "AI",
		status = "Production",
		responsibilities = {
			"own server-authoritative monster knowledge and memory",
			"score interest, curiosity, threat, patience, territory, and search priority",
			"produce explainable monster intentions",
			"coordinate shared investigation claims and shared believed facts",
			"expose diagnostics, snapshots, and self-check evidence",
		},
		doesNotOwn = {
			"Monster AI movement",
			"pathfinding",
			"navigation",
			"NPC spawning",
			"animations",
			"attacks or damage",
			"Workspace mutation",
			"sound playback",
			"Lighting mutation",
			"client remotes",
			"Chapter 1 content",
			"horror pacing ownership",
		},
		dependencies = {
			"Core Runtime",
			"Observation Engine",
			"Director Ecosystem Foundation",
			"Gameplay Execution Bridge",
			"London Bible canon",
		},
		observationsEmitted = {},
		directorApprovalsRequired = {
			{
				director = "Monster",
				reason = "Future monster execution may only consume Director-approved intentions.",
				requiredFor = {
					"monster reveal",
					"stalk pressure",
					"investigation escalation",
					"chase permission",
				},
			},
			{
				director = "Horror",
				reason = "Monster pressure must not own global horror pacing.",
				requiredFor = {
					"major scare pressure",
					"high-tension monster attention",
				},
			},
		},
		executionPermissions = {
			{
				action = "Request intent-only future execution records",
				requiresApproval = true,
				approval = "Monster",
			},
		},
		clientPresentation = {
			allowed = false,
			description = "Monster Intelligence is server-only and creates no client remotes.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "MonsterIntelligenceCoordinator.inspect" },
		snapshotProviders = { "monsterIntelligence" },
		cleanupBehavior = {
			"cancel cleanup task",
			"clear monster registry, memory, knowledge, claims, and decision history on shutdown",
		},
		multiplayerGuarantees = {
			"server owns monster intent truth",
			"duplicate monster ids reject",
			"duplicate investigation claims reject",
			"future Monster AI cannot decide intent",
		},
		failureModes = {
			"unknown monsters reject intent requests",
			"unsafe execution fields reject",
			"invalid confidence and interest values reject",
			"invalid state transitions reject",
			"memory and diagnostics remain bounded",
		},
		documentation = {
			"MONSTER_INTELLIGENCE.md",
			"MONSTER_MEMORY.md",
			"MONSTER_BEHAVIOR.md",
			"MONSTER_GROUPS.md",
			"MONSTER_KNOWLEDGE.md",
			"MONSTER_INTEREST.md",
			"MONSTER_DIAGNOSTICS.md",
		},
		tags = { "ai", "monster-intelligence", "server", "intent-only" },
	},
	{
		systemName = "Horror Orchestration Framework",
		ownerLayer = "Horror",
		status = "Production",
		responsibilities = {
			"coordinate cross-system horror pressure",
			"own bounded pressure budget and release/silence decisions",
			"protect emotional beats, safe rooms, and puzzle readability",
			"bundle approval-only requests for sensory, environment, monster, gameplay, and narrative systems",
			"expose diagnostics, snapshots, and self-checks",
		},
		doesNotOwn = {
			"gameplay truth",
			"Monster AI",
			"monster movement",
			"pathfinding",
			"damage",
			"animations",
			"Lighting mutation",
			"audio playback",
			"Workspace mutation",
			"final UI",
			"final scares",
			"chapter content",
			"client authority",
		},
		dependencies = {
			"Core Runtime",
			"Observation Engine",
			"Director Ecosystem Foundation",
			"Psychological Horror Director",
			"Environment Director",
			"Lighting Director",
			"Audio Director",
			"Monster Intelligence Foundation",
			"Gameplay Intelligence Runtime",
			"Gameplay Execution Bridge",
			"London Bible canon",
		},
		observationsEmitted = {},
		directorApprovalsRequired = {
			{
				director = "Horror",
				reason = "Major pressure changes must preserve psychological pacing.",
				requiredFor = {
					"scare eligibility",
					"pressure escalation",
					"release timing",
				},
			},
			{
				director = "Monster",
				reason = "Monster pressure and chase preparation require future Monster Director approval.",
				requiredFor = {
					"monster pressure request",
					"chase preparation",
				},
			},
		},
		executionPermissions = {
			{
				action = "Create approval-only coordination bundles",
				requiresApproval = true,
				approval = "Horror",
			},
		},
		clientPresentation = {
			allowed = false,
			description = "Horror Orchestration creates no client remotes and owns no presentation.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "HorrorOrchestrator.inspect" },
		snapshotProviders = { "horrorOrchestration" },
		cleanupBehavior = {
			"cancel cleanup task",
			"clear pressure queue, pressure state, request ids, decisions, suppressions, and bundles on shutdown",
		},
		multiplayerGuarantees = {
			"pressure budget accounts for multiplayer load",
			"duplicate request ids reject",
			"client authority is not accepted",
			"safe rooms and puzzle rooms suppress unfair pressure",
		},
		failureModes = {
			"malformed pressure requests reject",
			"expired requests reject or expire from queue",
			"duplicate request ids reject",
			"unsafe execution fields reject",
			"no action is valid when timing is wrong",
		},
		documentation = {
			"HORROR_ORCHESTRATION.md",
			"HORROR_PRESSURE_BUDGET.md",
			"HORROR_COORDINATION.md",
			"HORROR_SILENCE_AND_RELEASE.md",
			"HORROR_ORCHESTRATION_DIAGNOSTICS.md",
			"HORROR_ORCHESTRATION_AUDIT.md",
			"HORROR_ORCHESTRATION_PRODUCTION_REVIEW.md",
			"HORROR_COORDINATION_REVIEW.md",
			"HORROR_PRESSURE_MODEL_REVIEW.md",
		},
		tags = { "horror", "orchestration", "server", "approval-only" },
	},
	{
		systemName = "Living Cognition Runtime",
		ownerLayer = "AI",
		status = "Production",
		responsibilities = {
			"coordinate cognition lifecycle",
			"normalize trusted observations",
			"create evidence without treating it as truth",
			"generate and rank hypotheses",
			"promote hypotheses into thoughts",
			"update slow-changing beliefs",
			"preserve confidence, uncertainty, provenance, traces, diagnostics, snapshots, and serialization hooks",
		},
		doesNotOwn = {
			"gameplay truth",
			"Monster AI",
			"movement",
			"navigation",
			"pathfinding",
			"attacks",
			"animations",
			"NPC spawning",
			"Workspace mutation",
			"client remotes",
			"Roblox Lighting modification",
			"Audio playback",
			"Chapter content",
			"presentation",
			"client-owned truth",
		},
		dependencies = {
			"Core Runtime",
			"Observation Engine",
			"Monster Intelligence Foundation",
			"Horror Orchestration Framework",
		},
		observationsEmitted = {},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = false,
			description = "Living Cognition is server-only and creates no client remotes or presentation.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "LivingCognitionCoordinator.inspect" },
		snapshotProviders = { "livingCognition" },
		cleanupBehavior = {
			"clear registry, observations, evidence, hypotheses, thoughts, beliefs, traces, and validation failures on shutdown",
		},
		multiplayerGuarantees = {
			"server-authoritative cognition only",
			"no client authority accepted",
			"duplicate cognitive entity ids reject",
			"payloads containing execution leakage reject",
		},
		failureModes = {
			"malformed observations reject",
			"unknown cognitive entities reject",
			"invalid confidence rejects",
			"invalid timestamps reject",
			"Workspace and execution leakage reject",
		},
		documentation = {
			"LIVING_COGNITION_RUNTIME.md",
			"COGNITIVE_PIPELINE.md",
			"EVIDENCE_RUNTIME.md",
			"HYPOTHESIS_RUNTIME.md",
			"THOUGHT_RUNTIME.md",
			"BELIEF_RUNTIME.md",
			"COGNITION_DIAGNOSTICS.md",
			"COGNITION_VALIDATION.md",
			"COGNITION_CERTIFICATION.md",
			"COGNITION_PRODUCTION_REVIEW.md",
			"LIVING_COGNITION_AUDIT.md",
			"LIVING_COGNITION_PRODUCTION_REVIEW.md",
			"COGNITION_SELF_CHECKS.md",
			"COGNITION_RUNTIME_LIMITS.md",
			"COGNITION_SERIALIZATION.md",
		},
		tags = { "ai", "living-cognition", "server", "cognition-only" },
	},
	{
		systemName = "Monster AI Execution Foundation",
		ownerLayer = "AI",
		status = "Foundation",
		responsibilities = {
			"consume approved monster intent/context only",
			"turn approved intent into dry-run execution records",
			"prepare reusable foundations for future chase, stalk, watch, retreat, perception, and navigation execution",
			"emit server observations for future monster state records",
			"expose diagnostics, snapshots, bounded history, validation failures, and deterministic self-checks",
		},
		doesNotOwn = {
			"intent decisions",
			"horror pacing",
			"story reveals",
			"Monster Director approvals",
			"Horror Director approvals",
			"Living Cognition beliefs",
			"Monster Intelligence reasoning",
			"navigation/pathfinding execution",
			"movement",
			"attacks",
			"damage",
			"animations",
			"monster models",
			"NPC spawning",
			"Workspace mutation",
			"client remotes",
			"Lighting changes",
			"Audio playback",
			"UI/presentation",
			"Chapter content",
		},
		dependencies = {
			"Core Runtime",
			"Observation Engine",
			"Director Ecosystem",
			"Living Cognition Runtime",
			"Monster Intelligence Foundation",
			"Horror Orchestration Framework",
			"Gameplay Execution Bridge",
		},
		observationsEmitted = {
			{
				id = "Monster.Ignored",
				when = "approved Monster AI intent is recorded as a dry-run execution state",
				required = true,
			},
		},
		directorApprovalsRequired = {
			{
				director = "Monster Director / DirectorCoordinator",
				reason = "Monster AI cannot invent its own intent or pacing",
				requiredFor = { "Chase", "Stalk", "Watch", "Retreat", "Navigate", "Perceive" },
			},
		},
		executionPermissions = {
			{
				action = "dry-run execution record",
				requiresApproval = true,
				approval = "Director-approved intent/context only",
			},
		},
		clientPresentation = {
			allowed = false,
			description = "Monster AI Execution Foundation is server-only and creates no client remotes or presentation.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "MonsterAIService.inspect" },
		snapshotProviders = { "monsterAIExecution" },
		cleanupBehavior = {
			"clear monster registry, intent records, execution records, validation failures, and snapshot history on shutdown",
		},
		multiplayerGuarantees = {
			"server-authoritative approved intent intake only",
			"no client authority accepted",
			"duplicate monster and duplicate intent ids reject",
			"unsafe execution payloads reject before planning",
		},
		failureModes = {
			"missing Director approval rejects",
			"unknown monsters reject",
			"unsupported intents reject",
			"expired intents reject",
			"unsafe payloads reject",
			"all accepted execution remains dry-run only",
		},
		documentation = {
			"MONSTER_AI_EXECUTION.md",
			"MONSTER_AI_BOUNDARIES.md",
			"MONSTER_AI_DIAGNOSTICS.md",
			"MONSTER_AI_SELF_CHECKS.md",
			"MONSTER_AI_PRODUCTION_REVIEW.md",
		},
		tags = { "ai", "monster-ai", "server", "dry-run", "execution-foundation" },
	},
	{
		systemName = "Door Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"register reusable door definitions",
			"validate door state transitions",
			"track failed open attempts",
			"expose door diagnostics",
		},
		doesNotOwn = {
			"door animation",
			"physical door movement",
			"Chapter 1 locks",
			"final audio",
		},
		dependencies = { "Gameplay Intelligence Runtime", "Object Runtime", "Observation Engine" },
		observationsEmitted = {
			{ id = "Door.Opened", when = "server opens door", required = true },
			{ id = "Door.Closed", when = "server closes door", required = true },
			{ id = "Door.Locked", when = "server locks door", required = true },
			{ id = "Door.Unlocked", when = "server unlocks door", required = true },
			{ id = "Door.FailedOpen", when = "server rejects open attempt", required = true },
		},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Future clients may show server-approved door feedback.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "DoorService.inspect" },
		snapshotProviders = { "gameplayIntelligence.doors" },
		cleanupBehavior = { "clear door definitions, state, and transitions on shutdown" },
		multiplayerGuarantees = {
			"server-authoritative door state machine",
			"invalid transitions fail closed",
		},
		failureModes = { "unknown doors reject", "locked unavailable doors fail open attempts" },
		documentation = { "DOOR_RUNTIME.md" },
		tags = { "gameplay", "doors", "server" },
	},
	{
		systemName = "Inventory Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"own personal inventory truth",
			"prepare party inventory hooks",
			"validate item additions and removals",
			"expose inventory diagnostics",
		},
		doesNotOwn = {
			"client inventory UI",
			"item spawning",
			"save persistence",
			"Chapter 1 rewards",
		},
		dependencies = { "Gameplay Intelligence Runtime", "Observation Engine" },
		observationsEmitted = {
			{ id = "Inventory.ItemAdded", when = "server adds item", required = true },
			{ id = "Inventory.ItemRemoved", when = "server removes item", required = true },
		},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Future clients may render server-owned inventory state.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "InventoryService.inspect" },
		snapshotProviders = { "gameplayIntelligence.inventory" },
		cleanupBehavior = { "clear inventory containers on shutdown" },
		multiplayerGuarantees = {
			"clients cannot create items",
			"server validates every inventory mutation",
		},
		failureModes = { "invalid item definitions reject", "missing items cannot be removed" },
		documentation = { "INVENTORY_RUNTIME.md" },
		tags = { "gameplay", "inventory", "server" },
	},
	{
		systemName = "Key Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"register key data definitions",
			"validate key collection and use",
			"support single-use, reusable, master, party-shared, and reward keys",
		},
		doesNotOwn = { "key models", "key UI", "door animation", "Chapter 1 key placement" },
		dependencies = {
			"Gameplay Intelligence Runtime",
			"Inventory Runtime",
			"Observation Engine",
		},
		observationsEmitted = {
			{ id = "Key.Collected", when = "server accepts key collection", required = true },
			{ id = "Key.Used", when = "server accepts key use", required = true },
		},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Future clients may present server-approved key feedback.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "KeyService.inspect" },
		snapshotProviders = { "gameplayIntelligence.keys" },
		cleanupBehavior = { "clear key registry on shutdown" },
		multiplayerGuarantees = { "server validates target unlocks", "clients cannot claim keys" },
		failureModes = {
			"unknown keys reject",
			"wrong target rejects",
			"single-use keys are consumed",
		},
		documentation = { "KEY_RUNTIME.md" },
		tags = { "gameplay", "keys", "server" },
	},
	{
		systemName = "Objective Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"register reusable objectives",
			"validate start, progress, completion, and failure",
			"support primary, secondary, hidden, personal, party, branching, and timed objective hooks",
		},
		doesNotOwn = {
			"Chapter 1 objective content",
			"story pacing",
			"final UI",
			"save persistence",
		},
		dependencies = {
			"Gameplay Intelligence Runtime",
			"Observation Engine",
			"Director Ecosystem Foundation",
		},
		observationsEmitted = {
			{ id = "Objective.Started", when = "server starts objective", required = true },
			{ id = "Objective.Progressed", when = "server progresses objective", required = true },
			{ id = "Objective.Completed", when = "server completes objective", required = true },
			{ id = "Objective.Failed", when = "server fails objective", required = true },
		},
		directorApprovalsRequired = {
			{
				director = "Environment",
				reason = "Objective progress pressure must be Director-approved before future execution.",
				requiredFor = { "future objective presentation pressure" },
			},
		},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Future clients may present server objective state.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "ObjectiveService.inspect" },
		snapshotProviders = { "gameplayIntelligence.objectives" },
		cleanupBehavior = { "clear objective registry and state on shutdown" },
		multiplayerGuarantees = {
			"server-owned objective progress",
			"party objective hooks remain server-owned",
		},
		failureModes = {
			"unknown objectives reject",
			"completed or failed objectives cannot progress",
		},
		documentation = { "OBJECTIVE_RUNTIME.md" },
		tags = { "gameplay", "objectives", "server" },
	},
	{
		systemName = "Puzzle Runtime",
		ownerLayer = "Gameplay",
		status = "Production",
		responsibilities = {
			"register graph-based puzzles",
			"validate puzzle node dependencies",
			"track puzzle progress and wrong inputs",
			"provide progressive hint hooks",
			"protect puzzle fairness",
		},
		doesNotOwn = {
			"Chapter 1 puzzle answers",
			"copied puzzles",
			"final UI",
			"horror pacing",
			"physical Workspace mutation",
		},
		dependencies = {
			"Gameplay Intelligence Runtime",
			"Observation Engine",
			"Director Ecosystem Foundation",
			"World Intelligence",
		},
		observationsEmitted = {
			{ id = "Puzzle.Started", when = "server starts puzzle", required = true },
			{ id = "Puzzle.NodeCompleted", when = "server completes node", required = true },
			{ id = "Puzzle.WrongInput", when = "server rejects puzzle input", required = true },
			{ id = "Puzzle.HintRequested", when = "hint is requested", required = true },
			{
				id = "Puzzle.HintShown",
				when = "hint is approved for presentation",
				required = true,
			},
			{ id = "Puzzle.Completed", when = "server completes puzzle", required = true },
			{ id = "Puzzle.Failed", when = "server fails puzzle", required = true },
		},
		directorApprovalsRequired = {
			{
				director = "Environment",
				reason = "Puzzle pressure and hints must preserve fairness before future execution.",
				requiredFor = { "future puzzle pressure", "future hint presentation pressure" },
			},
		},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Future clients may present server-approved puzzle state and hints.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "PuzzleService.inspect" },
		snapshotProviders = { "gameplayIntelligence.puzzles" },
		cleanupBehavior = { "clear puzzle registry, state, and hint cooldowns on shutdown" },
		multiplayerGuarantees = {
			"graph progress is server-owned",
			"co-op puzzle hooks are data-driven",
		},
		failureModes = {
			"impossible graphs reject",
			"missing dependencies reject",
			"instant spoiler hints reject by cooldown",
		},
		documentation = { "PUZZLE_RUNTIME.md", "PUZZLE_HINTS.md", "GAMEPLAY_GRAPH.md" },
		tags = { "gameplay", "puzzles", "server" },
	},
	{
		systemName = "Client Player Presentation Runtime",
		ownerLayer = "ClientPresentation",
		status = "Production",
		responsibilities = {
			"input collection",
			"first-person camera presentation",
			"prompt presentation",
			"audio feedback hooks",
			"accessibility hooks",
		},
		doesNotOwn = {
			"gameplay truth",
			"interaction completion",
			"Observation Engine facts",
			"horror pacing",
			"final UI art",
		},
		dependencies = { "Core Runtime", "RemoteManager", "Player Runtime", "Interaction Runtime" },
		observationsEmitted = {},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = true,
			description = "Client owns presentation only and sends requests to server remotes.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "client debug prints and future presentation diagnostics" },
		snapshotProviders = { "server-visible presentation contract only" },
		cleanupBehavior = {
			"disconnect input and camera connections on shutdown",
			"clear temporary prompt state",
		},
		multiplayerGuarantees = {
			"client cannot create trusted observations",
			"client cannot complete interactions",
			"server validates all remote requests",
		},
		failureModes = {
			"disable client controller when remotes are unavailable",
			"hide prompt when focus validation fails",
		},
		documentation = { "PLAYER_EXPERIENCE.md", "PLAYER_RUNTIME.md", "INTERACTION_RUNTIME.md" },
		tags = { "client", "presentation", "player" },
	},
	{
		systemName = "Simulation Validation Framework",
		ownerLayer = "Core",
		status = "Production",
		responsibilities = {
			"dev-only synthetic simulation scenarios",
			"cross-system validation reports",
			"diagnostic and snapshot sampling",
			"decision trace inspection",
			"architecture violation reporting",
		},
		doesNotOwn = {
			"gameplay content",
			"Chapter 1 logic",
			"Monster AI",
			"client remotes",
			"Workspace mutation",
			"live player truth",
			"final scares",
			"final UI or art",
		},
		dependencies = {
			"Core Runtime",
			"Observation Engine",
			"Director Ecosystem Foundation",
			"Environment Director",
			"Player Runtime",
			"Interaction Runtime",
		},
		observationsEmitted = {},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = false,
			description = "Simulation has no client remotes or client presentation.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "SimulationService.inspect" },
		snapshotProviders = { "simulationFramework" },
		cleanupBehavior = {
			"clear simulation traces",
			"clear simulation reports",
			"cleanup synthetic Environment Director state created by scenarios",
		},
		multiplayerGuarantees = {
			"synthetic profiles only",
			"no live Player mutation",
			"disabled by default",
		},
		failureModes = {
			"disabled mode refuses scenario execution",
			"unknown scenarios fail closed",
			"reports record architectural violations instead of mutating gameplay",
		},
		documentation = {
			"SIMULATION_FRAMEWORK.md",
			"PHASE_9_SIMULATION_REVIEW.md",
		},
		tags = { "core", "simulation", "validation", "dev-only" },
	},
	{
		systemName = "World Intelligence",
		ownerLayer = "Documentation",
		status = "Production",
		responsibilities = {
			"world profile contracts",
			"zone context resolution",
			"safe unknown-zone defaults",
			"affordance policy data",
		},
		doesNotOwn = {
			"Workspace mutation",
			"Chapter 1 map content",
			"Monster AI",
			"final lighting effects",
			"final audio playback",
		},
		dependencies = { "Core Runtime" },
		observationsEmitted = {},
		directorApprovalsRequired = {},
		executionPermissions = {},
		clientPresentation = {
			allowed = false,
			description = "World Intelligence is server-side contract data.",
			mustBeServerApproved = true,
		},
		diagnosticsExposed = { "WorldDiagnostics.capture" },
		snapshotProviders = { "future owning service may include WorldDiagnostics" },
		cleanupBehavior = { "clear registered synthetic profiles when explicitly requested" },
		multiplayerGuarantees = {
			"unknown zones fail conservative",
			"affordances are permissions, not actions",
		},
		failureModes = {
			"invalid profiles fail validation",
			"unknown zones deny major hostile pressure",
		},
		documentation = { "WORLD_INTELLIGENCE.md", "WORLD_INTELLIGENCE_REVIEW.md" },
		tags = { "world", "policy", "server" },
	},
}

function EngineContractRegistry.register(contract: EngineContract): boolean
	assert(type(contract) == "table", "contract must be a table")
	assert(
		type(contract.systemName) == "string" and contract.systemName ~= "",
		"contract.systemName is required"
	)

	if contracts[contract.systemName] == nil then
		table.insert(registrationOrder, contract.systemName)
	end

	contracts[contract.systemName] = cloneContract(contract)
	return true
end

function EngineContractRegistry.replace(contract: EngineContract): boolean
	assert(type(contract) == "table", "contract must be a table")
	assert(
		type(contract.systemName) == "string" and contract.systemName ~= "",
		"contract.systemName is required"
	)

	if contracts[contract.systemName] == nil then
		return false
	end

	contracts[contract.systemName] = cloneContract(contract)
	return true
end

function EngineContractRegistry.get(systemName: string): EngineContract?
	local contract = contracts[systemName]

	if contract == nil then
		return nil
	end

	return cloneContract(contract)
end

function EngineContractRegistry.getAll(): { EngineContract }
	local all = {}

	for _, systemName in ipairs(registrationOrder) do
		local contract = contracts[systemName]

		if contract ~= nil then
			table.insert(all, cloneContract(contract))
		end
	end

	return all
end

function EngineContractRegistry.registerBuiltIns()
	for _, contract in ipairs(builtInContracts) do
		if contracts[contract.systemName] == nil then
			registerBuiltIn(contract)
		end
	end
end

function EngineContractRegistry.clear()
	table.clear(contracts)
	table.clear(registrationOrder)
end

function EngineContractRegistry.inspect()
	return {
		count = #registrationOrder,
		order = table.clone(registrationOrder),
		contracts = EngineContractRegistry.getAll(),
	}
end

function EngineContractRegistry.validate(): (boolean, string?)
	local seen = {}

	for _, systemName in ipairs(registrationOrder) do
		if seen[systemName] then
			return false, "Duplicate governance registration: " .. systemName
		end

		if contracts[systemName] == nil then
			return false, "Governance registration missing contract: " .. systemName
		end

		seen[systemName] = true
	end

	return true, nil
end

return EngineContractRegistry
