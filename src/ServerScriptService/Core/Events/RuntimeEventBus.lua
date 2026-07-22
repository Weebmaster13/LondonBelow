--!strict

local Cancellation = require(script.Parent.EventCancellationRuntime)
local Diagnostics = require(script.Parent.EventDiagnostics)
local Dispatcher = require(script.Parent.EventDispatcher)
local Evidence = require(script.Parent.EventEvidence)
local EventQueue = require(script.Parent.EventQueue)
local EventRegistry = require(script.Parent.EventRegistry)
local PublisherRegistry = require(script.Parent.EventPublisherRegistry)
local ReplaySafety = require(script.Parent.EventReplaySafety)
local Router = require(script.Parent.EventRouter)
local Serialization = require(script.Parent.EventSerialization)
local SubscriberRegistry = require(script.Parent.EventSubscriberRegistry)
local Types = require(script.Parent.EventTypes)
local Validation = require(script.Parent.EventValidation)

local Runtime = {}

local sequence = 0
local legacyListenerId = 0
local shutdown = false
local dispatchDepth = 0
local routingHistory: { any } = {}
local legacyDisconnects: { [number]: string } = {}
local counters = {
	routing = 0,
	dispatching = 0,
	delivered = 0,
	cancelled = 0,
	rejected = 0,
	dropped = 0,
	failed = 0,
	subscriberFailures = 0,
	queueOverflows = 0,
	recursivePublishRejections = 0,
	queueDepthSamples = 0,
	queueDepthTotal = 0,
	lastEventId = nil :: string?,
	lastFailure = nil :: any?,
}

local function nextSequence(): number
	sequence += 1
	return sequence
end

local function normalizeFailure(failureType: string, stage: string, reason: string, envelope: any?)
	local failure = {
		failureType = failureType,
		failureCode = failureType,
		failureReason = reason,
		stage = stage,
		eventId = if envelope ~= nil then envelope.eventId else nil,
		eventType = if envelope ~= nil then envelope.eventType else nil,
		retryable = false,
	}
	counters.lastFailure = Serialization.deepCopy(failure)
	Evidence.record("event rejected", failure)
	return failure
end

local function publisherAllowed(definition: any, publisherId: string): boolean
	for _, allowed in ipairs(definition.allowedPublishers) do
		if allowed == "*" or allowed == publisherId then
			return true
		end
	end
	return false
end

local function defaultCorePayloadValidator(payload: any): (boolean, string?)
	return Validation.payload(payload)
end

local function registerCoreDefaults()
	for _, eventType in pairs(Types.CoreEventTypes) do
		if not EventRegistry.has(eventType) then
			EventRegistry.register({
				eventType = eventType,
				schemaVersion = "1",
				ownerRuntime = Types.ProviderName,
				defaultPriority = Types.Priority.Normal,
				deliveryPolicy = Types.DeliveryPolicy.AtMostOnce,
				replayPolicy = Types.ReplayPolicy.ReplayMetadataOnly,
				payloadValidator = defaultCorePayloadValidator,
				allowedPublishers = { Types.ProviderName, "legacyEventBus" },
				metadataPolicy = "BoundedMetadata",
				noSubscriberPolicy = Types.NoSubscriberPolicy.AllowNoSubscribers,
			})
		end
	end
	if not PublisherRegistry.has(Types.ProviderName) then
		PublisherRegistry.register({
			publisherId = Types.ProviderName,
			runtimeId = Types.ProviderName,
			allowedEventTypes = { "*" },
			authorityPolicy = "ServerAuthority",
		})
	end
	if not PublisherRegistry.has("legacyEventBus") then
		PublisherRegistry.register({
			publisherId = "legacyEventBus",
			runtimeId = "CoreRuntime",
			allowedEventTypes = { "*" },
			authorityPolicy = "ServerAuthority",
		})
	end
end

local function ensureLegacyEventType(eventType: string)
	if EventRegistry.has(eventType) then
		return
	end
	EventRegistry.register({
		eventType = eventType,
		schemaVersion = "legacy",
		ownerRuntime = "CoreRuntime",
		defaultPriority = Types.Priority.Normal,
		deliveryPolicy = Types.DeliveryPolicy.BestEffort,
		replayPolicy = Types.ReplayPolicy.ReplayMetadataOnly,
		payloadValidator = defaultCorePayloadValidator,
		allowedPublishers = { "legacyEventBus", Types.ProviderName },
		metadataPolicy = "LegacyCompatibility",
		noSubscriberPolicy = Types.NoSubscriberPolicy.AllowNoSubscribers,
	})
end

local function createEnvelope(request: any, definition: any): any
	local id = request.eventId or string.format("evt.%06d", sequence + 1)
	local envelope = {
		eventId = id,
		eventType = request.eventType,
		schemaVersion = request.schemaVersion or definition.schemaVersion,
		sourceRuntime = request.sourceRuntime or definition.ownerRuntime,
		issuedTimestamp = request.issuedTimestamp or os.clock(),
		priority = request.priority or definition.defaultPriority,
		payload = request.payload or {},
		correlationId = request.correlationId or id,
		causationId = request.causationId,
		sequence = nextSequence(),
		metadata = request.metadata or {},
	}
	counters.lastEventId = envelope.eventId
	return Serialization.deepCopy(envelope)
end

function Runtime.registerEventType(definition: any)
	return EventRegistry.register(definition)
end

function Runtime.registerPublisher(publisher: any)
	return PublisherRegistry.register(publisher)
end

function Runtime.unregisterPublisher(publisherId: string)
	return PublisherRegistry.unregister(publisherId)
end

function Runtime.subscribe(subscription: any)
	return SubscriberRegistry.subscribe(subscription, EventRegistry.has)
end

function Runtime.unsubscribe(subscriptionId: string)
	return SubscriberRegistry.unsubscribe(subscriptionId)
end

function Runtime.publish(request: any)
	if shutdown then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ShutdownRejected,
			failure = normalizeFailure(
				Types.FailureType.ShutdownRejected,
				"publication",
				"runtime is shut down",
				request
			),
		}
	end
	if type(request) ~= "table" then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			failure = normalizeFailure(
				Types.FailureType.ValidationFailure,
				"publication",
				"request must be a table",
				nil
			),
		}
	end
	if dispatchDepth > Types.Limits.MaxDispatchDepth then
		counters.recursivePublishRejections += 1
		return {
			ok = false,
			code = Types.FailureType.RecursivePublishRejected,
			failure = normalizeFailure(
				Types.FailureType.RecursivePublishRejected,
				"publication",
				"dispatch depth exceeded",
				request
			),
		}
	end
	if
		request.causationDepth ~= nil
		and request.causationDepth > Types.Limits.MaxCausationDepth
	then
		counters.recursivePublishRejections += 1
		return {
			ok = false,
			code = Types.FailureType.RecursivePublishRejected,
			failure = normalizeFailure(
				Types.FailureType.RecursivePublishRejected,
				"publication",
				"causation depth exceeded",
				request
			),
		}
	end
	local definition = EventRegistry.get(request.eventType)
	if definition == nil then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.UnknownEventType,
			failure = normalizeFailure(
				Types.FailureType.UnknownEventType,
				"event type resolution",
				"unknown event type",
				request
			),
		}
	end
	local envelope = createEnvelope(request, definition)
	Evidence.record(
		"event submitted",
		{ eventId = envelope.eventId, eventType = envelope.eventType }
	)
	if envelope.schemaVersion ~= definition.schemaVersion then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			failure = normalizeFailure(
				Types.FailureType.ValidationFailure,
				"schema version",
				"schemaVersion mismatch",
				envelope
			),
		}
	end
	local payloadOk, payloadReason = definition.payloadValidator(envelope.payload)
	if not payloadOk then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.InvalidPayload,
			failure = normalizeFailure(
				Types.FailureType.InvalidPayload,
				"payload validation",
				tostring(payloadReason),
				envelope
			),
		}
	end
	local publisherId = request.publisherId or envelope.sourceRuntime
	if not PublisherRegistry.has(publisherId) then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.UnknownPublisher,
			failure = normalizeFailure(
				Types.FailureType.UnknownPublisher,
				"publisher resolution",
				"unknown publisher",
				envelope
			),
		}
	end
	if
		not PublisherRegistry.canPublish(publisherId, envelope.eventType)
		or not publisherAllowed(definition, publisherId)
	then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.PublisherNotAuthorized,
			failure = normalizeFailure(
				Types.FailureType.PublisherNotAuthorized,
				"publisher permission",
				"publisher cannot emit event",
				envelope
			),
		}
	end
	if not Validation.isValidPriority(envelope.priority) then
		counters.rejected += 1
		return {
			ok = false,
			code = Types.FailureType.InvalidPriority,
			failure = normalizeFailure(
				Types.FailureType.InvalidPriority,
				"priority",
				"invalid priority",
				envelope
			),
		}
	end
	Evidence.record("event validated", { eventId = envelope.eventId })
	local replayMetadata = ReplaySafety.metadata(envelope, definition)
	local queued = EventQueue.enqueue(envelope)
	if not queued.ok then
		if queued.code == Types.FailureType.QueueFull then
			counters.queueOverflows += 1
			counters.dropped += 1
		else
			counters.rejected += 1
		end
		return {
			ok = false,
			code = queued.code,
			failure = normalizeFailure(queued.code, "queue admission", queued.message, envelope),
		}
	end
	counters.queueDepthSamples += 1
	counters.queueDepthTotal += EventQueue.getDepth()
	return Serialization.deepCopy({
		ok = true,
		code = "Ok",
		eventId = envelope.eventId,
		eventType = envelope.eventType,
		status = Types.Status.Queued,
		queued = true,
		routeCount = 0,
		deliveredCount = 0,
		failedDeliveries = 0,
		correlationId = envelope.correlationId,
		sequence = envelope.sequence,
		replayMetadata = replayMetadata,
	})
end

function Runtime.publishBatch(requests: { any })
	if type(requests) ~= "table" or #requests > Types.Limits.MaxBatchSize then
		return { ok = false, code = Types.FailureType.ValidationFailure, message = "invalid batch" }
	end
	local results = {}
	for _, request in ipairs(requests) do
		table.insert(results, Runtime.publish(request))
	end
	return { ok = true, code = "Ok", results = Serialization.copyArray(results) }
end

function Runtime.cancel(eventId: string)
	local result = Cancellation.requestCancellation(eventId)
	if result.ok then
		counters.cancelled += 1
	else
		counters.rejected += 1
	end
	return result
end

function Runtime.dispatchNext()
	local envelope = EventQueue.dequeue()
	if envelope == nil then
		return { ok = true, code = "Empty", deliveredCount = 0, failedDeliveries = 0 }
	end
	local definition = EventRegistry.get(envelope.eventType)
	if definition == nil then
		counters.failed += 1
		return { ok = false, code = Types.FailureType.UnknownEventType, eventId = envelope.eventId }
	end
	counters.routing += 1
	local subscriptions = SubscriberRegistry.listSubscribersForEvent(envelope.eventType)
	local plan = Router.route(envelope, definition, subscriptions)
	table.insert(routingHistory, Serialization.deepCopy(plan))
	while #routingHistory > Types.Limits.MaxDispatchHistory do
		table.remove(routingHistory, 1)
	end
	counters.dispatching += 1
	dispatchDepth += 1
	local result = Dispatcher.dispatch(envelope, plan)
	dispatchDepth -= 1
	if result.ok then
		counters.delivered += 1
	else
		counters.failed += 1
		counters.subscriberFailures += result.failedDeliveries or 0
	end
	return result
end

function Runtime.dispatchAll()
	local results = {}
	while EventQueue.getDepth() > 0 do
		table.insert(results, Runtime.dispatchNext())
	end
	return { ok = true, code = "Ok", results = Serialization.copyArray(results) }
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return require(script.Parent.EventSnapshots).capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return true, nil
end

function Runtime.shutdown()
	shutdown = true
	Evidence.record("shutdown completed", {})
	EventQueue.clear()
	Cancellation.clear()
	Dispatcher.clear()
end

function Runtime.reset()
	shutdown = false
	sequence = 0
	dispatchDepth = 0
	table.clear(routingHistory)
	for key in pairs(counters) do
		if key == "lastEventId" or key == "lastFailure" then
			counters[key] = nil
		else
			counters[key] = 0
		end
	end
	EventRegistry.clear()
	PublisherRegistry.clear()
	SubscriberRegistry.clear()
	EventQueue.clear()
	Cancellation.clear()
	Dispatcher.clear()
	Evidence.clear()
	table.clear(legacyDisconnects)
	registerCoreDefaults()
end

function Runtime.isShutdown(): boolean
	return shutdown
end

function Runtime.getCounters()
	return {
		eventTypes = #Serialization.sortedKeys(EventRegistry.inspect()),
		publishers = #Serialization.sortedKeys(PublisherRegistry.inspect()),
		subscribers = #Serialization.sortedKeys(SubscriberRegistry.inspect()),
		queued = EventQueue.getDepth(),
		routing = counters.routing,
		dispatching = counters.dispatching,
		delivered = counters.delivered,
		cancelled = counters.cancelled,
		rejected = counters.rejected,
		dropped = counters.dropped,
		failed = counters.failed,
		subscriberFailures = counters.subscriberFailures,
		queueOverflows = counters.queueOverflows,
		recursivePublishRejections = counters.recursivePublishRejections,
		averageQueueDepth = if counters.queueDepthSamples == 0
			then 0
			else counters.queueDepthTotal / counters.queueDepthSamples,
		maximumQueueDepth = EventQueue.getMaximumDepth(),
		lastEventId = counters.lastEventId,
		lastFailure = counters.lastFailure,
	}
end

function Runtime.getRoutingHistory()
	return Serialization.copyArray(routingHistory)
end

function Runtime.legacySubscribe(
	eventName: string,
	callback: (any, ...any) -> (),
	priority: number?,
	once: boolean?
)
	ensureLegacyEventType(eventName)
	legacyListenerId += 1
	local subscriptionId = "legacy." .. tostring(legacyListenerId)
	local result = Runtime.subscribe({
		subscriptionId = subscriptionId,
		subscriberId = subscriptionId,
		runtimeId = "legacyEventBus",
		eventTypes = { eventName },
		handler = function(envelope: any, _context: any)
			local event = {
				name = envelope.eventType,
				namespace = string.match(envelope.eventType, "^([^%.]+)%.") or envelope.eventType,
				payload = envelope.payload,
				cancelled = false,
			}
			function event:cancel()
				self.cancelled = true
			end
			callback(event)
			if once == true then
				Runtime.unsubscribe(subscriptionId)
			end
			if event.cancelled then
				return { success = false, failureReason = "legacy event cancelled" }
			end
			return { success = true }
		end,
		priorityFilter = nil,
		failurePolicy = Types.FailurePolicy.ContinueAfterSubscriberFailure,
		metadata = { legacyPriority = priority or 0 },
	})
	if not result.ok then
		error(result.message or "legacy subscription rejected", 2)
	end
	legacyDisconnects[legacyListenerId] = subscriptionId
	return legacyListenerId, function()
		Runtime.unsubscribe(subscriptionId)
	end
end

function Runtime.legacyPublish(eventName: string, payload: any)
	ensureLegacyEventType(eventName)
	local published = Runtime.publish({
		eventType = eventName,
		schemaVersion = "legacy",
		sourceRuntime = "CoreRuntime",
		publisherId = "legacyEventBus",
		payload = payload or {},
		priority = Types.Priority.Normal,
	})
	local dispatch = Runtime.dispatchAll()
	return {
		name = eventName,
		namespace = string.match(eventName, "^([^%.]+)%.") or eventName,
		payload = payload,
		cancelled = dispatch.ok == false,
		published = published,
		dispatch = dispatch,
	}
end

Runtime.reset()

return Runtime
