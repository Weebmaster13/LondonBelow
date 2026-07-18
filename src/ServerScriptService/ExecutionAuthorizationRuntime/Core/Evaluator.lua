--!strict

local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Evaluator = {}

local function outcome(rule: any, passed: boolean, detail: string): any
	return {
		ruleId = rule.ruleId,
		ruleKind = rule.ruleKind,
		outcome = if passed then Types.RuleOutcome.Pass else Types.RuleOutcome.Fail,
		detail = detail,
		orderingKey = 0,
	}
end

local function evaluateRule(rule: any, planning: any): any
	local publication = planning.publication
	if rule.ruleKind == Types.RuleKind.RuntimeBlocked then
		return outcome(
			rule,
			publication.runtimeTruth.executionBlocked == true,
			"execution remains blocked"
		)
	elseif rule.ruleKind == Types.RuleKind.PlanningComplete then
		return outcome(rule, publication.publicationState == "PUBLISHED", "planning is published")
	elseif rule.ruleKind == Types.RuleKind.DependenciesValid then
		return outcome(
			rule,
			type(publication.dependencySummary) == "table",
			"dependency summary exists"
		)
	elseif rule.ruleKind == Types.RuleKind.ConstraintsValid then
		return outcome(
			rule,
			type(publication.constraintSummary) == "table",
			"constraint summary exists"
		)
	elseif rule.ruleKind == Types.RuleKind.EligibilityNotInvalid then
		local summary = publication.eligibilitySummary or {}
		return outcome(rule, (summary.invalid or 0) == 0, "eligibility invalid count is zero")
	elseif rule.ruleKind == Types.RuleKind.RuntimeTruthPreserved then
		return outcome(
			rule,
			publication.runtimeTruth.runnerInvoked == false
				and publication.runtimeTruth.structuredResultCaptured == false,
			"runner and structured capture remain false"
		)
	elseif rule.ruleKind == Types.RuleKind.AuthorityIdentitySupported then
		return outcome(
			rule,
			publication.planningClassification ~= nil,
			"planning classification exists"
		)
	elseif rule.ruleKind == Types.RuleKind.PlanningVersionSupported then
		return outcome(
			rule,
			publication.planVersion == Types.RequiredPlanningVersion,
			"planning version supported"
		)
	end
	return {
		ruleId = rule.ruleId,
		ruleKind = rule.ruleKind,
		outcome = Types.RuleOutcome.Invalid,
		detail = "unsupported rule kind",
		orderingKey = 0,
	}
end

function Evaluator.evaluate(planning: any, rules: { any }): (boolean, any, string?)
	local planningOk, planningReason = Validation.planningPublication(planning)
	if not planningOk then
		return false, nil, planningReason
	end
	local evaluated = {}
	for index, rule in ipairs(rules) do
		local item = evaluateRule(rule, planning)
		item.orderingKey = index
		table.insert(evaluated, item)
	end
	return true, evaluated, nil
end

return Evaluator
