--!strict

local Cancellation = require(script.Parent.EventCancellationRuntime)
local Dispatcher = require(script.Parent.EventDispatcher)
local Evidence = require(script.Parent.EventEvidence)
local EventQueue = require(script.Parent.EventQueue)
local EventRegistry = require(script.Parent.EventRegistry)
local PublisherRegistry = require(script.Parent.EventPublisherRegistry)
local Serialization = require(script.Parent.EventSerialization)
local SubscriberRegistry = require(script.Parent.EventSubscriberRegistry)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		eventRegistrySnapshot = EventRegistry.inspect(),
		publisherRegistrySnapshot = PublisherRegistry.inspect(),
		subscriberRegistrySnapshot = SubscriberRegistry.inspect(),
		queueSnapshot = EventQueue.inspect(),
		routingSnapshot = runtime.getRoutingHistory(),
		dispatchSnapshot = Dispatcher.inspect(),
		cancellationSnapshot = Cancellation.inspectCancellation(),
		diagnosticsSnapshot = runtime.inspect(),
		evidenceSnapshot = Evidence.inspect(),
	})
end

return Snapshots
