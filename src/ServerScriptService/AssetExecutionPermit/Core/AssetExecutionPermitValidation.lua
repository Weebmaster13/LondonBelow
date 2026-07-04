--!strict

local Serialization = require(script.Parent.AssetExecutionPermitSerialization)
local Types = require(script.Parent.AssetExecutionPermitTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"load" .. "Asset",
	"preload" .. "Asset",
	"content" .. "Provider",
	"preload" .. "Async",
	"insert" .. "Service",
	"marketplace" .. "Service",
	"animationLoad",
	"soundLoad",
	"meshLoad",
	"textureLoad",
	"materialLoad",
	"decalLoad",
	"modelSpawn",
	"assetApplication",
	"assetPlayback",
	"create" .. "Instance",
	"createUI",
	"vfxCreate",
	"particleCreate",
	"work" .. "space",
	"replicated" .. "Storage",
	"server" .. "Storage",
	"data" .. "Store",
	"http" .. "Service",
	"messaging" .. "Service",
	"remote" .. "Event",
	"remote" .. "Function",
	"fire" .. "Client",
	"fire" .. "AllClients",
	"invoke" .. "Client",
	"clientAuthority",
	"gameplayExecution",
	"presentationExecution",
	"saveExecution",
	"chapterContent",
	"cutscene",
	"dialogue",
	"mapLoad",
	"roomLoad",
	"ana" .. "lytics",
	"tele" .. "metry",
	"runtimeObject",
	"serviceHandle",
	"assetHandle",
	"loadedAsset",
	"moduleReference",
	"callback",
	"eventListener",
	"executionAdapter",
	"execute",
	"dispatch",
	"publish",
	"subscribe",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}
for _, field in ipairs(FORBIDDEN_FIELDS) do
	FORBIDDEN_LOOKUP[string.lower(field)] = true
end

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 150
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "AssetExecutionPermit payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "AssetExecutionPermit payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "AssetExecutionPermit payload contains forbidden value: " .. nested
		end
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function validateArrayIds(values: any, limit: number, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	if type(values) ~= "table" then
		return false, label .. " must be a table"
	end
	if #values > limit then
		return false, label .. " exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
		if seen[value] == true then
			return false, label .. " contains duplicate id"
		end
		seen[value] = true
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return true, nil
	end
	local ok, reason = validateArrayIds(tags, Types.Limits.MaxTags, "tags")
	if not ok then
		return false, reason
	end
	for _, tag in ipairs(tags) do
		if FORBIDDEN_LOOKUP[string.lower(tag)] == true then
			return false, "tag uses forbidden AssetExecutionPermit marker: " .. tag
		end
	end
	return true, nil
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

local function validateSchema(
	schema: any,
	idField: string,
	expectedType: string,
	label: string
): (boolean, string?)
	if schema == nil then
		return false, label .. " schema is nil"
	end
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema[idField]) then
		return false, label .. " id is invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= expectedType then
		return false, "unsupported " .. label .. " schema type"
	end
	return validateTags(schema.tags)
end

function Validation.permit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "permitId", Types.SchemaType.ExecutionPermit, "permit")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.assetId)
		or not validId(schema.usagePlanId)
		or not validId(schema.checklistId)
		or not validId(schema.approvalId)
	then
		return false, "permit identity fields are invalid"
	end
	if
		Types.PermitKind[schema.permitKind] ~= true
		or Types.PermitStatus[schema.permitStatus] ~= true
	then
		return false, "permit kind/status fields are invalid"
	end
	if not validId(schema.issuedBy) then
		return false, "permit issuedBy is invalid"
	end
	local checks = {
		{ schema.scopeIds, Types.Limits.MaxPermitChildren, "scopeIds" },
		{ schema.restrictionIds, Types.Limits.MaxPermitChildren, "restrictionIds" },
		{ schema.auditIds, Types.Limits.MaxPermitChildren, "auditIds" },
	}
	for _, check in ipairs(checks) do
		local listOk, listReason = validateArrayIds(check[1], check[2], check[3])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.scope(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "scopeId", Types.SchemaType.ExecutionPermitScope, "scope")
	if not ok then
		return false, reason
	end
	if not validId(schema.permitId) or Types.ScopeKind[schema.scopeKind] ~= true then
		return false, "scope fields are invalid"
	end
	if not validId(schema.runtimeName) then
		return false, "scope runtimeName is invalid"
	end
	if type(schema.allowed) ~= "boolean" then
		return false, "scope allowed must be boolean"
	end
	if type(schema.summary) ~= "string" or schema.summary == "" then
		return false, "scope summary is invalid"
	end
	return true, nil
end

function Validation.restriction(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"restrictionId",
		Types.SchemaType.ExecutionPermitRestriction,
		"restriction"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.permitId)
		or Types.RestrictionKind[schema.restrictionKind] ~= true
		or Types.Severity[schema.severity] ~= true
	then
		return false, "restriction fields are invalid"
	end
	if type(schema.summary) ~= "string" or schema.summary == "" then
		return false, "restriction summary is invalid"
	end
	if type(schema.active) ~= "boolean" then
		return false, "restriction active must be boolean"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.ExecutionPermitAudit, "audit")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.permitId)
		or Types.AuditKind[schema.auditKind] ~= true
		or Types.AuditStatus[schema.status] ~= true
	then
		return false, "audit fields are invalid"
	end
	if not validId(schema.reviewer) then
		return false, "audit reviewer is invalid"
	end
	return validateArrayIds(schema.findings, Types.Limits.MaxAuditFindings, "findings")
end

function Validation.validate(): (boolean, string?)
	return true, nil
end

return Validation
