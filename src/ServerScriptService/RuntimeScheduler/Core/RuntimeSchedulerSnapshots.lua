--!strict
-- Snapshot builder for Runtime Scheduler schema state.

local Diagnostics = require(script.Parent.RuntimeSchedulerDiagnostics)
local Serialization = require(script.Parent.RuntimeSchedulerSerialization)

local Snapshots = {}

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = dependencies.State.inspect()
	local diagnostics = Diagnostics.capture(lifecycle, dependencies)
	local snapshot = Serialization.deepCopy({
		schemaVersion = 1,
		createdBy = "RuntimeScheduler",
		lifecycleState = diagnostics.lifecycleState,
		health = diagnostics.health,
		counts = state.counts,
		plans = state.plans,
		slots = state.slots,
		queues = state.queues,
		priorities = state.priorities,
		budgets = state.budgets,
		deadlines = state.deadlines,
		retries = state.retries,
		intervals = state.intervals,
		windows = state.windows,
		dependencies = state.dependencies,
		audits = state.audits,
		integrityPosture = {
			scheduler = diagnostics.schedulerIntegrityPosture,
			plan = diagnostics.planIntegrityPosture,
			slot = diagnostics.slotIntegrityPosture,
			queue = diagnostics.queueIntegrityPosture,
			priority = diagnostics.priorityIntegrityPosture,
			budget = diagnostics.budgetIntegrityPosture,
			deadline = diagnostics.deadlineIntegrityPosture,
			retry = diagnostics.retryIntegrityPosture,
			interval = diagnostics.intervalIntegrityPosture,
			window = diagnostics.windowIntegrityPosture,
			dependency = diagnostics.dependencyIntegrityPosture,
			audit = diagnostics.auditIntegrityPosture,
		},
		noExecutionPosture = diagnostics.noExecutionPosture,
		recentValidationFailures = state.validationFailures,
	})
	dependencies.State.recordSnapshot(snapshot)
	return snapshot
end

return Snapshots
