--!strict

local Evidence = require(script.Parent.ExecutionEvidence)
local Metrics = require(script.Parent.ExecutionMetrics)
local Profiler = require(script.Parent.ExecutionProfiler)
local Types = require(script.Parent.DialogueExecutionTypes)

local Traversal = {}

local function nodesById(dialogue: any)
	local result = {}
	for _, node in ipairs(dialogue.nodes or {}) do
		result[node.nodeId] = node
	end
	return result
end

function Traversal.getNode(dialogue: any, nodeId: string)
	local nodes = nodesById(dialogue)
	return nodes[nodeId]
end

function Traversal.validateDestination(dialogue: any, destinationNodeId: string)
	if Traversal.getNode(dialogue, destinationNodeId) == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownNode,
			message = "unknown destination node",
		}
	end
	return { ok = true, code = "Ok" }
end

function Traversal.enterNode(executionId: string, node: any)
	Metrics.increment("nodeExecutions")
	Profiler.record(node.nodeId, "nodeExecutionDuration", 0)
	Evidence.record("node entered", {
		executionId = executionId,
		nodeId = node.nodeId,
		nodeType = node.nodeType,
	})
	return { ok = true, code = "Ok" }
end

function Traversal.exitNode(executionId: string, node: any)
	Evidence.record("node exited", {
		executionId = executionId,
		nodeId = node.nodeId,
		nodeType = node.nodeType,
	})
	return { ok = true, code = "Ok" }
end

function Traversal.transition(executionId: string, fromNodeId: string, toNodeId: string)
	Metrics.increment("transitions")
	Profiler.record(executionId, "transitionLatency", 0)
	Evidence.record("node transition", {
		executionId = executionId,
		fromNodeId = fromNodeId,
		toNodeId = toNodeId,
	})
	return { ok = true, code = "Ok" }
end

return Traversal
