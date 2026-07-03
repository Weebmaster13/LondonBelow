--!strict
-- Validation boundary for server-owned Trigger schemas.

local Serialization = require(script.Parent.TriggerSerialization)
local Types = require(script.Parent.TriggerTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"adapterReference",
	"ana" .. "lytics",
	"callback",
	"chapterContent",
	"clientAuthority",
	"condition" .. "Evaluation",
	"cutscene",
	"dataStore",
	"dialogue",
	"dispatch",
	"dispatchEvent",
	"emitEvent",
	"eventDispatch",
	"execute",
	"executeTrigger",
	"fireEvent",
	"frameworkReference",
	"gameplayExecution",
	"handlerReference",
	"http" .. "Service",
	"instanceReference",
	"interactionExecution",
	"inventoryExecution",
	"lifecycleExecution",
	"listener",
	"listenerExecution",
	"messaging" .. "Service",
	"moduleReference",
	"monsterAIExecution",
	"narrativeExecution",
	"objectiveExecution",
	"presentationExecution",
	"publish",
	"puzzleExecution",
	"remote",
	"remote" .. "Event",
	"remote" .. "Function",
	"ruleEvaluation",
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
		return false, "Trigger payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Trigger payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Trigger payload contains forbidden value: " .. nested
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
	local ok, reason = validateArrayIds(tags, Types.Limits.MaxTagsPerSchema, "tags")
	if not ok then
		return false, reason
	end
	for _, tag in ipairs(tags) do
		if FORBIDDEN_LOOKUP[string.lower(tag)] == true then
			return false, "tag uses forbidden Trigger domain: " .. tag
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
	local ok, reason =
		validateSchema(schema, "triggerId", Types.SchemaType.TriggerDefinitionSchema, "trigger")
	if not ok then
		return false, reason
	end
	if not validId(schema.triggerName) or Types.Domain[schema.triggerDomain] ~= true then
		return false, "trigger fields are invalid"
	end
	local checks = {
		{ schema.categoryIds, Types.Limits.MaxTriggerCategories, "categoryIds" },
		{ schema.sourceIds, Types.Limits.MaxTriggerSources, "sourceIds" },
		{ schema.targetIds, Types.Limits.MaxTriggerTargets, "targetIds" },
		{ schema.eventIds, Types.Limits.MaxTriggerEvents, "eventIds" },
		{ schema.filterIds, Types.Limits.MaxTriggerFilters, "filterIds" },
		{ schema.conditionIds, Types.Limits.MaxTriggerConditions, "conditionIds" },
		{ schema.dependencyIds, Types.Limits.MaxTriggerDependencies, "dependencyIds" },
		{ schema.outcomeIds, Types.Limits.MaxTriggerOutcomes, "outcomeIds" },
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
		validateSchema(schema, "categoryId", Types.SchemaType.TriggerCategorySchema, "category")
	if not ok then
		return false, reason
	end
	if not validId(schema.categoryName) or Types.Domain[schema.triggerDomain] ~= true then
		return false, "category fields are invalid"
	end
	return true, nil
end

function Validation.source(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "sourceId", Types.SchemaType.TriggerSourceSchema, "source")
	if not ok then
		return false, reason
	end
	if not validId(schema.sourceKind) then
		return false, "source fields are invalid"
	end
	return true, nil
end

function Validation.target(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "targetId", Types.SchemaType.TriggerTargetSchema, "target")
	if not ok then
		return false, reason
	end
	if not validId(schema.targetKind) then
		return false, "target fields are invalid"
	end
	return true, nil
end

function Validation.event(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "eventId", Types.SchemaType.TriggerEventSchema, "event")
	if not ok then
		return false, reason
	end
	if not validId(schema.triggerId) or Types.EventKind[schema.eventKind] ~= true then
		return false, "event fields are invalid"
	end
	return true, nil
end

function Validation.filter(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "filterId", Types.SchemaType.TriggerFilterSchema, "filter")
	if not ok then
		return false, reason
	end
	if not validId(schema.triggerId) or not validId(schema.filterKind) then
		return false, "filter fields are invalid"
	end
	return true, nil
end

function Validation.condition(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "conditionId", Types.SchemaType.TriggerConditionSchema, "condition")
	if not ok then
		return false, reason
	end
	if not validId(schema.triggerId) or not validId(schema.conditionRefId) then
		return false, "condition fields are invalid"
	end
	return true, nil
end

function Validation.dependency(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"dependencyId",
		Types.SchemaType.TriggerDependencySchema,
		"dependency"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceTriggerId)
		or not validId(schema.targetTriggerId)
		or Types.DependencyKind[schema.dependencyKind] ~= true
	then
		return false, "dependency fields are invalid"
	end
	if schema.sourceTriggerId == schema.targetTriggerId then
		return false, "self-dependency rejects"
	end
	return true, nil
end

function Validation.group(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "groupId", Types.SchemaType.TriggerGroupSchema, "group")
	if not ok then
		return false, reason
	end
	if Types.GroupType[schema.groupType] ~= true then
		return false, "unsupported group type"
	end
	return validateArrayIds(schema.triggerIds, Types.Limits.MaxGroupMembers, "triggerIds")
end

function Validation.outcome(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "outcomeId", Types.SchemaType.TriggerOutcomeSchema, "outcome")
	if not ok then
		return false, reason
	end
	if not validId(schema.triggerId) or Types.OutcomeKind[schema.outcomeKind] ~= true then
		return false, "outcome fields are invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.TriggerAuditSchema, "audit")
	if not ok then
		return false, reason
	end
	if schema.triggerId ~= nil and not validId(schema.triggerId) then
		return false, "audit triggerId is invalid"
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
