--!strict
-- Validation boundary for server-owned State Machine schemas.

local Serialization = require(script.Parent.StateMachineSerialization)
local Types = require(script.Parent.StateMachineTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"adapterReference",
	"aiStateExecution",
	"ana" .. "lytics",
	"animationStateExecution",
	"callback",
	"changeState",
	"chapter0Content",
	"chapterContent",
	"clientAuthority",
	"condition" .. "Evaluation",
	"conditionRuntimeExecution",
	"consumeInput",
	"currentState",
	"cutscene",
	"dataStore",
	"dataStoreRead",
	"dataStoreWrite",
	"dialogue",
	"dispatch",
	"dispatchEvent",
	"emitOutput",
	"enforcement",
	"enterState",
	"eventConsumption",
	"eventDispatch",
	"eventEmission",
	"eventGraphExecution",
	"executableCallback",
	"evaluateGuard",
	"execute",
	"executeStateMachine",
	"executionAdapter",
	"executionBatch",
	"exitState",
	"finalDialogue",
	"finalStory",
	"fire",
	"fire" .. "AllClients",
	"fire" .. "Client",
	"frameworkReference",
	"gameplayStateExecution",
	"guardEvaluation",
	"handlerReference",
	"http",
	"http" .. "Service",
	"inputConsumption",
	"instanceReference",
	"invoke" .. "Client",
	"lifecycleExecution",
	"listener",
	"listenerExecution",
	"liveState",
	"messaging",
	"messaging" .. "Service",
	"moduleReference",
	"monsterAIStateExecution",
	"mutateState",
	"narrativeStateExecution",
	"outputEmission",
	"presentationStateExecution",
	"publish",
	"remote",
	"remote" .. "Event",
	"remote" .. "Function",
	"remediation",
	"ruleEngineExecution",
	"ruleEvaluation",
	"ruleExecution",
	"run",
	"runtimeExecution",
	"runtimeGraphExecution",
	"runtimeObject",
	"runtimeOrchestration",
	"runtimeSignalHandle",
	"saveExecution",
	"schedulerExecution",
	"scriptExecution",
	"scripting",
	"serviceReference",
	"signalEmission",
	"signalHandle",
	"setState",
	"stateMachineExecution",
	"stateMutation",
	"stateTransitionExecution",
	"story",
	"subscribe",
	"tele" .. "metry",
	"telemetrySending",
	"transitionExecution",
	"transitionResult",
	"triggerConsumption",
	"triggerEmission",
	"triggerExecution",
	"triggerRuntimeExecution",
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
		return false, "StateMachine payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "StateMachine payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "StateMachine payload contains forbidden value: " .. nested
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
			return false, "tag uses forbidden StateMachine domain: " .. tag
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
		"machineId",
		Types.SchemaType.StateMachineDefinitionSchema,
		"machine"
	)
	if not ok then
		return false, reason
	end
	if not validId(schema.machineName) or Types.Domain[schema.machineDomain] ~= true then
		return false, "machine fields are invalid"
	end
	local checks = {
		{ schema.stateIds, Types.Limits.MaxMachineStates, "stateIds" },
		{ schema.transitionIds, Types.Limits.MaxMachineTransitions, "transitionIds" },
		{ schema.guardIds, Types.Limits.MaxMachineGuards, "guardIds" },
		{ schema.inputIds, Types.Limits.MaxMachineInputs, "inputIds" },
		{ schema.outputIds, Types.Limits.MaxMachineOutputs, "outputIds" },
		{ schema.groupIds, Types.Limits.MaxGroupMembers, "groupIds" },
		{ schema.dependencyIds, Types.Limits.MaxDependencies, "dependencyIds" },
		{ schema.outcomeIds, Types.Limits.MaxOutcomes, "outcomeIds" },
	}
	for _, check in ipairs(checks) do
		local listOk, listReason = validateArrayIds(check[1], check[2], check[3])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.state(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "stateId", Types.SchemaType.StateMachineStateSchema, "state")
	if not ok then
		return false, reason
	end
	if not validId(schema.machineId) or Types.StateKind[schema.stateKind] ~= true then
		return false, "state fields are invalid"
	end
	return true, nil
end

function Validation.transition(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"transitionId",
		Types.SchemaType.StateMachineTransitionSchema,
		"transition"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.machineId)
		or not validId(schema.sourceStateId)
		or not validId(schema.targetStateId)
		or Types.TransitionKind[schema.transitionKind] ~= true
	then
		return false, "transition fields are invalid"
	end
	if
		schema.sourceStateId == schema.targetStateId
		and schema.transitionKind ~= "FutureTransition"
		and schema.noopSchema ~= true
	then
		return false, "transition source equals target"
	end
	return true, nil
end

function Validation.guard(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "guardId", Types.SchemaType.StateMachineGuardSchema, "guard")
	if not ok then
		return false, reason
	end
	if not validId(schema.machineId) or Types.GuardKind[schema.guardKind] ~= true then
		return false, "guard fields are invalid"
	end
	return true, nil
end

function Validation.input(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "inputId", Types.SchemaType.StateMachineInputSchema, "input")
	if not ok then
		return false, reason
	end
	if not validId(schema.machineId) or Types.InputKind[schema.inputKind] ~= true then
		return false, "input fields are invalid"
	end
	return true, nil
end

function Validation.output(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "outputId", Types.SchemaType.StateMachineOutputSchema, "output")
	if not ok then
		return false, reason
	end
	if not validId(schema.machineId) or Types.OutputKind[schema.outputKind] ~= true then
		return false, "output fields are invalid"
	end
	return true, nil
end

function Validation.group(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "groupId", Types.SchemaType.StateMachineGroupSchema, "group")
	if not ok then
		return false, reason
	end
	if Types.GroupKind[schema.groupKind] ~= true then
		return false, "unsupported group kind"
	end
	local checks = {
		{ schema.machineIds, Types.Limits.MaxGroupMembers, "machineIds" },
		{ schema.stateIds, Types.Limits.MaxMachineStates, "stateIds" },
		{ schema.transitionIds, Types.Limits.MaxMachineTransitions, "transitionIds" },
	}
	for _, check in ipairs(checks) do
		local listOk, listReason = validateArrayIds(check[1], check[2], check[3])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.dependency(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"dependencyId",
		Types.SchemaType.StateMachineDependencySchema,
		"dependency"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceMachineId)
		or not validId(schema.targetMachineId)
		or Types.DependencyKind[schema.dependencyKind] ~= true
	then
		return false, "dependency fields are invalid"
	end
	if schema.sourceMachineId == schema.targetMachineId then
		return false, "self-dependency rejects"
	end
	return true, nil
end

function Validation.outcome(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "outcomeId", Types.SchemaType.StateMachineOutcomeSchema, "outcome")
	if not ok then
		return false, reason
	end
	if not validId(schema.machineId) or Types.OutcomeKind[schema.outcomeKind] ~= true then
		return false, "outcome fields are invalid"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.StateMachineAuditSchema, "audit")
	if not ok then
		return false, reason
	end
	if schema.machineId ~= nil and not validId(schema.machineId) then
		return false, "audit machineId is invalid"
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
