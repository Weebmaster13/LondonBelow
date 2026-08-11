--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Governance = {}

local contract = {
	systemName = "Roblox Visual Composition Runtime",
	ownerLayer = "Presentation",
	status = "ProductionCandidate",
	provider = Types.RobloxVisualCompositionProviderName,
	snapshotProvider = Types.RobloxVisualCompositionProviderName,
	responsibilities = {
		"visual composition definition ownership",
		"composition graph ownership",
		"hierarchy ownership",
		"layout intent ownership",
		"responsive metadata",
		"semantic-role metadata",
		"state variants",
		"composition compilation",
		"revision authority",
		"Roblox rendering-session binding",
		"diagnostics",
		"snapshots",
		"evidence",
		"metrics",
		"budgets",
	},
	doesNotOwn = {
		"GUI instantiation",
		"Roblox Instance mutation",
		"visual rendering",
		"client rendering",
		"camera execution",
		"animation execution",
		"audio execution",
		"asset loading",
		"localization resolution",
		"accessibility execution",
		"networking",
		"persistence",
		"gameplay",
		"dialogue",
		"AI",
		"analytics",
		"telemetry",
		"client authority",
	},
	certificationBoundary = "Production Candidate until authoritative Roblox Studio Runtime Execution Framework evidence is imported.",
}

function Governance.inspect()
	return Serialization.deepCopy(contract)
end

return Governance
