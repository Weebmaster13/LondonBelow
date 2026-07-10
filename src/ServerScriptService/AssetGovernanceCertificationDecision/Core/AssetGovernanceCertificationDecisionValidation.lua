--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationDecisionSerialization)
local Types = require(script.Parent.AssetGovernanceCertificationDecisionTypes)

local Validation = {}

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 150
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function validateArrayIds(values: any, limit: number, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	if type(values) ~= "table" then
		return false, label .. " must be a table"
	end
	if #values > limit then
		return false, label .. " exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] then
			return false, label .. " contains duplicate id"
		end
		seen[value] = true
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return false, "tags are required"
	end
	return validateArrayIds(tags, Types.Limits.MaxTags, "tags")
end

local function validateEvidence(values: any): (boolean, string?)
	if values == nil then
		return false, "evidence is required"
	end
	return validateArrayIds(values, Types.Limits.MaxEvidence, "evidence")
end

local function validateSchema(
	schema: any,
	idField: string,
	expectedType: string,
	label: string
): (boolean, string?)
	if schema == nil then
		return false, label .. " schema is nil"
	end
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema[idField]) then
		return false, label .. " id is invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= expectedType then
		return false, "unsupported " .. label .. " schema type"
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	if type(schema.metadata) ~= "table" then
		return false, label .. " metadata is required"
	end
	return true, nil
end

local function validateRuntimeProviderSnapshot(schema: any): (boolean, string?)
	local runtimeOrder = Types.RuntimeName[schema.runtimeName]
	if runtimeOrder == nil then
		return false, "runtimeName is unsupported"
	end
	if Types.ProviderName[schema.providerName] ~= runtimeOrder then
		return false, "providerName does not match runtimeName"
	end
	if Types.SnapshotProviderName[schema.snapshotProviderName] ~= runtimeOrder then
		return false, "snapshotProviderName does not match runtimeName"
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	return Serialization.validateSerializable(payload)
end

function Validation.decision(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "decisionId", Types.SchemaType.GovernanceDecision, "decision")
	if not ok then
		return false, reason
	end
	if not validId(schema.inspectionId) then
		return false, "decision inspectionId is invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeProviderSnapshot(schema)
	if not runtimeOk then
		return false, runtimeReason
	end
	if Types.DecisionKind[schema.decisionKind] ~= true then
		return false, "decision kind is invalid"
	end
	if Types.DecisionStatus[schema.decisionStatus] ~= true then
		return false, "decision status is invalid"
	end
	if schema.requirementIds == nil then
		return false, "requirementIds are required"
	end
	if schema.evaluationIds == nil then
		return false, "evaluationIds are required"
	end
	if schema.auditIds == nil then
		return false, "auditIds are required"
	end
	for _, group in ipairs({
		{ schema.requirementIds, "requirementIds" },
		{ schema.evaluationIds, "evaluationIds" },
		{ schema.auditIds, "auditIds" },
	}) do
		local listOk, listReason =
			validateArrayIds(group[1], Types.Limits.MaxDecisionChildren, group[2])
		if not listOk then
			return false, listReason
		end
	end
	return validateEvidence(schema.evidence)
end

function Validation.requirement(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"requirementId",
		Types.SchemaType.GovernanceDecisionRequirement,
		"requirement"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.decisionId) then
		return false, "requirement decisionId is invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeProviderSnapshot(schema)
	if not runtimeOk then
		return false, runtimeReason
	end
	if Types.RequirementKind[schema.requirementKind] ~= true then
		return false, "requirement kind is invalid"
	end
	if Types.RequirementStatus[schema.requirementStatus] ~= true then
		return false, "requirement status is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.evaluation(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"evaluationId",
		Types.SchemaType.GovernanceDecisionEvaluation,
		"evaluation"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.decisionId) then
		return false, "evaluation decisionId is invalid"
	end
	if not validId(schema.requirementId) then
		return false, "evaluation requirementId is invalid"
	end
	local runtimeOk, runtimeReason = validateRuntimeProviderSnapshot(schema)
	if not runtimeOk then
		return false, runtimeReason
	end
	if Types.EvaluationKind[schema.evaluationKind] ~= true then
		return false, "evaluation kind is invalid"
	end
	if Types.EvaluationStatus[schema.evaluationStatus] ~= true then
		return false, "evaluation status is invalid"
	end
	return validateEvidence(schema.evidence)
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.GovernanceDecisionAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.decisionId) then
		return false, "audit decisionId is invalid"
	end
	if Types.AuditKind[schema.auditKind] ~= true then
		return false, "audit kind is invalid"
	end
	if Types.AuditStatus[schema.auditStatus] ~= true then
		return false, "audit status is invalid"
	end
	if not validId(schema.reviewer) then
		return false, "audit reviewer is invalid"
	end
	if schema.evaluationIds == nil then
		return false, "evaluationIds are required"
	end
	local evaluationOk, evaluationReason =
		validateArrayIds(schema.evaluationIds, Types.Limits.MaxDecisionChildren, "evaluationIds")
	if not evaluationOk then
		return false, evaluationReason
	end
	return validateEvidence(schema.evidence)
end

function Validation.validate(): (boolean, string?)
	return true, nil
end

return Validation
