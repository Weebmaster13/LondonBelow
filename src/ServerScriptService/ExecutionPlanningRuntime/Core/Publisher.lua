--!strict

local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)

local Publisher = {}

local function countEligibility(states: { [string]: string }): { [string]: number }
	local summary = {
		eligible = 0,
		notEligible = 0,
		blocked = 0,
		waiting = 0,
		invalid = 0,
		unknown = 0,
	}
	for _, state in pairs(states) do
		if state == Types.EligibilityState.Eligible then
			summary.eligible += 1
		elseif state == Types.EligibilityState.NotEligible then
			summary.notEligible += 1
		elseif state == Types.EligibilityState.Blocked then
			summary.blocked += 1
		elseif state == Types.EligibilityState.Waiting then
			summary.waiting += 1
		elseif state == Types.EligibilityState.Invalid then
			summary.invalid += 1
		else
			summary.unknown += 1
		end
	end
	return summary
end

function Publisher.publish(
	graph: any,
	constraintSummary: { [string]: number },
	eligibilityStates: { [string]: string }
): any
	local dependencySummary = {
		total = #graph.dependencies,
		nodes = #graph.nodes,
	}
	local eligibilitySummary = countEligibility(eligibilityStates)
	local structure = {
		graphId = graph.graphId,
		graphHash = graph.graphHash,
		dependencySummary = dependencySummary,
		constraintSummary = constraintSummary,
		eligibilitySummary = eligibilitySummary,
	}
	return {
		planId = graph.graphId .. ".plan",
		planVersion = Types.PlanVersion,
		graphId = graph.graphId,
		generationId = graph.graphId .. ".generation.001",
		createdAt = Types.StableTimestamp,
		planningClassification = Types.PlanningClassification.FutureExecutionPlanning,
		planningHash = Serialization.deterministicHash(structure),
		dependencySummary = dependencySummary,
		constraintSummary = constraintSummary,
		eligibilitySummary = eligibilitySummary,
		runtimeTruth = Serialization.deepCopy(Types.RuntimeTruth),
		publicationState = Types.PublicationState.Published,
	}
end

return Publisher
