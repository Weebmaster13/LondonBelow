--!strict

local Serialization = require(script.Parent.AssetExecutionImplementationReadinessSerialization)
local Types = require(script.Parent.AssetExecutionImplementationReadinessTypes)
local Validation = require(script.Parent.AssetExecutionImplementationReadinessValidation)

local State = {}

local readinessRecords: { [string]: any } = {}
local checklists: { [string]: any } = {}
local gaps: { [string]: any } = {}
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

function State.registerReadiness(schema: any): (boolean, string?)
	local ok, reason = Validation.readiness(schema)
	if not ok then
		return false, reason
	end
	local referencechecklists = {
		{ checklists, schema.checklistIds, "checklist" },
		{ gaps, schema.gapIds, "gap" },
		{ audits, schema.auditIds, "audit" },
	}
	for _, referencechecklist in ipairs(referencechecklists) do
		local refsOk, refsReason =
			hasAll(referencechecklist[1], referencechecklist[2], referencechecklist[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		readinessRecords,
		schema.readinessId,
		schema,
		Types.Limits.MaxReadinessRecords,
		"duplicate readinessId",
		"readiness limit exceeded"
	)
end

local function registerReadinessChild(
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
	if readinessRecords[schema.readinessId] == nil then
		return false, "invalid readinessId reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerChecklist(schema: any): (boolean, string?)
	return registerReadinessChild(
		schema,
		Validation.checklist,
		checklists,
		"checklistId",
		Types.Limits.MaxChecklists,
		"duplicate checklistId",
		"checklist limit exceeded"
	)
end

function State.registerGap(schema: any): (boolean, string?)
	return registerReadinessChild(
		schema,
		Validation.gap,
		gaps,
		"gapId",
		Types.Limits.MaxGaps,
		"duplicate gapId",
		"gap limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerReadinessChild(
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
		readinessRecords = readinessRecords,
		checklists = checklists,
		gaps = gaps,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			readinessRecords = countMap(readinessRecords),
			checklists = countMap(checklists),
			gaps = countMap(gaps),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(readinessRecords)
	table.clear(checklists)
	table.clear(gaps)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
