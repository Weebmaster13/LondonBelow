--!strict

local Serialization = require(script.Parent.AssetGovernanceIntegrationSerialization)
local Types = require(script.Parent.AssetGovernanceIntegrationTypes)
local Validation = require(script.Parent.AssetGovernanceIntegrationValidation)

local State = {}

local chains: { [string]: any } = {}
local runtimeNodes: { [string]: any } = {}
local referenceReviews: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local runtimeNamesByChain: { [string]: { [string]: boolean } } = {}
local expectedOrdersByChain: { [string]: { [number]: boolean } } = {}

local counts = {
	chains = 0,
	runtimeNodes = 0,
	referenceReviews = 0,
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
	countKey: "chains" | "runtimeNodes" | "referenceReviews" | "audits"
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

function State.registerChain(schema: any): (boolean, string?)
	local ok, reason = Validation.chain(schema)
	if not ok then
		return false, reason
	end
	for _, group in ipairs({
		{ runtimeNodes, schema.runtimeNodeIds, "runtime node" },
		{ referenceReviews, schema.referenceReviewIds, "reference review" },
		{ audits, schema.auditIds, "audit" },
	}) do
		local refsOk, refsReason = hasAll(group[1], group[2], group[3])
		if not refsOk then
			return false, refsReason
		end
	end
	local registered, registerReason = register(
		chains,
		schema.chainId,
		schema,
		Types.Limits.MaxChains,
		"duplicate chainId",
		"chain limit exceeded",
		"chains"
	)
	if registered then
		runtimeNamesByChain[schema.chainId] = {}
		expectedOrdersByChain[schema.chainId] = {}
	end
	return registered, registerReason
end

function State.registerRuntimeNode(schema: any): (boolean, string?)
	local ok, reason = Validation.runtimeNode(schema)
	if not ok then
		return false, reason
	end
	if chains[schema.chainId] == nil then
		return false, "invalid chainId reference"
	end
	local runtimeNames = runtimeNamesByChain[schema.chainId] or {}
	local expectedOrders = expectedOrdersByChain[schema.chainId] or {}
	if runtimeNames[schema.runtimeName] == true then
		return false, "duplicate runtimeName in chain"
	end
	if expectedOrders[schema.expectedOrder] == true then
		return false, "duplicate expectedOrder in chain"
	end
	local registered, registerReason = register(
		runtimeNodes,
		schema.nodeId,
		schema,
		Types.Limits.MaxRuntimeNodes,
		"duplicate nodeId",
		"runtime node limit exceeded",
		"runtimeNodes"
	)
	if registered then
		runtimeNames[schema.runtimeName] = true
		expectedOrders[schema.expectedOrder] = true
		runtimeNamesByChain[schema.chainId] = runtimeNames
		expectedOrdersByChain[schema.chainId] = expectedOrders
	end
	return registered, registerReason
end

function State.registerReferenceReview(schema: any): (boolean, string?)
	local ok, reason = Validation.referenceReview(schema)
	if not ok then
		return false, reason
	end
	if chains[schema.chainId] == nil then
		return false, "invalid chainId reference"
	end
	return register(
		referenceReviews,
		schema.reviewId,
		schema,
		Types.Limits.MaxReferenceReviews,
		"duplicate reviewId",
		"reference review limit exceeded",
		"referenceReviews"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	if chains[schema.chainId] == nil then
		return false, "invalid chainId reference"
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
		chains = chains,
		runtimeNodes = runtimeNodes,
		referenceReviews = referenceReviews,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			chains = counts.chains,
			runtimeNodes = counts.runtimeNodes,
			referenceReviews = counts.referenceReviews,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(chains)
	table.clear(runtimeNodes)
	table.clear(referenceReviews)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	table.clear(runtimeNamesByChain)
	table.clear(expectedOrdersByChain)
	counts.chains = 0
	counts.runtimeNodes = 0
	counts.referenceReviews = 0
	counts.audits = 0
end

return State
