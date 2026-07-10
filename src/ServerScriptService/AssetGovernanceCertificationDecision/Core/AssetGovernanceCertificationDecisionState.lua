--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationDecisionSerialization)
local Types = require(script.Parent.AssetGovernanceCertificationDecisionTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationDecisionValidation)

local State = {}

local decisions: { [string]: any } = {}
local requirements: { [string]: any } = {}
local evaluations: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = { decisions = 0, requirements = 0, evaluations = 0, audits = 0 }

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function hasAll(map: { [string]: any }, values: any, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	for _, id in ipairs(values) do
		if map[id] == nil then
			return false, "invalid " .. label .. " reference"
		end
	end
	return true, nil
end

local function register(
	map: { [string]: any },
	id: string,
	schema: any,
	limit: number,
	duplicate: string,
	limitReason: string,
	countKey: "decisions" | "requirements" | "evaluations" | "audits"
): (boolean, string?)
	if schemaIds[id] == true then
		return false, duplicate
	end
	if counts[countKey] >= limit then
		return false, limitReason
	end
	schemaIds[id] = true
	map[id] = Serialization.deepCopy(schema)
	counts[countKey] += 1
	return true, nil
end

function State.registerDecision(schema: any): (boolean, string?)
	local ok, reason = Validation.decision(schema)
	if not ok then
		return false, reason
	end
	local requirementOk, requirementReason =
		hasAll(requirements, schema.requirementIds, "requirement")
	if not requirementOk then
		return false, requirementReason
	end
	local evaluationOk, evaluationReason = hasAll(evaluations, schema.evaluationIds, "evaluation")
	if not evaluationOk then
		return false, evaluationReason
	end
	local auditOk, auditReason = hasAll(audits, schema.auditIds, "audit")
	if not auditOk then
		return false, auditReason
	end
	return register(
		decisions,
		schema.decisionId,
		schema,
		Types.Limits.MaxDecisions,
		"duplicate decisionId",
		"decision limit exceeded",
		"decisions"
	)
end

function State.registerRequirement(schema: any): (boolean, string?)
	local ok, reason = Validation.requirement(schema)
	if not ok then
		return false, reason
	end
	local decisionOk, decisionReason = hasAll(decisions, { schema.decisionId }, "decision")
	if not decisionOk then
		return false, decisionReason
	end
	return register(
		requirements,
		schema.requirementId,
		schema,
		Types.Limits.MaxRequirements,
		"duplicate requirementId",
		"requirement limit exceeded",
		"requirements"
	)
end

function State.registerEvaluation(schema: any): (boolean, string?)
	local ok, reason = Validation.evaluation(schema)
	if not ok then
		return false, reason
	end
	local decisionOk, decisionReason = hasAll(decisions, { schema.decisionId }, "decision")
	if not decisionOk then
		return false, decisionReason
	end
	local requirementOk, requirementReason =
		hasAll(requirements, { schema.requirementId }, "requirement")
	if not requirementOk then
		return false, requirementReason
	end
	return register(
		evaluations,
		schema.evaluationId,
		schema,
		Types.Limits.MaxEvaluations,
		"duplicate evaluationId",
		"evaluation limit exceeded",
		"evaluations"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	local decisionOk, decisionReason = hasAll(decisions, { schema.decisionId }, "decision")
	if not decisionOk then
		return false, decisionReason
	end
	local evaluationOk, evaluationReason = hasAll(evaluations, schema.evaluationIds, "evaluation")
	if not evaluationOk then
		return false, evaluationReason
	end
	return register(
		audits,
		schema.auditId,
		schema,
		Types.Limits.MaxAudits,
		"duplicate auditId",
		"audit limit exceeded",
		"audits"
	)
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(
		validationFailures,
		{ reason = reason, payload = Serialization.diagnosticCopy(payload) },
		Types.Limits.MaxValidationFailures
	)
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function State.inspect()
	return Serialization.deepCopy({
		decisions = decisions,
		requirements = requirements,
		evaluations = evaluations,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			decisions = counts.decisions,
			requirements = counts.requirements,
			evaluations = counts.evaluations,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(decisions)
	table.clear(requirements)
	table.clear(evaluations)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.decisions = 0
	counts.requirements = 0
	counts.evaluations = 0
	counts.audits = 0
end

return State
