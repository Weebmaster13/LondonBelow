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

local function cloneContract(contract: EngineContract): EngineContract
	return {
		systemName = contract.systemName,
		ownerLayer = contract.ownerLayer,
		status = contract.status,
		responsibilities = copyArray(contract.responsibilities),
		doesNotOwn = copyArray(contract.doesNotOwn),
		dependencies = copyArray(contract.dependencies),
		observationsEmitted = copyArray(contract.observationsEmitted),
		directorApprovalsRequired = copyArray(contract.directorApprovalsRequired),
		executionPermissions = copyArray(contract.executionPermissions),
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
			"logging",
			"events",
			"scheduling",
			"dependency validation",
			"remote definitions",
			"diagnostics",
			"snapshots",
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
			"validation",
			"enrichment",
			"aggregation",
			"memory",
			"timelines",
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
}

function EngineContractRegistry.register(contract: EngineContract): boolean
	if contracts[contract.systemName] == nil then
		table.insert(registrationOrder, contract.systemName)
	end

	contracts[contract.systemName] = cloneContract(contract)
	return true
end

function EngineContractRegistry.replace(contract: EngineContract): boolean
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
