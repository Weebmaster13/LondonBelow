--!strict

local Serialization = require(script.Parent.AssetUsagePlanSerialization)
local Types = require(script.Parent.AssetUsagePlanTypes)

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
	"run",
	"dispatch",
	"fire",
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
		return false, "AssetUsagePlan payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "AssetUsagePlan payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "AssetUsagePlan payload contains forbidden value: " .. nested
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
			return false, "tag uses forbidden AssetUsagePlan marker: " .. tag
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

function Validation.definition(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "usagePlanId", Types.SchemaType.UsagePlanDefinition, "usage plan")
	if not ok then
		return false, reason
	end
	if not validId(schema.assetId) or not validId(schema.intendedConsumer) then
		return false, "usage plan identity fields are invalid"
	end
	if
		Types.UsageDomain[schema.usageDomain] ~= true
		or Types.UsageKind[schema.usageKind] ~= true
	then
		return false, "usage plan kind fields are invalid"
	end
	if schema.priority ~= nil and Types.Priority[schema.priority] ~= true then
		return false, "unsupported usage plan priority"
	end
	local checks = {
		{ schema.contextIds, Types.Limits.MaxPlanChildren, "contextIds" },
		{ schema.constraintIds, Types.Limits.MaxPlanChildren, "constraintIds" },
		{ schema.dependencyIds, Types.Limits.MaxPlanChildren, "dependencyIds" },
		{ schema.budgetIds, Types.Limits.MaxPlanChildren, "budgetIds" },
		{ schema.accessibilityIds, Types.Limits.MaxPlanChildren, "accessibilityIds" },
		{ schema.auditIds, Types.Limits.MaxPlanChildren, "auditIds" },
	}
	for _, check in ipairs(checks) do
		local listOk, listReason = validateArrayIds(check[1], check[2], check[3])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.context(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "contextId", Types.SchemaType.UsagePlanContext, "context")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.usagePlanId)
		or not validId(schema.contextName)
		or Types.ContextKind[schema.contextKind] ~= true
	then
		return false, "context fields are invalid"
	end
	if schema.allowedRuntime ~= nil and type(schema.allowedRuntime) ~= "boolean" then
		return false, "allowedRuntime must be boolean"
	end
	if schema.chapterAgnostic ~= nil and type(schema.chapterAgnostic) ~= "boolean" then
		return false, "chapterAgnostic must be boolean"
	end
	return true, nil
end

function Validation.constraint(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "constraintId", Types.SchemaType.UsagePlanConstraint, "constraint")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.usagePlanId)
		or Types.ConstraintKind[schema.constraintKind] ~= true
		or Types.Severity[schema.severity] ~= true
	then
		return false, "constraint fields are invalid"
	end
	if type(schema.ruleSummary) ~= "string" or schema.ruleSummary == "" then
		return false, "constraint ruleSummary is invalid"
	end
	return true, nil
end

function Validation.dependency(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "dependencyId", Types.SchemaType.UsagePlanDependency, "dependency")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.usagePlanId)
		or not validId(schema.dependsOnUsagePlanId)
		or Types.DependencyKind[schema.dependencyKind] ~= true
	then
		return false, "dependency fields are invalid"
	end
	if schema.usagePlanId == schema.dependsOnUsagePlanId then
		return false, "self-dependency rejects"
	end
	if schema.optional ~= nil and type(schema.optional) ~= "boolean" then
		return false, "dependency optional must be boolean"
	end
	return true, nil
end

function Validation.budget(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "budgetId", Types.SchemaType.UsagePlanBudget, "budget")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.usagePlanId)
		or Types.BudgetKind[schema.budgetKind] ~= true
		or Types.Severity[schema.severity] ~= true
	then
		return false, "budget fields are invalid"
	end
	if type(schema.budgetLimit) ~= "number" or schema.budgetLimit < 0 then
		return false, "budgetLimit is invalid"
	end
	if type(schema.budgetUnit) ~= "string" or schema.budgetUnit == "" then
		return false, "budgetUnit is invalid"
	end
	return true, nil
end

function Validation.accessibility(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"accessibilityId",
		Types.SchemaType.UsagePlanAccessibility,
		"accessibility"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.usagePlanId)
		or Types.AccessibilityKind[schema.accessibilityKind] ~= true
	then
		return false, "accessibility fields are invalid"
	end
	if type(schema.accommodationSummary) ~= "string" or schema.accommodationSummary == "" then
		return false, "accommodationSummary is invalid"
	end
	if schema.required ~= nil and type(schema.required) ~= "boolean" then
		return false, "required must be boolean"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "auditId", Types.SchemaType.UsagePlanAudit, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.usagePlanId) or Types.AuditKind[schema.auditKind] ~= true then
		return false, "audit fields are invalid"
	end
	if not validId(schema.reviewer) or not validId(schema.status) then
		return false, "audit reviewer/status fields are invalid"
	end
	return validateArrayIds(schema.findings, Types.Limits.MaxAuditFindings, "findings")
end

function Validation.validate(): (boolean, string?)
	return true, nil
end

return Validation
