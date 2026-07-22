# Diagnostics and Evidence

Diagnostics expose `commandBusPosture`, registered command/requester/handler counts, queued/routing/executing/succeeded/cancelled/rejected/failed command counts, queue overflows, idempotency rejects, maximum queue depth, last command id, and last failure.

Snapshots expose command registry, requester registry, handler registry, queue, routing, execution, diagnostics, and evidence snapshots.

Part II adds lifecycle snapshots and deterministic failure categories: `SchemaFailure`, `AuthorizationFailure`, `AuthorityFailure`, `RoutingFailure`, `HandlerFailure`, `QueueFailure`, `ValidationFailure`, `ExecutionFailure`, `CancellationFailure`, and `InternalRuntimeFailure`.

Part III expands diagnostics with `activeTransactions`, `heldLocks`, `queuedRetries`, `timeoutCount`, `replayState`, `interruptedCommands`, `nestedDepth`, `batchCount`, `transactionFailures`, `rollbackFailures`, `lockFailures`, and `retryLimitExceeded`.

Part III expands snapshots with `executionPolicyRegistrySnapshot`, `lockRegistrySnapshot`, `activeTransactionsSnapshot`, `retryQueueSnapshot`, `replayMetadataSnapshot`, `recoveryMetadataSnapshot`, `interruptedCommandsSnapshot`, `nestedAncestryGraphSnapshot`, and `batchStateSnapshot`.

Part III adds deterministic failure categories: `ExecutionTimeoutFailure`, `TransactionFailure`, `RollbackFailure`, `LockFailure`, `LockTimeoutFailure`, `ReplayFailure`, `InterruptedExecutionFailure`, `RetryLimitExceeded`, `CircularCommandFailure`, and `NestedCommandDepthExceeded`.

Part IV expands passive observability with immutable command timelines, stage duration metadata, runtime trace graphs, workflow correlation graphs, runtime health, profiler data, latency histograms, throughput history, pressure metrics, active diagnostic sessions, and deterministic inspection views.

Part IV diagnostics expose `instrumentationFaults`, `runtimeHealth`, `pressureMetrics`, and `observabilityMetrics`. Instrumentation faults do not prevent command execution; they are recorded as evidence for investigation.

Part IV snapshots expose `timelineSnapshot`, `profilerSnapshot`, `latencyHistogramSnapshot`, `throughputHistorySnapshot`, `runtimeHealthSnapshot`, `pressureMetricsSnapshot`, `executionGraphSnapshot`, `correlationGraphSnapshot`, `activeSessionsSnapshot`, and `inspectionViewsSnapshot`.

Part V expands production governance evidence with `certificationSnapshot`, `resourceBudgetsSnapshot`, `performanceBudgetsSnapshot`, `compatibilitySnapshot`, `migrationSnapshot`, `auditSnapshot`, `stressValidationSnapshot`, `faultInjectionSnapshot`, `integritySnapshot`, and `productionReviewSnapshot`.

Part V diagnostics expose `certificationStatus`, `integrityScore`, `resourceBudgets`, `performanceBudgets`, `compatibilityMetadata`, `migrationMetadata`, `auditMetadata`, `stressValidation`, `faultInjection`, and `productionReview`. These fields are informational governance evidence only and never alter command execution.
