--!strict

local Budgets = require(script.Parent.DomainBudgets)
local Certification = require(script.Parent.DomainCertification)
local Communication = require(script.Parent.CapabilityCommunicationContracts)
local Evidence = require(script.Parent.DomainEvidence)
local Governance = require(script.Parent.DomainGovernance)
local Identity = require(script.Parent.DomainIdentityRegistry)
local InterfaceOwnership = require(script.Parent.InterfaceOwnershipRegistry)
local LifecycleIntegration = require(script.Parent.DomainLifecycleIntegration)
local Metrics = require(script.Parent.DomainMetrics)
local Profiler = require(script.Parent.DomainProfiler)
local Serialization = require(script.Parent.DomainSerialization)
local Types = require(script.Parent.DomainCapabilityTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	return Serialization.deepCopy({
		providerName = Types.ProviderName,
		domainCapabilityPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
		domainCapabilities = Identity.inspect(),
		interfaceOwnership = InterfaceOwnership.inspect(),
		communicationContracts = Communication.inspect(),
		lifecycleIntegration = LifecycleIntegration.inspect(),
		domainEvidence = Evidence.inspect(),
		domainMetrics = Metrics.inspect(),
		domainProfiler = Profiler.inspect(),
		domainBudgets = Budgets.inspect(),
		domainGovernance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = runtime.getCounters(),
		noConcreteDomainImplementation = true,
		noDirectCapabilityCoupling = true,
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
