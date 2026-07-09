--!strict

local Serialization = require(script.Parent.AssetExecutionImplementationContractSerialization)
local Types = require(script.Parent.AssetExecutionImplementationContractTypes)
local Validation = require(script.Parent.AssetExecutionImplementationContractValidation)

local State = {}

local contracts: { [string]: any } = {}
local responsibilities: { [string]: any } = {}
local boundaries: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = {
	contracts = 0,
	responsibilities = 0,
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

local function register(
	map: { [string]: any },
	id: string,
	schema: any,
	limit: number,
	duplicate: string,
	limitReason: string,
	countKey: "contracts" | "responsibilities" | "boundaries" | "audits"
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

function State.registerContract(schema: any): (boolean, string?)
	local ok, reason = Validation.contract(schema)
	if not ok then
		return false, reason
	end
	local referenceGroups = {
		{ responsibilities, schema.responsibilityIds, "responsibility" },
		{ boundaries, schema.boundaryIds, "boundary" },
		{ audits, schema.auditIds, "audit" },
	}
	for _, referenceGroup in ipairs(referenceGroups) do
		local refsOk, refsReason = hasAll(referenceGroup[1], referenceGroup[2], referenceGroup[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		contracts,
		schema.contractId,
		schema,
		Types.Limits.MaxContracts,
		"duplicate contractId",
		"contract limit exceeded",
		"contracts"
	)
end

local function registerContractChild(
	schema: any,
	validate: (any) -> (boolean, string?),
	map: { [string]: any },
	idField: string,
	limit: number,
	duplicate: string,
	limitReason: string,
	countKey: "contracts" | "responsibilities" | "boundaries" | "audits"
): (boolean, string?)
	local ok, reason = validate(schema)
	if not ok then
		return false, reason
	end
	if contracts[schema.contractId] == nil then
		return false, "invalid contractId reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason, countKey)
end

function State.registerResponsibility(schema: any): (boolean, string?)
	return registerContractChild(
		schema,
		Validation.responsibility,
		responsibilities,
		"responsibilityId",
		Types.Limits.MaxResponsibilities,
		"duplicate responsibilityId",
		"responsibility limit exceeded",
		"responsibilities"
	)
end

function State.registerBoundary(schema: any): (boolean, string?)
	return registerContractChild(
		schema,
		Validation.boundary,
		boundaries,
		"boundaryId",
		Types.Limits.MaxBoundaries,
		"duplicate boundaryId",
		"boundary limit exceeded",
		"boundaries"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerContractChild(
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
		contracts = contracts,
		responsibilities = responsibilities,
		boundaries = boundaries,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			contracts = counts.contracts,
			responsibilities = counts.responsibilities,
			boundaries = counts.boundaries,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(contracts)
	table.clear(responsibilities)
	table.clear(boundaries)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.contracts = 0
	counts.responsibilities = 0
	counts.boundaries = 0
	counts.audits = 0
end

return State
