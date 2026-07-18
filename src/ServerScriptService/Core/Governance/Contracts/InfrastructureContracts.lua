--!strict
-- Governance contract group extracted from EngineContractRegistry.

local Types = require(script.Parent.Parent.EngineContractTypes)

type EngineContract = Types.EngineContract

local contracts: { EngineContract } = {
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
}

return contracts
