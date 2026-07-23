--!strict

local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialoguePresentationTypes)

local Governance = {}

local metadata = {
	systemName = "Dialogue Presentation Contract Foundation",
	ownerLayer = "Dialogue",
	providerName = Types.ProviderName,
	contractId = Types.ContractId,
	status = "ProductionCandidate",
	responsibilities = {
		"presentation contract definitions",
		"presentation request metadata",
		"presentation descriptor validation",
		"presentation acknowledgement contracts",
		"synchronization policies",
		"speaker presentation references",
		"localization token references",
		"accessibility metadata",
		"presentation lifecycle metadata",
		"diagnostics",
		"snapshots",
		"evidence",
		"metrics",
		"profiler metadata",
		"certification posture",
	},
	doesNotOwn = {
		"ScreenGui creation",
		"UI rendering",
		"text rendering",
		"portrait rendering",
		"subtitle rendering",
		"camera control",
		"animation playback",
		"voice playback",
		"audio routing",
		"localization resolution",
		"font selection",
		"layout calculation",
		"visual effects",
		"tweening",
		"input capture",
		"networking",
		"RemoteEvents",
		"RemoteFunctions",
		"persistence",
		"save serialization",
		"Workspace mutation",
		"NPC behavior",
		"gameplay execution",
		"client authority",
		"analytics",
		"telemetry",
	},
}

function Governance.inspect()
	return Serialization.deepCopy(metadata)
end

return Governance
