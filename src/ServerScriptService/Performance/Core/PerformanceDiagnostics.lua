--!strict
-- Diagnostics for Performance Budget Runtime Foundation.

local Serialization = require(script.Parent.PerformanceSerialization)
local Types = require(script.Parent.PerformanceTypes)

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
			budgets = state.counts.budgets .. "/" .. Types.Limits.MaxBudgets,
			categories = state.counts.categories .. "/" .. Types.Limits.MaxCategories,
			thresholds = state.counts.thresholds .. "/" .. Types.Limits.MaxThresholds,
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
			noGameplayExecution = true,
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
	if state.counts.budgets > Types.Limits.MaxBudgets then
		return false, "budget count exceeds limit"
	end
	if state.counts.categories > Types.Limits.MaxCategories then
		return false, "category count exceeds limit"
	end
	if state.counts.thresholds > Types.Limits.MaxThresholds then
		return false, "threshold count exceeds limit"
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
