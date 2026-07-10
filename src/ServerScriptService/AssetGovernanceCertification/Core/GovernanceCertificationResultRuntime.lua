--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationCoordinator)

local GovernanceCertificationResultRuntime = {}

function GovernanceCertificationResultRuntime.register(schema: any)
	return Coordinator.registerGovernanceCertificationResult(schema)
end

function GovernanceCertificationResultRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceCertificationResultRuntime
