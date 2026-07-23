--!strict

local Certification = {}

function Certification.inspect()
	return {
		status = "ProductionCandidate",
		productionCertified = false,
		runtimeExecutionFrameworkEvidence = false,
		authoritativeStudioEvidenceImported = false,
		blockedReason = "Authoritative Roblox Studio runtime evidence has not been imported.",
	}
end

return Certification
