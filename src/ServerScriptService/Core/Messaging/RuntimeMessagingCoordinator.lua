--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeMessagingIntegration)
local SelfChecks = require(script.Parent.MessagingSelfChecks)
local Types = require(script.Parent.MessagingTypes)

local Coordinator = {}
local log = Logger.scope("RuntimeMessagingIntegration")
local COORDINATOR_ID = "RuntimeMessagingCoordinator"
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
	log.success("Runtime Messaging Integration initialized")
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

function Coordinator.registerConsumer(contract: any)
	return Runtime.registerConsumer(contract)
end

function Coordinator.registerSubscription(subscription: any)
	return Runtime.registerSubscription(subscription)
end

function Coordinator.validateDependencies()
	return Runtime.validateDependencies()
end

function Coordinator.initializeConsumers()
	return Runtime.initializeConsumers()
end

function Coordinator.startConsumers()
	return Runtime.startConsumers()
end

function Coordinator.shutdownConsumers()
	return Runtime.shutdownConsumers()
end

function Coordinator.resolveInterface(interfaceId: string)
	return Runtime.resolveInterface(interfaceId)
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
			reason = "Runtime Messaging Integration self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
