--!strict

local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local TraceGraph = {}
local nodes: { [string]: any } = {}
local edges: { any } = {}

local function trim()
	while #edges > Types.Limits.MaxTraceGraphEdges do
		table.remove(edges, 1)
	end
end

local function hasPath(fromId: string, targetId: string): boolean
	if fromId == targetId then
		return true
	end
	for _, edge in ipairs(edges) do
		if edge.from == fromId and hasPath(edge.to, targetId) then
			return true
		end
	end
	return false
end

function TraceGraph.record(command: any)
	if type(command.commandId) ~= "string" then
		return { ok = false, code = Types.FailureType.ReplayFailure, message = "missing command id" }
	end
	nodes[command.commandId] = {
		commandId = command.commandId,
		commandType = command.commandType,
		correlationId = command.correlationId,
		causationId = command.causationId,
		ownerRuntime = command.ownerRuntime,
	}
	if command.causationId ~= nil and command.causationId ~= "root" then
		if hasPath(command.commandId, command.causationId) then
			return {
				ok = false,
				code = Types.FailureType.CircularCommandFailure,
				message = "trace graph cycle rejected",
			}
		end
		table.insert(edges, { from = command.causationId, to = command.commandId })
		trim()
	end
	return { ok = true, code = "Ok" }
end

function TraceGraph.inspect()
	return Serialization.deepCopy({
		nodes = nodes,
		edges = edges,
		acyclic = true,
	})
end

function TraceGraph.clear()
	table.clear(nodes)
	table.clear(edges)
end

return TraceGraph
