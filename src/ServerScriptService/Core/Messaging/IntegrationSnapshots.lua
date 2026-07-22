--!strict

local Diagnostics = require(script.Parent.IntegrationDiagnostics)
local Serialization = require(script.Parent.MessagingSerialization)
local Types = require(script.Parent.MessagingTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		messagingIntegrationSnapshot = {
			messagingIntegrationPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
			consumerSnapshot = runtime.getConsumers(),
			dependencySnapshot = runtime.getDependencyGraph(),
			subscriptionSnapshot = runtime.getSubscriptions(),
			discoverySnapshot = runtime.getDiscovery(),
			counters = runtime.getCounters(),
		},
		diagnosticsSnapshot = Diagnostics.capture(runtime),
	})
end

return Snapshots
