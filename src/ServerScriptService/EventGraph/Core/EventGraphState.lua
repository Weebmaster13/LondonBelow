--!strict
-- Central bounded state store for the Event Graph Foundation.

local Serialization = require(script.Parent.EventGraphSerialization)
local Types = require(script.Parent.EventGraphTypes)
local Validation = require(script.Parent.EventGraphValidation)

local State = {}

local nodes: { [string]: any } = {}
local channels: { [string]: any } = {}
local edges: { [string]: any } = {}
local sources: { [string]: any } = {}
local sinks: { [string]: any } = {}
local subscriptions: { [string]: any } = {}
local propagations: { [string]: any } = {}
local priorities: { [string]: any } = {}
local filters: { [string]: any } = {}
local payloadContracts: { [string]: any } = {}
local orderings: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function hasAll(map: { [string]: any }, values: any, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	for _, id in ipairs(values) do
		if map[id] == nil then
			return false, "invalid " .. label .. " reference"
		end
	end
	return true, nil
end

local function register(
	map: { [string]: any },
	id: string,
	schema: any,
	limit: number,
	duplicate: string,
	limitReason: string
): (boolean, string?)
	if schemaIds[id] == true then
		return false, duplicate
	end
	if countMap(map) >= limit then
		return false, limitReason
	end
	schemaIds[id] = true
	map[id] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerNode(schema: any): (boolean, string?)
	local ok, reason = Validation.node(schema)
	if not ok then
		return false, reason
	end
	local checks = {
		{ channels, schema.channelIds, "channel" },
		{ sources, schema.sourceIds, "source" },
		{ sinks, schema.sinkIds, "sink" },
		{ payloadContracts, schema.payloadContractIds, "payload contract" },
	}
	for _, check in ipairs(checks) do
		local refsOk, refsReason = hasAll(check[1], check[2], check[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		nodes,
		schema.eventNodeId,
		schema,
		Types.Limits.MaxEventNodes,
		"duplicate eventNodeId",
		"event node limit exceeded"
	)
end

function State.registerChannel(schema: any): (boolean, string?)
	local ok, reason = Validation.channel(schema)
	if not ok then
		return false, reason
	end
	return register(
		channels,
		schema.channelId,
		schema,
		Types.Limits.MaxChannels,
		"duplicate channelId",
		"channel limit exceeded"
	)
end

function State.registerEdge(schema: any): (boolean, string?)
	local ok, reason = Validation.edge(schema)
	if not ok then
		return false, reason
	end
	if nodes[schema.sourceEventNodeId] == nil or nodes[schema.targetEventNodeId] == nil then
		return false, "invalid edge event node reference"
	end
	for _, existing in pairs(edges) do
		if
			existing.sourceEventNodeId == schema.targetEventNodeId
			and existing.targetEventNodeId == schema.sourceEventNodeId
		then
			if
				(existing.edgeKind == "MustPrecede" and schema.edgeKind == "MustFollow")
				or (existing.edgeKind == "MustFollow" and schema.edgeKind == "MustPrecede")
			then
				return false, "direct event edge cycle"
			end
		end
	end
	return register(
		edges,
		schema.edgeId,
		schema,
		Types.Limits.MaxEdges,
		"duplicate edgeId",
		"edge limit exceeded"
	)
end

function State.registerSource(schema: any): (boolean, string?)
	local ok, reason = Validation.source(schema)
	if not ok then
		return false, reason
	end
	if nodes[schema.eventNodeId] == nil or channels[schema.channelId] == nil then
		return false, "invalid source reference"
	end
	return register(
		sources,
		schema.sourceId,
		schema,
		Types.Limits.MaxSources,
		"duplicate sourceId",
		"source limit exceeded"
	)
end

function State.registerSink(schema: any): (boolean, string?)
	local ok, reason = Validation.sink(schema)
	if not ok then
		return false, reason
	end
	if nodes[schema.eventNodeId] == nil or channels[schema.channelId] == nil then
		return false, "invalid sink reference"
	end
	return register(
		sinks,
		schema.sinkId,
		schema,
		Types.Limits.MaxSinks,
		"duplicate sinkId",
		"sink limit exceeded"
	)
end

function State.registerSubscription(schema: any): (boolean, string?)
	local ok, reason = Validation.subscription(schema)
	if not ok then
		return false, reason
	end
	if
		nodes[schema.sourceEventNodeId] == nil
		or nodes[schema.targetEventNodeId] == nil
		or channels[schema.channelId] == nil
	then
		return false, "invalid subscription reference"
	end
	local filtersOk, filtersReason = hasAll(filters, schema.filterIds, "filter")
	if not filtersOk then
		return false, filtersReason
	end
	if schema.priorityId ~= nil and priorities[schema.priorityId] == nil then
		return false, "invalid priority reference"
	end
	return register(
		subscriptions,
		schema.subscriptionId,
		schema,
		Types.Limits.MaxSubscriptions,
		"duplicate subscriptionId",
		"subscription limit exceeded"
	)
end

function State.registerPropagation(schema: any): (boolean, string?)
	local ok, reason = Validation.propagation(schema)
	if not ok then
		return false, reason
	end
	if nodes[schema.sourceEventNodeId] == nil then
		return false, "invalid propagation event node reference"
	end
	local channelsOk, channelsReason = hasAll(channels, schema.channelIds, "channel")
	if not channelsOk then
		return false, channelsReason
	end
	local filtersOk, filtersReason = hasAll(filters, schema.filterIds, "filter")
	if not filtersOk then
		return false, filtersReason
	end
	if schema.priorityId ~= nil and priorities[schema.priorityId] == nil then
		return false, "invalid priority reference"
	end
	return register(
		propagations,
		schema.propagationId,
		schema,
		Types.Limits.MaxPropagations,
		"duplicate propagationId",
		"propagation limit exceeded"
	)
end

function State.registerPriority(schema: any): (boolean, string?)
	local ok, reason = Validation.priority(schema)
	if not ok then
		return false, reason
	end
	return register(
		priorities,
		schema.priorityId,
		schema,
		Types.Limits.MaxPriorities,
		"duplicate priorityId",
		"priority limit exceeded"
	)
end

function State.registerFilter(schema: any): (boolean, string?)
	local ok, reason = Validation.filter(schema)
	if not ok then
		return false, reason
	end
	return register(
		filters,
		schema.filterId,
		schema,
		Types.Limits.MaxFilters,
		"duplicate filterId",
		"filter limit exceeded"
	)
end

function State.registerPayloadContract(schema: any): (boolean, string?)
	local ok, reason = Validation.payloadContract(schema)
	if not ok then
		return false, reason
	end
	if nodes[schema.eventNodeId] == nil then
		return false, "invalid payload contract event node reference"
	end
	return register(
		payloadContracts,
		schema.payloadContractId,
		schema,
		Types.Limits.MaxPayloadContracts,
		"duplicate payloadContractId",
		"payload contract limit exceeded"
	)
end

function State.registerOrdering(schema: any): (boolean, string?)
	local ok, reason = Validation.ordering(schema)
	if not ok then
		return false, reason
	end
	if nodes[schema.sourceEventNodeId] == nil or nodes[schema.targetEventNodeId] == nil then
		return false, "invalid ordering event node reference"
	end
	for _, existing in pairs(orderings) do
		if
			existing.sourceEventNodeId == schema.targetEventNodeId
			and existing.targetEventNodeId == schema.sourceEventNodeId
		then
			if
				(existing.orderingKind == "Before" and schema.orderingKind == "Before")
				or (existing.orderingKind == "After" and schema.orderingKind == "After")
			then
				return false, "direct ordering contradiction"
			end
		end
	end
	return register(
		orderings,
		schema.orderingId,
		schema,
		Types.Limits.MaxOrderings,
		"duplicate orderingId",
		"ordering limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	if schema.eventNodeId ~= nil and nodes[schema.eventNodeId] == nil then
		return false, "invalid audit event node reference"
	end
	return register(
		audits,
		schema.auditId,
		schema,
		Types.Limits.MaxAudits,
		"duplicate auditId",
		"audit limit exceeded"
	)
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function State.inspect()
	return Serialization.deepCopy({
		nodes = nodes,
		channels = channels,
		edges = edges,
		sources = sources,
		sinks = sinks,
		subscriptions = subscriptions,
		propagations = propagations,
		priorities = priorities,
		filters = filters,
		payloadContracts = payloadContracts,
		orderings = orderings,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			nodes = countMap(nodes),
			channels = countMap(channels),
			edges = countMap(edges),
			sources = countMap(sources),
			sinks = countMap(sinks),
			subscriptions = countMap(subscriptions),
			propagations = countMap(propagations),
			priorities = countMap(priorities),
			filters = countMap(filters),
			payloadContracts = countMap(payloadContracts),
			orderings = countMap(orderings),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(nodes)
	table.clear(channels)
	table.clear(edges)
	table.clear(sources)
	table.clear(sinks)
	table.clear(subscriptions)
	table.clear(propagations)
	table.clear(priorities)
	table.clear(filters)
	table.clear(payloadContracts)
	table.clear(orderings)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
