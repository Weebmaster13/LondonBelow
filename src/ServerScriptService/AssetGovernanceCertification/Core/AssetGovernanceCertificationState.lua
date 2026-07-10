--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationSerialization)
local Types = require(script.Parent.AssetGovernanceCertificationTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationValidation)

local State = {}

local certifications: { [string]: any } = {}
local requirements: { [string]: any } = {}
local results: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = {
	certifications = 0,
	requirements = 0,
	results = 0,
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

local function register(
	map: { [string]: any },
	id: string,
	schema: any,
	limit: number,
	duplicate: string,
	limitReason: string,
	countKey: "certifications" | "requirements" | "results" | "audits"
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

function State.registerCertification(schema: any): (boolean, string?)
	local ok, reason = Validation.certification(schema)
	if not ok then
		return false, reason
	end
	for _, group in ipairs({
		{ requirements, schema.requirementIds, "requirement" },
		{ results, schema.resultIds, "result" },
		{ audits, schema.auditIds, "audit" },
	}) do
		local refsOk, refsReason = hasAll(group[1], group[2], group[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		certifications,
		schema.certificationId,
		schema,
		Types.Limits.MaxCertifications,
		"duplicate certificationId",
		"certification limit exceeded",
		"certifications"
	)
end

local function registerCertificationChild(
	schema: any,
	validate: (any) -> (boolean, string?),
	map: { [string]: any },
	idField: string,
	limit: number,
	duplicate: string,
	limitReason: string,
	countKey: "requirements" | "results" | "audits"
): (boolean, string?)
	local ok, reason = validate(schema)
	if not ok then
		return false, reason
	end
	if certifications[schema.certificationId] == nil then
		return false, "invalid certificationId reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason, countKey)
end

function State.registerRequirement(schema: any): (boolean, string?)
	return registerCertificationChild(
		schema,
		Validation.requirement,
		requirements,
		"requirementId",
		Types.Limits.MaxRequirements,
		"duplicate requirementId",
		"requirement limit exceeded",
		"requirements"
	)
end

function State.registerResult(schema: any): (boolean, string?)
	return registerCertificationChild(
		schema,
		Validation.result,
		results,
		"resultId",
		Types.Limits.MaxResults,
		"duplicate resultId",
		"result limit exceeded",
		"results"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerCertificationChild(
		schema,
		Validation.audit,
		audits,
		"auditId",
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
		certifications = certifications,
		requirements = requirements,
		results = results,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			certifications = counts.certifications,
			requirements = counts.requirements,
			results = counts.results,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(certifications)
	table.clear(requirements)
	table.clear(results)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.certifications = 0
	counts.requirements = 0
	counts.results = 0
	counts.audits = 0
end

return State
