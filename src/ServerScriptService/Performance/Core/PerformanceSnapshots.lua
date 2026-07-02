--!strict
-- Snapshot provider for Performance Budget Runtime.

local Serialization = require(script.Parent.PerformanceSerialization)
local Types = require(script.Parent.PerformanceTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local current = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = current.counts,
		budgets = current.budgets,
		categories = current.categories,
		thresholds = current.thresholds,
		reports = current.reports,
		noExecutionPosture = {
			noLiveProfiling = true,
			noOptimizationExecution = true,
			noAutomaticThrottling = true,
			noAnalyticsCollection = true,
			noTelemetrySending = true,
			noMemoryMutation = true,
			noNetworkMutation = true,
			noRenderMutation = true,
			noClientMonitoring = true,
			noRemotes = true,
			noWorldMutation = true,
			noChapterContent = true,
		},
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
