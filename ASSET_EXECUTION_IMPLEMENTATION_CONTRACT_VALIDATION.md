# Asset Execution Implementation Contract Validation

Validation occurs before mutation. Failed validation records a bounded, sanitized failure and leaves state unchanged.

The validator rejects nil and non-table schemas, invalid ids, unsupported schema types, unsupported contract kinds, unsupported contract statuses, unsupported responsibility kinds, unsupported boundary kinds, unsupported audit kinds, unsupported audit statuses, missing contract references, unsafe metadata, unsafe tags, unsafe findings, duplicate ids in the global schema namespace, duplicate child ids, Roblox Instances, instance-shaped tables, functions, threads, userdata, callbacks, listeners, service handles, runtime handles, asset handles, loaded asset handles, module references, execution adapters, remotes, cycles, oversized strings, deep payloads, and oversized node counts.

Forbidden markers cover asset loading, preloading, streaming, spawning, application, playback, UI, VFX, storage mutation, Workspace mutation, client authority, remotes, DataStore, HTTP, MessagingService, analytics, telemetry, gameplay execution, Presentation execution, Save execution, Chapter content, maps, rooms, dialogue, and cutscenes.

Accepted contract kinds are `RuntimeImplementation`, `SafetyImplementation`, `AccessibilityImplementation`, `PerformanceImplementation`, `ProductionImplementation`, `ConditionalImplementation`, and `FutureImplementation`.

Accepted contract statuses are `Open`, `Passed`, `Blocked`, `Deferred`, and `NeedsReview`.

Accepted responsibility kinds are `OwnershipResponsibility`, `ValidationResponsibility`, `DiagnosticsResponsibility`, `SnapshotResponsibility`, `CleanupResponsibility`, `SafetyResponsibility`, `AccessibilityResponsibility`, `PerformanceResponsibility`, and `FutureResponsibility`.

Accepted boundary kinds are `NoLoadingBoundary`, `NoExecutionBoundary`, `ClientAuthorityBoundary`, `StorageBoundary`, `SafetyBoundary`, `AccessibilityBoundary`, `PerformanceBoundary`, and `FutureBoundary`.

Accepted audit kinds are `DesignAudit`, `SafetyAudit`, `AccessibilityAudit`, `PerformanceAudit`, `ProductionAudit`, and `FutureAudit`.

Accepted audit statuses are `Passed`, `Failed`, `Warning`, `Deferred`, and `Blocked`.

Implementation contract integration references are validated as bounded ids: `readinessId`, `designContractId`, `assetId`, `usagePlanId`, `checklistId`, `approvalId`, `permitId`, and `gateId`. Phase 58 does not resolve those references across runtimes; it only proves the fields are present and safe for future read-only integration inspection.

Validation happens before mutation. Failed validation never registers schema data; coordinator-level failures are recorded only as bounded sanitized diagnostics.
