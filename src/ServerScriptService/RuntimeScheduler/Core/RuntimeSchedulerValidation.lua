--!strict
-- Validation boundary for server-owned Runtime Scheduler schemas.

local Serialization = require(script.Parent.RuntimeSchedulerSerialization)
local Types = require(script.Parent.RuntimeSchedulerTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"adapterReference",
	"analytics",
	"analyticsCollection",
	"assetLoading",
	"asyncExecution",
	"blockingExecution",
	"callRuntime",
	"callback",
	"chapter0Content",
	"chapterContent",
	"clientAuthority",
	"contentLoading",
	"coroutine",
	"coroutineCreate",
	"coroutineExecution",
	"coroutineHandle",
	"coroutineResume",
	"cutscene",
	"dataStore",
	"dataStoreRead",
	"dataStoreWrite",
	"dependencyInjection",
	"dialogue",
	"Delay",
	"DelayExecution",
	"dispatchExecution",
	"dispatchState",
	"enforcement",
	"executionGate",
	"executableCallback",
	"execute",
	"executionAdapter",
	"finalDialogue",
	"finalStory",
	"fireAllClients",
	"fireClient",
	"frameScheduling",
	"frameworkReference",
	"gameplayExecution",
	"handlerReference",
	"heartbeat",
	"http",
	"httpService",
	"initializationExecution",
	"initializeRuntime",
	"instanceReference",
	"interactionExecution",
	"inventoryExecution",
	"invokeClient",
	"jobExecution",
	"livePerformanceMutation",
	"liveQueue",
	"liveSchedulerHandle",
	"liveScheduling",
	"liveTimeCheck",
	"mapLoading",
	"messaging",
	"messagingService",
	"moduleLoading",
	"moduleReference",
	"monsterAIExecution",
	"narrativeExecution",
	"objectiveExecution",
	"presentationExecution",
	"puzzleExecution",
	"queueProcessing",
	"processQueue",
	"remediation",
	"remote",
	"remoteEvent",
	"remoteFunction",
	"renderStepped",
	"require",
	"requireCall",
	"retryExecution",
	"roomLoading",
	"runService",
	"runtimeApiCall",
	"runtimeObject",
	"runtimeOrchestration",
	"runServiceReference",
	"savePersistence",
	"scheduleExecution",
	"serviceReference",
	"serviceResolution",
	"shutdownExecution",
	"shutdownRuntime",
	"Spawn",
	"startupExecution",
	"startRuntime",
	"stepped",
	"story",
	"taskDefer",
	"taskHandle",
	"TaskDelay",
	"taskExecution",
	"taskSpawn",
	"telemetry",
	"telemetrySending",
	"timerExecution",
	"timerHandle",
	"tickExecution",
	"timeoutExecution",
	"throttlingExecution",
	"Wait",
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
		return false, "Runtime Scheduler payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Runtime Scheduler payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Runtime Scheduler payload contains forbidden value: " .. nested
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
			return false, "tag uses forbidden runtime scheduler domain: " .. tag
		end
	end
	return true, nil
end

local function validOptionalNumber(value: any): boolean
	return value == nil or (type(value) == "number" and value >= 0 and value < math.huge)
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

function Validation.plan(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "schedulePlanId", Types.SchemaType.SchedulePlanSchema, "plan")
	if not ok then
		return false, reason
	end
	if Types.ScheduleKind[schema.scheduleKind] ~= true then
		return false, "unsupported schedule kind"
	end
	local checks = {
		{ schema.queueIds, Types.Limits.MaxPlanQueues, "queueIds" },
		{ schema.slotIds, Types.Limits.MaxPlanSlots, "slotIds" },
		{ schema.budgetIds, Types.Limits.MaxPlanBudgets, "budgetIds" },
		{ schema.deadlineIds, Types.Limits.MaxPlanDeadlines, "deadlineIds" },
		{ schema.retryIds, Types.Limits.MaxPlanRetries, "retryIds" },
		{ schema.intervalIds, Types.Limits.MaxPlanIntervals, "intervalIds" },
		{ schema.windowIds, Types.Limits.MaxPlanWindows, "windowIds" },
		{ schema.dependencyIds, Types.Limits.MaxPlanDependencies, "dependencyIds" },
	}
	for _, check in ipairs(checks) do
		local listOk, listReason = validateArrayIds(check[1], check[2], check[3])
		if not listOk then
			return false, listReason
		end
	end
	if schema.priorityId ~= nil and not validId(schema.priorityId) then
		return false, "priorityId is invalid"
	end
	return true, nil
end

function Validation.slot(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "slotId", Types.SchemaType.ScheduleSlotSchema, "slot")
	if not ok then
		return false, reason
	end
	if not validId(schema.slotKind) or not validOptionalNumber(schema.plannedOrder) then
		return false, "slot fields are invalid"
	end
	return true, nil
end

function Validation.queue(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "queueId", Types.SchemaType.ScheduleQueueSchema, "queue")
	if not ok then
		return false, reason
	end
	if Types.QueueKind[schema.queueKind] ~= true then
		return false, "unsupported queue kind"
	end
	local prioritiesOk, prioritiesReason =
		validateArrayIds(schema.priorityIds, Types.Limits.MaxPlanQueues, "priorityIds")
	if not prioritiesOk then
		return false, prioritiesReason
	end
	return validateArrayIds(schema.budgetIds, Types.Limits.MaxPlanBudgets, "budgetIds")
end

function Validation.priority(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "priorityId", Types.SchemaType.SchedulePrioritySchema, "priority")
	if not ok then
		return false, reason
	end
	if
		Types.PriorityKind[schema.priorityKind] ~= true
		or not validOptionalNumber(schema.priorityValue)
	then
		return false, "priority fields are invalid"
	end
	return true, nil
end

function Validation.budget(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "budgetId", Types.SchemaType.ScheduleBudgetSchema, "budget")
	if not ok then
		return false, reason
	end
	if
		Types.BudgetKind[schema.budgetKind] ~= true or not validOptionalNumber(schema.limitValue)
	then
		return false, "budget fields are invalid"
	end
	if schema.unit ~= nil and not validId(schema.unit) then
		return false, "budget unit is invalid"
	end
	return true, nil
end

function Validation.deadline(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "deadlineId", Types.SchemaType.ScheduleDeadlineSchema, "deadline")
	if not ok then
		return false, reason
	end
	if Types.DeadlineKind[schema.deadlineKind] ~= true then
		return false, "unsupported deadline kind"
	end
	return true, nil
end

function Validation.retry(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "retryId", Types.SchemaType.ScheduleRetrySchema, "retry")
	if not ok then
		return false, reason
	end
	if Types.RetryKind[schema.retryKind] ~= true or not validOptionalNumber(schema.maxAttempts) then
		return false, "retry fields are invalid"
	end
	return true, nil
end

function Validation.interval(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "intervalId", Types.SchemaType.ScheduleIntervalSchema, "interval")
	if not ok then
		return false, reason
	end
	if not validId(schema.intervalKind) or not validOptionalNumber(schema.intervalValue) then
		return false, "interval fields are invalid"
	end
	return true, nil
end

function Validation.window(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "windowId", Types.SchemaType.ScheduleWindowSchema, "window")
	if not ok then
		return false, reason
	end
	if Types.WindowKind[schema.windowKind] ~= true then
		return false, "unsupported window kind"
	end
	return true, nil
end

function Validation.dependency(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"dependencyId",
		Types.SchemaType.ScheduleDependencySchema,
		"dependency"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceSchedulePlanId)
		or not validId(schema.targetSchedulePlanId)
		or not validId(schema.dependencyKind)
	then
		return false, "dependency fields are invalid"
	end
	if schema.sourceSchedulePlanId == schema.targetSchedulePlanId then
		return false, "schedule dependency cannot target itself"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "auditId", Types.SchemaType.ScheduleAuditSchema, "audit")
	if not ok then
		return false, reason
	end
	if schema.schedulePlanId ~= nil and not validId(schema.schedulePlanId) then
		return false, "audit schedule plan reference is invalid"
	end
	return validateArrayIds(schema.findings, Types.Limits.MaxAuditFindings, "findings")
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeRuntimeSchedulerSchemaRuntime" then
		return false, "Runtime Scheduler must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
