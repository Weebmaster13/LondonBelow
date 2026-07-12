--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterRegistrySerialization)
local Types = require(script.Parent.AssetExecutionAdapterRegistryTypes)
local Validation = require(script.Parent.AssetExecutionAdapterRegistryValidation)

local State = {}

local registries: { [string]: any } = {}
local registrations: { [string]: any } = {}
local boundaries: { [string]: any } = {}
local compatibilities: { [string]: any } = {}
local audits: { [string]: any } = {}
local registrySnapshots: { [string]: any } = {}
local registryNames: { [string]: boolean } = {}
local adapterIds: { [string]: boolean } = {}
local adapterNames: { [string]: boolean } = {}
local owners: { [string]: boolean } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local counts = {
	registries = 0,
	registrations = 0,
	boundaries = 0,
	compatibilities = 0,
	audits = 0,
	registrySnapshots = 0,
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

local function hasAllForRegistration(
	map: { [string]: any },
	values: any,
	label: string,
	registryId: string,
	registrationId: string
): (boolean, string?)
	local ok, reason = hasAll(map, values, label)
	if not ok then
		return false, reason
	end
	for _, id in ipairs(values) do
		if map[id].registryId ~= registryId or map[id].registrationId ~= registrationId then
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
	countKey: "registries" | "registrations" | "boundaries" | "compatibilities" | "audits" | "registrySnapshots"
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

function State.registerRegistry(schema: any): (boolean, string?)
	local ok, reason = Validation.registry(schema)
	if not ok then
		return false, reason
	end
	if registryNames[schema.registryName] == true then
		return false, "duplicate registryName"
	end
	for _, group in ipairs({
		{ registrations, schema.registrationIds, "registration" },
		{ compatibilities, schema.compatibilityIds, "compatibility" },
		{ boundaries, schema.boundaryIds, "boundary" },
		{ audits, schema.auditIds, "audit" },
		{ registrySnapshots, schema.snapshotIds, "registry snapshot" },
	}) do
		local groupOk, groupReason = hasAll(group[1], group[2], group[3])
		if not groupOk then
			return false, groupReason
		end
	end
	local registered, registerReason = register(
		registries,
		schema.registryId,
		schema,
		Types.Limits.MaxRegistries,
		"duplicate registryId",
		"registry limit exceeded",
		"registries"
	)
	if registered then
		registryNames[schema.registryName] = true
	end
	return registered, registerReason
end

function State.registerRegistration(schema: any): (boolean, string?)
	local ok, reason = Validation.registration(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(registries, { schema.registryId }, "registry")
	if not parentOk then
		return false, parentReason
	end
	local adapterKey = schema.registryId .. ":" .. schema.adapterId
	local adapterNameKey = schema.registryId .. ":" .. schema.adapterName
	local ownerKey = schema.registryId .. ":" .. schema.owner
	if adapterIds[adapterKey] == true then
		return false, "duplicate adapterId"
	end
	if adapterNames[adapterNameKey] == true then
		return false, "duplicate adapterName"
	end
	if owners[ownerKey] == true then
		return false, "duplicate ownership"
	end
	local registered, registerReason = register(
		registrations,
		schema.registrationId,
		schema,
		Types.Limits.MaxRegistrations,
		"duplicate registrationId",
		"registration limit exceeded",
		"registrations"
	)
	if registered then
		adapterIds[adapterKey] = true
		adapterNames[adapterNameKey] = true
		owners[ownerKey] = true
	end
	return registered, registerReason
end

function State.registerBoundary(schema: any): (boolean, string?)
	local ok, reason = Validation.boundary(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(registries, { schema.registryId }, "registry")
	if not parentOk then
		return false, parentReason
	end
	local registrationOk, registrationReason =
		hasAll(registrations, { schema.registrationId }, "registration")
	if not registrationOk then
		return false, registrationReason
	end
	if registrations[schema.registrationId].registryId ~= schema.registryId then
		return false, "invalid registration parent reference"
	end
	return register(
		boundaries,
		schema.boundaryId,
		schema,
		Types.Limits.MaxRegistrationBoundaries,
		"duplicate boundaryId",
		"boundary limit exceeded",
		"boundaries"
	)
end

function State.registerCompatibility(schema: any): (boolean, string?)
	local ok, reason = Validation.compatibility(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(registries, { schema.registryId }, "registry")
	if not parentOk then
		return false, parentReason
	end
	local registrationOk, registrationReason =
		hasAll(registrations, { schema.registrationId }, "registration")
	if not registrationOk then
		return false, registrationReason
	end
	if registrations[schema.registrationId].registryId ~= schema.registryId then
		return false, "invalid registration parent reference"
	end
	return register(
		compatibilities,
		schema.compatibilityId,
		schema,
		Types.Limits.MaxRegistryCompatibilities,
		"duplicate compatibilityId",
		"compatibility limit exceeded",
		"compatibilities"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(registries, { schema.registryId }, "registry")
	if not parentOk then
		return false, parentReason
	end
	local registrationOk, registrationReason =
		hasAll(registrations, { schema.registrationId }, "registration")
	if not registrationOk then
		return false, registrationReason
	end
	if registrations[schema.registrationId].registryId ~= schema.registryId then
		return false, "invalid registration parent reference"
	end
	for _, group in ipairs({
		{ boundaries, schema.boundaryIds, "boundary" },
		{ compatibilities, schema.compatibilityIds, "compatibility" },
	}) do
		local groupOk, groupReason = hasAllForRegistration(
			group[1],
			group[2],
			group[3],
			schema.registryId,
			schema.registrationId
		)
		if not groupOk then
			return false, groupReason
		end
	end
	return register(
		audits,
		schema.auditId,
		schema,
		Types.Limits.MaxRegistrationAudits,
		"duplicate auditId",
		"audit limit exceeded",
		"audits"
	)
end

function State.registerRegistrySnapshot(schema: any): (boolean, string?)
	local ok, reason = Validation.registrySnapshot(schema)
	if not ok then
		return false, reason
	end
	local parentOk, parentReason = hasAll(registries, { schema.registryId }, "registry")
	if not parentOk then
		return false, parentReason
	end
	local registrationsOk, registrationsReason =
		hasAll(registrations, schema.registrationIds, "registration")
	if not registrationsOk then
		return false, registrationsReason
	end
	local compatibilitiesOk, compatibilitiesReason =
		hasAll(compatibilities, schema.compatibilityIds, "compatibility")
	if not compatibilitiesOk then
		return false, compatibilitiesReason
	end
	return register(
		registrySnapshots,
		schema.registrySnapshotId,
		schema,
		Types.Limits.MaxRegistrySnapshots,
		"duplicate registrySnapshotId",
		"registry snapshot limit exceeded",
		"registrySnapshots"
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
		registries = registries,
		registrations = registrations,
		boundaries = boundaries,
		compatibilities = compatibilities,
		audits = audits,
		registrySnapshots = registrySnapshots,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			registries = counts.registries,
			registrations = counts.registrations,
			boundaries = counts.boundaries,
			compatibilities = counts.compatibilities,
			audits = counts.audits,
			registrySnapshots = counts.registrySnapshots,
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(registries)
	table.clear(registrations)
	table.clear(boundaries)
	table.clear(compatibilities)
	table.clear(audits)
	table.clear(registrySnapshots)
	table.clear(registryNames)
	table.clear(adapterIds)
	table.clear(adapterNames)
	table.clear(owners)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	counts.registries = 0
	counts.registrations = 0
	counts.boundaries = 0
	counts.compatibilities = 0
	counts.audits = 0
	counts.registrySnapshots = 0
end

return State
