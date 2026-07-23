--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Governance = {}

local metadata = {
	systemName = "Presentation Runtime Capability Foundation",
	ownerLayer = "Presentation",
	providerName = Types.ProviderName,
	capabilityId = Types.CapabilityId,
	status = "ProductionCandidate",
	responsibilities = {
		"presentation capability registration",
		"presentation sessions",
		"presentation consumers",
		"presentation queues",
		"presentation lifecycle",
		"synchronization runtime",
		"acknowledgement production",
		"diagnostics",
		"snapshots",
		"evidence",
		"metrics",
		"profiler metadata",
		"certification posture",
	},
	doesNotOwn = {
		"ScreenGui creation",
		"Roblox GUI",
		"TextLabels",
		"ImageLabels",
		"camera movement",
		"animation playback",
		"sound playback",
		"localization resolution",
		"accessibility implementation",
		"RemoteEvents",
		"RemoteFunctions",
		"networking",
		"persistence",
		"Workspace mutation",
		"gameplay logic",
		"dialogue execution",
		"NPC AI",
		"analytics",
		"telemetry",
		"client authority",
	},
}

function Governance.inspect()
	return Serialization.deepCopy(metadata)
end

return Governance
