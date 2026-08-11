--!strict

local Certification = {}

local posture = {
	status = "ProductionCandidate",
	productionCertified = false,
	runtimeExecutionFrameworkEvidence = false,
	blockedReason = "Authoritative Roblox Studio runtime evidence has not been imported through the Runtime Execution Framework.",
	nextAction = "Import authoritative Roblox Studio evidence before Production Certification.",
}

function Certification.inspect()
	return table.clone(posture)
end

return Certification
