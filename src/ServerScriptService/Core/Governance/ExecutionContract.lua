--!strict
--[[
	Standard execution-system contract.

	Owns rules for systems that perform actions after engine approval.

	Does not approve pacing, invent horror, or own observations. Execution
	systems execute approved decisions and emit observations when they create new
	server truth.
]]

local ExecutionContract = {}

ExecutionContract.RequiredRules = {
	"can only execute approved decisions when approval is required",
	"must fail safely",
	"must emit observations when creating new server truth",
	"must expose diagnostics",
	"must clean up tasks and connections",
}

function ExecutionContract.describe()
	return {
		requiredRules = table.clone(ExecutionContract.RequiredRules),
		examples = {
			"Door execution opens a door after validation or approval.",
			"Lighting execution flickers lights after Lighting Director approval.",
			"Monster AI movement starts after Monster Director permission.",
		},
	}
end

function ExecutionContract.validateContract(contract: any): (boolean, string?)
	if type(contract) ~= "table" then
		return false, "Execution contract must be a table"
	end

	if type(contract.executionPermissions) ~= "table" or #contract.executionPermissions == 0 then
		return false, "Execution systems must declare execution permissions"
	end

	if type(contract.cleanupBehavior) ~= "table" or #contract.cleanupBehavior == 0 then
		return false, "Execution systems must declare cleanup behavior"
	end

	if type(contract.diagnosticsExposed) ~= "table" or #contract.diagnosticsExposed == 0 then
		return false, "Execution systems must expose diagnostics"
	end

	return true, nil
end

return ExecutionContract
