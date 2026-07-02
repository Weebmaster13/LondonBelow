--!strict
-- Snapshot provider for Analytics Boundary Foundation.

local Serialization = require(script.Parent.AnalyticsSerialization)
local Types = require(script.Parent.AnalyticsTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local inspected = state.inspect()
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		counts = inspected.counts,
		events = inspected.events,
		metrics = inspected.metrics,
		aggregations = inspected.aggregations,
		consents = inspected.consents,
		retentions = inspected.retentions,
		reports = inspected.reports,
		recentValidationFailures = inspected.validationFailures,
	})
	state.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
