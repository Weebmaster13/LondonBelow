--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeEventBus)
local SelfChecks = require(script.Parent.EventSelfChecks)
local Types = require(script.Parent.EventTypes)

local Coordinator = {}
local log = Logger.scope("RuntimeEventBus")
local COORDINATOR_ID = "EventBusCoordinator"
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
	log.success("Runtime Event Bus initialized")
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

function Coordinator.registerEventType(definition: any)
	return Runtime.registerEventType(definition)
end

function Coordinator.registerPublisher(publisher: any)
	return Runtime.registerPublisher(publisher)
end

function Coordinator.subscribe(subscription: any)
	return Runtime.subscribe(subscription)
end

function Coordinator.unsubscribe(subscriptionId: string)
	return Runtime.unsubscribe(subscriptionId)
end

function Coordinator.publish(request: any)
	return Runtime.publish(request)
end

function Coordinator.publishBatch(requests: { any })
	return Runtime.publishBatch(requests)
end

function Coordinator.cancel(eventId: string)
	return Runtime.cancel(eventId)
end

function Coordinator.dispatchNext()
	return Runtime.dispatchNext()
end

function Coordinator.dispatchAll()
	return Runtime.dispatchAll()
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
			{ ok = false, reason = "Runtime Event Bus self-checks require a stopped runtime." }
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
