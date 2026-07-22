--!strict

local ConversationEngine = require(script.Parent.ConversationExecutionEngine)
local DialogueCoordinator = require(script.Parent.DialogueCoordinator)
local Diagnostics = require(script.Parent.ExecutionDiagnostics)
local Evidence = require(script.Parent.ExecutionEvidence)
local Memory = require(script.Parent.RuntimeConversationMemory)
local Metrics = require(script.Parent.ExecutionMetrics)
local Profiler = require(script.Parent.ExecutionProfiler)
local Scheduler = require(script.Parent.DialogueScheduler)
local Serialization = require(script.Parent.DialogueSerialization)
local Snapshots = require(script.Parent.ExecutionSnapshots)
local Types = require(script.Parent.DialogueExecutionTypes)
local Validation = require(script.Parent.ExecutionValidation)

local Runtime = {}
local shutdown = false
local counters = {
	executionsStarted = 0,
	executionsCompleted = 0,
	executionsRecovered = 0,
	nodeTransitions = 0,
	activeConditions = 0,
	pendingChoices = 0,
	runtimeVariables = 0,
	lifecycle = "Stopped",
	lastFailure = nil :: any?,
}

local function fail(code: string, message: string, payload: any?)
	counters.lastFailure =
		{ code = code, message = message, payload = Serialization.deepCopy(payload) }
	Evidence.record("execution failure", counters.lastFailure)
	return { ok = false, code = code, message = message }
end

local function buildContext(request: any, conversation: any)
	return {
		executionId = request.executionId,
		conversationId = conversation.conversationId,
		dialogueId = conversation.dialogueId,
		currentNodeId = conversation.currentNodeId,
		previousNodeId = nil,
		variables = Serialization.deepCopy(conversation.currentVariables),
		participants = Serialization.deepCopy(conversation.participants),
		workflowReference = Serialization.deepCopy(request.workflowReference or {}),
		executionState = Types.ExecutionState.Initializing,
		runtimeMetadata = Serialization.deepCopy(request.runtimeMetadata or {}),
	}
end

function Runtime.startExecution(request: any)
	if shutdown then
		return fail(Types.FailureType.RuntimeShutdown, "runtime is shut down", request)
	end
	if
		type(request) ~= "table"
		or type(request.executionId) ~= "string"
		or type(request.conversationId) ~= "string"
	then
		return fail(Types.FailureType.ValidationFailure, "invalid execution request", request)
	end
	local conversation = DialogueCoordinator.getConversation(request.conversationId)
	if conversation == nil then
		return fail(Types.FailureType.UnknownConversation, "unknown conversation", request)
	end
	local dialogue = DialogueCoordinator.getDialogue(conversation.dialogueId)
	if dialogue == nil then
		return fail(Types.FailureType.UnknownDialogue, "unknown dialogue", request)
	end
	local context = buildContext(request, conversation)
	local validation = Validation.validateContext(context)
	if not validation.ok then
		return fail(validation.code, validation.message, request)
	end
	Scheduler.enqueue(request.executionId)
	local result = ConversationEngine.start(context, dialogue)
	if not result.ok then
		return fail(result.code, result.message, request)
	end
	counters.executionsStarted += 1
	counters.lifecycle = "Running"
	Metrics.set("activeConversations", Memory.countActive())
	return result
end

function Runtime.selectChoice(executionId: string, choiceId: string)
	local context = Memory.get(executionId)
	if context == nil then
		return fail(
			Types.FailureType.UnknownExecution,
			"unknown execution",
			{ executionId = executionId }
		)
	end
	local dialogue = DialogueCoordinator.getDialogue(context.dialogueId)
	if dialogue == nil then
		return fail(Types.FailureType.UnknownDialogue, "unknown dialogue", context)
	end
	local result = ConversationEngine.selectChoice(executionId, dialogue, choiceId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId, choiceId = choiceId })
	end
	counters.pendingChoices = 0
	Metrics.set("activeConversations", Memory.countActive())
	return result
end

function Runtime.recoverExecution(executionId: string)
	local result = ConversationEngine.recover(executionId)
	if not result.ok then
		return fail(result.code, result.message, { executionId = executionId })
	end
	counters.executionsRecovered += 1
	return result
end

function Runtime.suspendExecution(executionId: string, reason: string)
	return Scheduler.suspend(executionId, reason)
end

function Runtime.resumeExecution(executionId: string)
	return Scheduler.resume(executionId)
end

function Runtime.inspect()
	return Diagnostics.capture(Runtime)
end

function Runtime.getSnapshot()
	return Snapshots.capture(Runtime)
end

function Runtime.validate(): (boolean, string?)
	return Validation.validateRuntime()
end

function Runtime.shutdown()
	shutdown = true
	counters.lifecycle = "Shutdown"
end

function Runtime.reset()
	shutdown = false
	for key in pairs(counters) do
		if key == "lastFailure" then
			counters[key] = nil
		elseif key == "lifecycle" then
			counters[key] = "Stopped"
		else
			counters[key] = 0
		end
	end
	Evidence.clear()
	Memory.clear()
	Metrics.clear()
	Profiler.clear()
	Scheduler.clear()
end

function Runtime.getCounters()
	return Serialization.deepCopy(counters)
end

Runtime.reset()

return Runtime
