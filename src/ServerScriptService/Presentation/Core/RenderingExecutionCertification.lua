--!strict

local Certification = {}

function Certification.inspect()
	return {
		status = "ProductionCandidate",
		productionCertified = false,
		authoritativeStudioEvidenceImported = false,
		blockedReason = "Authoritative Roblox Studio runtime evidence has not been imported through the Runtime Execution Framework.",
	}
end

return Certification
