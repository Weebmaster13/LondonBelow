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
