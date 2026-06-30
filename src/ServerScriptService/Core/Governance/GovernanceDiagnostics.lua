--!strict
--[[
	Diagnostics aggregation for Engine Governance.

	Owns read-only capture and validation of governance registry, issues,
	scorecards, and enforcement status.

	Does not enforce by itself; EngineGovernance orchestrates lifecycle.
]]

local GovernanceDiagnostics = {}

function GovernanceDiagnostics.capture(state: any, dependencies: { [string]: any })
	return {
		state = state,
		registry = dependencies.EngineContractRegistry.inspect(),
		issues = dependencies.getIssues(),
		scorecards = dependencies.getScorecards(),
		directorContract = dependencies.DirectorContract.describe(),
		observationContract = dependencies.ObservationContract.describe(),
		executionContract = dependencies.ExecutionContract.describe(),
	}
end

function GovernanceDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	local registryOk, registryErr = dependencies.EngineContractRegistry.validate()

	if not registryOk then
		return false, registryErr
	end

	for _, contract in ipairs(dependencies.EngineContractRegistry.getAll()) do
		local issues = dependencies.EngineContractValidator.validate(contract)

		if dependencies.EngineContractValidator.hasErrors(issues) then
			return false, "Governance contract has errors: " .. contract.systemName
		end
	end

	return true, nil
end

return GovernanceDiagnostics
