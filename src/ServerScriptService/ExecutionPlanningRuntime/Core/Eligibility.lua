--!strict

local Types = require(script.Parent.Types)

local Eligibility = {}

function Eligibility.analyze(nodes: { any }, constraints: { any }): { [string]: string }
	local blocked = {}
	for _, constraint in ipairs(constraints) do
		if constraint.constraintKind == Types.ConstraintKind.RuntimeBlocked then
			blocked[constraint.nodeId] = true
		elseif constraint.constraintKind == Types.ConstraintKind.VerificationIncomplete then
			blocked[constraint.nodeId] = "waiting"
		end
	end
	local states = {}
	for _, node in ipairs(nodes) do
		if blocked[node.nodeId] == true then
			states[node.nodeId] = Types.EligibilityState.Blocked
		elseif blocked[node.nodeId] == "waiting" then
			states[node.nodeId] = Types.EligibilityState.Waiting
		elseif node.planningClassification == Types.PlanningClassification.Invalid then
			states[node.nodeId] = Types.EligibilityState.Invalid
		else
			states[node.nodeId] = Types.EligibilityState.Eligible
		end
	end
	return states
end

return Eligibility
