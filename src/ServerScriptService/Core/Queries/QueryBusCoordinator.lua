--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeQueryBus)
local SelfChecks = require(script.Parent.QuerySelfChecks)
local Types = require(script.Parent.QueryTypes)

local Coordinator = {}
local log = Logger.scope("RuntimeQueryBus")
local COORDINATOR_ID = "QueryBusCoordinator"
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
	log.success("Runtime Query Bus initialized")
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

function Coordinator.registerQueryType(definition: any)
	return Runtime.registerQueryType(definition)
end

function Coordinator.registerRequester(requester: any)
	return Runtime.registerRequester(requester)
end

function Coordinator.registerHandler(handler: any)
	return Runtime.registerHandler(handler)
end

function Coordinator.query(request: any)
	return Runtime.query(request)
end

function Coordinator.queryBatch(requests: { any })
	return Runtime.queryBatch(requests)
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
			{ ok = false, reason = "Runtime Query Bus self-checks require a stopped runtime." }
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
