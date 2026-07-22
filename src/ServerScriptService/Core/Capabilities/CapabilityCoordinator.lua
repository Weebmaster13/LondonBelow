--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeCapabilityFramework)
local SelfChecks = require(script.Parent.CapabilitySelfChecks)
local Types = require(script.Parent.CapabilityTypes)

local Coordinator = {}
local log = Logger.scope("RuntimeCapabilityFramework")
local COORDINATOR_ID = "RuntimeCapabilityCoordinator"
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
	log.success("Runtime Capability Framework initialized")
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

function Coordinator.registerCapability(definition: any)
	return Runtime.registerCapability(definition)
end

function Coordinator.validateCapability(capabilityId: string)
	return Runtime.validateCapability(capabilityId)
end

function Coordinator.initializeCapability(capabilityId: string)
	return Runtime.initializeCapability(capabilityId)
end

function Coordinator.markReady(capabilityId: string)
	return Runtime.markReady(capabilityId)
end

function Coordinator.activateCapability(capabilityId: string)
	return Runtime.activateCapability(capabilityId)
end

function Coordinator.suspendCapability(capabilityId: string, reason: string)
	return Runtime.suspendCapability(capabilityId, reason)
end

function Coordinator.recoverCapability(capabilityId: string)
	return Runtime.recoverCapability(capabilityId)
end

function Coordinator.shutdownCapability(capabilityId: string)
	return Runtime.shutdownCapability(capabilityId)
end

function Coordinator.resolveInterface(interfaceId: string, version: string, owner: string?)
	return Runtime.resolveInterface(interfaceId, version, owner)
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
		lastSelfChecks =
			{ ok = false, reason = "Runtime Capability self-checks require a stopped runtime." }
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
