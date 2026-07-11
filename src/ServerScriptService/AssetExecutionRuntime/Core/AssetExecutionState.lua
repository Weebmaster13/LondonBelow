--!strict

local Serialization = require(script.Parent.AssetExecutionSerialization)
local Types = require(script.Parent.AssetExecutionTypes)
local Validation = require(script.Parent.AssetExecutionValidation)

local State = {}

local runtimes: { [string]: any } = {}
local requests: { [string]: any } = {}
local boundaries: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = {
	runtimes = 0,
	requests = 0,
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

local function hasAllForRuntime(
	map: { [string]: any },
	values: any,
	label: string,
	runtimeId: string
): (boolean, string?)
	local ok, reason = hasAll(map, values, label)
	if not ok then
		return false, reason
	end
	for _, id in ipairs(values) do
		if map[id].runtimeId ~= runtimeId then
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
	countKey: "runtimes" | "requests" | "boundaries" | "audits"
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

function State.registerRuntime(schema: any): (boolean, string?)
	local ok, reason = Validation.runtime(schema)
	if not ok then
		return false, reason
	end
	for _, group in ipairs({
		{ requests, schema.requestIds, "request" },
		{ boundaries, schema.boundaryIds, "boundary" },
		{ audits, schema.auditIds, "audit" },
	}) do
		local groupOk, groupReason =
			hasAllForRuntime(group[1], group[2], group[3], schema.runtimeId)
		if not groupOk then
			return false, groupReason
		end
	end
	return register(
		runtimes,
		schema.runtimeId,
		schema,
		Types.Limits.MaxRuntimes,
		"duplicate runtimeId",
		"runtime limit exceeded",
		"runtimes"
	)
end

function State.registerRequest(schema: any): (boolean, string?)
	local ok, reason = Validation.request(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(runtimes, { schema.runtimeId }, "runtime")
	if not parentOk then
		return false, parentReason
	end
	return register(
		requests,
		schema.requestId,
		schema,
		Types.Limits.MaxRequests,
		"duplicate requestId",
		"request limit exceeded",
		"requests"
	)
end

function State.registerBoundary(schema: any): (boolean, string?)
	local ok, reason = Validation.boundary(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(runtimes, { schema.runtimeId }, "runtime")
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
	local parentOk, parentReason = hasAll(runtimes, { schema.runtimeId }, "runtime")
	if not parentOk then
		return false, parentReason
	end
	for _, group in ipairs({
		{ requests, schema.requestIds, "request" },
		{ boundaries, schema.boundaryIds, "boundary" },
	}) do
		local groupOk, groupReason =
			hasAllForRuntime(group[1], group[2], group[3], schema.runtimeId)
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
		runtimes = runtimes,
		requests = requests,
		boundaries = boundaries,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			runtimes = counts.runtimes,
			requests = counts.requests,
			boundaries = counts.boundaries,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(runtimes)
	table.clear(requests)
	table.clear(boundaries)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.runtimes = 0
	counts.requests = 0
	counts.boundaries = 0
	counts.audits = 0
end

return State
