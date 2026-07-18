--!strict

local Serialization = require(script.Parent.Serialization)
local Types = require(script.Parent.Types)

local Validation = {}

local function result(ok: boolean, code: string, reason: string?): (boolean, string?)
	return ok, if ok then nil else code .. ": " .. tostring(reason)
end

local function enumContains(enum: { [string]: string }, value: any): boolean
	for _, enumValue in pairs(enum) do
		if enumValue == value then
			return true
		end
	end
	return false
end

local function exactFields(value: any, fields: { string }, label: string): (boolean, string?)
	if type(value) ~= "table" then
		return result(false, Types.ResultCode.InvalidSchema, label .. " must be a table")
	end
	for _, field in ipairs(fields) do
		if value[field] == nil then
			return result(false, Types.ResultCode.InvalidSchema, label .. " missing " .. field)
		end
	end
	for key in pairs(value) do
		if not table.find(fields, key) then
			return result(
				false,
				Types.ResultCode.InvalidSchema,
				label .. " has unsupported field " .. tostring(key)
			)
		end
	end
	return result(true, Types.ResultCode.Ok, nil)
end

local function id(value: any, label: string): (boolean, string?)
	if type(value) ~= "string" or value == "" or string.find(value, "%s") ~= nil then
		return result(false, Types.ResultCode.InvalidSchema, label .. " must be stable id")
	end
	return result(true, Types.ResultCode.Ok, nil)
end

local function metadata(value: any): (boolean, string?)
	if type(value) ~= "table" then
		return result(false, Types.ResultCode.InvalidSchema, "metadata must be table")
	end
	local unsafe, reason = Serialization.hasUnsafePayload(value)
	if unsafe then
		return result(false, Types.ResultCode.UnsafePayload, reason)
	end
	return result(true, Types.ResultCode.Ok, nil)
end

function Validation.policy(policy: any): (boolean, string?)
	local ok, reason = exactFields(policy, Types.PolicyFields, "authorization policy")
	if not ok then
		return ok, reason
	end
	ok, reason = id(policy.policyId, "policyId")
	if not ok then
		return ok, reason
	end
	if not enumContains(Types.PolicyKind, policy.policyKind) then
		return result(false, Types.ResultCode.InvalidSchema, "unsupported policyKind")
	end
	if policy.policyVersion ~= Types.PolicyVersion then
		return result(false, Types.ResultCode.VersionMismatch, "policy version mismatch")
	end
	if type(policy.required) ~= "boolean" then
		return result(false, Types.ResultCode.InvalidSchema, "required must be boolean")
	end
	if type(policy.ruleIds) ~= "table" then
		return result(false, Types.ResultCode.InvalidSchema, "ruleIds must be array")
	end
	for index, ruleId in ipairs(policy.ruleIds) do
		ok, reason = id(ruleId, "ruleIds[" .. tostring(index) .. "]")
		if not ok then
			return ok, reason
		end
	end
	return metadata(policy.metadata)
end

function Validation.rule(rule: any): (boolean, string?)
	local ok, reason = exactFields(rule, Types.RuleFields, "authorization rule")
	if not ok then
		return ok, reason
	end
	for _, field in ipairs({ "ruleId", "policyId" }) do
		ok, reason = id(rule[field], field)
		if not ok then
			return ok, reason
		end
	end
	if not enumContains(Types.RuleKind, rule.ruleKind) then
		return result(false, Types.ResultCode.InvalidSchema, "unsupported ruleKind")
	end
	if type(rule.expected) ~= "boolean" then
		return result(false, Types.ResultCode.InvalidSchema, "expected must be boolean")
	end
	return metadata(rule.metadata)
end

function Validation.planningPublication(planning: any): (boolean, string?)
	if type(planning) ~= "table" or type(planning.publication) ~= "table" then
		return result(
			false,
			Types.ResultCode.MissingPlanningPublication,
			"planning publication missing"
		)
	end
	local publication = planning.publication
	if type(publication.planId) ~= "string" or publication.planId == "" then
		return result(false, Types.ResultCode.MissingPlanningPublication, "planId missing")
	end
	if publication.planVersion ~= Types.RequiredPlanningVersion then
		return result(false, Types.ResultCode.VersionMismatch, "planning version mismatch")
	end
	if publication.publicationState ~= "PUBLISHED" then
		return result(false, Types.ResultCode.InvalidSchema, "planning publication not published")
	end
	if publication.runtimeTruth == nil or publication.runtimeTruth.executionBlocked ~= true then
		return result(false, Types.ResultCode.InvalidSchema, "planning runtime truth drift")
	end
	return result(true, Types.ResultCode.Ok, nil)
end

function Validation.decision(decision: any): (boolean, string?)
	local ok, reason = exactFields(decision, Types.DecisionFields, "authorization decision")
	if not ok then
		return ok, reason
	end
	for _, field in ipairs({
		"authorizationId",
		"planningId",
		"planningVersion",
		"ruleSetVersion",
		"policyVersion",
	}) do
		ok, reason = id(decision[field], field)
		if not ok then
			return ok, reason
		end
	end
	if decision.planningVersion ~= Types.RequiredPlanningVersion then
		return result(false, Types.ResultCode.VersionMismatch, "decision planning version mismatch")
	end
	if
		decision.ruleSetVersion ~= Types.RuleSetVersion
		or decision.policyVersion ~= Types.PolicyVersion
	then
		return result(
			false,
			Types.ResultCode.VersionMismatch,
			"decision policy/rule version mismatch"
		)
	end
	if not enumContains(Types.Decision, decision.decision) then
		return result(false, Types.ResultCode.InvalidDecision, "unsupported decision")
	end
	if
		not enumContains(Types.AuthorizationClassification, decision.authorizationClassification)
	then
		return result(false, Types.ResultCode.InvalidClassification, "unsupported classification")
	end
	if type(decision.evaluatedRules) ~= "table" then
		return result(false, Types.ResultCode.InvalidSchema, "evaluatedRules must be array")
	end
	if
		decision.blockedRuntimeTruth.executionBlocked ~= true
		or decision.blockedRuntimeTruth.runnerInvoked ~= false
	then
		return result(false, Types.ResultCode.InvalidSchema, "blocked runtime truth drift")
	end
	if type(decision.orderingKey) ~= "number" then
		return result(false, Types.ResultCode.InvalidSchema, "orderingKey must be number")
	end
	if decision.publicationState ~= Types.PublicationState.Published then
		return result(false, Types.ResultCode.PublicationRejected, "decision must be published")
	end
	return metadata(decision.metadata)
end

function Validation.lifecycle(transitions: { string }): (boolean, string?)
	local expected = {
		Types.LifecycleState.Uninitialized,
		Types.LifecycleState.Bootstrapping,
		Types.LifecycleState.PolicyLoading,
		Types.LifecycleState.RuleValidation,
		Types.LifecycleState.AuthorizationEvaluation,
		Types.LifecycleState.DecisionBuilding,
		Types.LifecycleState.DecisionPublication,
		Types.LifecycleState.Complete,
	}
	if #transitions ~= #expected then
		return result(false, Types.ResultCode.InvalidSchema, "lifecycle transition count invalid")
	end
	for index, state in ipairs(expected) do
		if transitions[index] ~= state then
			return result(
				false,
				Types.ResultCode.InvalidSchema,
				"lifecycle transition ordering invalid"
			)
		end
	end
	return result(true, Types.ResultCode.Ok, nil)
end

function Validation.validate(): (boolean, string?)
	if Types.RuntimeProviderName ~= "executionAuthorizationRuntime" then
		return result(false, Types.ResultCode.InvalidSchema, "provider drift")
	end
	if Types.RuntimeTruth.executionBlocked ~= true or Types.RuntimeTruth.runnerInvoked ~= false then
		return result(false, Types.ResultCode.InvalidSchema, "runtime truth drift")
	end
	return result(true, Types.ResultCode.Ok, nil)
end

return Validation
