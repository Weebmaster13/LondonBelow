--!strict

local Serialization = require(script.Parent.AssetApprovalLedgerSerialization)
local Types = require(script.Parent.AssetApprovalLedgerTypes)
local Validation = require(script.Parent.AssetApprovalLedgerValidation)

local State = {}

local approvals: { [string]: any } = {}
local conditions: { [string]: any } = {}
local revocations: { [string]: any } = {}
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

function State.registerApproval(schema: any): (boolean, string?)
	local ok, reason = Validation.approval(schema)
	if not ok then
		return false, reason
	end
	local checks = {
		{ conditions, schema.conditionIds, "condition" },
		{ revocations, schema.revocationIds, "revocation" },
		{ audits, schema.auditIds, "audit" },
	}
	for _, check in ipairs(checks) do
		local refsOk, refsReason = hasAll(check[1], check[2], check[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		approvals,
		schema.approvalId,
		schema,
		Types.Limits.MaxApprovals,
		"duplicate approvalId",
		"approval limit exceeded"
	)
end

local function registerApprovalChild(
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
	if approvals[schema.approvalId] == nil then
		return false, "invalid approvalId reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerCondition(schema: any): (boolean, string?)
	return registerApprovalChild(
		schema,
		Validation.condition,
		conditions,
		"conditionId",
		Types.Limits.MaxConditions,
		"duplicate conditionId",
		"condition limit exceeded"
	)
end

function State.registerRevocation(schema: any): (boolean, string?)
	return registerApprovalChild(
		schema,
		Validation.revocation,
		revocations,
		"revocationId",
		Types.Limits.MaxRevocations,
		"duplicate revocationId",
		"revocation limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerApprovalChild(
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
		approvals = approvals,
		conditions = conditions,
		revocations = revocations,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			approvals = countMap(approvals),
			conditions = countMap(conditions),
			revocations = countMap(revocations),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(approvals)
	table.clear(conditions)
	table.clear(revocations)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
