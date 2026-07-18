--!strict

local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local RuleSet = {}

function RuleSet.defaultRules(): { any }
	return {
		{
			ruleId = "rule.runtime.blocked",
			policyId = "policy.runtime.truth",
			ruleKind = Types.RuleKind.RuntimeBlocked,
			expected = true,
			metadata = { metadataOnly = true },
		},
		{
			ruleId = "rule.planning.complete",
			policyId = "policy.planning.integrity",
			ruleKind = Types.RuleKind.PlanningComplete,
			expected = true,
			metadata = { metadataOnly = true },
		},
		{
			ruleId = "rule.dependencies.valid",
			policyId = "policy.planning.integrity",
			ruleKind = Types.RuleKind.DependenciesValid,
			expected = true,
			metadata = { metadataOnly = true },
		},
		{
			ruleId = "rule.constraints.valid",
			policyId = "policy.planning.integrity",
			ruleKind = Types.RuleKind.ConstraintsValid,
			expected = true,
			metadata = { metadataOnly = true },
		},
		{
			ruleId = "rule.eligibility.not.invalid",
			policyId = "policy.planning.integrity",
			ruleKind = Types.RuleKind.EligibilityNotInvalid,
			expected = true,
			metadata = { metadataOnly = true },
		},
		{
			ruleId = "rule.runtime.truth.preserved",
			policyId = "policy.runtime.truth",
			ruleKind = Types.RuleKind.RuntimeTruthPreserved,
			expected = true,
			metadata = { metadataOnly = true },
		},
		{
			ruleId = "rule.authority.identity.supported",
			policyId = "policy.version.compatibility",
			ruleKind = Types.RuleKind.AuthorityIdentitySupported,
			expected = true,
			metadata = { metadataOnly = true },
		},
		{
			ruleId = "rule.planning.version.supported",
			policyId = "policy.version.compatibility",
			ruleKind = Types.RuleKind.PlanningVersionSupported,
			expected = true,
			metadata = { metadataOnly = true },
		},
	}
end

function RuleSet.validateAll(rules: { any }, policies: { any }): (boolean, string?)
	if #rules > Types.Limits.MaxRules then
		return false, Types.ResultCode.InvalidSchema .. ": rule limit exceeded"
	end
	local policiesById = {}
	for _, policy in ipairs(policies) do
		policiesById[policy.policyId] = true
	end
	local seen = {}
	for _, rule in ipairs(rules) do
		local ok, reason = Validation.rule(rule)
		if not ok then
			return ok, reason
		end
		if seen[rule.ruleId] then
			return false, Types.ResultCode.DuplicateRule .. ": " .. rule.ruleId
		end
		if not policiesById[rule.policyId] then
			return false, Types.ResultCode.InvalidSchema .. ": rule references unknown policy"
		end
		seen[rule.ruleId] = true
	end
	return true, nil
end

return RuleSet
