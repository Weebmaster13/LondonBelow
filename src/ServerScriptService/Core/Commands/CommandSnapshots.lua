--!strict

local CommandRegistry = require(script.Parent.CommandRegistry)
local Ancestry = require(script.Parent.CommandAncestry)
local Batch = require(script.Parent.CommandBatchRuntime)
local CommandQueue = require(script.Parent.CommandQueue)
local Evidence = require(script.Parent.CommandEvidence)
local Execution = require(script.Parent.CommandExecutionRuntime)
local LockManager = require(script.Parent.CommandLockManager)
local Recovery = require(script.Parent.CommandRecovery)
local Replay = require(script.Parent.CommandReplay)
local HandlerRegistry = require(script.Parent.CommandHandlerRegistry)
local Lifecycle = require(script.Parent.CommandLifecycle)
local RequesterRegistry = require(script.Parent.CommandRequesterRegistry)
local RetryRuntime = require(script.Parent.CommandRetryRuntime)
local Serialization = require(script.Parent.CommandSerialization)
local TransactionRuntime = require(script.Parent.CommandTransactionRuntime)
local Types = require(script.Parent.CommandTypes)

local Snapshots = {}

function Snapshots.capture(runtime: any)
	return Serialization.deepCopy({
		commandRegistrySnapshot = CommandRegistry.inspect(),
		requesterRegistrySnapshot = RequesterRegistry.inspect(),
		handlerRegistrySnapshot = HandlerRegistry.inspect(),
		lifecycleSnapshot = Lifecycle.inspect(),
		executionPolicyRegistrySnapshot = {
			executionModes = Types.ExecutionMode,
			retryPolicies = Types.RetryPolicy,
			replayPolicies = Types.CommandReplayPolicy,
			limits = {
				maxLocksPerCommand = Types.Limits.MaxLocksPerCommand,
				defaultExecutionBudget = Types.Limits.DefaultExecutionBudget,
				maxExecutionBudget = Types.Limits.MaxExecutionBudget,
				maxRetryAttempts = Types.Limits.MaxRetryAttempts,
				maxNestedDepth = Types.Limits.MaxNestedDepth,
			},
		},
		lockRegistrySnapshot = LockManager.inspect(),
		activeTransactionsSnapshot = TransactionRuntime.inspect(),
		retryQueueSnapshot = RetryRuntime.inspect(),
		replayMetadataSnapshot = Replay.inspect(),
		recoveryMetadataSnapshot = Recovery.inspect(),
		interruptedCommandsSnapshot = Recovery.inspect(),
		nestedAncestryGraphSnapshot = Ancestry.inspect(),
		batchStateSnapshot = Batch.inspect(),
		timelineSnapshot = runtime.getObservabilitySnapshot().timelines,
		profilerSnapshot = runtime.getObservabilitySnapshot().profiler,
		latencyHistogramSnapshot = runtime.getObservabilitySnapshot().metrics.latencyHistogram,
		throughputHistorySnapshot = runtime.getObservabilitySnapshot().metrics.throughputHistory,
		runtimeHealthSnapshot = runtime.getObservabilitySnapshot().health,
		pressureMetricsSnapshot = runtime.getObservabilitySnapshot().pressureMetrics,
		executionGraphSnapshot = runtime.getObservabilitySnapshot().traceGraph,
		correlationGraphSnapshot = runtime.getObservabilitySnapshot().correlationGraph,
		activeSessionsSnapshot = runtime.getObservabilitySnapshot().sessions,
		inspectionViewsSnapshot = runtime.getObservabilitySnapshot().inspectionViews,
		queueSnapshot = CommandQueue.inspect(),
		routingSnapshot = runtime.getRoutingHistory(),
		executionSnapshot = Execution.inspect(),
		diagnosticsSnapshot = runtime.inspect(),
		evidenceSnapshot = Evidence.inspect(),
	})
end

return Snapshots
