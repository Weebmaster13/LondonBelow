--!strict

local Serialization = require(script.Parent.CapabilitySerialization)

local Certification = {}

local certification = {
	status = "ProductionCandidate",
	runtimeExecutionFrameworkEvidence = false,
	authoritativeStudioEvidenceImported = false,
	productionCertified = false,
	blockedReason = "Authoritative Runtime Execution Framework evidence is not imported.",
}

function Certification.inspect()
	return Serialization.deepCopy(certification)
end

return Certification
