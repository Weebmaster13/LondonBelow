--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimePresentationRenderingContract)
local SelfChecks = require(script.Parent.PresentationRenderingSelfChecks)
local Types = require(script.Parent.PresentationTypes)

local Coordinator = {}
local log = Logger.scope("PresentationRenderingContract")
local initialized = false
local started = false
local lastSelfChecks: any = nil

function Coordinator.initialize()
	if initialized then
		return
	end
	Diagnostics.registerSampler(Types.RenderingContractProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(
		Types.RenderingContractSnapshotProviderName,
		Coordinator.getSnapshot
	)
	initialized = true
	log.success("Presentation Rendering Contract initialized")
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

function Coordinator.registerRendererCapability(capability: any)
	return Runtime.registerRendererCapability(capability)
end

function Coordinator.createRenderingRequest(input: any)
	return Runtime.createRenderingRequest(input)
end

function Coordinator.evaluateRendererCompatibility(requestId: string, rendererCapabilityId: string)
	return Runtime.evaluateRendererCompatibility(requestId, rendererCapabilityId)
end

function Coordinator.acknowledgeRenderingRequest(acknowledgement: any)
	return Runtime.acknowledgeRenderingRequest(acknowledgement)
end

function Coordinator.resolveRenderingSynchronization(requestId: string)
	return Runtime.resolveRenderingSynchronization(requestId)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = "PresentationRenderingCoordinator"
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
			reason = "Presentation rendering contract self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
