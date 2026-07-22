--!strict

local Types = require(script.Parent.EventTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	local counters = runtime.getCounters()
	return {
		eventBusPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
		registeredEventTypes = counters.eventTypes,
		registeredPublishers = counters.publishers,
		registeredSubscribers = counters.subscribers,
		queuedEvents = counters.queued,
		routingEvents = counters.routing,
		dispatchingEvents = counters.dispatching,
		deliveredEvents = counters.delivered,
		cancelledEvents = counters.cancelled,
		rejectedEvents = counters.rejected,
		droppedEvents = counters.dropped,
		failedEvents = counters.failed,
		subscriberFailures = counters.subscriberFailures,
		queueOverflows = counters.queueOverflows,
		recursivePublishRejections = counters.recursivePublishRejections,
		averageQueueDepth = counters.averageQueueDepth,
		maximumQueueDepth = counters.maximumQueueDepth,
		lastEventId = counters.lastEventId,
		lastFailure = counters.lastFailure,
		limits = Types.Limits,
	}
end

return Diagnostics
