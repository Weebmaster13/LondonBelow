--!strict

local Coordinator = require(script.Parent.AssetGovernanceCertificationCoordinator)

local GovernanceCertificationRuntime = {}

function GovernanceCertificationRuntime.register(schema: any)
	return Coordinator.registerGovernanceCertification(schema)
end

function GovernanceCertificationRuntime.inspect()
	return Coordinator.inspect()
end

return GovernanceCertificationRuntime
