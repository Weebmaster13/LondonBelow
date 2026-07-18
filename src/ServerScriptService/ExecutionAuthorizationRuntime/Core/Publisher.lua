--!strict

local Decision = require(script.Parent.Decision)
local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Publisher = {}

function Publisher.publish(planning: any, evaluatedRules: { any }): (boolean, any, string?)
	local decision = Decision.fromEvaluation(evaluatedRules)
	local publication = planning.publication
	local record = {
		authorizationId = publication.planId .. ".authorization",
		planningId = publication.planId,
		planningVersion = publication.planVersion,
		ruleSetVersion = Types.RuleSetVersion,
		policyVersion = Types.PolicyVersion,
		decision = decision,
		evaluatedRules = Serialization.deepCopy(evaluatedRules),
		blockedRuntimeTruth = Serialization.deepCopy(Types.RuntimeTruth),
		authorizationClassification = Decision.classification(decision),
		metadata = {
			authorizationHash = Serialization.deterministicHash({
				planningId = publication.planId,
				evaluatedRules = evaluatedRules,
				decision = decision,
			}),
			metadataOnly = true,
		},
		orderingKey = 1,
		publicationState = Types.PublicationState.Published,
	}
	local ok, reason = Validation.decision(record)
	if not ok then
		return false, nil, reason
	end
	return true, record, nil
end

return Publisher
