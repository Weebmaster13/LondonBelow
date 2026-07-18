--!strict

local Types = require(script.Parent.Types)

local Decision = {}

function Decision.fromEvaluation(evaluatedRules: { any }): string
	local failed = 0
	local invalid = 0
	for _, rule in ipairs(evaluatedRules) do
		if rule.outcome == Types.RuleOutcome.Invalid then
			invalid += 1
		elseif rule.outcome ~= Types.RuleOutcome.Pass then
			failed += 1
		end
	end
	if invalid > 0 then
		return Types.Decision.Invalid
	elseif failed > 0 then
		return Types.Decision.Denied
	end
	return Types.Decision.Blocked
end

function Decision.classification(decision: string): string
	if decision == Types.Decision.Blocked then
		return Types.AuthorizationClassification.PlanningAuthorizedButExecutionBlocked
	elseif decision == Types.Decision.Denied then
		return Types.AuthorizationClassification.PlanningDenied
	elseif decision == Types.Decision.Invalid then
		return Types.AuthorizationClassification.Invalid
	end
	return Types.AuthorizationClassification.MetadataOnly
end

return Decision
