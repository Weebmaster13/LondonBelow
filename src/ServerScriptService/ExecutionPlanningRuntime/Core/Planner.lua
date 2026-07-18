--!strict

local Constraint = require(script.Parent.Constraint)
local Eligibility = require(script.Parent.Eligibility)
local Graph = require(script.Parent.Graph)
local Publisher = require(script.Parent.Publisher)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Planner = {}

local lifecycle = {
	Types.LifecycleState.Uninitialized,
	Types.LifecycleState.Bootstrapping,
	Types.LifecycleState.GraphBuilding,
	Types.LifecycleState.DependencyValidation,
	Types.LifecycleState.ConstraintValidation,
	Types.LifecycleState.EligibilityAnalysis,
	Types.LifecycleState.PlanFinalization,
	Types.LifecycleState.PlanPublication,
	Types.LifecycleState.Complete,
}

function Planner.plan(input: any): any
	State.clear()
	local lifecycleOk, lifecycleReason = Validation.lifecycle(lifecycle)
	if not lifecycleOk then
		State.recordValidationFailure(lifecycleReason or "invalid lifecycle", input)
		State.transition(Types.LifecycleState.Failed)
		return { ok = false, reason = lifecycleReason, state = Types.LifecycleState.Failed }
	end
	State.transition(Types.LifecycleState.Bootstrapping)
	State.transition(Types.LifecycleState.GraphBuilding)
	local graphOk, graph, graphReason = Graph.build(input)
	if not graphOk then
		State.recordValidationFailure(graphReason or "graph build failed", input)
		State.transition(Types.LifecycleState.Failed)
		return { ok = false, reason = graphReason, state = Types.LifecycleState.Failed }
	end
	State.setGraph(graph)
	State.transition(Types.LifecycleState.DependencyValidation)
	State.transition(Types.LifecycleState.ConstraintValidation)
	local constraints = if type(input) == "table" and type(input.constraints) == "table"
		then input.constraints
		else {}
	local constraintsOk, constraintReason, constraintSummary =
		Constraint.evaluate(graph.nodesById, constraints)
	if not constraintsOk then
		State.recordValidationFailure(
			constraintReason or "constraint validation failed",
			constraints
		)
		State.transition(Types.LifecycleState.Failed)
		return { ok = false, reason = constraintReason, state = Types.LifecycleState.Failed }
	end
	State.transition(Types.LifecycleState.EligibilityAnalysis)
	local eligibilityStates = Eligibility.analyze(graph.nodes, constraints)
	State.transition(Types.LifecycleState.PlanFinalization)
	State.transition(Types.LifecycleState.PlanPublication)
	local publication = Publisher.publish(graph, constraintSummary, eligibilityStates)
	State.setPublication(publication)
	State.transition(Types.LifecycleState.Complete)
	return {
		ok = true,
		state = Types.LifecycleState.Complete,
		graph = graph,
		eligibilityStates = eligibilityStates,
		publication = publication,
		audit = State.audit(),
	}
end

return Planner
