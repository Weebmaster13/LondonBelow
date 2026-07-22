--!strict

local CapabilityFramework = require(script.Parent.Parent.Capabilities.CapabilityCoordinator)
local CapabilityTypes = require(script.Parent.Parent.Capabilities.CapabilityTypes)
local Communication = require(script.Parent.CapabilityCommunicationContracts)
local Diagnostics = require(script.Parent.DomainDiagnostics)
local Evidence = require(script.Parent.DomainEvidence)
local Identity = require(script.Parent.DomainIdentityRegistry)
local InterfaceOwnership = require(script.Parent.InterfaceOwnershipRegistry)
local LifecycleIntegration = require(script.Parent.DomainLifecycleIntegration)
local Metrics = require(script.Parent.DomainMetrics)
local Profiler = require(script.Parent.DomainProfiler)
local Serialization = require(script.Parent.DomainSerialization)
local Snapshots = require(script.Parent.DomainSnapshots)
local Types = require(script.Parent.DomainCapabilityTypes)

local Runtime = {}
local shutdown = false
local counters = {
	registeredDomainCapabilities = 0,
	frameworkRegistrations = 0,
	interfaceContracts = 0,
	communicationContracts = 0,
	lifecycleIntegrations = 0,
	lastFailure = nil :: any?,
}

Runtime.Responsibilities = {
	"domain capability contracts",
	"capability identity",
	"domain boundaries",
	"service contracts",
	"interface ownership",
	"communication contracts",
	"capability framework registration",
}

local function failure(code: string, message: string, payload: any?)
	counters.lastFailure =
		{ code = code, message = message, payload = Serialization.deepCopy(payload) }
	Evidence.record("domain capability failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

local function toCapabilityDefinition(definition: any): any
	return {
		capabilityId = definition.capabilityId,
		version = definition.version,
		owner = definition.owner,
		category = CapabilityTypes.Category.Gameplay,
		authority = definition.authority,
		interfaces = Serialization.copyArray(definition.interfaces),
		dependencies = Serialization.copyArray(definition.dependencies),
		healthProvider = definition.healthProvider,
		diagnosticsProvider = definition.diagnosticsProvider,
		snapshotProvider = definition.snapshotProvider,
		metadata = {
			domain = definition.domain,
			workflowParticipation = definition.workflowParticipation,
			foundationProvider = Types.ProviderName,
		},
	}
end

local function registerSelf()
	Runtime.registerDomainCapability({
		capabilityId = Types.ProviderName .. ".self",
		domain = Types.Domain.WorldSimulation,
		version = "1",
		owner = "Core",
		authority = Types.Authority.Core,
		workflowParticipation = Types.WorkflowParticipation.Observer,
		interfaces = {
			{
				interfaceId = "runtime.domainCapability.contracts",
				version = "1",
				methods = { "registerDomainCapability", "inspect" },
			},
		},
		dependencies = {},
		healthProvider = "RuntimeDomainCapabilityCoordinator.inspect",
		diagnosticsProvider = "RuntimeDomainCapabilityCoordinator.inspect",
		snapshotProvider = Types.ProviderName,
		metadata = { foundationPhase = 171 },
	})
end

function Runtime.registerDomainCapability(definition: any)
	if shutdown then
		return failure(Types.FailureType.RuntimeShutdown, "runtime is shut down", definition)
	end
	local canRegister = Identity.canRegister(definition)
	if not canRegister.ok then
		return failure(canRegister.code, canRegister.message, definition)
	end
	local framework = CapabilityFramework.registerCapability(toCapabilityDefinition(definition))
	if not framework.ok then
		return failure(Types.FailureType.CapabilityFrameworkRejected, framework.message, definition)
	end
	local registered = Identity.register(definition)
	if not registered.ok then
		return failure(registered.code, registered.message, definition)
	end
	local interfaces = InterfaceOwnership.registerCapabilityInterfaces(definition.capabilityId)
	if not interfaces.ok then
		return failure(Types.FailureType.InvalidInterface, interfaces.message, definition)
	end
	Communication.record(definition.capabilityId, definition.workflowParticipation)
	LifecycleIntegration.record(definition.capabilityId, "Registered")
	counters.registeredDomainCapabilities = Identity.count()
	counters.frameworkRegistrations += 1
	counters.interfaceContracts += #definition.interfaces
	counters.communicationContracts += 1
	counters.lifecycleIntegrations += 1
	Metrics.set("registeredDomains", Identity.count())
	Evidence.record("domain capability registered with framework", {
		capabilityId = definition.capabilityId,
		domain = definition.domain,
	})
	return { ok = true, code = "Ok", capabilityId = definition.capabilityId }
end

function Runtime.validateDomainCapability(capabilityId: string)
	local definition = Identity.get(capabilityId)
	if definition == nil then
		return failure(Types.FailureType.UnknownDomainCapability, "unknown domain capability", {
			capabilityId = capabilityId,
		})
	end
	local result = CapabilityFramework.validateCapability(capabilityId)
	if not result.ok then
		Metrics.increment("dependencyFailures")
		return failure(Types.FailureType.CapabilityFrameworkRejected, result.message, {
			capabilityId = capabilityId,
		})
	end
	LifecycleIntegration.record(capabilityId, "Validated")
	return result
end

function Runtime.initializeDomainCapability(capabilityId: string)
	local result = CapabilityFramework.initializeCapability(capabilityId)
	if result.ok then
		Metrics.increment("initializationCount")
		Profiler.record(capabilityId, "initializationDuration", 0)
		LifecycleIntegration.record(capabilityId, "Initialized")
	end
	return result
end

function Runtime.markDomainReady(capabilityId: string)
	local result = CapabilityFramework.markReady(capabilityId)
	if result.ok then
		LifecycleIntegration.record(capabilityId, "Ready")
	end
	return result
end

function Runtime.activateDomainCapability(capabilityId: string)
	local result = CapabilityFramework.activateCapability(capabilityId)
	if result.ok then
		Metrics.increment("activationCount")
		Profiler.record(capabilityId, "activationLatency", 0)
		LifecycleIntegration.record(capabilityId, "Running")
	end
	return result
end

function Runtime.suspendDomainCapability(capabilityId: string, reason: string)
	local result = CapabilityFramework.suspendCapability(capabilityId, reason)
	if result.ok then
		Metrics.increment("suspensionCount")
		LifecycleIntegration.record(capabilityId, "Suspended")
	end
	return result
end

function Runtime.recoverDomainCapability(capabilityId: string)
	local result = CapabilityFramework.recoverCapability(capabilityId)
	if result.ok then
		Metrics.increment("recoveryCount")
		LifecycleIntegration.record(capabilityId, "Ready")
	end
	return result
end

function Runtime.resolveDomainInterface(interfaceId: string, version: string, owner: string?)
	local result = CapabilityFramework.resolveInterface(interfaceId, version, owner)
	if result.ok then
		Metrics.increment("interfaceResolutions")
		Profiler.record(interfaceId, "interfaceResolutionTime", 0)
	end
	return result
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return Snapshots.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return true, nil
end

function Runtime.shutdown()
	shutdown = true
end

function Runtime.reset()
	shutdown = false
	for key in pairs(counters) do
		if key == "lastFailure" then
			counters[key] = nil
		else
			counters[key] = 0
		end
	end
	Identity.clear()
	InterfaceOwnership.clear()
	Communication.clear()
	LifecycleIntegration.clear()
	Evidence.clear()
	Metrics.clear()
	Profiler.clear()
	registerSelf()
end

function Runtime.isShutdown(): boolean
	return shutdown
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

Runtime.reset()

return Runtime
