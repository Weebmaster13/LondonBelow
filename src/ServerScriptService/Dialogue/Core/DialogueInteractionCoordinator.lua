--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeDialogueInteraction)
local SelfChecks = require(script.Parent.DialogueInteractionSelfChecks)
local Types = require(script.Parent.DialogueInteractionTypes)

local Coordinator = {}
local log = Logger.scope("DialogueRuntimeInteraction")
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
	log.success("Dialogue Runtime Interaction initialized")
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

function Coordinator.requestInteraction(request: any)
	return Runtime.requestInteraction(request)
end

function Coordinator.submitResponse(interactionId: string, response: any)
	return Runtime.submitResponse(interactionId, response)
end

function Coordinator.cancelInteraction(interactionId: string, reason: string)
	return Runtime.cancelInteraction(interactionId, reason)
end

function Coordinator.expireInteraction(interactionId: string, reason: string)
	return Runtime.expireInteraction(interactionId, reason)
end

function Coordinator.interruptExecution(executionId: string, reason: string, priority: number)
	return Runtime.interruptExecution(executionId, reason, priority)
end

function Coordinator.resumeExecution(executionId: string)
	return Runtime.resumeExecution(executionId)
end

function Coordinator.enterNestedConversation(
	parentExecutionId: string,
	childExecutionId: string,
	returnTarget: string,
	depth: number
)
	return Runtime.enterNestedConversation(parentExecutionId, childExecutionId, returnTarget, depth)
end

function Coordinator.exitNestedConversation(childExecutionId: string)
	return Runtime.exitNestedConversation(childExecutionId)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = "DialogueInteractionCoordinator"
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
			reason = "Dialogue interaction self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
