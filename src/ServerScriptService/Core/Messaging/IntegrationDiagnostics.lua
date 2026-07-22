--!strict

local Budgets = require(script.Parent.IntegrationBudgets)
local Certification = require(script.Parent.IntegrationCertification)
local ConsumerRegistry = require(script.Parent.ConsumerRegistry)
local DependencyRegistry = require(script.Parent.DependencyRegistry)
local Evidence = require(script.Parent.MessagingEvidence)
local Lifecycle = require(script.Parent.ConsumerLifecycle)
local Metrics = require(script.Parent.MessagingMetrics)
local Profiler = require(script.Parent.IntegrationProfiler)
local RuntimeDiscovery = require(script.Parent.RuntimeDiscovery)
local Serialization = require(script.Parent.MessagingSerialization)
local SubscriptionRegistry = require(script.Parent.SubscriptionRegistry)
local Types = require(script.Parent.MessagingTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	local counters = runtime.getCounters()
	local health = if runtime.isShutdown()
		then Types.HealthStatus.Shutdown
		elseif counters.failed > 0 then Types.HealthStatus.Warning
		else Types.HealthStatus.Healthy
	return {
		providerName = Types.ProviderName,
		messagingIntegrationPosture = health,
		consumerRegistry = ConsumerRegistry.inspect(),
		consumerLifecycle = Lifecycle.inspect(),
		dependencyGraph = DependencyRegistry.inspect(),
		subscriptionRegistry = SubscriptionRegistry.inspect(),
		runtimeDiscovery = RuntimeDiscovery.inspect(),
		integrationMetrics = Metrics.inspect(),
		integrationProfiler = Profiler.inspect(),
		integrationBudgets = Budgets.inspect(),
		integrationEvidence = Evidence.inspect(),
		certification = Certification.inspect(),
		counters = Serialization.deepCopy(counters),
		noDirectGameplayCoupling = true,
		noCommandOwnership = true,
		noEventOwnership = true,
		noQueryOwnership = true,
		noNetworking = true,
		noPersistence = true,
		noWorkspaceMutation = true,
		noClientAuthority = true,
	}
end

return Diagnostics
