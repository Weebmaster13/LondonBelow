--!strict

local Serialization = require(script.Parent.MessagingSerialization)

local Inspection = {}

function Inspection.capture(runtime: any)
	return Serialization.deepCopy({
		consumers = runtime.getConsumers(),
		dependencyGraph = runtime.getDependencyGraph(),
		subscriptions = runtime.getSubscriptions(),
		discovery = runtime.getDiscovery(),
		counters = runtime.getCounters(),
	})
end

return Inspection
