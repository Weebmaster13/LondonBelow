--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeDomainCapabilityFoundation)
local SelfChecks = require(script.Parent.DomainSelfChecks)
local Types = require(script.Parent.DomainCapabilityTypes)

local Coordinator = {}
local log = Logger.scope("RuntimeDomainCapabilityFoundation")
local COORDINATOR_ID = "RuntimeDomainCapabilityCoordinator"
local initialized = false
local started = false
local lastSelfChecks: any = nil

function Coordinator.initialize()
	if initialized then
		return
	end
	Diagnostics.registerSampler(Types.ProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(Types.ProviderName, Coordinator.getSnapshot)
	initialized = true
	log.success("Runtime Domain Capability Foundation initialized")
end

function Coordinator.start()
	if not initialized then
		Coordinator.initialize()
	end
	started = true
end

function Coordinator.shutdown()
	Runtime.shutdown()
	started = false
	initialized = false
end

function Coordinator.registerDomainCapability(definition: any)
	return Runtime.registerDomainCapability(definition)
end

function Coordinator.validateDomainCapability(capabilityId: string)
	return Runtime.validateDomainCapability(capabilityId)
end

function Coordinator.initializeDomainCapability(capabilityId: string)
	return Runtime.initializeDomainCapability(capabilityId)
end

function Coordinator.markDomainReady(capabilityId: string)
	return Runtime.markDomainReady(capabilityId)
end

function Coordinator.activateDomainCapability(capabilityId: string)
	return Runtime.activateDomainCapability(capabilityId)
end

function Coordinator.suspendDomainCapability(capabilityId: string, reason: string)
	return Runtime.suspendDomainCapability(capabilityId, reason)
end

function Coordinator.recoverDomainCapability(capabilityId: string)
	return Runtime.recoverDomainCapability(capabilityId)
end

function Coordinator.resolveDomainInterface(interfaceId: string, version: string, owner: string?)
	return Runtime.resolveDomainInterface(interfaceId, version, owner)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = COORDINATOR_ID
	diagnostics.initialized = initialized
	diagnostics.started = started
	diagnostics.lastSelfChecks = lastSelfChecks
	return diagnostics
end

function Coordinator.getSnapshot()
	return Runtime.getSnapshot()
end

function Coordinator.validate(): (boolean, string?)
	return Runtime.validate()
end

function Coordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Runtime Domain Capability self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
