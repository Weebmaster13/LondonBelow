--!strict
--[[
	Structured scorecards for London Engine subsystem contracts.

	Owns the 100000/10 standard as inspectable categories rather than a vague
	compliment.

	Does not replace validation. A system can score well and still have a
	specific governance issue that must be fixed.
]]

local Types = require(script.Parent.EngineContractTypes)

local EngineScorecard = {}

type EngineContract = Types.EngineContract
type Scorecard = Types.Scorecard

local MAX_PER_CATEGORY = 10

local function has(values: { any }): boolean
	return #values > 0
end

local function scoreSingleResponsibility(contract: EngineContract): number
	if #contract.responsibilities == 0 then
		return 0
	elseif #contract.responsibilities <= 5 then
		return 10
	elseif #contract.responsibilities <= 9 then
		return 7
	end

	return 4
end

function EngineScorecard.score(
	contract: EngineContract,
	issues: { Types.ContractIssue }?
): Scorecard
	local blockingIssues = 0
	local warningIssues = 0

	for _, contractIssue in ipairs(issues or {}) do
		if contractIssue.severity == "Fatal" or contractIssue.severity == "Error" then
			blockingIssues += 1
		elseif contractIssue.severity == "Warning" then
			warningIssues += 1
		end
	end

	local categories = {
		singleResponsibility = scoreSingleResponsibility(contract),
		serverAuthority = if contract.clientPresentation.allowed
				and not contract.clientPresentation.mustBeServerApproved
			then 2
			else 10,
		observationOutput = if contract.ownerLayer == "Gameplay"
				and not has(contract.observationsEmitted)
			then 0
			elseif has(contract.observationsEmitted) or contract.ownerLayer == "Observation" then 10
			else 7,
		directorIntegration = if has(contract.directorApprovalsRequired)
				or contract.ownerLayer == "Director"
				or contract.ownerLayer == "Core"
				or contract.ownerLayer == "Observation"
			then 10
			elseif contract.ownerLayer == "AI" or contract.ownerLayer == "Execution" then 6
			else 7,
		diagnostics = if has(contract.diagnosticsExposed) then 10 else 0,
		snapshotSupport = if has(contract.snapshotProviders) then 10 else 2,
		cleanup = if has(contract.cleanupBehavior) then 10 else 0,
		multiplayerSafety = if has(contract.multiplayerGuarantees) then 10 else 0,
		documentation = if has(contract.documentation) then 10 else 0,
		extensibility = if has(contract.doesNotOwn) and #contract.doesNotOwn >= 2 then 10 else 4,
		failureSafety = if has(contract.failureModes) then 10 else 0,
	}

	local total = 0
	local max = 0

	for _, value in pairs(categories) do
		total += value
		max += MAX_PER_CATEGORY
	end

	local notes = {}

	if categories.singleResponsibility < 10 then
		table.insert(notes, "Review responsibility count for possible system split.")
	end

	if categories.observationOutput < 8 then
		table.insert(notes, "Gameplay truth should emit Observation Engine facts.")
	end

	if categories.snapshotSupport < 10 then
		table.insert(notes, "Consider adding SnapshotManager provider when runtime state grows.")
	end

	if blockingIssues > 0 then
		table.insert(notes, "Blocking governance issues must be fixed before production readiness.")
	end

	if warningIssues > 0 then
		table.insert(notes, "Warnings should be reviewed before expanding this subsystem.")
	end

	local percentage = total / max
	local passed = blockingIssues == 0 and percentage >= 0.8
	local grade: "Excellent" | "Good" | "Weak" | "Failing" = "Failing"

	if blockingIssues > 0 or percentage < 0.65 then
		grade = "Failing"
	elseif percentage < 0.8 then
		grade = "Weak"
	elseif percentage < 0.92 then
		grade = "Good"
	else
		grade = "Excellent"
	end

	return {
		systemName = contract.systemName,
		total = total,
		max = max,
		percentage = percentage,
		passed = passed,
		grade = grade,
		categories = categories,
		notes = notes,
	}
end

return EngineScorecard
