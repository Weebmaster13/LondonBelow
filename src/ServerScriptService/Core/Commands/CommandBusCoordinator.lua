--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeCommandBus)
local SelfChecks = require(script.Parent.CommandSelfChecks)
local Types = require(script.Parent.CommandTypes)

local Coordinator = {}
local log = Logger.scope("RuntimeCommandBus")
local COORDINATOR_ID = "CommandBusCoordinator"
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
	log.success("Runtime Command Bus initialized")
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

function Coordinator.registerCommandType(definition: any)
	return Runtime.registerCommandType(definition)
end

function Coordinator.registerRequester(requester: any)
	return Runtime.registerRequester(requester)
end

function Coordinator.registerHandler(handler: any)
	return Runtime.registerHandler(handler)
end

function Coordinator.submit(request: any)
	return Runtime.submit(request)
end

function Coordinator.submitBatch(requests: { any })
	return Runtime.submitBatch(requests)
end

function Coordinator.cancel(commandId: string)
	return Runtime.cancel(commandId)
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
			{ ok = false, reason = "Runtime Command Bus self-checks require a stopped runtime." }
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
