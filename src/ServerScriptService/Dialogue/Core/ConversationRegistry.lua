--!strict

local DialogueRegistry = require(script.Parent.DialogueRegistry)
local Evidence = require(script.Parent.DialogueEvidence)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueTypes)

local ConversationRegistry = {}
local conversations = {}
local order = {}
local nextOrdinal = 0

function ConversationRegistry.create(request: any)
	if #order >= Types.Limits.MaxConversationInstances then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "conversation limit exceeded",
		}
	end
	if type(request) ~= "table" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "conversation request must be a table",
		}
	end
	if type(request.conversationId) ~= "string" or request.conversationId == "" then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "invalid conversationId",
		}
	end
	if type(request.dialogueId) ~= "string" or DialogueRegistry.get(request.dialogueId) == nil then
		return { ok = false, code = Types.FailureType.UnknownDialogue, message = "unknown dialogue" }
	end
	if conversations[request.conversationId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateConversation,
			message = "duplicate conversation",
		}
	end
	local definition = DialogueRegistry.get(request.dialogueId)
	nextOrdinal += 1
	local conversation = {
		conversationId = request.conversationId,
		dialogueId = request.dialogueId,
		participants = Serialization.deepCopy(request.participants or {}),
		currentNodeId = definition.entryNodeId,
		currentVariables = Serialization.deepCopy(request.variables or {}),
		state = Types.ConversationState.Created,
		startedTime = nextOrdinal,
		updatedTime = nextOrdinal,
	}
	conversations[request.conversationId] = conversation
	order[#order + 1] = request.conversationId
	Evidence.record("conversation created", {
		conversationId = request.conversationId,
		dialogueId = request.dialogueId,
	})
	return { ok = true, code = "Ok", conversation = Serialization.deepCopy(conversation) }
end

function ConversationRegistry.setState(conversationId: string, state: string)
	local conversation = conversations[conversationId]
	if conversation == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownConversation,
			message = "unknown conversation",
		}
	end
	nextOrdinal += 1
	conversation.state = state
	conversation.updatedTime = nextOrdinal
	Evidence.record(
		"conversation state changed",
		{ conversationId = conversationId, state = state }
	)
	return { ok = true, code = "Ok", conversation = Serialization.deepCopy(conversation) }
end

function ConversationRegistry.get(conversationId: string): any?
	local conversation = conversations[conversationId]
	if conversation == nil then
		return nil
	end
	return Serialization.deepCopy(conversation)
end

function ConversationRegistry.inspect()
	local items = {}
	for index, conversationId in ipairs(order) do
		items[index] = Serialization.deepCopy(conversations[conversationId])
	end
	return items
end

function ConversationRegistry.count(): number
	return #order
end

function ConversationRegistry.clear()
	table.clear(conversations)
	table.clear(order)
	nextOrdinal = 0
end

return ConversationRegistry
