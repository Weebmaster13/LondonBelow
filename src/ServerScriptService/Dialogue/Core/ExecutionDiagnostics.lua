--!strict

local Budgets = require(script.Parent.ExecutionBudgets)
local Certification = require(script.Parent.ExecutionCertification)
local Evidence = require(script.Parent.ExecutionEvidence)
local Governance = require(script.Parent.ExecutionGovernance)
local Memory = require(script.Parent.RuntimeConversationMemory)
local Metrics = require(script.Parent.ExecutionMetrics)
local Profiler = require(script.Parent.ExecutionProfiler)
local Scheduler = require(script.Parent.DialogueScheduler)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueExecutionTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	local counters = runtime.getCounters()
	return {
		providerName = Types.ProviderName,
		dialogueExecutionPosture = {
			health = "Healthy",
			status = "ProductionCandidate",
			serverAuthoritative = true,
			deterministicExecution = true,
		},
		executingConversations = Memory.inspect(),
		schedulerState = Scheduler.inspect(),
		executionQueue = Scheduler.inspect().activeQueue,
		runtimeVariables = counters.runtimeVariables,
		nodeTransitions = counters.nodeTransitions,
		activeConditions = counters.activeConditions,
		pendingChoices = counters.pendingChoices,
		lifecycle = counters.lifecycle,
		executionEvidence = Evidence.inspect(),
		executionMetrics = Metrics.inspect(),
		executionProfiler = Profiler.inspect(),
		executionBudgets = Budgets.inspect(),
		executionGovernance = Governance.inspect(),
		certification = Certification.inspect(),
		counters = counters,
		noGameplayExecution = true,
		noRendering = true,
		noUi = true,
		noNpcBehavior = true,
		noAiDecisions = true,
		noInventoryAuthority = true,
		noObjectiveAuthority = true,
		noSaveSerialization = true,
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
