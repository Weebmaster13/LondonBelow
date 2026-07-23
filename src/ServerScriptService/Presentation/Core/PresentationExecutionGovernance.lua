--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Governance = {}

local metadata = {
	systemName = "Presentation Runtime Execution and Session Management",
	ownerLayer = "Presentation",
	providerName = Types.ExecutionProviderName,
	runtimeId = Types.ExecutionRuntimeId,
	status = "ProductionCandidate",
	responsibilities = {
		"execution scheduler",
		"execution queue",
		"lifecycle execution",
		"acknowledgement execution",
		"synchronization execution",
		"execution suspension",
		"execution resumption",
		"execution cancellation",
		"execution expiration",
		"diagnostics",
		"snapshots",
		"evidence",
		"metrics",
		"profiler metadata",
	},
	doesNotOwn = {
		"ScreenGui creation",
		"Roblox GUI",
		"TextLabels",
		"ImageLabels",
		"viewport rendering",
		"animation playback",
		"sound playback",
		"camera movement",
		"localization resolution",
		"accessibility rendering",
		"networking",
		"RemoteEvents",
		"RemoteFunctions",
		"Workspace mutation",
		"persistence",
		"gameplay",
		"dialogue execution",
		"AI",
		"analytics",
		"telemetry",
		"client authority",
	},
}

function Governance.inspect()
	return Serialization.deepCopy(metadata)
end

return Governance
