--!strict
-- Validation boundary for server-owned Event Graph schemas.

local Serialization = require(script.Parent.EventGraphSerialization)
local Types = require(script.Parent.EventGraphTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"adapterReference",
	"analytics",
	"analyticsCollection",
	"callback",
	"chapter0Content",
	"chapterContent",
	"clientAuthority",
	"cutscene",
	"dataStore",
	"dataStoreRead",
	"dataStoreService",
	"dataStoreWrite",
	"dialogue",
	"dispatchHandle",
	"dispatchEvent",
	"dispatchOrdering",
	"enforcement",
	"eventBus",
	"EventBus",
	"eventDispatch",
	"eventRoutingExecution",
	"executableCallback",
	"execute",
	"executionAdapter",
	"filterExecution",
	"finalDialogue",
	"finalStory",
	"fireAllClients",
	"fireClient",
	"fireSignal",
	"frameworkReference",
	"gameplayEventExecution",
	"handlerReference",
	"http",
	"httpService",
	"instanceReference",
	"interactionEventExecution",
	"inventoryEventExecution",
	"invokeClient",
	"lifecycleExecution",
	"listener",
	"listenerReference",
	"liveListener",
	"liveEventBus",
	"liveOrdering",
	"messaging",
	"messagingService",
	"moduleReference",
	"monsterAIEventExecution",
	"narrativeEventExecution",
	"objectiveEventExecution",
	"payloadDelivery",
	"payloadHandle",
	"payloadInspectionExecution",
	"presentationEventExecution",
	"priorityExecution",
	"processQueue",
	"propagationExecution",
	"publish",
	"publishDeferred",
	"puzzleEventExecution",
	"queueProcessing",
	"remote",
	"remoteCommunication",
	"remoteEvent",
	"remoteFunction",
	"remediation",
	"routeEvent",
	"runListener",
	"runtimeValidationExecution",
	"runtimeObject",
	"runtimeOrchestration",
	"saveEventExecution",
	"schedulerExecution",
	"sequencingExecution",
	"serviceReference",
	"signalFire",
	"signalFiring",
	"story",
	"subscriptionHandle",
	"subscribe",
	"telemetry",
	"telemetrySending",
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
		return false, "Event Graph payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "Event Graph payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		if type(nested) == "string" and FORBIDDEN_LOOKUP[string.lower(nested)] == true then
			return false, "Event Graph payload contains forbidden value: " .. nested
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
			return false, "tag uses forbidden Event Graph domain: " .. tag
		end
	end
	return true, nil
end

local function validateFieldList(values: any, limit: number, label: string): (boolean, string?)
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
		if
			type(value) ~= "string"
			or value == ""
			or #value > Types.Limits.MaxPayloadStringLength
		then
			return false, label .. " contains invalid field name"
		end
		if FORBIDDEN_LOOKUP[string.lower(value)] == true then
			return false, label .. " contains forbidden field name"
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

function Validation.node(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "eventNodeId", Types.SchemaType.EventNodeSchema, "event node")
	if not ok then
		return false, reason
	end
	if not validId(schema.eventName) or Types.EventDomain[schema.eventDomain] ~= true then
		return false, "event node fields are invalid"
	end
	local checks = {
		{ schema.channelIds, Types.Limits.MaxNodeChannels, "channelIds" },
		{ schema.sourceIds, Types.Limits.MaxNodeSources, "sourceIds" },
		{ schema.sinkIds, Types.Limits.MaxNodeSinks, "sinkIds" },
		{ schema.payloadContractIds, Types.Limits.MaxNodePayloadContracts, "payloadContractIds" },
	}
	for _, check in ipairs(checks) do
		local listOk, listReason = validateArrayIds(check[1], check[2], check[3])
		if not listOk then
			return false, listReason
		end
	end
	return true, nil
end

function Validation.channel(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "channelId", Types.SchemaType.EventChannelSchema, "channel")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.channelName)
		or Types.ChannelKind[schema.channelKind] ~= true
		or Types.EventDomain[schema.eventDomain] ~= true
	then
		return false, "channel fields are invalid"
	end
	return true, nil
end

function Validation.edge(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "edgeId", Types.SchemaType.EventEdgeSchema, "edge")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceEventNodeId)
		or not validId(schema.targetEventNodeId)
		or Types.EdgeKind[schema.edgeKind] ~= true
	then
		return false, "edge fields are invalid"
	end
	if schema.sourceEventNodeId == schema.targetEventNodeId then
		return false, "self-edge rejects"
	end
	return true, nil
end

function Validation.source(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "sourceId", Types.SchemaType.EventSourceSchema, "source")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceName)
		or not validId(schema.sourceKind)
		or not validId(schema.eventNodeId)
		or not validId(schema.channelId)
	then
		return false, "source fields are invalid"
	end
	return true, nil
end

function Validation.sink(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "sinkId", Types.SchemaType.EventSinkSchema, "sink")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sinkName)
		or not validId(schema.sinkKind)
		or not validId(schema.eventNodeId)
		or not validId(schema.channelId)
	then
		return false, "sink fields are invalid"
	end
	return true, nil
end

function Validation.subscription(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"subscriptionId",
		Types.SchemaType.EventSubscriptionSchema,
		"subscription"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceEventNodeId)
		or not validId(schema.targetEventNodeId)
		or not validId(schema.channelId)
	then
		return false, "subscription fields are invalid"
	end
	if schema.sourceEventNodeId == schema.targetEventNodeId then
		return false, "self-subscription rejects"
	end
	if schema.priorityId ~= nil and not validId(schema.priorityId) then
		return false, "priorityId is invalid"
	end
	return validateArrayIds(schema.filterIds, Types.Limits.MaxSubscriptionFilters, "filterIds")
end

function Validation.propagation(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"propagationId",
		Types.SchemaType.EventPropagationSchema,
		"propagation"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceEventNodeId)
		or Types.PropagationKind[schema.propagationKind] ~= true
	then
		return false, "propagation fields are invalid"
	end
	if schema.priorityId ~= nil and not validId(schema.priorityId) then
		return false, "priorityId is invalid"
	end
	local channelOk, channelReason =
		validateArrayIds(schema.channelIds, Types.Limits.MaxPropagationChannels, "channelIds")
	if not channelOk then
		return false, channelReason
	end
	return validateArrayIds(schema.filterIds, Types.Limits.MaxPropagationFilters, "filterIds")
end

function Validation.priority(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "priorityId", Types.SchemaType.EventPrioritySchema, "priority")
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

function Validation.filter(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "filterId", Types.SchemaType.EventFilterSchema, "filter")
	if not ok then
		return false, reason
	end
	if Types.FilterKind[schema.filterKind] ~= true then
		return false, "unsupported filter kind"
	end
	return true, nil
end

function Validation.payloadContract(schema: any): (boolean, string?)
	local ok, reason = validateSchema(
		schema,
		"payloadContractId",
		Types.SchemaType.EventPayloadContractSchema,
		"payload contract"
	)
	if not ok then
		return false, reason
	end
	if
		not validId(schema.eventNodeId)
		or not validId(schema.contractKind)
		or not validId(schema.schemaVersion)
	then
		return false, "payload contract fields are invalid"
	end
	local allowedOk, allowedReason = validateFieldList(
		schema.allowedFields,
		Types.Limits.MaxPayloadAllowedFields,
		"allowedFields"
	)
	if not allowedOk then
		return false, allowedReason
	end
	local requiredOk, requiredReason = validateFieldList(
		schema.requiredFields,
		Types.Limits.MaxPayloadRequiredFields,
		"requiredFields"
	)
	if not requiredOk then
		return false, requiredReason
	end
	return validateFieldList(
		schema.forbiddenFields,
		Types.Limits.MaxPayloadForbiddenFields,
		"forbiddenFields"
	)
end

function Validation.ordering(schema: any): (boolean, string?)
	local ok, reason =
		validateSchema(schema, "orderingId", Types.SchemaType.EventOrderingSchema, "ordering")
	if not ok then
		return false, reason
	end
	if
		not validId(schema.sourceEventNodeId)
		or not validId(schema.targetEventNodeId)
		or Types.OrderingKind[schema.orderingKind] ~= true
	then
		return false, "ordering fields are invalid"
	end
	if schema.sourceEventNodeId == schema.targetEventNodeId then
		return false, "self-ordering rejects"
	end
	return true, nil
end

function Validation.audit(schema: any): (boolean, string?)
	local ok, reason = validateSchema(schema, "auditId", Types.SchemaType.EventAuditSchema, "audit")
	if not ok then
		return false, reason
	end
	if schema.eventNodeId ~= nil and not validId(schema.eventNodeId) then
		return false, "audit eventNodeId is invalid"
	end
	if not validId(schema.auditKind) or not validId(schema.resultStatus) then
		return false, "audit fields are invalid"
	end
	if schema.findings ~= nil then
		return validateFieldList(schema.findings, Types.Limits.MaxAuditFindings, "findings")
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	return true, nil
end

return Validation
