--!strict
-- Validation boundary for server-owned Runtime Lifecycle schemas.

local Serialization = require(script.Parent.RuntimeLifecycleSerialization)
local Types = require(script.Parent.RuntimeLifecycleTypes)

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
	"finalDialogue",
	"finalStory",
	"fireAllClients",
	"fireClient",
	"frameworkMutation",
	"frameworkReference",
	"frameworkReplacement",
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
	"liveServiceManagement",
	"loadModule",
	"mapLoading",
	"messaging",
	"messagingService",
	"moduleLoading",
	"moduleReference",
	"monsterAIExecution",
	"narrativeExecution",
	"objectiveExecution",
	"orchestrationExecution",
	"pauseExecution",
	"pauseRuntime",
	"presentationExecution",
	"puzzleExecution",
	"recoverRuntime",
	"recoveryExecution",
	"reloadRuntime",
	"remote",
	"remoteEvent",
	"remoteFunction",
	"require",
	"requireCall",
	"resolveService",
	"restartExecution",
	"restartRuntime",
	"resumeExecution",
	"resumeRuntime",
	"roomLoading",
	"runtimeApiCall",
	"runtimeGraphOwnership",
	"runtimeObject",
	"savePersistence",
	"serviceReference",
	"serviceResolution",
	"shutdownExecution",
	"shutdownRuntime",
	"startupExecution",
	"startRuntime",
	"story",
	"telemetry",
	"telemetrySending",
	"unloadRuntime",
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
		return false, "Runtime Lifecycle payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Runtime Lifecycle payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Runtime Lifecycle payload contains forbidden value: " .. nested
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
			return false, "tag uses forbidden runtime lifecycle domain: " .. tag
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

function Validation.lifecycleState(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"lifecycleStateId",
		Types.SchemaType.LifecycleStateSchema,
		"lifecycle state"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeNodeId) or Types.LifecycleState[schema.lifecycleState] ~= true then
		return false, "lifecycle state fields are invalid"
	end
	return true, nil
end

function Validation.transition(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"transitionId",
		Types.SchemaType.LifecycleTransitionSchema,
		"transition"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeNodeId) then
		return false, "transition runtime node is invalid"
	end
	if
		Types.LifecycleState[schema.fromState] ~= true
		or Types.LifecycleState[schema.toState] ~= true
	then
		return false, "transition states are invalid"
	end
	if schema.fromState == schema.toState and schema.transitionKind ~= "FutureOnly" then
		return false, "identical transition states are invalid"
	end
	if Types.TransitionKind[schema.transitionKind] ~= true then
		return false, "unsupported transition kind"
	end
	local policyOk, policyReason =
		validateArrayIds(schema.policyIds, Types.Limits.MaxPolicyRefs, "policyIds")
	if not policyOk then
		return false, policyReason
	end
	return validateArrayIds(schema.guardIds, Types.Limits.MaxGuardRefs, "guardIds")
end

function Validation.policy(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "policyId", Types.SchemaType.LifecyclePolicySchema, "policy")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeNodeId) or Types.PolicyKind[schema.policyKind] ~= true then
		return false, "policy fields are invalid"
	end
	if schema.lifecycleState ~= nil and Types.LifecycleState[schema.lifecycleState] ~= true then
		return false, "unsupported lifecycle state"
	end
	if schema.transitionKind ~= nil and Types.TransitionKind[schema.transitionKind] ~= true then
		return false, "unsupported transition kind"
	end
	if
		schema.policyKind == "RequiredState"
		and schema.transitionKind ~= nil
		and schema.lifecycleState == nil
	then
		return false, "self-contradictory policy record"
	end
	return true, nil
end

function Validation.guard(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "guardId", Types.SchemaType.LifecycleGuardSchema, "guard")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeNodeId) or Types.GuardKind[schema.guardKind] ~= true then
		return false, "guard fields are invalid"
	end
	return true, nil
end

function Validation.event(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "eventId", Types.SchemaType.LifecycleEventSchema, "event")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeNodeId) or Types.EventKind[schema.eventKind] ~= true then
		return false, "event fields are invalid"
	end
	if schema.relatedStateId ~= nil and not validId(schema.relatedStateId) then
		return false, "event related state reference is invalid"
	end
	if schema.relatedTransitionId ~= nil and not validId(schema.relatedTransitionId) then
		return false, "event related transition reference is invalid"
	end
	return true, nil
end

function Validation.failure(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "failureId", Types.SchemaType.LifecycleFailureSchema, "failure")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeNodeId) or Types.FailureKind[schema.failureKind] ~= true then
		return false, "failure fields are invalid"
	end
	if schema.relatedStateId ~= nil and not validId(schema.relatedStateId) then
		return false, "failure related state reference is invalid"
	end
	if schema.relatedTransitionId ~= nil and not validId(schema.relatedTransitionId) then
		return false, "failure related transition reference is invalid"
	end
	return true, nil
end

function Validation.recovery(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "recoveryId", Types.SchemaType.LifecycleRecoverySchema, "recovery")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeNodeId) or Types.RecoveryKind[schema.recoveryKind] ~= true then
		return false, "recovery fields are invalid"
	end
	if schema.relatedFailureId ~= nil and not validId(schema.relatedFailureId) then
		return false, "recovery related failure reference is invalid"
	end
	return true, nil
end

function Validation.checkpoint(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"checkpointId",
		Types.SchemaType.LifecycleCheckpointSchema,
		"checkpoint"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeNodeId) or Types.LifecycleState[schema.lifecycleState] ~= true then
		return false, "checkpoint fields are invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.LifecycleAuditSchema, "audit")
	if not ok then
		return false, reason
	end
	if not validId(schema.runtimeNodeId) then
		return false, "audit runtime node is invalid"
	end
	return validateArrayIds(schema.findings, Types.Limits.MaxAuditFindings, "findings")
end

function Validation.compatibility(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"compatibilityId",
		Types.SchemaType.LifecycleCompatibilitySchema,
		"compatibility"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.runtimeNodeId)
		or Types.CompatibilityKind[schema.compatibilityKind] ~= true
	then
		return false, "compatibility fields are invalid"
	end
	if schema.lifecycleState ~= nil and Types.LifecycleState[schema.lifecycleState] ~= true then
		return false, "unsupported lifecycle state"
	end
	if schema.transitionKind ~= nil and Types.TransitionKind[schema.transitionKind] ~= true then
		return false, "unsupported transition kind"
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeRuntimeLifecycleSchemaRuntime" then
		return false, "Runtime Lifecycle must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
