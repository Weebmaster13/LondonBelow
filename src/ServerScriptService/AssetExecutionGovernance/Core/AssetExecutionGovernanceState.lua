--!strict

local Serialization = require(script.Parent.AssetExecutionGovernanceSerialization)
local Types = require(script.Parent.AssetExecutionGovernanceTypes)
local Validation = require(script.Parent.AssetExecutionGovernanceValidation)

local State = {}

local governanceRecords: { [string]: any } = {}
local requirements: { [string]: any } = {}
local assessments: { [string]: any } = {}
local findings: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = {
	governance = 0,
	requirements = 0,
	assessments = 0,
	findings = 0,
	audits = 0,
}

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

local function hasAllForParent(
	map: { [string]: any },
	values: any,
	label: string,
	parentField: string,
	parentId: string
): (boolean, string?)
	local ok, reason = hasAll(map, values, label)
	if not ok then
		return false, reason
	end
	for _, id in ipairs(values) do
		if map[id][parentField] ~= parentId then
			return false, "invalid " .. label .. " parent reference"
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
	countKey: "governance" | "requirements" | "assessments" | "findings" | "audits"
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

function State.registerGovernance(schema: any): (boolean, string?)
	local ok, reason = Validation.governance(schema)
	if not ok then
		return false, reason
	end
	local requirementOk, requirementReason = hasAllForParent(
		requirements,
		schema.requirementIds,
		"requirement",
		"governanceId",
		schema.governanceId
	)
	if not requirementOk then
		return false, requirementReason
	end
	local assessmentOk, assessmentReason = hasAllForParent(
		assessments,
		schema.assessmentIds,
		"assessment",
		"governanceId",
		schema.governanceId
	)
	if not assessmentOk then
		return false, assessmentReason
	end
	local findingOk, findingReason =
		hasAllForParent(findings, schema.findingIds, "finding", "governanceId", schema.governanceId)
	if not findingOk then
		return false, findingReason
	end
	local auditOk, auditReason =
		hasAllForParent(audits, schema.auditIds, "audit", "governanceId", schema.governanceId)
	if not auditOk then
		return false, auditReason
	end
	return register(
		governanceRecords,
		schema.governanceId,
		schema,
		Types.Limits.MaxGovernance,
		"duplicate governanceId",
		"governance limit exceeded",
		"governance"
	)
end

function State.registerRequirement(schema: any): (boolean, string?)
	local ok, reason = Validation.requirement(schema)
	if not ok then
		return false, reason
	end
	local governanceOk, governanceReason =
		hasAll(governanceRecords, { schema.governanceId }, "governance")
	if not governanceOk then
		return false, governanceReason
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

function State.registerAssessment(schema: any): (boolean, string?)
	local ok, reason = Validation.assessment(schema)
	if not ok then
		return false, reason
	end
	local governanceOk, governanceReason =
		hasAll(governanceRecords, { schema.governanceId }, "governance")
	if not governanceOk then
		return false, governanceReason
	end
	local requirementOk, requirementReason =
		hasAll(requirements, { schema.requirementId }, "requirement")
	if not requirementOk then
		return false, requirementReason
	end
	if requirements[schema.requirementId].governanceId ~= schema.governanceId then
		return false, "invalid requirement parent reference"
	end
	return register(
		assessments,
		schema.assessmentId,
		schema,
		Types.Limits.MaxAssessments,
		"duplicate assessmentId",
		"assessment limit exceeded",
		"assessments"
	)
end

function State.registerFinding(schema: any): (boolean, string?)
	local ok, reason = Validation.finding(schema)
	if not ok then
		return false, reason
	end
	local governanceOk, governanceReason =
		hasAll(governanceRecords, { schema.governanceId }, "governance")
	if not governanceOk then
		return false, governanceReason
	end
	local assessmentOk, assessmentReason =
		hasAll(assessments, { schema.assessmentId }, "assessment")
	if not assessmentOk then
		return false, assessmentReason
	end
	if assessments[schema.assessmentId].governanceId ~= schema.governanceId then
		return false, "invalid assessment parent reference"
	end
	return register(
		findings,
		schema.findingId,
		schema,
		Types.Limits.MaxFindings,
		"duplicate findingId",
		"finding limit exceeded",
		"findings"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	local governanceOk, governanceReason =
		hasAll(governanceRecords, { schema.governanceId }, "governance")
	if not governanceOk then
		return false, governanceReason
	end
	local assessmentOk, assessmentReason = hasAllForParent(
		assessments,
		schema.assessmentIds,
		"assessment",
		"governanceId",
		schema.governanceId
	)
	if not assessmentOk then
		return false, assessmentReason
	end
	local findingOk, findingReason =
		hasAllForParent(findings, schema.findingIds, "finding", "governanceId", schema.governanceId)
	if not findingOk then
		return false, findingReason
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
		governance = governanceRecords,
		requirements = requirements,
		assessments = assessments,
		findings = findings,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			governance = counts.governance,
			requirements = counts.requirements,
			assessments = counts.assessments,
			findings = counts.findings,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(governanceRecords)
	table.clear(requirements)
	table.clear(assessments)
	table.clear(findings)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.governance = 0
	counts.requirements = 0
	counts.assessments = 0
	counts.findings = 0
	counts.audits = 0
end

return State
