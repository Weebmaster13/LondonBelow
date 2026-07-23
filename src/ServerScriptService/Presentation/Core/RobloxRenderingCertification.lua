--!strict

local Certification = {}

function Certification.inspect()
	return {
		status = "ProductionCandidate",
		productionCertified = false,
		blockedReason = "Authoritative Roblox Studio runtime evidence has not been imported through the Runtime Execution Framework.",
		staticValidationRequired = true,
		runtimeEvidenceRequired = true,
		noRenderingBoundary = true,
	}
end

return Certification
