--!strict

local Budgets = require(script.Parent.CapabilityBudgets)
local Certification = require(script.Parent.CapabilityCertification)
local DependencyGraph = require(script.Parent.CapabilityDependencyGraph)
local Discovery = require(script.Parent.CapabilityDiscovery)
local Evidence = require(script.Parent.CapabilityEvidence)
local Governance = require(script.Parent.CapabilityGovernance)
local Health = require(script.Parent.CapabilityHealth)
local Lifecycle = require(script.Parent.CapabilityLifecycle)
local Metrics = require(script.Parent.CapabilityMetrics)
local Profiler = require(script.Parent.CapabilityProfiler)
local Registry = require(script.Parent.CapabilityRegistry)
local Serialization = require(script.Parent.CapabilitySerialization)
local Types = require(script.Parent.CapabilityTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		capabilityFrameworkPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
		capabilityRegistry = Registry.inspect(),
		capabilityLifecycle = Lifecycle.inspect(),
		capabilityDependencyGraph = DependencyGraph.inspect(),
		capabilityDiscovery = Discovery.inspect(),
		capabilityHealth = Health.inspect(),
		capabilityEvidence = Evidence.inspect(),
		capabilityMetrics = Metrics.inspect(),
		capabilityProfiler = Profiler.inspect(),
		capabilityBudgets = Budgets.inspect(),
		capabilityGovernance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = runtime.getCounters(),
		noDirectSubsystemCoupling = true,
		noGameplayAuthority = true,
		noCommandExecution = true,
		noEventPublication = true,
		noQueryExecution = true,
		noNetworking = true,
		noPersistenceExecution = true,
		noWorkspaceMutation = true,
		noClientAuthority = true,
	})
end

return Diagnostics
