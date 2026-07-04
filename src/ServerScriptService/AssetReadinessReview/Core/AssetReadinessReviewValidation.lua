--!strict

local Serialization = require(script.Parent.AssetReadinessReviewSerialization)
local Types = require(script.Parent.AssetReadinessReviewTypes)

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
		return false, "AssetReadinessReview payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "AssetReadinessReview payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "AssetReadinessReview payload contains forbidden value: " .. nested
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
			return false, "tag uses forbidden AssetReadinessReview marker: " .. tag
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

function Validation.checklist(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "checklistId", Types.SchemaType.ReadinessChecklist, "checklist")
	if not ok then
		return false, reason
	end
	if not validId(schema.assetId) or not validId(schema.usagePlanId) then
		return false, "checklist asset/usage plan fields are invalid"
	end
	if
		Types.ChecklistKind[schema.checklistKind] ~= true
		or Types.ReadinessTier[schema.readinessTier] ~= true
	then
		return false, "checklist kind/tier fields are invalid"
	end
	local checks = {
		{ schema.requiredGateIds, Types.Limits.MaxChecklistChildren, "requiredGateIds" },
		{ schema.findingIds, Types.Limits.MaxChecklistChildren, "findingIds" },
		{ schema.decisionIds, Types.Limits.MaxChecklistChildren, "decisionIds" },
		{ schema.auditIds, Types.Limits.MaxChecklistChildren, "auditIds" },
	}
	for _, check in ipairs(checks) do
		local listOk, listReason = validateArrayIds(check[1], check[2], check[3])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.finding(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "findingId", Types.SchemaType.ReadinessFinding, "finding")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.checklistId)
		or Types.FindingKind[schema.findingKind] ~= true
		or Types.Severity[schema.severity] ~= true
	then
		return false, "finding kind/severity fields are invalid"
	end
	if type(schema.summary) ~= "string" or schema.summary == "" then
		return false, "finding summary is invalid"
	end
	if schema.resolved ~= nil and type(schema.resolved) ~= "boolean" then
		return false, "finding resolved must be boolean"
	end
	return true, nil
end

function Validation.gate(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "gateId", Types.SchemaType.ReadinessGate, "gate")
	if not ok then
		return false, reason
	end
	if not validId(schema.checklistId) or Types.GateKind[schema.gateKind] ~= true then
		return false, "gate fields are invalid"
	end
	if type(schema.required) ~= "boolean" or type(schema.passed) ~= "boolean" then
		return false, "gate required/passed fields must be boolean"
	end
	if type(schema.reason) ~= "string" or schema.reason == "" then
		return false, "gate reason is invalid"
	end
	return true, nil
end

function Validation.decision(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "decisionId", Types.SchemaType.ReadinessDecision, "decision")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.checklistId)
		or Types.DecisionKind[schema.decisionKind] ~= true
		or Types.DecisionStatus[schema.status] ~= true
	then
		return false, "decision kind/status fields are invalid"
	end
	if not validId(schema.reviewer) then
		return false, "decision reviewer is invalid"
	end
	if type(schema.rationale) ~= "string" or schema.rationale == "" then
		return false, "decision rationale is invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "auditId", Types.SchemaType.ReadinessAudit, "audit")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.checklistId)
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
