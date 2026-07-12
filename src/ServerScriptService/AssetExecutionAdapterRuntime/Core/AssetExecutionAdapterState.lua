--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterSerialization)
local Types = require(script.Parent.AssetExecutionAdapterTypes)
local Validation = require(script.Parent.AssetExecutionAdapterValidation)

local State = {}

local adapters: { [string]: any } = {}
local capabilities: { [string]: any } = {}
local compatibilities: { [string]: any } = {}
local boundaries: { [string]: any } = {}
local audits: { [string]: any } = {}
local adapterNames: { [string]: boolean } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = {
	adapters = 0,
	capabilities = 0,
	compatibilities = 0,
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

local function hasAllForAdapter(
	map: { [string]: any },
	values: any,
	label: string,
	adapterId: string
): (boolean, string?)
	local ok, reason = hasAll(map, values, label)
	if not ok then
		return false, reason
	end
	for _, id in ipairs(values) do
		if map[id].adapterId ~= adapterId then
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
	countKey: "adapters" | "capabilities" | "compatibilities" | "boundaries" | "audits"
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

function State.registerAdapter(schema: any): (boolean, string?)
	local ok, reason = Validation.adapter(schema)
	if not ok then
		return false, reason
	end
	if adapterNames[schema.adapterName] == true then
		return false, "duplicate adapterName"
	end
	for _, group in ipairs({
		{ capabilities, schema.capabilityIds, "capability" },
		{ compatibilities, schema.compatibilityIds, "compatibility" },
		{ boundaries, schema.boundaryIds, "boundary" },
		{ audits, schema.auditIds, "audit" },
	}) do
		local groupOk, groupReason =
			hasAllForAdapter(group[1], group[2], group[3], schema.adapterId)
		if not groupOk then
			return false, groupReason
		end
	end
	local registered, registerReason = register(
		adapters,
		schema.adapterId,
		schema,
		Types.Limits.MaxAdapters,
		"duplicate adapterId",
		"adapter limit exceeded",
		"adapters"
	)
	if registered then
		adapterNames[schema.adapterName] = true
	end
	return registered, registerReason
end

function State.registerCapability(schema: any): (boolean, string?)
	local ok, reason = Validation.capability(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(adapters, { schema.adapterId }, "adapter")
	if not parentOk then
		return false, parentReason
	end
	return register(
		capabilities,
		schema.capabilityId,
		schema,
		Types.Limits.MaxCapabilities,
		"duplicate capabilityId",
		"capability limit exceeded",
		"capabilities"
	)
end

function State.registerCompatibility(schema: any): (boolean, string?)
	local ok, reason = Validation.compatibility(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(adapters, { schema.adapterId }, "adapter")
	if not parentOk then
		return false, parentReason
	end
	return register(
		compatibilities,
		schema.compatibilityId,
		schema,
		Types.Limits.MaxCompatibilities,
		"duplicate compatibilityId",
		"compatibility limit exceeded",
		"compatibilities"
	)
end

function State.registerBoundary(schema: any): (boolean, string?)
	local ok, reason = Validation.boundary(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(adapters, { schema.adapterId }, "adapter")
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
	local parentOk, parentReason = hasAll(adapters, { schema.adapterId }, "adapter")
	if not parentOk then
		return false, parentReason
	end
	for _, group in ipairs({
		{ capabilities, schema.capabilityIds, "capability" },
		{ compatibilities, schema.compatibilityIds, "compatibility" },
		{ boundaries, schema.boundaryIds, "boundary" },
	}) do
		local groupOk, groupReason =
			hasAllForAdapter(group[1], group[2], group[3], schema.adapterId)
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
		adapters = adapters,
		capabilities = capabilities,
		compatibilities = compatibilities,
		boundaries = boundaries,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			adapters = counts.adapters,
			capabilities = counts.capabilities,
			compatibilities = counts.compatibilities,
			boundaries = counts.boundaries,
			audits = counts.audits,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(adapters)
	table.clear(capabilities)
	table.clear(compatibilities)
	table.clear(boundaries)
	table.clear(audits)
	table.clear(adapterNames)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.adapters = 0
	counts.capabilities = 0
	counts.compatibilities = 0
	counts.boundaries = 0
	counts.audits = 0
end

return State
