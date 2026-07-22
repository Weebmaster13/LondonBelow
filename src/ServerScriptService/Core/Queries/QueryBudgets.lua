--!strict
local Serialization = require(script.Parent.QuerySerialization)
local Types = require(script.Parent.QueryTypes)
local Budgets = {}
function Budgets.inspect()
	return Serialization.deepCopy({
		resourceBudgets = {
			maximumQueueDepth = Types.Limits.MaxQueueDepth,
			maximumConcurrentQueries = Types.Limits.MaxQueueDepth,
			cacheSize = Types.Limits.MaxCacheEntries,
			snapshotCount = Types.Limits.MaxSnapshotCount,
			projectionCount = Types.Limits.MaxProjectionCount,
			inspectionHistory = Types.Limits.MaxInspectionHistory,
		},
		performanceBudgets = {
			validationMs = 1,
			routingMs = 1,
			executionOverheadMs = 2,
			cacheLookupMs = 1,
			observabilityOverheadPercent = 5,
		},
	})
end
return Budgets
