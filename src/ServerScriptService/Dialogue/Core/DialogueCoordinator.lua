--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Runtime = require(script.Parent.RuntimeDialogueCapability)
local SelfChecks = require(script.Parent.DialogueSelfChecks)
local Types = require(script.Parent.DialogueTypes)

local Coordinator = {}
local log = Logger.scope("DialogueRuntimeCapability")
local initialized = false
local started = false
local lastSelfChecks: any = nil

function Coordinator.initialize()
	if initialized then
		return
	end
	local registered = Runtime.registerDomainCapability()
	if not registered.ok then
		error("Dialogue domain capability registration failed: " .. tostring(registered.message), 0)
	end
	Diagnostics.registerSampler(Types.ProviderName, Coordinator.inspect)
	SnapshotManager.registerProvider(Types.ProviderName, Coordinator.getSnapshot)
	initialized = true
	log.success("Dialogue Runtime Capability initialized")
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

function Coordinator.registerDialogueDefinition(definition: any)
	return Runtime.registerDialogueDefinition(definition)
end

function Coordinator.registerParticipant(participant: any)
	return Runtime.registerParticipant(participant)
end

function Coordinator.createConversation(request: any)
	return Runtime.createConversation(request)
end

function Coordinator.transitionConversation(conversationId: string, state: string)
	return Runtime.transitionConversation(conversationId, state)
end

function Coordinator.evaluateCondition(conditionId: string, context: any?)
	return Runtime.evaluateCondition(conditionId, context)
end

function Coordinator.getConversation(conversationId: string)
	return Runtime.getConversation(conversationId)
end

function Coordinator.getConversationState(conversationId: string)
	local conversation = Runtime.getConversation(conversationId)
	return if conversation then conversation.state else nil
end

function Coordinator.getParticipant(participantId: string)
	return Runtime.getParticipant(participantId)
end

function Coordinator.inspect()
	local diagnostics = Runtime.inspect()
	diagnostics.coordinatorId = "DialogueCoordinator"
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
			reason = "Dialogue self-checks require a stopped runtime.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run()
	return lastSelfChecks
end

return Coordinator
