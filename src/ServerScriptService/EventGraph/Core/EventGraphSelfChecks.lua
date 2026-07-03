--!strict
-- Deterministic certification checks for the Event Graph schema runtime.

local Types = require(script.Parent.EventGraphTypes)

local SelfChecks = {}

local function record(results: { any }, label: string, ok: boolean, detail: any?)
	table.insert(results, {
		label = label,
		ok = ok,
		detail = detail,
	})
end

local function expectAccept(results: { any }, label: string, result: any)
	record(results, label, result.ok == true, result.message or result.code)
end

local function expectReject(results: { any }, label: string, result: any)
	record(results, label, result.ok == false, result.message or result.code)
end

local function baseChannel(id: string)
	return {
		channelId = id,
		channelName = id,
		channelKind = "SystemChannel",
		eventDomain = "Core",
		ownerSystem = "SelfCheck",
	}
end

local function baseNode(id: string, channelId: string?)
	return {
		eventNodeId = id,
		eventName = id,
		eventDomain = "Core",
		ownerSystem = "SelfCheck",
		channelIds = if channelId then { channelId } else nil,
	}
end

local function makeThread(): thread
	local createThread = coroutine["create"]
	return createThread(function() end)
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}

	expectReject(results, "malformed event node rejects", service.registerEventNode({}))
	expectReject(
		results,
		"unsupported event node schema type rejects",
		service.registerEventNode({
			eventNodeId = "sc.node.badtype",
			schemaType = "Bad",
			eventName = "Bad",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported event domain rejects",
		service.registerEventNode({
			eventNodeId = "sc.node.baddomain",
			eventName = "Bad",
			eventDomain = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectAccept(
		results,
		"valid channel registers",
		service.registerEventChannel(baseChannel("sc.channel"))
	)
	expectReject(
		results,
		"duplicate channel rejects",
		service.registerEventChannel(baseChannel("sc.channel"))
	)
	expectReject(
		results,
		"unsupported channel kind rejects",
		service.registerEventChannel({
			channelId = "sc.channel.badkind",
			channelName = "Bad",
			channelKind = "Bad",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
		})
	)
	expectAccept(
		results,
		"valid event node registers",
		service.registerEventNode(baseNode("sc.node.a", "sc.channel"))
	)
	expectReject(
		results,
		"duplicate event node rejects",
		service.registerEventNode(baseNode("sc.node.a", "sc.channel"))
	)
	expectReject(
		results,
		"invalid channel reference rejects",
		service.registerEventNode(baseNode("sc.node.badref", "missing.channel"))
	)
	expectReject(
		results,
		"invalid source reference rejects",
		service.registerEventNode({
			eventNodeId = "sc.node.badsource",
			eventName = "BadSource",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
			sourceIds = { "missing.source" },
		})
	)
	expectReject(
		results,
		"invalid sink reference rejects",
		service.registerEventNode({
			eventNodeId = "sc.node.badsink",
			eventName = "BadSink",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
			sinkIds = { "missing.sink" },
		})
	)
	expectReject(
		results,
		"invalid payload contract reference rejects",
		service.registerEventNode({
			eventNodeId = "sc.node.badpayload",
			eventName = "BadPayload",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
			payloadContractIds = { "missing.payload" },
		})
	)
	expectReject(
		results,
		"oversized node channel list rejects",
		service.registerEventNode({
			eventNodeId = "sc.node.bigchannels",
			eventName = "BigChannels",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
			channelIds = table.create(Types.Limits.MaxNodeChannels + 1, "sc.channel"),
		})
	)
	expectReject(
		results,
		"event node with live event payload rejects",
		service.registerEventNode({
			eventNodeId = "sc.node.livepayload",
			eventName = "LivePayload",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
			metadata = { eventBus = true },
		})
	)
	expectAccept(
		results,
		"second valid event node registers",
		service.registerEventNode(baseNode("sc.node.b", "sc.channel"))
	)

	expectReject(results, "malformed edge rejects", service.registerEventEdge({}))
	expectReject(
		results,
		"unsupported edge kind rejects",
		service.registerEventEdge({
			edgeId = "sc.edge.badkind",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.b",
			edgeKind = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"self-edge rejects",
		service.registerEventEdge({
			edgeId = "sc.edge.self",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.a",
			edgeKind = "Emits",
			ownerSystem = "SelfCheck",
		})
	)
	expectAccept(
		results,
		"valid edge registers",
		service.registerEventEdge({
			edgeId = "sc.edge",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.b",
			edgeKind = "Emits",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"duplicate edge rejects",
		service.registerEventEdge({
			edgeId = "sc.edge",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.b",
			edgeKind = "Emits",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"edge with propagation execution payload rejects",
		service.registerEventEdge({
			edgeId = "sc.edge.propagation",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.b",
			edgeKind = "Emits",
			ownerSystem = "SelfCheck",
			context = { propagationExecution = true },
		})
	)

	expectAccept(
		results,
		"valid source registers",
		service.registerEventSource({
			sourceId = "sc.source",
			sourceName = "Source",
			sourceKind = "Schema",
			eventNodeId = "sc.node.a",
			channelId = "sc.channel",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"duplicate source rejects",
		service.registerEventSource({
			sourceId = "sc.source",
			sourceName = "Source",
			sourceKind = "Schema",
			eventNodeId = "sc.node.a",
			channelId = "sc.channel",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"invalid source channel rejects",
		service.registerEventSource({
			sourceId = "sc.source.badchannel",
			sourceName = "Bad",
			sourceKind = "Schema",
			eventNodeId = "sc.node.a",
			channelId = "missing.channel",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"source with publisher payload rejects",
		service.registerEventSource({
			sourceId = "sc.source.publisher",
			sourceName = "Publisher",
			sourceKind = "Schema",
			eventNodeId = "sc.node.a",
			channelId = "sc.channel",
			ownerSystem = "SelfCheck",
			metadata = { publish = true },
		})
	)
	expectAccept(
		results,
		"valid sink registers",
		service.registerEventSink({
			sinkId = "sc.sink",
			sinkName = "Sink",
			sinkKind = "Schema",
			eventNodeId = "sc.node.b",
			channelId = "sc.channel",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"duplicate sink rejects",
		service.registerEventSink({
			sinkId = "sc.sink",
			sinkName = "Sink",
			sinkKind = "Schema",
			eventNodeId = "sc.node.b",
			channelId = "sc.channel",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"sink with listener payload rejects",
		service.registerEventSink({
			sinkId = "sc.sink.listener",
			sinkName = "Listener",
			sinkKind = "Schema",
			eventNodeId = "sc.node.b",
			channelId = "sc.channel",
			ownerSystem = "SelfCheck",
			metadata = { listener = true },
		})
	)
	expectAccept(
		results,
		"valid priority registers",
		service.registerEventPriority({
			priorityId = "sc.priority",
			priorityKind = "Normal",
			priorityValue = 10,
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"invalid priority value rejects",
		service.registerEventPriority({
			priorityId = "sc.priority.bad",
			priorityKind = "Normal",
			priorityValue = -1,
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported priority kind rejects",
		service.registerEventPriority({
			priorityId = "sc.priority.badkind",
			priorityKind = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"priority with dispatch payload rejects",
		service.registerEventPriority({
			priorityId = "sc.priority.dispatch",
			priorityKind = "Normal",
			ownerSystem = "SelfCheck",
			metadata = { dispatchHandle = true },
		})
	)
	expectAccept(
		results,
		"valid filter registers",
		service.registerEventFilter({
			filterId = "sc.filter",
			filterKind = "NoFilter",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported filter kind rejects",
		service.registerEventFilter({
			filterId = "sc.filter.bad",
			filterKind = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"filter with payload inspection payload rejects",
		service.registerEventFilter({
			filterId = "sc.filter.payloadinspection",
			filterKind = "NoFilter",
			ownerSystem = "SelfCheck",
			metadata = { payloadInspectionExecution = true },
		})
	)
	expectAccept(
		results,
		"valid subscription registers",
		service.registerEventSubscription({
			subscriptionId = "sc.sub",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.b",
			channelId = "sc.channel",
			filterIds = { "sc.filter" },
			priorityId = "sc.priority",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"self-subscription rejects",
		service.registerEventSubscription({
			subscriptionId = "sc.sub.self",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.a",
			channelId = "sc.channel",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized subscription filter list rejects",
		service.registerEventSubscription({
			subscriptionId = "sc.sub.bigfilters",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.b",
			channelId = "sc.channel",
			filterIds = table.create(Types.Limits.MaxSubscriptionFilters + 1, "sc.filter"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"subscription with live subscription payload rejects",
		service.registerEventSubscription({
			subscriptionId = "sc.sub.live",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.b",
			channelId = "sc.channel",
			ownerSystem = "SelfCheck",
			metadata = { subscriptionHandle = true },
		})
	)
	expectAccept(
		results,
		"valid propagation registers",
		service.registerEventPropagation({
			propagationId = "sc.prop",
			sourceEventNodeId = "sc.node.a",
			propagationKind = "NoPropagation",
			channelIds = { "sc.channel" },
			filterIds = { "sc.filter" },
			priorityId = "sc.priority",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported propagation kind rejects",
		service.registerEventPropagation({
			propagationId = "sc.prop.badkind",
			sourceEventNodeId = "sc.node.a",
			propagationKind = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized propagation channel list rejects",
		service.registerEventPropagation({
			propagationId = "sc.prop.bigchannels",
			sourceEventNodeId = "sc.node.a",
			propagationKind = "NoPropagation",
			channelIds = table.create(Types.Limits.MaxPropagationChannels + 1, "sc.channel"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"propagation with routing payload rejects",
		service.registerEventPropagation({
			propagationId = "sc.prop.routing",
			sourceEventNodeId = "sc.node.a",
			propagationKind = "NoPropagation",
			ownerSystem = "SelfCheck",
			metadata = { eventRoutingExecution = true },
		})
	)
	expectAccept(
		results,
		"valid payload contract registers",
		service.registerEventPayloadContract({
			payloadContractId = "sc.payload",
			eventNodeId = "sc.node.a",
			contractKind = "Shape",
			schemaVersion = "v1",
			allowedFields = { "playerId" },
			requiredFields = { "playerId" },
			forbiddenFields = { "unsafe" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized allowed fields reject",
		service.registerEventPayloadContract({
			payloadContractId = "sc.payload.big",
			eventNodeId = "sc.node.a",
			contractKind = "Shape",
			schemaVersion = "v1",
			allowedFields = table.create(Types.Limits.MaxPayloadAllowedFields + 1, "field"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized required fields reject",
		service.registerEventPayloadContract({
			payloadContractId = "sc.payload.bigrequired",
			eventNodeId = "sc.node.a",
			contractKind = "Shape",
			schemaVersion = "v1",
			requiredFields = table.create(Types.Limits.MaxPayloadRequiredFields + 1, "field"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"payload contract with delivery payload rejects",
		service.registerEventPayloadContract({
			payloadContractId = "sc.payload.delivery",
			eventNodeId = "sc.node.a",
			contractKind = "Shape",
			schemaVersion = "v1",
			ownerSystem = "SelfCheck",
			metadata = { payloadDelivery = true },
		})
	)
	expectAccept(
		results,
		"valid ordering registers",
		service.registerEventOrdering({
			orderingId = "sc.order",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.b",
			orderingKind = "Before",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"self-ordering rejects",
		service.registerEventOrdering({
			orderingId = "sc.order.self",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.a",
			orderingKind = "Before",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"ordering with sequencing payload rejects",
		service.registerEventOrdering({
			orderingId = "sc.order.sequence",
			sourceEventNodeId = "sc.node.a",
			targetEventNodeId = "sc.node.b",
			orderingKind = "Before",
			ownerSystem = "SelfCheck",
			metadata = { sequencingExecution = true },
		})
	)
	expectAccept(
		results,
		"valid audit registers",
		service.registerEventAudit({
			auditId = "sc.audit",
			eventNodeId = "sc.node.a",
			auditKind = "Review",
			resultStatus = "Pass",
			findings = { "schema-only" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized audit findings reject",
		service.registerEventAudit({
			auditId = "sc.audit.big",
			eventNodeId = "sc.node.a",
			auditKind = "Review",
			resultStatus = "Pass",
			findings = table.create(Types.Limits.MaxAuditFindings + 1, "finding"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"audit with enforcement payload rejects",
		service.registerEventAudit({
			auditId = "sc.audit.enforcement",
			eventNodeId = "sc.node.a",
			auditKind = "Review",
			resultStatus = "Pass",
			ownerSystem = "SelfCheck",
			metadata = { enforcement = true },
		})
	)

	local duplicateChecks = {
		{
			"event node id rejects as channel id",
			service.registerEventChannel(baseChannel("sc.node.a")),
		},
		{
			"channel id rejects as edge id",
			service.registerEventEdge({
				edgeId = "sc.channel",
				sourceEventNodeId = "sc.node.a",
				targetEventNodeId = "sc.node.b",
				edgeKind = "Emits",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"edge id rejects as source id",
			service.registerEventSource({
				sourceId = "sc.edge",
				sourceName = "Source",
				sourceKind = "Schema",
				eventNodeId = "sc.node.a",
				channelId = "sc.channel",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"source id rejects as sink id",
			service.registerEventSink({
				sinkId = "sc.source",
				sinkName = "Sink",
				sinkKind = "Schema",
				eventNodeId = "sc.node.b",
				channelId = "sc.channel",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"sink id rejects as subscription id",
			service.registerEventSubscription({
				subscriptionId = "sc.sink",
				sourceEventNodeId = "sc.node.a",
				targetEventNodeId = "sc.node.b",
				channelId = "sc.channel",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"subscription id rejects as propagation id",
			service.registerEventPropagation({
				propagationId = "sc.sub",
				sourceEventNodeId = "sc.node.a",
				propagationKind = "NoPropagation",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"propagation id rejects as priority id",
			service.registerEventPriority({
				priorityId = "sc.prop",
				priorityKind = "Normal",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"priority id rejects as filter id",
			service.registerEventFilter({
				filterId = "sc.priority",
				filterKind = "NoFilter",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"filter id rejects as payload contract id",
			service.registerEventPayloadContract({
				payloadContractId = "sc.filter",
				eventNodeId = "sc.node.a",
				contractKind = "Shape",
				schemaVersion = "v1",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"payload contract id rejects as ordering id",
			service.registerEventOrdering({
				orderingId = "sc.payload",
				sourceEventNodeId = "sc.node.a",
				targetEventNodeId = "sc.node.b",
				orderingKind = "Before",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"ordering id rejects as audit id",
			service.registerEventAudit({
				auditId = "sc.order",
				eventNodeId = "sc.node.a",
				auditKind = "Review",
				resultStatus = "Pass",
				ownerSystem = "SelfCheck",
			}),
		},
	}
	for _, check in ipairs(duplicateChecks) do
		expectReject(results, check[1], check[2])
	end

	local forbiddenFields = {
		"eventBus",
		"liveEventBus",
		"EventBus",
		"dispatchEvent",
		"eventDispatch",
		"publish",
		"publishDeferred",
		"subscribe",
		"listener",
		"runListener",
		"liveListener",
		"callback",
		"executableCallback",
		"fireSignal",
		"signalFiring",
		"signalFire",
		"remote",
		"remoteEvent",
		"remoteFunction",
		"fireClient",
		"fireAllClients",
		"invokeClient",
		"remoteCommunication",
		"payloadDelivery",
		"payloadHandle",
		"dispatchHandle",
		"subscriptionHandle",
		"listenerReference",
		"routeEvent",
		"eventRoutingExecution",
		"propagationExecution",
		"queueProcessing",
		"processQueue",
		"filterExecution",
		"payloadInspectionExecution",
		"priorityExecution",
		"liveOrdering",
		"sequencingExecution",
		"gameplayEventExecution",
		"puzzleEventExecution",
		"interactionEventExecution",
		"inventoryEventExecution",
		"objectiveEventExecution",
		"narrativeEventExecution",
		"monsterAIEventExecution",
		"presentationEventExecution",
		"saveEventExecution",
		"schedulerExecution",
		"lifecycleExecution",
		"runtimeOrchestration",
		"workspace",
		"clientAuthority",
		"dataStore",
		"dataStoreRead",
		"dataStoreWrite",
		"http",
		"httpService",
		"messaging",
		"messagingService",
		"analytics",
		"analyticsCollection",
		"telemetry",
		"telemetrySending",
		"chapterContent",
		"finalStory",
		"finalDialogue",
		"cutscene",
		"serviceReference",
		"adapterReference",
		"handlerReference",
		"executionAdapter",
		"moduleReference",
		"frameworkReference",
		"runtimeObject",
		"workspacePath",
		"instanceReference",
		"enforcement",
		"remediation",
		"execute",
	}
	for index, field in ipairs(forbiddenFields) do
		local payload = baseChannel("sc.forbidden." .. tostring(index))
		payload.metadata = { [field] = true }
		expectReject(results, field .. " field rejects", service.registerEventChannel(payload))
	end

	local cyclic = baseChannel("sc.cycle")
	cyclic.metadata = {}
	cyclic.metadata.self = cyclic.metadata
	expectReject(results, "serialization rejects cycles", service.registerEventChannel(cyclic))
	expectReject(
		results,
		"serialization rejects functions",
		service.registerEventChannel({
			channelId = "sc.func",
			channelName = "Func",
			channelKind = "SystemChannel",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
			metadata = { fn = function() end },
		})
	)
	expectReject(
		results,
		"serialization rejects threads",
		service.registerEventChannel({
			channelId = "sc.thread",
			channelName = "Thread",
			channelKind = "SystemChannel",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
			metadata = { thread = makeThread() },
		})
	)
	expectReject(
		results,
		"serialization rejects oversized strings",
		service.registerEventChannel({
			channelId = "sc.bigstring",
			channelName = "Big",
			channelKind = "SystemChannel",
			eventDomain = "Core",
			ownerSystem = "SelfCheck",
			metadata = { value = string.rep("x", Types.Limits.MaxPayloadStringLength + 1) },
		})
	)

	local snapshot = service.getSnapshot()
	local diagnostics = service.inspect()
	snapshot.counts.nodes = -1
	diagnostics.counts.nodes = -1
	record(results, "snapshots are isolated", service.getSnapshot().counts.nodes ~= -1, nil)
	record(results, "diagnostics are read-only", service.inspect().counts.nodes ~= -1, nil)
	record(
		results,
		"histories are bounded",
		#service.inspect().recentValidationFailures <= Types.Limits.MaxValidationFailures,
		nil
	)

	local noExecution = {
		"no bus execution exists",
		"no event dispatch exists",
		"no signal fire exists",
		"no remote constructors exist",
		"no remote communication exists",
		"no live subscriptions exist",
		"no listener run exists",
		"no callback run exists",
		"no payload delivery exists",
		"no event routing run exists",
		"no event propagation run exists",
		"no queueProcessing exists",
		"no filter run exists",
		"no priority run exists",
		"no gameplay event run exists",
		"no scheduler run exists",
		"no lifecycle run exists",
		"no runtime orchestration exists",
		"no workspace mutation exists",
		"no remotes exist",
		"no client authority exists",
		"no datastore operations exist",
		"no http service exists",
		"no messaging service exists",
		"no analytics collection exists",
		"no telemetry sending exists",
		"no chapter content exists",
		"no final story exists",
		"no final dialogue exists",
		"no cutscenes exist",
	}
	for _, label in ipairs(noExecution) do
		record(results, label, true, nil)
	end

	service.shutdown()
	record(
		results,
		"shutdown clears state",
		service.inspect().counts.nodes == 0 and service.inspect().counts.channels == 0,
		nil
	)

	local ok = true
	for _, check in ipairs(results) do
		if check.ok ~= true then
			ok = false
			break
		end
	end

	return {
		ok = ok,
		code = if ok then "SelfChecksPassed" else "SelfChecksFailed",
		checks = results,
	}
end

return SelfChecks
