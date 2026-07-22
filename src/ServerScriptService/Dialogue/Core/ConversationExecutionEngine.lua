--!strict

local ChoiceExecution = require(script.Parent.ChoiceExecutionEngine)
local ConditionExecution = require(script.Parent.ConditionExecutionEngine)
local Evidence = require(script.Parent.ExecutionEvidence)
local Memory = require(script.Parent.RuntimeConversationMemory)
local NodeTraversal = require(script.Parent.NodeTraversalEngine)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueExecutionTypes)
local VariableStore = require(script.Parent.RuntimeVariableStore)

local Engine = {}

local function findCondition(dialogue: any, conditionId: string)
	for _, condition in ipairs(dialogue.conditions or {}) do
		if condition.conditionId == conditionId then
			return condition
		end
	end
	return nil
end

local function updateState(executionId: string, state: string)
	return Memory.update(executionId, { executionState = state })
end

function Engine.start(context: any, dialogue: any)
	local variableResult = VariableStore.initialize(context.executionId, context.variables or {})
	if not variableResult.ok then
		return variableResult
	end
	local created = Memory.create(context)
	if not created.ok then
		return created
	end
	Evidence.record("execution start", {
		executionId = context.executionId,
		conversationId = context.conversationId,
		dialogueId = context.dialogueId,
	})
	return Engine.executeCurrentNode(context.executionId, dialogue)
end

function Engine.executeCurrentNode(executionId: string, dialogue: any)
	local context = Memory.get(executionId)
	if context == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	local node = NodeTraversal.getNode(dialogue, context.currentNodeId)
	if node == nil then
		return { ok = false, code = Types.FailureType.UnknownNode, message = "unknown current node" }
	end
	updateState(executionId, Types.ExecutionState.Executing)
	NodeTraversal.enterNode(executionId, node)
	Memory.addHistory(
		executionId,
		{ action = "enter", nodeId = node.nodeId, nodeType = node.nodeType }
	)
	if node.nodeType == "End" then
		updateState(executionId, Types.ExecutionState.Completing)
		Evidence.record("execution completed", { executionId = executionId })
		return updateState(executionId, Types.ExecutionState.Closed)
	end
	if node.nodeType == "Choice" then
		return updateState(executionId, Types.ExecutionState.WaitingChoice)
	end
	if node.nodeType == "Condition" then
		updateState(executionId, Types.ExecutionState.WaitingCondition)
		for _, conditionId in ipairs(node.metadata.conditionIds or {}) do
			local condition = findCondition(dialogue, conditionId)
			if condition ~= nil then
				ConditionExecution.evaluate(
					condition,
					VariableStore.clone(executionId),
					context.workflowReference
				)
			end
		end
	end
	if node.nodeType == "VariableAssignment" then
		for variableId, value in pairs(node.metadata.assignments or {}) do
			VariableStore.write(executionId, variableId, value, node.nodeId)
		end
	end
	local destination = node.nextNodeIds[1]
	if destination == nil then
		NodeTraversal.exitNode(executionId, node)
		return updateState(executionId, Types.ExecutionState.WaitingChoice)
	end
	return Engine.transitionTo(executionId, dialogue, destination)
end

function Engine.selectChoice(executionId: string, dialogue: any, choiceId: string)
	local context = Memory.get(executionId)
	if context == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	if context.executionState ~= Types.ExecutionState.WaitingChoice then
		return {
			ok = false,
			code = Types.FailureType.InvalidExecutionState,
			message = "execution is not waiting for a choice",
		}
	end
	local node = NodeTraversal.getNode(dialogue, context.currentNodeId)
	local choice = ChoiceExecution.resolve(node, choiceId)
	if not choice.ok then
		return choice
	end
	return Engine.transitionTo(executionId, dialogue, choice.choice.destinationNodeId)
end

function Engine.transitionTo(executionId: string, dialogue: any, destinationNodeId: string)
	local context = Memory.get(executionId)
	if context == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	local destination = NodeTraversal.validateDestination(dialogue, destinationNodeId)
	if not destination.ok then
		return destination
	end
	local fromNodeId = context.currentNodeId
	updateState(executionId, Types.ExecutionState.Transitioning)
	NodeTraversal.transition(executionId, fromNodeId, destinationNodeId)
	Memory.addHistory(executionId, {
		action = "transition",
		fromNodeId = fromNodeId,
		toNodeId = destinationNodeId,
	})
	Memory.update(executionId, {
		previousNodeId = fromNodeId,
		currentNodeId = destinationNodeId,
		variables = VariableStore.clone(executionId),
	})
	return Engine.executeCurrentNode(executionId, dialogue)
end

function Engine.recover(executionId: string)
	local context = Memory.get(executionId)
	if context == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownExecution,
			message = "unknown execution",
		}
	end
	Evidence.record("execution recovery", {
		executionId = executionId,
		state = context.executionState,
		nodeId = context.currentNodeId,
	})
	return { ok = true, code = "Ok", context = Serialization.deepCopy(context) }
end

return Engine
