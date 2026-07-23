--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeDialoguePresentationContract)
local SelfChecks = require(script.Parent.DialoguePresentationSelfChecks)
local Types = require(script.Parent.DialoguePresentationTypes)

local Coordinator = {}
local log = Logger.scope("DialogueRuntimePresentationContract")
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
	log.success("Dialogue Runtime Presentation Contract initialized")
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

function Coordinator.createPresentationRequest(input: any)
	return Runtime.createPresentationRequest(input)
end

function Coordinator.getPresentationRequest(presentationId: string)
	return Runtime.getPresentationRequest(presentationId)
end

function Coordinator.inspectPresentationRequests()
	return Runtime.inspectPresentationRequests()
end

function Coordinator.acknowledgePresentation(acknowledgement: any)
	return Runtime.acknowledgePresentation(acknowledgement)
end

function Coordinator.getPresentationAcknowledgement(acknowledgementId: string)
	return Runtime.getPresentationAcknowledgement(acknowledgementId)
end

function Coordinator.resolveSynchronizationState(presentationId: string)
	return Runtime.resolveSynchronizationState(presentationId)
end

function Coordinator.getLocalizationReferences(presentationId: string)
	return Runtime.getLocalizationReferences(presentationId)
end

function Coordinator.getAccessibilityMetadata(presentationId: string)
	return Runtime.getAccessibilityMetadata(presentationId)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = "DialoguePresentationCoordinator"
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
			reason = "Dialogue presentation self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
