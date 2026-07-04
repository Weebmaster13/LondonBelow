--!strict

local Serialization = require(script.Parent.AssetReadinessReviewSerialization)
local Types = require(script.Parent.AssetReadinessReviewTypes)
local Validation = require(script.Parent.AssetReadinessReviewValidation)

local State = {}

local checklists: { [string]: any } = {}
local findings: { [string]: any } = {}
local gates: { [string]: any } = {}
local decisions: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
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
	limitReason: string
): (boolean, string?)
	if schemaIds[id] == true then
		return false, duplicate
	end
	if countMap(map) >= limit then
		return false, limitReason
	end
	schemaIds[id] = true
	map[id] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerChecklist(schema: any): (boolean, string?)
	local ok, reason = Validation.checklist(schema)
	if not ok then
		return false, reason
	end
	local checks = {
		{ gates, schema.requiredGateIds, "gate" },
		{ findings, schema.findingIds, "finding" },
		{ decisions, schema.decisionIds, "decision" },
		{ audits, schema.auditIds, "audit" },
	}
	for _, check in ipairs(checks) do
		local refsOk, refsReason = hasAll(check[1], check[2], check[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		checklists,
		schema.checklistId,
		schema,
		Types.Limits.MaxChecklists,
		"duplicate checklistId",
		"checklist limit exceeded"
	)
end

local function registerChecklistChild(
	schema: any,
	validate: (any) -> (boolean, string?),
	map: { [string]: any },
	idField: string,
	limit: number,
	duplicate: string,
	limitReason: string
): (boolean, string?)
	local ok, reason = validate(schema)
	if not ok then
		return false, reason
	end
	if checklists[schema.checklistId] == nil then
		return false, "invalid checklistId reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerFinding(schema: any): (boolean, string?)
	return registerChecklistChild(
		schema,
		Validation.finding,
		findings,
		"findingId",
		Types.Limits.MaxFindings,
		"duplicate findingId",
		"finding limit exceeded"
	)
end

function State.registerGate(schema: any): (boolean, string?)
	return registerChecklistChild(
		schema,
		Validation.gate,
		gates,
		"gateId",
		Types.Limits.MaxGates,
		"duplicate gateId",
		"gate limit exceeded"
	)
end

function State.registerDecision(schema: any): (boolean, string?)
	return registerChecklistChild(
		schema,
		Validation.decision,
		decisions,
		"decisionId",
		Types.Limits.MaxDecisions,
		"duplicate decisionId",
		"decision limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerChecklistChild(
		schema,
		Validation.audit,
		audits,
		"auditId",
		Types.Limits.MaxAudits,
		"duplicate auditId",
		"audit limit exceeded"
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
		checklists = checklists,
		findings = findings,
		gates = gates,
		decisions = decisions,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			checklists = countMap(checklists),
			findings = countMap(findings),
			gates = countMap(gates),
			decisions = countMap(decisions),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(checklists)
	table.clear(findings)
	table.clear(gates)
	table.clear(decisions)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
