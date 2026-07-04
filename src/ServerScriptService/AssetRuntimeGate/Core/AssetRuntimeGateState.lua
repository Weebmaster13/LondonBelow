--!strict

local Serialization = require(script.Parent.AssetRuntimeGateSerialization)
local Types = require(script.Parent.AssetRuntimeGateTypes)
local Validation = require(script.Parent.AssetRuntimeGateValidation)

local State = {}

local gates: { [string]: any } = {}
local checks: { [string]: any } = {}
local blocks: { [string]: any } = {}
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

function State.registerGate(schema: any): (boolean, string?)
	local ok, reason = Validation.gate(schema)
	if not ok then
		return false, reason
	end
	local referenceChecks = {
		{ checks, schema.checkIds, "check" },
		{ blocks, schema.blockIds, "block" },
		{ audits, schema.auditIds, "audit" },
	}
	for _, referenceCheck in ipairs(referenceChecks) do
		local refsOk, refsReason = hasAll(referenceCheck[1], referenceCheck[2], referenceCheck[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		gates,
		schema.gateId,
		schema,
		Types.Limits.MaxGates,
		"duplicate gateId",
		"gate limit exceeded"
	)
end

local function registerGateChild(
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
	if gates[schema.gateId] == nil then
		return false, "invalid gateId reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerCheck(schema: any): (boolean, string?)
	return registerGateChild(
		schema,
		Validation.check,
		checks,
		"checkId",
		Types.Limits.MaxChecks,
		"duplicate checkId",
		"check limit exceeded"
	)
end

function State.registerBlock(schema: any): (boolean, string?)
	return registerGateChild(
		schema,
		Validation.block,
		blocks,
		"blockId",
		Types.Limits.MaxBlocks,
		"duplicate blockId",
		"block limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerGateChild(
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
		gates = gates,
		checks = checks,
		blocks = blocks,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			gates = countMap(gates),
			checks = countMap(checks),
			blocks = countMap(blocks),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(gates)
	table.clear(checks)
	table.clear(blocks)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
