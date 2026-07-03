--!strict
-- Validation boundary for server-owned Runtime Graph schemas.

local Serialization = require(script.Parent.RuntimeGraphSerialization)
local Types = require(script.Parent.RuntimeGraphTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"adapterReference",
	"analytics",
	"analyticsCollection",
	"assetLoading",
	"callRuntime",
	"callback",
	"chapter0Content",
	"chapterContent",
	"clientAuthority",
	"contentLoading",
	"cutscene",
	"dataStore",
	"dataStoreRead",
	"dataStoreWrite",
	"dependencyInjection",
	"dependencyInjectionExecution",
	"dialogue",
	"executableCallback",
	"execute",
	"executionAdapter",
	"executionGroup",
	"executionPermission",
	"finalDialogue",
	"finalStory",
	"fireAllClients",
	"fireClient",
	"frameworkMutation",
	"frameworkReplacement",
	"frameworkReference",
	"gameplayExecution",
	"handlerReference",
	"http",
	"httpService",
	"initializationExecution",
	"initializeRuntime",
	"instanceReference",
	"interactionExecution",
	"inventoryExecution",
	"invokeClient",
	"lifecycleExecution",
	"liveSystemMutation",
	"loadModule",
	"mapLoading",
	"messaging",
	"messagingService",
	"migrationExecution",
	"moduleLoading",
	"moduleReference",
	"monsterAIExecution",
	"narrativeExecution",
	"objectiveExecution",
	"orchestrationExecution",
	"presentationExecution",
	"puzzleExecution",
	"remote",
	"remoteEvent",
	"remoteFunction",
	"require",
	"requireCall",
	"resolveService",
	"roomLoading",
	"runtimeApiCall",
	"runtimeObject",
	"savePersistence",
	"serviceReference",
	"serviceResolution",
	"serviceLookup",
	"shutdownExecution",
	"shutdownRuntime",
	"startupExecution",
	"startRuntime",
	"story",
	"telemetry",
	"telemetrySending",
	"workspace",
	"workspacePath",
	"adapterLoading",
	"enforcement",
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
		return false, "Runtime Graph payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Runtime Graph payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Runtime Graph payload contains forbidden value: " .. nested
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
			return false, "tag uses forbidden runtime graph domain: " .. tag
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

function Validation.node(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "nodeId", Types.SchemaType.RuntimeNodeSchema, "runtime node")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeName) or Types.RuntimeLayer[schema.runtimeLayer] ~= true then
		return false, "runtime node fields are invalid"
	end
	local depsOk, depsReason =
		validateArrayIds(schema.dependencyIds, Types.Limits.MaxDependencies, "dependencyIds")
	if not depsOk then
		return false, depsReason
	end
	return validateArrayIds(schema.groupIds, Types.Limits.MaxGroups, "groupIds")
end

function Validation.dependency(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"dependencyId",
		Types.SchemaType.RuntimeDependencySchema,
		"dependency"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.sourceNodeId) or not validId(schema.targetNodeId) then
		return false, "dependency node references are invalid"
	end
	if schema.sourceNodeId == schema.targetNodeId then
		return false, "self-dependency is invalid"
	end
	if Types.DependencyKind[schema.dependencyKind] ~= true then
		return false, "unsupported dependency kind"
	end
	return true, nil
end

function Validation.capability(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"capabilityId",
		Types.SchemaType.RuntimeCapabilitySchema,
		"capability"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.nodeId) or not validId(schema.capabilityName) then
		return false, "capability fields are invalid"
	end
	return true, nil
end

function Validation.requirement(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"requirementId",
		Types.SchemaType.RuntimeRequirementSchema,
		"requirement"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.nodeId) or not validId(schema.requiredCapability) then
		return false, "requirement fields are invalid"
	end
	return true, nil
end

function Validation.compatibility(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"compatibilityId",
		Types.SchemaType.RuntimeCompatibilitySchema,
		"compatibility"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.sourceNodeId) or not validId(schema.targetNodeId) then
		return false, "compatibility node references are invalid"
	end
	if Types.CompatibilityKind[schema.compatibilityKind] ~= true then
		return false, "unsupported compatibility kind"
	end
	return true, nil
end

function Validation.ordering(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "orderingId", Types.SchemaType.RuntimeOrderingSchema, "ordering")
	if not ok then
		return false, reason
	end
	if not validId(schema.sourceNodeId) or not validId(schema.targetNodeId) then
		return false, "ordering node references are invalid"
	end
	if schema.sourceNodeId == schema.targetNodeId then
		return false, "self-ordering is invalid"
	end
	if Types.OrderingKind[schema.orderingKind] ~= true then
		return false, "unsupported ordering kind"
	end
	return true, nil
end

function Validation.startupPlan(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"startupPlanId",
		Types.SchemaType.RuntimeStartupPlanSchema,
		"startup plan"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.planName) then
		return false, "startup plan name is invalid"
	end
	local nodesOk, nodesReason =
		validateArrayIds(schema.nodeIds, Types.Limits.MaxPlanNodes, "nodeIds")
	if not nodesOk then
		return false, nodesReason
	end
	local depsOk, depsReason =
		validateArrayIds(schema.dependencyIds, Types.Limits.MaxPlanDependencies, "dependencyIds")
	if not depsOk then
		return false, depsReason
	end
	return validateArrayIds(schema.orderingIds, Types.Limits.MaxPlanOrderings, "orderingIds")
end

function Validation.shutdownPlan(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"shutdownPlanId",
		Types.SchemaType.RuntimeShutdownPlanSchema,
		"shutdown plan"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.planName) then
		return false, "shutdown plan name is invalid"
	end
	local nodesOk, nodesReason =
		validateArrayIds(schema.nodeIds, Types.Limits.MaxPlanNodes, "nodeIds")
	if not nodesOk then
		return false, nodesReason
	end
	local depsOk, depsReason =
		validateArrayIds(schema.dependencyIds, Types.Limits.MaxPlanDependencies, "dependencyIds")
	if not depsOk then
		return false, depsReason
	end
	return validateArrayIds(schema.orderingIds, Types.Limits.MaxPlanOrderings, "orderingIds")
end

function Validation.group(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "groupId", Types.SchemaType.RuntimeGroupSchema, "group")
	if not ok then
		return false, reason
	end
	if not validId(schema.groupName) then
		return false, "group name is invalid"
	end
	return validateArrayIds(schema.nodeIds, Types.Limits.MaxGroupNodes, "nodeIds")
end

function Validation.validationRecord(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"validationId",
		Types.SchemaType.RuntimeGraphValidationSchema,
		"graph validation"
	)
	if not ok then
		return false, reason
	end
	local nodesOk, nodesReason =
		validateArrayIds(schema.nodeIds, Types.Limits.MaxPlanNodes, "nodeIds")
	if not nodesOk then
		return false, nodesReason
	end
	return validateArrayIds(schema.dependencyIds, Types.Limits.MaxPlanDependencies, "dependencyIds")
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeRuntimeGraphSchemaRuntime" then
		return false, "Runtime Graph must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
