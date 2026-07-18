--!strict

local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Policy = {}

function Policy.defaultPolicies(): { any }
	return {
		{
			policyId = "policy.planning.integrity",
			policyKind = Types.PolicyKind.PlanningIntegrity,
			policyVersion = Types.PolicyVersion,
			required = true,
			ruleIds = {
				"rule.planning.complete",
				"rule.dependencies.valid",
				"rule.constraints.valid",
				"rule.eligibility.not.invalid",
			},
			metadata = { metadataOnly = true },
		},
		{
			policyId = "policy.runtime.truth",
			policyKind = Types.PolicyKind.RuntimeTruth,
			policyVersion = Types.PolicyVersion,
			required = true,
			ruleIds = {
				"rule.runtime.blocked",
				"rule.runtime.truth.preserved",
			},
			metadata = { metadataOnly = true },
		},
		{
			policyId = "policy.version.compatibility",
			policyKind = Types.PolicyKind.VersionCompatibility,
			policyVersion = Types.PolicyVersion,
			required = true,
			ruleIds = {
				"rule.planning.version.supported",
				"rule.authority.identity.supported",
			},
			metadata = { metadataOnly = true },
		},
	}
end

function Policy.validateAll(policies: { any }): (boolean, string?)
	if #policies > Types.Limits.MaxPolicies then
		return false, Types.ResultCode.InvalidSchema .. ": policy limit exceeded"
	end
	local seen = {}
	for _, policy in ipairs(policies) do
		local ok, reason = Validation.policy(policy)
		if not ok then
			return ok, reason
		end
		if seen[policy.policyId] then
			return false, Types.ResultCode.DuplicatePolicy .. ": " .. policy.policyId
		end
		seen[policy.policyId] = true
	end
	return true, nil
end

return Policy
