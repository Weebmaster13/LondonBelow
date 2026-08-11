--!strict

local Serialization = require(script.Parent.PresentationSerialization)

local Certification = {}

function Certification.inspect()
	return Serialization.deepCopy({
		status = "ProductionCandidate",
		productionCertified = false,
		runtimeExecutionFrameworkEvidence = false,
		blockedReason = "Authoritative Roblox Studio runtime evidence has not been imported through the Runtime Execution Framework.",
	})
end

return Certification
