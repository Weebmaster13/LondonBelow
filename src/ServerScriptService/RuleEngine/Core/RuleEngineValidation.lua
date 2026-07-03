--!strict
-- Validation boundary for server-owned Rule Engine schemas.

local Serialization = require(script.Parent.RuleEngineSerialization)
local Types = require(script.Parent.RuleEngineTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"adapterReference",
	"analytics",
	"analyticsCollection",
	"antiCheat",
	"antiCheatEnforcement",
	"assetLoading",
	"callback",
	"chapter0Content",
	"chapterContent",
	"clientAuthority",
	"conditionEvaluation",
	"contentLoading",
	"cutscene",
	"dataStore",
	"dataStoreRead",
	"dataStoreWrite",
	"denyPermission",
	"dialogue",
	"enforceRule",
	"enforcement",
	"eventBusExecution",
	"evaluateRule",
	"executableCallback",
	"execute",
	"executionAdapter",
	"finalDialogue",
	"finalStory",
	"fireAllClients",
	"fireClient",
	"frameworkReference",
	"gameplayExecution",
	"grantPermission",
	"handlerReference",
	"http",
	"httpService",
	"instanceReference",
	"interactionExecution",
	"inventoryExecution",
	"invokeClient",
	"lifecycleExecution",
	"liveRuleEvaluation",
	"mapLoading",
	"messaging",
	"messagingService",
	"moderation",
	"moduleReference",
	"monsterAIExecution",
	"narrativeExecution",
	"objectiveExecution",
	"permissionExecution",
	"policyEnforcement",
	"policyExecution",
	"predicateExecution",
	"presentationExecution",
	"punishment",
	"puzzleExecution",
	"remote",
	"remoteEvent",
	"remoteFunction",
	"remediation",
	"roomLoading",
	"ruleEnforcement",
	"ruleEvaluation",
	"runtimeObject",
	"runtimeOrchestration",
	"savePersistence",
	"schedulerExecution",
	"securityEnforcement",
	"serviceReference",
	"story",
	"telemetry",
	"telemetrySending",
	"triggerExecution",
	"workspace",
	"workspacePath",
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
		return false, "Rule Engine payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Rule Engine payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Rule Engine payload contains forbidden value: " .. nested
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
	for _, value in ipairs(values) do
		if not validId(value) then
			return false, label .. " contains invalid id"
		end
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return true, nil
	end
	local ok, reason = validateArrayIds(tags, Types.Limits.MaxTagsPerSchema, "tags")
	if not ok then
		return false, reason
	end
	for _, tag in ipairs(tags) do
		if FORBIDDEN_LOOKUP[string.lower(tag)] == true then
			return false, "tag uses forbidden Rule Engine domain: " .. tag
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

local function validateSchema(schema: any, idField: string, expectedType: string, label: string)
	if type(schema) ~= "table" then
		return false, label .. " schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema[idField]) or not validId(schema.ownerSystem) then
		return false, label .. " identity fields are invalid"
	end
	if schema.schemaType ~= nil and schema.schemaType ~= expectedType then
		return false, "unsupported " .. label .. " schema type"
	end
	return validateTags(schema.tags)
end

function Validation.rule(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "ruleId", Types.SchemaType.RuleDefinitionSchema, "rule")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.ruleName)
		or Types.RuleDomain[schema.ruleDomain] ~= true
		or Types.RuleKind[schema.ruleKind] ~= true
	then
		return false, "rule fields are invalid"
	end
	local checks = {
		{ schema.categoryIds, Types.Limits.MaxRuleCategories, "categoryIds" },
		{ schema.predicateIds, Types.Limits.MaxRulePredicates, "predicateIds" },
		{ schema.constraintIds, Types.Limits.MaxRuleConstraints, "constraintIds" },
		{ schema.permissionIds, Types.Limits.MaxRulePermissions, "permissionIds" },
		{ schema.policyIds, Types.Limits.MaxRulePolicies, "policyIds" },
		{ schema.dependencyIds, Types.Limits.MaxRuleDependencies, "dependencyIds" },
		{ schema.outcomeIds, Types.Limits.MaxRuleOutcomes, "outcomeIds" },
	}
	for _, check in ipairs(checks) do
		local listOk, listReason = validateArrayIds(check[1], check[2], check[3])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.category(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "categoryId", Types.SchemaType.RuleCategorySchema, "category")
	if not ok then
		return false, reason
	end
	if not validId(schema.categoryName) or Types.RuleDomain[schema.ruleDomain] ~= true then
		return false, "category fields are invalid"
	end
	return true, nil
end

function Validation.predicate(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "predicateId", Types.SchemaType.RulePredicateSchema, "predicate")
	if not ok then
		return false, reason
	end
	if Types.PredicateKind[schema.predicateKind] ~= true or not validId(schema.ruleId) then
		return false, "predicate fields are invalid"
	end
	return true, nil
end

function Validation.constraint(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "constraintId", Types.SchemaType.RuleConstraintSchema, "constraint")
	if not ok then
		return false, reason
	end
	if Types.ConstraintKind[schema.constraintKind] ~= true or not validId(schema.ruleId) then
		return false, "constraint fields are invalid"
	end
	return true, nil
end

function Validation.permission(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "permissionId", Types.SchemaType.RulePermissionSchema, "permission")
	if not ok then
		return false, reason
	end
	if Types.PermissionKind[schema.permissionKind] ~= true or not validId(schema.ruleId) then
		return false, "permission fields are invalid"
	end
	return true, nil
end

function Validation.policy(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "policyId", Types.SchemaType.RulePolicySchema, "policy")
	if not ok then
		return false, reason
	end
	if Types.PolicyKind[schema.policyKind] ~= true or not validId(schema.ruleId) then
		return false, "policy fields are invalid"
	end
	return true, nil
end

function Validation.group(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "groupId", Types.SchemaType.RuleGroupSchema, "group")
	if not ok then
		return false, reason
	end
	if not validId(schema.groupName) or not validId(schema.groupKind) then
		return false, "group fields are invalid"
	end
	return validateArrayIds(schema.ruleIds, Types.Limits.MaxGroupRules, "ruleIds")
end

function Validation.dependency(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "dependencyId", Types.SchemaType.RuleDependencySchema, "dependency")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceRuleId)
		or not validId(schema.targetRuleId)
		or not validId(schema.dependencyKind)
	then
		return false, "dependency fields are invalid"
	end
	if schema.sourceRuleId == schema.targetRuleId then
		return false, "self-dependency rejects"
	end
	return true, nil
end

function Validation.outcome(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "outcomeId", Types.SchemaType.RuleOutcomeSchema, "outcome")
	if not ok then
		return false, reason
	end
	if Types.OutcomeKind[schema.outcomeKind] ~= true or not validId(schema.ruleId) then
		return false, "outcome fields are invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "auditId", Types.SchemaType.RuleAuditSchema, "audit")
	if not ok then
		return false, reason
	end
	if schema.ruleId ~= nil and not validId(schema.ruleId) then
		return false, "audit ruleId is invalid"
	end
	if not validId(schema.auditKind) or not validId(schema.resultStatus) then
		return false, "audit fields are invalid"
	end
	return validateArrayIds(schema.findings, Types.Limits.MaxAuditFindings, "findings")
end

function Validation.validate(): (boolean, string?)
	return true, nil
end

return Validation
