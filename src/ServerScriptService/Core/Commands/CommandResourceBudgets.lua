--!strict

local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)

local ResourceBudgets = {}

function ResourceBudgets.inspect()
	return Serialization.deepCopy({
		maximumQueueDepth = Types.Limits.MaxQueueDepth,
		maximumRetryCount = Types.Limits.MaxRetryAttempts,
		maximumBatchSize = Types.Limits.MaxBatchSize,
		maximumLockCount = Types.Limits.MaxLocksPerCommand,
		maximumNestedDepth = Types.Limits.MaxNestedDepth,
		maximumTimelineEvents = Types.Limits.MaxTimelineEventsPerCommand,
		maximumTraceGraphEdges = Types.Limits.MaxTraceGraphEdges,
		maximumSessionCommands = Types.Limits.MaxSessionCommands,
		maximumThroughputHistory = Types.Limits.MaxThroughputHistory,
	})
end

return ResourceBudgets
