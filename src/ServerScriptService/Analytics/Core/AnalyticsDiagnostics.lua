--!strict
-- Diagnostics for Analytics Boundary Foundation.

local Serialization = require(script.Parent.AnalyticsSerialization)
local Types = require(script.Parent.AnalyticsTypes)

local Diagnostics = {}

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = dependencies.State.inspect()
	local validationOk, validationReason = dependencies.Validation.validate()
	local health = "Healthy"
	if not validationOk then
		health = "Unhealthy"
	elseif state.counts.validationFailures > 0 then
		health = "Warning"
	end

	return Serialization.deepCopy({
		health = health,
		validationOk = validationOk,
		validationReason = validationReason,
		lifecycleState = lifecycle.started and "Started"
			or (lifecycle.initialized and "Initialized" or "Stopped"),
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lastSelfChecks = lifecycle.lastSelfChecks,
		counts = state.counts,
		limits = Types.Limits,
		mode = Types.Mode,
		perCategoryLimitState = {
			events = state.counts.events .. "/" .. Types.Limits.MaxEvents,
			metrics = state.counts.metrics .. "/" .. Types.Limits.MaxMetrics,
			aggregations = state.counts.aggregations .. "/" .. Types.Limits.MaxAggregations,
			consents = state.counts.consents .. "/" .. Types.Limits.MaxConsents,
			retentions = state.counts.retentions .. "/" .. Types.Limits.MaxRetentions,
			reports = state.counts.reports .. "/" .. Types.Limits.MaxReports,
			validationFailures = state.counts.validationFailures
				.. "/"
				.. Types.Limits.MaxValidationFailures,
			snapshots = state.counts.snapshots .. "/" .. Types.Limits.MaxSnapshotHistory,
		},
		serializationPosture = {
			rejectsInstances = true,
			rejectsUnsafeRuntimeValues = true,
			rejectsCycles = true,
			rejectsOversizedPayloads = true,
			exportsDeepCopies = true,
		},
		snapshotIsolationProof = {
			snapshotsAreDeepCopies = true,
			diagnosticsAreDeepCopies = true,
			unsafeRuntimeValuesAreSanitized = true,
		},
		noExecutionPosture = {
			noAnalyticsCollection = true,
			noTelemetrySending = true,
			noPlayerTracking = true,
			noExternalReporting = true,
			noPlayerFacingUi = true,
			noModeration = true,
			noProfilingExecution = true,
			noHttpCalls = true,
			noMessaging = true,
			noDataStoreReads = true,
			noDataStoreWrites = true,
			noWorkspaceMutation = true,
			noRemotes = true,
			noClientAuthority = true,
			noChapterContent = true,
		},
		recentValidationFailures = state.validationFailures,
	})
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	local ok, reason = dependencies.Validation.validate()
	if not ok then
		return false, reason
	end
	local state = dependencies.State.inspect()
	if state.counts.events > Types.Limits.MaxEvents then
		return false, "event count exceeds limit"
	end
	if state.counts.metrics > Types.Limits.MaxMetrics then
		return false, "metric count exceeds limit"
	end
	if state.counts.aggregations > Types.Limits.MaxAggregations then
		return false, "aggregation schema count exceeds limit"
	end
	if state.counts.consents > Types.Limits.MaxConsents then
		return false, "consent count exceeds limit"
	end
	if state.counts.retentions > Types.Limits.MaxRetentions then
		return false, "retention count exceeds limit"
	end
	if state.counts.reports > Types.Limits.MaxReports then
		return false, "report count exceeds limit"
	end
	if state.counts.validationFailures > Types.Limits.MaxValidationFailures then
		return false, "validation failure history exceeds limit"
	end
	if state.counts.snapshots > Types.Limits.MaxSnapshotHistory then
		return false, "snapshot history exceeds limit"
	end
	return true, nil
end

return Diagnostics
