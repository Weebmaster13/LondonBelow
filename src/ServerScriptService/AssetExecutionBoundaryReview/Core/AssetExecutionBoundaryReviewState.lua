--!strict

local Serialization = require(script.Parent.AssetExecutionBoundaryReviewSerialization)
local Types = require(script.Parent.AssetExecutionBoundaryReviewTypes)
local Validation = require(script.Parent.AssetExecutionBoundaryReviewValidation)

local State = {}

local reviews: { [string]: any } = {}
local risks: { [string]: any } = {}
local requirements: { [string]: any } = {}
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

function State.registerReview(schema: any): (boolean, string?)
	local ok, reason = Validation.review(schema)
	if not ok then
		return false, reason
	end
	local referenceRisks = {
		{ risks, schema.riskIds, "risk" },
		{ requirements, schema.requirementIds, "requirement" },
		{ audits, schema.auditIds, "audit" },
	}
	for _, referenceRisk in ipairs(referenceRisks) do
		local refsOk, refsReason = hasAll(referenceRisk[1], referenceRisk[2], referenceRisk[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		reviews,
		schema.reviewId,
		schema,
		Types.Limits.MaxReviews,
		"duplicate reviewId",
		"review limit exceeded"
	)
end

local function registerReviewChild(
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
	if reviews[schema.reviewId] == nil then
		return false, "invalid reviewId reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerRisk(schema: any): (boolean, string?)
	return registerReviewChild(
		schema,
		Validation.risk,
		risks,
		"riskId",
		Types.Limits.MaxRisks,
		"duplicate riskId",
		"risk limit exceeded"
	)
end

function State.registerRequirement(schema: any): (boolean, string?)
	return registerReviewChild(
		schema,
		Validation.requirement,
		requirements,
		"requirementId",
		Types.Limits.MaxRequirements,
		"duplicate requirementId",
		"requirement limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerReviewChild(
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
		reviews = reviews,
		risks = risks,
		requirements = requirements,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			reviews = countMap(reviews),
			risks = countMap(risks),
			requirements = countMap(requirements),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(reviews)
	table.clear(risks)
	table.clear(requirements)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
