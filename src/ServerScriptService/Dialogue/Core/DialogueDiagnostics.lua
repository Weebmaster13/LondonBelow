--!strict

local Budgets = require(script.Parent.DialogueBudgets)
local Certification = require(script.Parent.DialogueCertification)
local ConversationRegistry = require(script.Parent.ConversationRegistry)
local DialogueEvidence = require(script.Parent.DialogueEvidence)
local DialogueRegistry = require(script.Parent.DialogueRegistry)
local Governance = require(script.Parent.DialogueGovernance)
local Metrics = require(script.Parent.DialogueMetrics)
local ParticipantRegistry = require(script.Parent.ParticipantRegistry)
local Profiler = require(script.Parent.DialogueProfiler)
local Serialization = require(script.Parent.DialogueSerialization)
local StateMachine = require(script.Parent.DialogueStateMachine)
local Types = require(script.Parent.DialogueTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	local counters = runtime.getCounters()
	return {
		providerName = Types.ProviderName,
		dialogueCapabilityPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			domainRegistered = counters.domainRegistered,
		},
		registeredDialogues = DialogueRegistry.inspect(),
		activeConversations = ConversationRegistry.inspect(),
		participantRegistry = ParticipantRegistry.inspect(),
		stateMachine = StateMachine.inspect(),
		conditionsEvaluated = counters.conditionsEvaluated,
		nodeTransitions = counters.nodeTransitions,
		dialogueEvidence = DialogueEvidence.inspect(),
		dialogueMetrics = Metrics.inspect(),
		dialogueProfiler = Profiler.inspect(),
		dialogueBudgets = Budgets.inspect(),
		dialogueGovernance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = counters,
		noRendering = true,
		noUiWidgets = true,
		noAnimations = true,
		noVoicePlayback = true,
		noPlayerInput = true,
		noNpcAi = true,
		noInventoryAuthority = true,
		noObjectiveAuthority = true,
		noNetworking = true,
		noPersistence = true,
		noWorkspaceMutation = true,
		noCommandExecution = true,
		noEventPublication = true,
		noQueryExecution = true,
		noClientAuthority = true,
	}
end

function Diagnostics.copy(value: any)
	return Serialization.deepCopy(value)
end

return Diagnostics
