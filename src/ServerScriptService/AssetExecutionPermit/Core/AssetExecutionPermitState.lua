--!strict

local Serialization = require(script.Parent.AssetExecutionPermitSerialization)
local Types = require(script.Parent.AssetExecutionPermitTypes)
local Validation = require(script.Parent.AssetExecutionPermitValidation)

local State = {}

local permits: { [string]: any } = {}
local scopes: { [string]: any } = {}
local restrictions: { [string]: any } = {}
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

function State.registerPermit(schema: any): (boolean, string?)
	local ok, reason = Validation.permit(schema)
	if not ok then
		return false, reason
	end
	local checks = {
		{ scopes, schema.scopeIds, "scope" },
		{ restrictions, schema.restrictionIds, "restriction" },
		{ audits, schema.auditIds, "audit" },
	}
	for _, check in ipairs(checks) do
		local refsOk, refsReason = hasAll(check[1], check[2], check[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		permits,
		schema.permitId,
		schema,
		Types.Limits.MaxPermits,
		"duplicate permitId",
		"permit limit exceeded"
	)
end

local function registerPermitChild(
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
	if permits[schema.permitId] == nil then
		return false, "invalid permitId reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerScope(schema: any): (boolean, string?)
	return registerPermitChild(
		schema,
		Validation.scope,
		scopes,
		"scopeId",
		Types.Limits.MaxScopes,
		"duplicate scopeId",
		"scope limit exceeded"
	)
end

function State.registerRestriction(schema: any): (boolean, string?)
	return registerPermitChild(
		schema,
		Validation.restriction,
		restrictions,
		"restrictionId",
		Types.Limits.MaxRestrictions,
		"duplicate restrictionId",
		"restriction limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerPermitChild(
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
		permits = permits,
		scopes = scopes,
		restrictions = restrictions,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			permits = countMap(permits),
			scopes = countMap(scopes),
			restrictions = countMap(restrictions),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(permits)
	table.clear(scopes)
	table.clear(restrictions)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
