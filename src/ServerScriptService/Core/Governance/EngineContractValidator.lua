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

local VALID_OWNER_LAYERS = {
	Core = true,
	Lobby = true,
	Portal = true,
	Observation = true,
	Director = true,
	Execution = true,
	Gameplay = true,
	AI = true,
	ClientPresentation = true,
	Saving = true,
	Performance = true,
	Documentation = true,
}

local VALID_STATUSES = {
	Foundation = true,
	Production = true,
	Experimental = true,
	Deprecated = true,
}

local VALID_APPROVALS = {
	Horror = true,
	Narrative = true,
	Story = true,
	Environment = true,
	Lighting = true,
	Audio = true,
	Music = true,
	Monster = true,
	Puzzle = true,
	Save = true,
	Difficulty = true,
	Performance = true,
}

local function issue(
	contract: any,
	code: string,
	severity: "Pass" | "Info" | "Warning" | "Error" | "Fatal",
	message: string
): ContractIssue
	return {
		systemName = if type(contract) == "table"
				and type(contract.systemName) == "string"
			then contract.systemName
			else "<unknown>",
		code = code,
		severity = severity,
		message = message,
	}
end

local function isArrayOfStrings(values: any): boolean
	if type(values) ~= "table" then
		return false
	end

	for _, value in ipairs(values) do
		if type(value) ~= "string" or value == "" then
			return false
		end
	end

	return true
end

local function hasAny(values: any): boolean
	return type(values) == "table" and #values > 0
end

local function textContains(values: any, pattern: string): boolean
	if type(values) ~= "table" then
		return false
	end

	local loweredPattern = string.lower(pattern)

	for _, value in ipairs(values) do
		if
			type(value) == "string"
			and string.find(string.lower(value), loweredPattern, 1, true) ~= nil
		then
			return true
		end
	end

	return false
end

local function textContainsAny(values: any, patterns: { string }): boolean
	for _, pattern in ipairs(patterns) do
		if textContains(values, pattern) then
			return true
		end
	end

	return false
end

local function validateObservationRules(contract: EngineContract, issues: { ContractIssue })
	for _, rule in ipairs(contract.observationsEmitted) do
		if type(rule.id) ~= "string" or not string.find(rule.id, "%.") then
			table.insert(
				issues,
				issue(
					contract,
					"INVALID_OBSERVATION_ID",
					"Error",
					"Observation rules require stable namespaced IDs."
				)
			)
		end

		if type(rule.when) ~= "string" or rule.when == "" then
			table.insert(
				issues,
				issue(
					contract,
					"INVALID_OBSERVATION_WHEN",
					"Error",
					"Observation rules must explain when they emit."
				)
			)
		end
	end
end

local function validateApprovalRules(contract: EngineContract, issues: { ContractIssue })
	for _, rule in ipairs(contract.directorApprovalsRequired) do
		if not VALID_APPROVALS[rule.director] then
			table.insert(
				issues,
				issue(
					contract,
					"INVALID_DIRECTOR_APPROVAL",
					"Error",
					"Director approval rule uses unknown Director."
				)
			)
		end

		if type(rule.reason) ~= "string" or rule.reason == "" then
			table.insert(
				issues,
				issue(
					contract,
					"MISSING_APPROVAL_REASON",
					"Error",
					"Director approval rules require a reason."
				)
			)
		end

		if type(rule.requiredFor) ~= "table" or #rule.requiredFor == 0 then
			table.insert(
				issues,
				issue(
					contract,
					"MISSING_APPROVAL_SCOPE",
					"Error",
					"Director approval rules must state what they apply to."
				)
			)
		end
	end
end

local function validateExecutionPermissions(contract: EngineContract, issues: { ContractIssue })
	for _, permission in ipairs(contract.executionPermissions) do
		if type(permission.action) ~= "string" or permission.action == "" then
			table.insert(
				issues,
				issue(
					contract,
					"INVALID_EXECUTION_ACTION",
					"Error",
					"Execution permissions require action names."
				)
			)
		end

		if permission.requiresApproval and permission.approval == nil then
			table.insert(
				issues,
				issue(
					contract,
					"MISSING_EXECUTION_APPROVAL",
					"Error",
					"Approval-gated execution must name the approving Director."
				)
			)
		end

		if permission.approval ~= nil and not VALID_APPROVALS[permission.approval] then
			table.insert(
				issues,
				issue(
					contract,
					"INVALID_EXECUTION_APPROVAL",
					"Error",
					"Execution permission references unknown Director."
				)
			)
		end
	end
end

local function validateShape(contract: any): { ContractIssue }
	local issues = {}

	if type(contract) ~= "table" then
		table.insert(
			issues,
			issue(contract, "INVALID_CONTRACT", "Fatal", "Contract must be a table.")
		)
		return issues
	end

	if type(contract.systemName) ~= "string" or contract.systemName == "" then
		table.insert(issues, issue(contract, "MISSING_NAME", "Fatal", "System name is required."))
	end

	if type(contract.ownerLayer) ~= "string" or not VALID_OWNER_LAYERS[contract.ownerLayer] then
		table.insert(
			issues,
			issue(contract, "INVALID_OWNER_LAYER", "Fatal", "Contract ownerLayer is invalid.")
		)
	end

	if type(contract.status) ~= "string" or not VALID_STATUSES[contract.status] then
		table.insert(
			issues,
			issue(contract, "INVALID_STATUS", "Fatal", "Contract status is invalid.")
		)
	end

	local stringArrayFields = {
		"responsibilities",
		"doesNotOwn",
		"dependencies",
		"diagnosticsExposed",
		"snapshotProviders",
		"cleanupBehavior",
		"multiplayerGuarantees",
		"failureModes",
		"documentation",
		"tags",
	}

	for _, fieldName in ipairs(stringArrayFields) do
		if not isArrayOfStrings(contract[fieldName]) then
			table.insert(
				issues,
				issue(
					contract,
					"INVALID_FIELD_" .. string.upper(fieldName),
					"Fatal",
					fieldName .. " must be an array of non-empty strings."
				)
			)
		end
	end

	if type(contract.observationsEmitted) ~= "table" then
		table.insert(
			issues,
			issue(
				contract,
				"INVALID_OBSERVATION_RULES",
				"Fatal",
				"observationsEmitted must be a table."
			)
		)
	end

	if type(contract.directorApprovalsRequired) ~= "table" then
		table.insert(
			issues,
			issue(
				contract,
				"INVALID_APPROVAL_RULES",
				"Fatal",
				"directorApprovalsRequired must be a table."
			)
		)
	end

	if type(contract.executionPermissions) ~= "table" then
		table.insert(
			issues,
			issue(
				contract,
				"INVALID_EXECUTION_RULES",
				"Fatal",
				"executionPermissions must be a table."
			)
		)
	end

	if type(contract.clientPresentation) ~= "table" then
		table.insert(
			issues,
			issue(
				contract,
				"INVALID_CLIENT_PRESENTATION",
				"Fatal",
				"clientPresentation must be a table."
			)
		)
	elseif
		type(contract.clientPresentation.allowed) ~= "boolean"
		or type(contract.clientPresentation.description) ~= "string"
		or contract.clientPresentation.description == ""
		or type(contract.clientPresentation.mustBeServerApproved) ~= "boolean"
	then
		table.insert(
			issues,
			issue(
				contract,
				"INVALID_CLIENT_PRESENTATION",
				"Fatal",
				"clientPresentation requires allowed, description, and mustBeServerApproved."
			)
		)
	end

	return issues
end

function EngineContractValidator.validate(contract: EngineContract | any): { ContractIssue }
	local issues = validateShape(contract)

	if EngineContractValidator.hasBlockingIssues(issues) then
		return issues
	end

	local typedContract = contract :: EngineContract

	if typedContract.status == "Deprecated" then
		table.insert(
			issues,
			issue(
				typedContract,
				"DEPRECATED_SYSTEM",
				"Warning",
				"Deprecated systems require removal or replacement planning."
			)
		)
	end

	if typedContract.status == "Experimental" then
		table.insert(
			issues,
			issue(
				typedContract,
				"EXPERIMENTAL_SYSTEM",
				"Warning",
				"Experimental systems cannot be treated as production-ready."
			)
		)
	end

	if #typedContract.responsibilities == 0 then
		table.insert(
			issues,
			issue(
				typedContract,
				"MISSING_RESPONSIBILITIES",
				"Error",
				"Contract must declare responsibilities."
			)
		)
	end

	if #typedContract.responsibilities > 7 then
		table.insert(
			issues,
			issue(
				typedContract,
				"GOD_SYSTEM_RISK",
				"Warning",
				"System declares many responsibilities; check for God-system drift."
			)
		)
	end

	if #typedContract.doesNotOwn < 2 then
		table.insert(
			issues,
			issue(
				typedContract,
				"WEAK_NON_OWNERSHIP",
				"Error",
				"Contract must clearly declare what it does not own."
			)
		)
	end

	if
		typedContract.clientPresentation.allowed
		and typedContract.ownerLayer ~= "ClientPresentation"
		and not typedContract.clientPresentation.mustBeServerApproved
	then
		table.insert(
			issues,
			issue(
				typedContract,
				"CLIENT_TRUTH_RISK",
				"Error",
				"Client presentation must be server-approved."
			)
		)
	end

	local createsGameplayTruth = typedContract.ownerLayer == "Gameplay"
		or typedContract.ownerLayer == "Saving"
		or textContainsAny(typedContract.responsibilities, {
			"truth",
			"state",
			"objective",
			"door",
			"key",
			"inventory",
			"checkpoint",
			"save",
			"puzzle",
		})

	if
		createsGameplayTruth
		and typedContract.ownerLayer ~= "Core"
		and typedContract.ownerLayer ~= "Lobby"
		and typedContract.ownerLayer ~= "Portal"
		and not hasAny(typedContract.observationsEmitted)
	then
		table.insert(
			issues,
			issue(
				typedContract,
				"NO_OBSERVATIONS",
				"Error",
				"Systems creating gameplay truth must declare Observation Engine output."
			)
		)
	end

	local majorHorrorSurface = typedContract.ownerLayer == "Director"
		or textContainsAny(typedContract.responsibilities, {
			"major scare",
			"scare",
			"horror",
			"reveal",
			"chase",
			"stalk",
			"whisper",
			"hallucination",
			"lighting pressure",
			"sound pressure",
		})

	if
		majorHorrorSurface
		and typedContract.ownerLayer ~= "Director"
		and typedContract.ownerLayer ~= "Observation"
		and not hasAny(typedContract.directorApprovalsRequired)
	then
		table.insert(
			issues,
			issue(
				typedContract,
				"MAJOR_HORROR_WITHOUT_DIRECTOR",
				"Error",
				"Major horror surfaces require Director approval rules."
			)
		)
	end

	if
		typedContract.ownerLayer == "Execution" and not hasAny(typedContract.executionPermissions)
	then
		table.insert(
			issues,
			issue(
				typedContract,
				"NO_EXECUTION_PERMISSIONS",
				"Error",
				"Execution systems must declare permissions."
			)
		)
	end

	if
		typedContract.ownerLayer == "AI"
		and textContainsAny(
			typedContract.responsibilities,
			{ "pacing", "climax", "scare selection", "reveal timing" }
		)
	then
		table.insert(
			issues,
			issue(
				typedContract,
				"MONSTER_AI_PACING",
				"Error",
				"Monster AI cannot own horror pacing, reveal timing, scare selection, or chapter climax."
			)
		)
	end

	if
		typedContract.ownerLayer == "Execution"
		and textContainsAny(
			typedContract.responsibilities,
			{ "pacing", "decide", "select scare", "choose scare" }
		)
	then
		table.insert(
			issues,
			issue(
				typedContract,
				"EXECUTION_INVENTS_PACING",
				"Error",
				"Execution systems cannot invent pacing decisions."
			)
		)
	end

	if
		textContains(typedContract.responsibilities, "remote")
		and typedContract.ownerLayer ~= "Core"
		and not textContains(typedContract.dependencies, "RemoteManager")
	then
		table.insert(
			issues,
			issue(
				typedContract,
				"REMOTE_MANAGER_MISSING",
				"Error",
				"Remote-owning systems must depend on RemoteManager."
			)
		)
	end

	if typedContract.status == "Production" then
		if not hasAny(typedContract.diagnosticsExposed) then
			table.insert(
				issues,
				issue(
					typedContract,
					"MISSING_DIAGNOSTICS",
					"Error",
					"Production systems must expose diagnostics."
				)
			)
		end

		if not hasAny(typedContract.snapshotProviders) then
			table.insert(
				issues,
				issue(
					typedContract,
					"MISSING_SNAPSHOT",
					"Error",
					"Production systems must expose or justify snapshot providers."
				)
			)
		end

		if not hasAny(typedContract.cleanupBehavior) then
			table.insert(
				issues,
				issue(
					typedContract,
					"MISSING_CLEANUP",
					"Error",
					"Production systems must declare cleanup behavior."
				)
			)
		end

		if not hasAny(typedContract.multiplayerGuarantees) then
			table.insert(
				issues,
				issue(
					typedContract,
					"MISSING_MULTIPLAYER_GUARANTEES",
					"Error",
					"Production systems must declare multiplayer guarantees."
				)
			)
		end

		if not hasAny(typedContract.documentation) then
			table.insert(
				issues,
				issue(
					typedContract,
					"MISSING_DOCUMENTATION",
					"Error",
					"Production systems must declare documentation."
				)
			)
		end

		if not hasAny(typedContract.failureModes) then
			table.insert(
				issues,
				issue(
					typedContract,
					"MISSING_FAILURE_MODES",
					"Error",
					"Production systems must document failure modes."
				)
			)
		end
	end

	if
		typedContract.ownerLayer == "Observation"
		and textContainsAny(typedContract.responsibilities, { "execute", "play", "move", "save" })
	then
		table.insert(
			issues,
			issue(
				typedContract,
				"OBSERVATION_EXECUTION_LEAK",
				"Error",
				"Observation Engine owns truth, not execution."
			)
		)
	end

	if
		typedContract.ownerLayer == "Director"
		and textContainsAny(
			typedContract.responsibilities,
			{ "movement", "pathfinding", "hitbox", "animation state" }
		)
	then
		table.insert(
			issues,
			issue(
				typedContract,
				"DIRECTOR_MOVEMENT_LEAK",
				"Error",
				"Directors approve; they do not own physical movement."
			)
		)
	end

	validateObservationRules(typedContract, issues)
	validateApprovalRules(typedContract, issues)
	validateExecutionPermissions(typedContract, issues)

	if #issues == 0 then
		table.insert(
			issues,
			issue(
				typedContract,
				"CONTRACT_PASSED",
				"Pass",
				"Contract satisfies current governance validation."
			)
		)
	end

	return issues
end

function EngineContractValidator.hasErrors(issues: { ContractIssue }): boolean
	for _, contractIssue in ipairs(issues) do
		if contractIssue.severity == "Error" or contractIssue.severity == "Fatal" then
			return true
		end
	end

	return false
end

function EngineContractValidator.hasBlockingIssues(issues: { ContractIssue }): boolean
	return EngineContractValidator.hasErrors(issues)
end

function EngineContractValidator.summarize(
	issues: { ContractIssue },
	lastValidatedAt: number
): Types.ValidationSummary
	local fatalIssues = 0
	local errorIssues = 0
	local warningIssues = 0
	local infoIssues = 0

	for _, contractIssue in ipairs(issues) do
		if contractIssue.severity == "Fatal" then
			fatalIssues += 1
		elseif contractIssue.severity == "Error" then
			errorIssues += 1
		elseif contractIssue.severity == "Warning" then
			warningIssues += 1
		elseif contractIssue.severity == "Info" then
			infoIssues += 1
		end
	end

	local health: Types.GovernanceHealth = "Healthy"

	if fatalIssues > 0 or errorIssues > 0 then
		health = "Failed"
	elseif warningIssues > 0 then
		health = "Warning"
	elseif lastValidatedAt <= 0 then
		health = "NotValidated"
	end

	return {
		health = health,
		totalIssues = fatalIssues + errorIssues + warningIssues + infoIssues,
		fatalIssues = fatalIssues,
		errorIssues = errorIssues,
		warningIssues = warningIssues,
		infoIssues = infoIssues,
		lastValidatedAt = lastValidatedAt,
	}
end

return EngineContractValidator
