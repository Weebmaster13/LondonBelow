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

function EngineScorecard.score(contract: EngineContract): Scorecard
	local categories = {
		singleResponsibility = scoreSingleResponsibility(contract),
		serverAuthority = if contract.clientPresentation.allowed
				and not contract.clientPresentation.mustBeServerApproved
			then 2
			else 10,
		observationOutput = if contract.ownerLayer == "Gameplay"
				and not has(contract.observationsEmitted)
			then 2
			else 8,
		directorIntegration = if has(contract.directorApprovalsRequired)
				or contract.ownerLayer == "Director"
				or contract.ownerLayer == "Core"
				or contract.ownerLayer == "Observation"
			then 10
			else 7,
		diagnostics = if has(contract.diagnosticsExposed) then 10 else 0,
		snapshotSupport = if has(contract.snapshotProviders) then 10 else 5,
		cleanup = if has(contract.cleanupBehavior) then 10 else 0,
		multiplayerSafety = if has(contract.multiplayerGuarantees) then 10 else 3,
		documentation = if has(contract.documentation) then 10 else 0,
		extensibility = if has(contract.doesNotOwn) and has(contract.dependencies) then 9 else 6,
		failureSafety = if has(contract.failureModes) then 10 else 3,
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

	return {
		systemName = contract.systemName,
		total = total,
		max = max,
		percentage = total / max,
		categories = categories,
		notes = notes,
	}
end

return EngineScorecard
