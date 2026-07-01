--!strict

local GameplayExecutionDiagnostics = {}

function GameplayExecutionDiagnostics.capture(state: any, dependencies: { [string]: any })
	local queue = dependencies.Queue.inspect()
	local runtimeState = dependencies.State.inspect()
	local router = dependencies.Router.inspect()

	return {
		initialized = state.initialized,
		started = state.started,
		mode = state.mode,
		physicalMutationEnabled = state.physicalMutationEnabled,
		queueSize = queue.size,
		queue = queue,
		appliedCount = runtimeState.counters.applied,
		rejectedCount = runtimeState.counters.rejected,
		failedCount = runtimeState.counters.failed,
		expiredCount = runtimeState.counters.expired,
		cancelledCount = runtimeState.counters.cancelled,
		duplicateCount = runtimeState.counters.duplicate,
		dryRunCount = runtimeState.counters.dryRun,
		adapterCount = router.adapterCount,
		objectLockCount = runtimeState.objectLockCount,
		recentExecutions = runtimeState.recentExecutions,
		recentFailures = runtimeState.recentFailures,
		router = router,
		state = runtimeState,
		health = {
			healthy = state.initialized and state.mode ~= "Enabled"
				or state.physicalMutationEnabled == true,
			status = if state.mode == "Disabled"
				then "Disabled"
				elseif state.started then "Running"
				else "Ready",
			message = "Gameplay Execution Bridge is dry-run or disabled unless explicitly enabled.",
		},
	}
end

return GameplayExecutionDiagnostics
