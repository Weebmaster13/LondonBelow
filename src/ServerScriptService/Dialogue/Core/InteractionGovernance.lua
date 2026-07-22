--!strict

local Governance = {}

function Governance.inspect()
	return {
		systemName = "Dialogue Interaction and Runtime Event Coordination",
		ownerLayer = "Dialogue",
		status = "ProductionCandidate",
		providerName = "dialogueRuntimeInteraction",
		responsibilities = {
			"interaction requests",
			"interaction sessions",
			"pending player responses",
			"interaction validation",
			"interruption handling",
			"cancellation handling",
			"timeout management",
			"nested interaction metadata",
			"runtime event coordination metadata",
			"interaction diagnostics",
			"interaction snapshots",
			"interaction evidence",
		},
		doesNotOwn = {
			"UI",
			"rendering",
			"voice",
			"subtitles",
			"networking",
			"RemoteEvents",
			"RemoteFunctions",
			"persistence",
			"save serialization",
			"NPC behavior",
			"gameplay execution",
			"animation",
			"client authority",
		},
	}
end

return Governance
