--!strict

local Budgets = require(script.Parent.InteractionBudgets)
local Certification = require(script.Parent.InteractionCertification)
local Evidence = require(script.Parent.InteractionEvidence)
local Governance = require(script.Parent.InteractionGovernance)
local Interruption = require(script.Parent.DialogueInterruptionManager)
local Metrics = require(script.Parent.InteractionMetrics)
local Nested = require(script.Parent.NestedConversationManager)
local PendingQueue = require(script.Parent.PendingChoiceQueue)
local Profiler = require(script.Parent.InteractionProfiler)
local Registry = require(script.Parent.InteractionSessionRegistry)
local RuntimeEvents = require(script.Parent.RuntimeEventCoordinator)
local Serialization = require(script.Parent.DialogueSerialization)
local TimeoutManager = require(script.Parent.InteractionTimeoutManager)
local Types = require(script.Parent.DialogueInteractionTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	local counters = runtime.getCounters()
	return {
		providerName = Types.ProviderName,
		dialogueInteractionPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			deterministicOrdering = true,
		},
		pendingInteractions = Registry.inspect(),
		activeWaits = PendingQueue.inspect(),
		interruptions = Interruption.inspect(),
		nestedConversations = Nested.inspect(),
		priorities = PendingQueue.inspect(),
		timeoutState = TimeoutManager.inspect(),
		runtimeQueue = RuntimeEvents.inspect(),
		coordinationStatus = counters.coordinationStatus,
		interactionEvidence = Evidence.inspect(),
		interactionMetrics = Metrics.inspect(),
		interactionProfiler = Profiler.inspect(),
		interactionBudgets = Budgets.inspect(),
		interactionGovernance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = counters,
		noUi = true,
		noRendering = true,
		noVoice = true,
		noSubtitles = true,
		noNetworking = true,
		noRemoteEvents = true,
		noRemoteFunctions = true,
		noPersistence = true,
		noSaveSerialization = true,
		noNpcBehavior = true,
		noGameplayExecution = true,
		noAnimation = true,
		noWorkspaceMutation = true,
		noClientAuthority = true,
	}
end

function Diagnostics.copy(value: any)
	return Serialization.deepCopy(value)
end

return Diagnostics
