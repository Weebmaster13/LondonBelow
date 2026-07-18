--!strict

local Evaluator = require(script.Parent.Evaluator)
local Policy = require(script.Parent.Policy)
local Publisher = require(script.Parent.Publisher)
local RuleSet = require(script.Parent.RuleSet)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Authorization = {}

local lifecycle = {
	Types.LifecycleState.Uninitialized,
	Types.LifecycleState.Bootstrapping,
	Types.LifecycleState.PolicyLoading,
	Types.LifecycleState.RuleValidation,
	Types.LifecycleState.AuthorizationEvaluation,
	Types.LifecycleState.DecisionBuilding,
	Types.LifecycleState.DecisionPublication,
	Types.LifecycleState.Complete,
}

function Authorization.evaluate(input: any): any
	State.clear()
	local lifecycleOk, lifecycleReason = Validation.lifecycle(lifecycle)
	if not lifecycleOk then
		State.recordValidationFailure(lifecycleReason or "invalid lifecycle", input)
		State.transition(Types.LifecycleState.Failed)
		return { ok = false, reason = lifecycleReason, state = Types.LifecycleState.Failed }
	end
	State.transition(Types.LifecycleState.Bootstrapping)
	State.transition(Types.LifecycleState.PolicyLoading)
	local policies = if type(input) == "table" and type(input.policies) == "table"
		then input.policies
		else Policy.defaultPolicies()
	local policiesOk, policiesReason = Policy.validateAll(policies)
	if not policiesOk then
		State.recordValidationFailure(policiesReason or "policy validation failed", policies)
		State.transition(Types.LifecycleState.Failed)
		return { ok = false, reason = policiesReason, state = Types.LifecycleState.Failed }
	end
	State.setPolicies(policies)
	State.transition(Types.LifecycleState.RuleValidation)
	local rules = if type(input) == "table" and type(input.rules) == "table"
		then input.rules
		else RuleSet.defaultRules()
	local rulesOk, rulesReason = RuleSet.validateAll(rules, policies)
	if not rulesOk then
		State.recordValidationFailure(rulesReason or "rule validation failed", rules)
		State.transition(Types.LifecycleState.Failed)
		return { ok = false, reason = rulesReason, state = Types.LifecycleState.Failed }
	end
	State.setRules(rules)
	State.transition(Types.LifecycleState.AuthorizationEvaluation)
	local planning = if type(input) == "table" then input.planning else nil
	local evaluatedOk, evaluatedRules, evaluatedReason = Evaluator.evaluate(planning, rules)
	if not evaluatedOk then
		State.recordValidationFailure(
			evaluatedReason or "authorization evaluation failed",
			planning
		)
		State.transition(Types.LifecycleState.Failed)
		return { ok = false, reason = evaluatedReason, state = Types.LifecycleState.Failed }
	end
	State.transition(Types.LifecycleState.DecisionBuilding)
	State.transition(Types.LifecycleState.DecisionPublication)
	local publishedOk, decision, publishedReason = Publisher.publish(planning, evaluatedRules)
	if not publishedOk then
		State.recordValidationFailure(
			publishedReason or "decision publication failed",
			evaluatedRules
		)
		State.transition(Types.LifecycleState.Failed)
		return { ok = false, reason = publishedReason, state = Types.LifecycleState.Failed }
	end
	State.setDecision(decision)
	State.transition(Types.LifecycleState.Complete)
	return {
		ok = true,
		state = Types.LifecycleState.Complete,
		policies = policies,
		rules = rules,
		evaluatedRules = evaluatedRules,
		decision = decision,
		audit = State.audit(),
	}
end

return Authorization
