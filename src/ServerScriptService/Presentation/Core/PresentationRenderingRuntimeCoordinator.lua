--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimePresentationRenderingCapability)
local SelfChecks = require(script.Parent.RenderingRuntimeSelfChecks)
local Types = require(script.Parent.PresentationTypes)

local Coordinator = {}
local log = Logger.scope("PresentationRenderingRuntime")
local initialized = false
local started = false
local lastSelfChecks: any = nil

function Coordinator.initialize()
	if initialized then
		return
	end
	Diagnostics.registerSampler(Types.RenderingRuntimeProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(Types.RenderingRuntimeProviderName, Coordinator.getSnapshot)
	initialized = true
	log.success("Presentation Rendering Runtime initialized")
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

function Coordinator.registerRenderer(renderer: any)
	return Runtime.registerRenderer(renderer)
end

function Coordinator.intakeRenderingRequest(request: any)
	return Runtime.intakeRenderingRequest(request)
end

function Coordinator.assignRenderer(sessionId: string)
	return Runtime.assignRenderer(sessionId)
end

function Coordinator.transitionLifecycle(sessionId: string, nextState: string)
	return Runtime.transitionLifecycle(sessionId, nextState)
end

function Coordinator.produceAcknowledgement(acknowledgement: any)
	return Runtime.produceAcknowledgement(acknowledgement)
end

function Coordinator.resolveSynchronization(sessionId: string)
	return Runtime.resolveSynchronization(sessionId)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = "PresentationRenderingRuntimeCoordinator"
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
			reason = "Presentation rendering runtime self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
