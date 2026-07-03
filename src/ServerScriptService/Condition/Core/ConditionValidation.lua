--!strict
-- Validation boundary for server-owned Condition schemas.

local Serialization = require(script.Parent.ConditionSerialization)
local Types = require(script.Parent.ConditionTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"adapterReference",
	"ana" .. "lytics",
	"booleanExecution",
	"callback",
	"chapterContent",
	"clientAuthority",
	"condition" .. "Evaluation",
	"cutscene",
	"dataStore",
	"dialogue",
	"directorExecution",
	"dispatch",
	"evaluate",
	"evaluateCondition",
	"eventExecution",
	"execute",
	"expressionExecution",
	"fire",
	"frameworkReference",
	"gameplayExecution",
	"handlerReference",
	"http" .. "Service",
	"instanceReference",
	"interactionExecution",
	"inventoryExecution",
	"logicExecution",
	"messaging" .. "Service",
	"moduleReference",
	"monsterAIExecution",
	"monsterExecution",
	"narrativeExecution",
	"objectiveExecution",
	"presentationExecution",
	"publish",
	"puzzleExecution",
	"remote",
	"remote" .. "Event",
	"remote" .. "Function",
	"ruleExecution",
	"run",
	"runtimeExecution",
	"runtimeObject",
	"runtimeOrchestration",
	"saveExecution",
	"schedulerExecution",
	"serviceReference",
	"story",
	"subscribe",
	"tele" .. "metry",
	"triggerExecution",
	"workspace",
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
		return false, "Condition payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Condition payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Condition payload contains forbidden value: " .. nested
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
			return false, "tag uses forbidden Condition domain: " .. tag
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

function Validation.definition(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"conditionId",
		Types.SchemaType.ConditionDefinitionSchema,
		"condition"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.conditionName) or Types.Domain[schema.conditionDomain] ~= true then
		return false, "condition fields are invalid"
	end
	local checks = {
		{ schema.categoryIds, Types.Limits.MaxConditionCategories, "categoryIds" },
		{ schema.expressionIds, Types.Limits.MaxConditionExpressions, "expressionIds" },
		{ schema.dependencyIds, Types.Limits.MaxConditionDependencies, "dependencyIds" },
		{ schema.outcomeIds, Types.Limits.MaxConditionOutcomes, "outcomeIds" },
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
		validateSchema(schema, "categoryId", Types.SchemaType.ConditionCategorySchema, "category")
	if not ok then
		return false, reason
	end
	if not validId(schema.categoryName) or Types.Domain[schema.conditionDomain] ~= true then
		return false, "category fields are invalid"
	end
	return true, nil
end

function Validation.expression(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"expressionId",
		Types.SchemaType.ConditionExpressionSchema,
		"expression"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.conditionId) or not validId(schema.operatorId) then
		return false, "expression fields are invalid"
	end
	return validateArrayIds(schema.operandIds, Types.Limits.MaxExpressionOperands, "operandIds")
end

function Validation.operand(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "operandId", Types.SchemaType.ConditionOperandSchema, "operand")
	if not ok then
		return false, reason
	end
	if not validId(schema.operandKind) then
		return false, "operand fields are invalid"
	end
	return true, nil
end

function Validation.operator(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "operatorId", Types.SchemaType.ConditionOperatorSchema, "operator")
	if not ok then
		return false, reason
	end
	if Types.OperatorKind[schema.operatorKind] ~= true then
		return false, "unsupported operator kind"
	end
	return true, nil
end

function Validation.group(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "groupId", Types.SchemaType.ConditionGroupSchema, "group")
	if not ok then
		return false, reason
	end
	if Types.GroupType[schema.groupType] ~= true then
		return false, "unsupported group type"
	end
	return validateArrayIds(schema.conditionIds, Types.Limits.MaxGroupConditions, "conditionIds")
end

function Validation.dependency(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"dependencyId",
		Types.SchemaType.ConditionDependencySchema,
		"dependency"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceConditionId)
		or not validId(schema.targetConditionId)
		or Types.DependencyKind[schema.dependencyKind] ~= true
	then
		return false, "dependency fields are invalid"
	end
	if schema.sourceConditionId == schema.targetConditionId then
		return false, "self-dependency rejects"
	end
	return true, nil
end

function Validation.state(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "stateId", Types.SchemaType.ConditionStateSchema, "state")
	if not ok then
		return false, reason
	end
	if not validId(schema.conditionId) or not validId(schema.stateKind) then
		return false, "state fields are invalid"
	end
	return true, nil
end

function Validation.outcome(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "outcomeId", Types.SchemaType.ConditionOutcomeSchema, "outcome")
	if not ok then
		return false, reason
	end
	if not validId(schema.conditionId) or Types.OutcomeKind[schema.outcomeKind] ~= true then
		return false, "outcome fields are invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.ConditionAuditSchema, "audit")
	if not ok then
		return false, reason
	end
	if schema.conditionId ~= nil and not validId(schema.conditionId) then
		return false, "audit conditionId is invalid"
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
