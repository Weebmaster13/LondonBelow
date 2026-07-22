--!strict

local Governance = {}

function Governance.inspect()
	return {
		systemName = "Dialogue Runtime Execution and State Management",
		ownerLayer = "Dialogue",
		status = "ProductionCandidate",
		providerName = "dialogueRuntimeExecution",
		responsibilities = {
			"conversation execution",
			"runtime state machine",
			"node traversal",
			"choice processing",
			"condition evaluation",
			"runtime variables",
			"participant synchronization metadata",
			"execution diagnostics",
			"execution snapshots",
			"execution evidence",
		},
		doesNotOwn = {
			"rendering",
			"UI",
			"NPC behavior",
			"AI decisions",
			"inventory",
			"objectives",
			"save serialization",
			"networking",
			"Workspace mutation",
			"command execution",
			"event publication",
			"query execution",
			"client authority",
		},
	}
end

return Governance
