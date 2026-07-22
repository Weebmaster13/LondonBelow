--!strict

local DomainCapabilityTypes =
	require(script.Parent.Parent.Parent.Core.DomainCapabilities.DomainCapabilityTypes)
local RuntimeDomainCapabilityCoordinator =
	require(script.Parent.Parent.Parent.Core.DomainCapabilities.DomainCapabilityCoordinator)

local Choices = require(script.Parent.DialogueChoices)
local Conditions = require(script.Parent.DialogueConditions)
local ConversationRegistry = require(script.Parent.ConversationRegistry)
local Diagnostics = require(script.Parent.DialogueDiagnostics)
local DialogueRegistry = require(script.Parent.DialogueRegistry)
local Evidence = require(script.Parent.DialogueEvidence)
local Metrics = require(script.Parent.DialogueMetrics)
local ParticipantRegistry = require(script.Parent.ParticipantRegistry)
local Profiler = require(script.Parent.DialogueProfiler)
local Serialization = require(script.Parent.DialogueSerialization)
local Snapshots = require(script.Parent.DialogueSnapshots)
local StateMachine = require(script.Parent.DialogueStateMachine)
local Types = require(script.Parent.DialogueTypes)
local Variables = require(script.Parent.DialogueVariables)

local Runtime = {}
local shutdown = false
local counters = {
	domainRegistered = false,
	dialoguesRegistered = 0,
	conversationsCreated = 0,
	participantsRegistered = 0,
	nodeTransitions = 0,
	conditionsEvaluated = 0,
	choicesSelected = 0,
	lastFailure = nil :: any?,
}

local function fail(code: string, message: string, payload: any?)
	counters.lastFailure =
		{ code = code, message = message, payload = Serialization.deepCopy(payload) }
	Evidence.record("dialogue failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

function Runtime.registerDomainCapability()
	local result = RuntimeDomainCapabilityCoordinator.registerDomainCapability({
		capabilityId = Types.CapabilityId,
		domain = DomainCapabilityTypes.Domain.Dialogue,
		version = "1",
		owner = "Dialogue",
		authority = DomainCapabilityTypes.Authority.Server,
		workflowParticipation = DomainCapabilityTypes.WorkflowParticipation.Coordinator,
		interfaces = {
			{
				interfaceId = "dialogue.conversation.contracts",
				version = "1",
				methods = {
					"startConversation",
					"advanceConversation",
					"endConversation",
					"getConversation",
					"getConversationState",
					"getParticipant",
					"evaluateCondition",
				},
			},
		},
		dependencies = {},
		healthProvider = "DialogueCoordinator.inspect",
		diagnosticsProvider = "DialogueCoordinator.inspect",
		snapshotProvider = Types.ProviderName,
		metadata = {
			phase = 172,
			referenceImplementation = true,
		},
	})
	if
		not result.ok
		and result.code ~= DomainCapabilityTypes.FailureType.DuplicateDomainCapability
	then
		return fail(
			Types.FailureType.DomainRegistrationFailed,
			result.message or "domain registration failed",
			result
		)
	end
	counters.domainRegistered = true
	Evidence.record("dialogue domain capability registered", { capabilityId = Types.CapabilityId })
	return { ok = true, code = "Ok" }
end

function Runtime.registerDialogueDefinition(definition: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", definition)
	end
	local result = DialogueRegistry.register(definition)
	if not result.ok then
		return fail(result.code, result.message, definition)
	end
	counters.dialoguesRegistered = DialogueRegistry.count()
	Metrics.set("dialoguesRegistered", DialogueRegistry.count())
	return result
end

function Runtime.registerParticipant(participant: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", participant)
	end
	local result = ParticipantRegistry.register(participant)
	if not result.ok then
		return fail(result.code, result.message, participant)
	end
	counters.participantsRegistered = ParticipantRegistry.count()
	return result
end

function Runtime.createConversation(request: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", request)
	end
	local dialogue = DialogueRegistry.get(request.dialogueId)
	if dialogue ~= nil and request.variables == nil then
		request = Serialization.deepCopy(request)
		request.variables = Variables.defaultVariables(dialogue)
	end
	local result = ConversationRegistry.create(request)
	if not result.ok then
		return fail(result.code, result.message, request)
	end
	counters.conversationsCreated = ConversationRegistry.count()
	Metrics.increment("conversationsCreated")
	return result
end

function Runtime.transitionConversation(conversationId: string, state: string)
	local result = StateMachine.transition(ConversationRegistry, conversationId, state)
	if not result.ok then
		return fail(result.code, result.message, { conversationId = conversationId, state = state })
	end
	if state == Types.ConversationState.Active then
		Metrics.increment("conversationsStarted")
	elseif state == Types.ConversationState.Completed then
		Metrics.increment("conversationsCompleted")
	elseif state == Types.ConversationState.Closed then
		Metrics.increment("conversationsCancelled")
	end
	return result
end

function Runtime.evaluateCondition(conditionId: string, context: any?)
	counters.conditionsEvaluated += 1
	Metrics.increment("conditionEvaluations")
	Profiler.record(conditionId, "conditionEvaluationTime", 0)
	return Conditions.evaluateMetadataOnly(conditionId, context)
end

function Runtime.recordChoice(conversationId: string, choiceId: string)
	counters.choicesSelected += 1
	Metrics.increment("choicesSelected")
	return Choices.recordSelection(conversationId, choiceId)
end

function Runtime.getDialogue(dialogueId: string)
	return DialogueRegistry.get(dialogueId)
end

function Runtime.getConversation(conversationId: string)
	return ConversationRegistry.get(conversationId)
end

function Runtime.getParticipant(participantId: string)
	return ParticipantRegistry.get(participantId)
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return Snapshots.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return true, nil
end

function Runtime.shutdown()
	shutdown = true
end

function Runtime.reset()
	shutdown = false
	for key in pairs(counters) do
		if key == "lastFailure" then
			counters[key] = nil
		elseif key == "domainRegistered" then
			counters[key] = false
		else
			counters[key] = 0
		end
	end
	DialogueRegistry.clear()
	ConversationRegistry.clear()
	ParticipantRegistry.clear()
	Evidence.clear()
	Metrics.clear()
	Profiler.clear()
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

Runtime.reset()

return Runtime
