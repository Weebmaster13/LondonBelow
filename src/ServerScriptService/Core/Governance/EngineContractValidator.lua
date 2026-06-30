--!strict
--[[
	Constitution validator for London Engine contracts.

	Owns architectural checks that make common violations visible before systems
	grow around them.

	Does not scan source code or replace code review. It validates declared
	contracts and gives future Codex tasks a strict target to satisfy.
]]

local Types = require(script.Parent.EngineContractTypes)

local EngineContractValidator = {}

type EngineContract = Types.EngineContract
type ContractIssue = Types.ContractIssue

local function issue(
	contract: EngineContract,
	code: string,
	severity: "Info" | "Warning" | "Error",
	message: string
): ContractIssue
	return {
		systemName = contract.systemName,
		code = code,
		severity = severity,
		message = message,
	}
end

local function hasAny(values: { any }): boolean
	return #values > 0
end

local function textContains(values: { string }, pattern: string): boolean
	local loweredPattern = string.lower(pattern)

	for _, value in ipairs(values) do
		if string.find(string.lower(value), loweredPattern, 1, true) ~= nil then
			return true
		end
	end

	return false
end

function EngineContractValidator.validate(contract: EngineContract): { ContractIssue }
	local issues = {}

	if contract.systemName == "" then
		table.insert(issues, issue(contract, "MISSING_NAME", "Error", "System name is required."))
	end

	if #contract.responsibilities == 0 then
		table.insert(
			issues,
			issue(
				contract,
				"MISSING_RESPONSIBILITIES",
				"Error",
				"Contract must declare responsibilities."
			)
		)
	end

	if #contract.responsibilities > 9 then
		table.insert(
			issues,
			issue(
				contract,
				"GOD_SYSTEM_RISK",
				"Warning",
				"System declares many responsibilities; check for God-system drift."
			)
		)
	end

	if #contract.doesNotOwn == 0 then
		table.insert(
			issues,
			issue(
				contract,
				"MISSING_NON_OWNERSHIP",
				"Error",
				"Contract must declare what it does not own."
			)
		)
	end

	if
		contract.clientPresentation.allowed
		and contract.ownerLayer ~= "ClientPresentation"
		and not contract.clientPresentation.mustBeServerApproved
	then
		table.insert(
			issues,
			issue(
				contract,
				"CLIENT_TRUTH_RISK",
				"Error",
				"Client presentation must be server-approved."
			)
		)
	end

	if contract.ownerLayer == "Gameplay" and not hasAny(contract.observationsEmitted) then
		table.insert(
			issues,
			issue(
				contract,
				"NO_OBSERVATIONS",
				"Error",
				"Gameplay systems must emit observations for server truth."
			)
		)
	end

	if contract.ownerLayer == "Execution" and not hasAny(contract.executionPermissions) then
		table.insert(
			issues,
			issue(
				contract,
				"NO_EXECUTION_PERMISSIONS",
				"Error",
				"Execution systems must declare permissions."
			)
		)
	end

	if contract.ownerLayer == "AI" then
		if
			textContains(contract.responsibilities, "pacing")
			or textContains(contract.responsibilities, "climax")
		then
			table.insert(
				issues,
				issue(
					contract,
					"MONSTER_AI_PACING",
					"Error",
					"Monster AI cannot own horror pacing or chapter climax."
				)
			)
		end
	end

	if contract.ownerLayer == "Execution" then
		if
			textContains(contract.responsibilities, "pacing")
			or textContains(contract.responsibilities, "decide")
		then
			table.insert(
				issues,
				issue(
					contract,
					"EXECUTION_INVENTS_PACING",
					"Error",
					"Execution systems cannot invent pacing decisions."
				)
			)
		end
	end

	if
		textContains(contract.responsibilities, "major scare")
		and not hasAny(contract.directorApprovalsRequired)
	then
		table.insert(
			issues,
			issue(
				contract,
				"MAJOR_HORROR_WITHOUT_DIRECTOR",
				"Error",
				"Major horror events require Director approval."
			)
		)
	end

	if
		textContains(contract.responsibilities, "remote")
		and not textContains(contract.dependencies, "RemoteManager")
	then
		table.insert(
			issues,
			issue(
				contract,
				"REMOTE_MANAGER_MISSING",
				"Warning",
				"Remote-owning systems should depend on RemoteManager."
			)
		)
	end

	if not hasAny(contract.diagnosticsExposed) then
		table.insert(
			issues,
			issue(
				contract,
				"MISSING_DIAGNOSTICS",
				"Error",
				"Production systems must expose diagnostics."
			)
		)
	end

	if not hasAny(contract.cleanupBehavior) then
		table.insert(
			issues,
			issue(contract, "MISSING_CLEANUP", "Error", "Systems must declare cleanup behavior.")
		)
	end

	if not hasAny(contract.documentation) then
		table.insert(
			issues,
			issue(contract, "MISSING_DOCUMENTATION", "Error", "Systems must declare documentation.")
		)
	end

	if not hasAny(contract.failureModes) then
		table.insert(
			issues,
			issue(
				contract,
				"MISSING_FAILURE_MODES",
				"Warning",
				"Systems should document failure modes."
			)
		)
	end

	if
		contract.ownerLayer == "Observation" and textContains(contract.responsibilities, "execute")
	then
		table.insert(
			issues,
			issue(
				contract,
				"OBSERVATION_EXECUTION_LEAK",
				"Error",
				"Observation Engine owns truth, not execution."
			)
		)
	end

	if
		contract.ownerLayer == "Director" and textContains(contract.responsibilities, "movement")
	then
		table.insert(
			issues,
			issue(
				contract,
				"DIRECTOR_MOVEMENT_LEAK",
				"Error",
				"Directors approve; they do not own physical movement."
			)
		)
	end

	return issues
end

function EngineContractValidator.hasErrors(issues: { ContractIssue }): boolean
	for _, contractIssue in ipairs(issues) do
		if contractIssue.severity == "Error" then
			return true
		end
	end

	return false
end

return EngineContractValidator
