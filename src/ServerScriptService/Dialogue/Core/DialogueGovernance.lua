--!strict

local Governance = {}

function Governance.inspect()
	return {
		systemName = "Dialogue Runtime Capability Foundation",
		ownerLayer = "Dialogue",
		status = "ProductionCandidate",
		providerName = "dialogueRuntimeCapability",
		responsibilities = {
			"conversation definitions",
			"conversation instances",
			"dialogue participants",
			"dialogue state metadata",
			"dialogue branching metadata",
			"dialogue conditions metadata",
			"dialogue variables metadata",
			"dialogue lifecycle metadata",
			"dialogue diagnostics",
			"dialogue snapshots",
			"dialogue evidence",
		},
		doesNotOwn = {
			"rendering",
			"UI widgets",
			"animations",
			"voice playback",
			"subtitles",
			"player input",
			"NPC AI",
			"inventory",
			"objectives",
			"networking",
			"persistence",
			"Workspace mutation",
			"command execution",
			"event publication",
			"query execution",
		},
	}
end

return Governance
