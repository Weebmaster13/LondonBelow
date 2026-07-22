--!strict

local Types = require(script.Parent.DialogueTypes)

local StateMachine = {}

local transitions = {
	[Types.ConversationState.Created] = {
		Types.ConversationState.Initialized,
		Types.ConversationState.Closed,
	},
	[Types.ConversationState.Initialized] = {
		Types.ConversationState.Active,
		Types.ConversationState.Closed,
	},
	[Types.ConversationState.Active] = {
		Types.ConversationState.Waiting,
		Types.ConversationState.Transitioning,
		Types.ConversationState.Completed,
		Types.ConversationState.Closed,
	},
	[Types.ConversationState.Waiting] = {
		Types.ConversationState.Transitioning,
		Types.ConversationState.Closed,
	},
	[Types.ConversationState.Transitioning] = {
		Types.ConversationState.Active,
		Types.ConversationState.Waiting,
		Types.ConversationState.Completed,
	},
	[Types.ConversationState.Completed] = { Types.ConversationState.Closed },
	[Types.ConversationState.Closed] = {},
}

function StateMachine.canTransition(fromState: string, toState: string): boolean
	for _, allowed in ipairs(transitions[fromState] or {}) do
		if allowed == toState then
			return true
		end
	end
	return false
end

function StateMachine.transition(registry: any, conversationId: string, toState: string)
	local conversation = registry.get(conversationId)
	if conversation == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownConversation,
			message = "unknown conversation",
		}
	end
	if not StateMachine.canTransition(conversation.state, toState) then
		return {
			ok = false,
			code = Types.FailureType.InvalidLifecycleTransition,
			message = "invalid conversation lifecycle transition",
		}
	end
	return registry.setState(conversationId, toState)
end

function StateMachine.inspect()
	return transitions
end

return StateMachine
