--!strict

local Types = require(script.Parent.CommandTypes)

local Diagnostics = {}

function Diagnostics.capture(runtime: any)
	local counters = runtime.getCounters()
	return {
		commandBusPosture = if runtime.isShutdown() then "Shutdown" else "Healthy",
		registeredCommandTypes = counters.commandTypes,
		registeredRequesters = counters.requesters,
		registeredHandlers = counters.handlers,
		queuedCommands = counters.queued,
		routingCommands = counters.routing,
		executingCommands = counters.executing,
		succeededCommands = counters.succeeded,
		cancelledCommands = counters.cancelled,
		rejectedCommands = counters.rejected,
		failedCommands = counters.failed,
		queueOverflows = counters.queueOverflows,
		idempotencyRejects = counters.idempotencyRejects,
		activeTransactions = counters.activeTransactions,
		heldLocks = counters.heldLocks,
		queuedRetries = counters.queuedRetries,
		timeoutCount = counters.timeoutCount,
		replayState = counters.replayState,
		interruptedCommands = counters.interruptedCommands,
		nestedDepth = counters.nestedDepth,
		batchCount = counters.batchCount,
		transactionFailures = counters.transactionFailures,
		rollbackFailures = counters.rollbackFailures,
		lockFailures = counters.lockFailures,
		retryLimitExceeded = counters.retryLimitExceeded,
		instrumentationFaults = counters.instrumentationFaults,
		runtimeHealth = counters.runtimeHealth,
		pressureMetrics = counters.pressureMetrics,
		observabilityMetrics = counters.metrics,
		certificationStatus = counters.certificationStatus,
		certificationBlockedReason = counters.certificationBlockedReason,
		integrityScore = counters.integrityScore,
		resourceBudgets = counters.resourceBudgets,
		performanceBudgets = counters.performanceBudgets,
		compatibilityMetadata = counters.compatibilityMetadata,
		migrationMetadata = counters.migrationMetadata,
		auditMetadata = counters.auditMetadata,
		stressValidation = counters.stressValidation,
		faultInjection = counters.faultInjection,
		productionReview = counters.productionReview,
		maximumQueueDepth = counters.maximumQueueDepth,
		lastCommandId = counters.lastCommandId,
		lastFailure = counters.lastFailure,
		limits = Types.Limits,
	}
end

return Diagnostics
