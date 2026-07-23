--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimePresentationCapability)
local SelfChecks = require(script.Parent.PresentationRuntimeSelfChecks)
local Types = require(script.Parent.PresentationTypes)

local Coordinator = {}
local log = Logger.scope("PresentationRuntimeCapability")
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
	log.success("Presentation Runtime Capability initialized")
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

function Coordinator.registerConsumer(consumer: any)
	return Runtime.registerConsumer(consumer)
end

function Coordinator.createSession(request: any)
	return Runtime.createSession(request)
end

function Coordinator.enqueueSession(sessionId: string)
	return Runtime.enqueueSession(sessionId)
end

function Coordinator.assignSession(sessionId: string)
	return Runtime.assignSession(sessionId)
end

function Coordinator.transitionSession(sessionId: string, state: string)
	return Runtime.transitionSession(sessionId, state)
end

function Coordinator.produceAcknowledgement(request: any)
	return Runtime.produceAcknowledgement(request)
end

function Coordinator.resolveSynchronization(sessionId: string)
	return Runtime.resolveSynchronization(sessionId)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = "PresentationRuntimeCoordinator"
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
			reason = "Presentation runtime self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
