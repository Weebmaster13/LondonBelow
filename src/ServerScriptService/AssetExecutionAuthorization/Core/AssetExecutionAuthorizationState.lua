--!strict

local Serialization = require(script.Parent.AssetExecutionAuthorizationSerialization)
local Types = require(script.Parent.AssetExecutionAuthorizationTypes)
local Validation = require(script.Parent.AssetExecutionAuthorizationValidation)

local State = {}

local authorizations: { [string]: any } = {}
local requirements: { [string]: any } = {}
local evaluations: { [string]: any } = {}
local boundaries: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = {
	authorizations = 0,
	requirements = 0,
	evaluations = 0,
	boundaries = 0,
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
	parentId: string
): (boolean, string?)
	local ok, reason = hasAll(map, values, label)
	if not ok then
		return false, reason
	end
	for _, id in ipairs(values) do
		if map[id].authorizationId ~= parentId then
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
	countKey: "authorizations" | "requirements" | "evaluations" | "boundaries" | "audits"
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

function State.registerAuthorization(schema: any): (boolean, string?)
	local ok, reason = Validation.authorization(schema)
	if not ok then
		return false, reason
	end
	for _, group in ipairs({
		{ requirements, schema.requirementIds, "requirement" },
		{ evaluations, schema.evaluationIds, "evaluation" },
		{ boundaries, schema.boundaryIds, "boundary" },
		{ audits, schema.auditIds, "audit" },
	}) do
		local groupOk, groupReason =
			hasAllForParent(group[1], group[2], group[3], schema.authorizationId)
		if not groupOk then
			return false, groupReason
		end
	end
	return register(
		authorizations,
		schema.authorizationId,
		schema,
		Types.Limits.MaxAuthorizations,
		"duplicate authorizationId",
		"authorization limit exceeded",
		"authorizations"
	)
end

function State.registerRequirement(schema: any): (boolean, string?)
	local ok, reason = Validation.requirement(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason =
		hasAll(authorizations, { schema.authorizationId }, "authorization")
	if not parentOk then
		return false, parentReason
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
	local parentOk, parentReason =
		hasAll(authorizations, { schema.authorizationId }, "authorization")
	if not parentOk then
		return false, parentReason
	end
	local requirementOk, requirementReason =
		hasAll(requirements, { schema.requirementId }, "requirement")
	if not requirementOk then
		return false, requirementReason
	end
	if requirements[schema.requirementId].authorizationId ~= schema.authorizationId then
		return false, "invalid requirement parent reference"
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

function State.registerBoundary(schema: any): (boolean, string?)
	local ok, reason = Validation.boundary(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason =
		hasAll(authorizations, { schema.authorizationId }, "authorization")
	if not parentOk then
		return false, parentReason
	end
	return register(
		boundaries,
		schema.boundaryId,
		schema,
		Types.Limits.MaxBoundaries,
		"duplicate boundaryId",
		"boundary limit exceeded",
		"boundaries"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason =
		hasAll(authorizations, { schema.authorizationId }, "authorization")
	if not parentOk then
		return false, parentReason
	end
	for _, group in ipairs({
		{ evaluations, schema.evaluationIds, "evaluation" },
		{ boundaries, schema.boundaryIds, "boundary" },
	}) do
		local groupOk, groupReason =
			hasAllForParent(group[1], group[2], group[3], schema.authorizationId)
		if not groupOk then
			return false, groupReason
		end
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
		authorizations = authorizations,
		requirements = requirements,
		evaluations = evaluations,
		boundaries = boundaries,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			authorizations = counts.authorizations,
			requirements = counts.requirements,
			evaluations = counts.evaluations,
			boundaries = counts.boundaries,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(authorizations)
	table.clear(requirements)
	table.clear(evaluations)
	table.clear(boundaries)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.authorizations = 0
	counts.requirements = 0
	counts.evaluations = 0
	counts.boundaries = 0
	counts.audits = 0
end

return State
