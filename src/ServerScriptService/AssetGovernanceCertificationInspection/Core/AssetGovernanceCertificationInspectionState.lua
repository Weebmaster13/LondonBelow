--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationInspectionSerialization)
local Types = require(script.Parent.AssetGovernanceCertificationInspectionTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationInspectionValidation)

local State = {}

local inspections: { [string]: any } = {}
local observations: { [string]: any } = {}
local findings: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = { inspections = 0, observations = 0, findings = 0, audits = 0 }

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
	countKey: "inspections" | "observations" | "findings" | "audits"
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

function State.registerInspection(schema: any): (boolean, string?)
	local ok, reason = Validation.inspection(schema)
	if not ok then
		return false, reason
	end
	local observationOk, observationReason =
		hasAll(observations, schema.observationIds, "observation")
	if not observationOk then
		return false, observationReason
	end
	local findingOk, findingReason = hasAll(findings, schema.findingIds, "finding")
	if not findingOk then
		return false, findingReason
	end
	local auditOk, auditReason = hasAll(audits, schema.auditIds, "audit")
	if not auditOk then
		return false, auditReason
	end
	return register(
		inspections,
		schema.inspectionId,
		schema,
		Types.Limits.MaxInspections,
		"duplicate inspectionId",
		"inspection limit exceeded",
		"inspections"
	)
end

function State.registerObservation(schema: any): (boolean, string?)
	local ok, reason = Validation.observation(schema)
	if not ok then
		return false, reason
	end
	local inspectionOk, inspectionReason =
		hasAll(inspections, { schema.inspectionId }, "inspection")
	if not inspectionOk then
		return false, inspectionReason
	end
	return register(
		observations,
		schema.observationId,
		schema,
		Types.Limits.MaxObservations,
		"duplicate observationId",
		"observation limit exceeded",
		"observations"
	)
end

function State.registerFinding(schema: any): (boolean, string?)
	local ok, reason = Validation.finding(schema)
	if not ok then
		return false, reason
	end
	local inspectionOk, inspectionReason =
		hasAll(inspections, { schema.inspectionId }, "inspection")
	if not inspectionOk then
		return false, inspectionReason
	end
	local observationOk, observationReason =
		hasAll(observations, { schema.observationId }, "observation")
	if not observationOk then
		return false, observationReason
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
	local inspectionOk, inspectionReason =
		hasAll(inspections, { schema.inspectionId }, "inspection")
	if not inspectionOk then
		return false, inspectionReason
	end
	local findingOk, findingReason = hasAll(findings, schema.findingIds, "finding")
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
		inspections = inspections,
		observations = observations,
		findings = findings,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			inspections = counts.inspections,
			observations = counts.observations,
			findings = counts.findings,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(inspections)
	table.clear(observations)
	table.clear(findings)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.inspections = 0
	counts.observations = 0
	counts.findings = 0
	counts.audits = 0
end

return State
