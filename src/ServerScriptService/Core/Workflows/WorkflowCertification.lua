--!strict

local Certification = {}

function Certification.inspect()
	return {
		certificationStatus = "ProductionCandidate",
		productionCertified = false,
		requiredRuntimeEvidence = {
			authoritativeRuntimeExecutionFrameworkEvidence = false,
			studioRuntimeEvidenceImported = false,
			workflowRuntimeSmokeExecuted = false,
		},
		blockedReason = "Authoritative Runtime Execution Framework evidence has not been imported from Roblox Studio.",
		nextAction = "Import authoritative Studio runtime evidence before Production Certification.",
	}
end

return Certification
