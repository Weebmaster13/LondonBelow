--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)

local Budgets = {}

function Budgets.inspect()
	return Serialization.deepCopy({
		maxSessions = Types.Limits.MaxRuntimeSessions,
		maxConsumers = Types.Limits.MaxRuntimeConsumers,
		maxQueuedSessions = Types.Limits.MaxRuntimeQueuedSessions,
		maxAcknowledgements = Types.Limits.MaxRuntimeAcknowledgements,
		maxSynchronizationRecords = Types.Limits.MaxRuntimeSynchronizationRecords,
		maxEvidence = Types.Limits.MaxEvidence,
		maxProfilerRecords = Types.Limits.MaxRuntimeProfilerRecords,
	})
end

return Budgets
