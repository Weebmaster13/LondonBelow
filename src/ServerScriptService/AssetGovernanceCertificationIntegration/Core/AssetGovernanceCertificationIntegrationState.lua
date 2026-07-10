--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationIntegrationSerialization)
local Types = require(script.Parent.AssetGovernanceCertificationIntegrationTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationIntegrationValidation)

local State = {}

local integrations: { [string]: any } = {}
local chains: { [string]: any } = {}
local reviews: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = {
	integrations = 0,
	chains = 0,
	reviews = 0,
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
	countKey: "integrations" | "chains" | "reviews" | "audits"
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

function State.registerIntegration(schema: any): (boolean, string?)
	local ok, reason = Validation.integration(schema)
	if not ok then
		return false, reason
	end
	local chainOk, chainReason = hasAll(chains, { schema.chainId }, "chain")
	if not chainOk then
		return false, chainReason
	end
	local reviewOk, reviewReason = hasAll(reviews, schema.reviewIds, "review")
	if not reviewOk then
		return false, reviewReason
	end
	local auditOk, auditReason = hasAll(audits, schema.auditIds, "audit")
	if not auditOk then
		return false, auditReason
	end
	return register(
		integrations,
		schema.integrationId,
		schema,
		Types.Limits.MaxIntegrations,
		"duplicate integrationId",
		"integration limit exceeded",
		"integrations"
	)
end

function State.registerChain(schema: any): (boolean, string?)
	local ok, reason = Validation.chain(schema)
	if not ok then
		return false, reason
	end
	return register(
		chains,
		schema.chainId,
		schema,
		Types.Limits.MaxChains,
		"duplicate chainId",
		"chain limit exceeded",
		"chains"
	)
end

local function registerIntegrationChild(
	schema: any,
	validate: (any) -> (boolean, string?),
	map: { [string]: any },
	idField: string,
	limit: number,
	duplicate: string,
	limitReason: string,
	countKey: "reviews" | "audits"
): (boolean, string?)
	local ok, reason = validate(schema)
	if not ok then
		return false, reason
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason, countKey)
end

function State.registerReview(schema: any): (boolean, string?)
	return registerIntegrationChild(
		schema,
		Validation.review,
		reviews,
		"reviewId",
		Types.Limits.MaxReviews,
		"duplicate reviewId",
		"review limit exceeded",
		"reviews"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerIntegrationChild(
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
		integrations = integrations,
		chains = chains,
		reviews = reviews,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			integrations = counts.integrations,
			chains = counts.chains,
			reviews = counts.reviews,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(integrations)
	table.clear(chains)
	table.clear(reviews)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.integrations = 0
	counts.chains = 0
	counts.reviews = 0
	counts.audits = 0
end

return State
