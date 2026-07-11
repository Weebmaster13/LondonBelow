# Asset Execution Governance Validation

Validation rejects nil and non-table schemas, unsupported fields, missing required fields, invalid field counts, misspelled fields, invalid ids, unordered arrays, sparse arrays, dictionary-shaped arrays, unsupported enum values, unsafe payloads, duplicate ids, missing references, cross-parent references, and bounded limit violations.

Validation runs before mutation. Failed validation records a bounded diagnostic failure through the coordinator and does not create or change governance, requirement, assessment, finding, or audit state.

Accepted schema fields match `AssetExecutionGovernanceTypes.SchemaFields`. Runtime metadata must use `runtimeName = "AssetExecutionGovernance"`, `providerName = "assetExecutionGovernanceRuntime"`, and `snapshotProviderName = "assetExecutionGovernanceRuntime"`.

Phase 81 also validates `AssetExecutionGovernanceTypes.IntegrationReadinessDeclarations` as an exact ordered static declaration array. The declaration count is `10`, sparse and dictionary-shaped arrays reject, inserted or swapped declarations reject, duplicate ids reject, and every declaration must match the copied runtime, provider, snapshot provider, coordinator, diagnostics provider, Bootstrap dependency, Engine Governance provider, documentation, Decision Runtime, execution-readiness evidence, and Asset Execution Governance identity fields.

Phase 82 hardening additionally validates exact declaration order arrays for `integrationId`, `compatibilityId`, `integrationDeclarationId`, `integrationKind`, `integrationStatus`, and `authorizationBoundaryKind`. Integration metadata is restricted to `copied`, `order`, and `compatibility`; unsupported metadata keys, missing metadata keys, false copied flags, invalid order values, invalid compatibility ids, nested unsafe metadata, oversized arrays, and authority-bearing markers reject before runtime health can report healthy.

Phase 83 validates `AssetExecutionGovernanceTypes.AuthorizationReadinessDeclarations` as exact ordered static metadata. The declaration count is `10`, sparse and dictionary-shaped arrays reject, inserted, swapped, rotated, or replaced declarations reject, and duplicate readiness, compatibility, dependency, identity, boundary, or kind ids reject. Every declaration must match copied runtime, provider, snapshot provider, coordinator, diagnostics provider, Bootstrap dependency, Engine Governance provider, documentation, governance compatibility, execution-readiness evidence, future authorization-runtime identity, and future execution-runtime identity fields. Authorization-readiness metadata is restricted to `copied`, `order`, `compatibility`, and `dependency`.

Accepted enum values:

- `governanceKind`: `DecisionEvidenceGovernance`, `ExecutionReadinessGovernance`, `ProviderGovernance`, `RuntimeGovernance`, `SnapshotGovernance`, `BootstrapGovernance`, `DocumentationGovernance`, `BoundaryGovernance`, `IsolationGovernance`, `FutureGovernance`
- `governanceStatus`: `Declared`, `UnderReview`, `Satisfied`, `Unsatisfied`, `Blocked`, `Deferred`, `Warning`
- `requirementKind`: `DecisionEvidenceRequirement`, `ExecutionReadinessRequirement`, `ProviderConsistencyRequirement`, `RuntimeConsistencyRequirement`, `SnapshotConsistencyRequirement`, `BootstrapConsistencyRequirement`, `DocumentationConsistencyRequirement`, `BoundaryRequirement`, `IsolationRequirement`, `FutureRequirement`
- `requirementStatus`: `Required`, `Satisfied`, `Unsatisfied`, `Deferred`, `Warning`
- `assessmentKind`: `DecisionEvidenceAssessment`, `ExecutionReadinessAssessment`, `ProviderConsistencyAssessment`, `RuntimeConsistencyAssessment`, `SnapshotConsistencyAssessment`, `BootstrapConsistencyAssessment`, `DocumentationConsistencyAssessment`, `BoundaryAssessment`, `IsolationAssessment`, `FutureAssessment`
- `assessmentStatus`: `Passed`, `Failed`, `Blocked`, `Deferred`, `Warning`
- `findingKind`: `MissingEvidence`, `CompatibilityDrift`, `ProviderDrift`, `RuntimeDrift`, `SnapshotDrift`, `BootstrapDrift`, `DocumentationDrift`, `BoundaryViolation`, `IsolationViolation`, `UnsafeMetadata`, `FutureFinding`
- `findingSeverity`: `Informational`, `Low`, `Medium`, `High`, `Critical`
- `findingStatus`: `Open`, `Reviewed`, `Acknowledged`, `Deferred`, `ResolvedMetadataOnly`
- `auditKind`: `GovernanceAudit`, `RequirementAudit`, `AssessmentAudit`, `FindingAudit`, `CoverageAudit`, `BoundaryAudit`, `ProductionAudit`, `FutureAudit`
- `auditStatus`: `Passed`, `Failed`, `Warning`, `Deferred`, `Blocked`
- `integrationKind`: `DecisionRuntimeIntegrationReadiness`, `ExecutionReadinessCompatibility`, `GovernanceRuntimeCompatibility`, `ProviderCompatibility`, `SnapshotCompatibility`, `BootstrapCompatibility`, `EngineGovernanceCompatibility`, `DocumentationCompatibility`, `AuthorizationBoundarySeparation`, `FutureExecutionSeparation`
- `integrationStatus`: `Declared`, `Compatible`, `IntegrationReady`, `BoundaryReady`, `Deferred`, `Warning`, `Blocked`
- `authorizationBoundaryKind`: `NoAuthorizationRuntime`, `NoExecutionPermission`, `NoAuthorityTokens`, `NoOperationalRejection`, `NoRoutingOrDispatch`, `NoQueueOrScheduler`, `NoOrchestration`, `NoAssetOperations`, `FutureAuthorizationSeparate`, `FutureExecutionSeparate`
- `authorizationReadinessKind`: `GovernanceCompatibilityReadiness`, `ExecutionReadinessCompatibility`, `AuthorizationSeparationReadiness`, `AuthorizationDependencyOrdering`, `FutureRuntimeCompatibility`, `ProviderIdentityReadiness`, `CoordinatorIdentityReadiness`, `BootstrapDependencyReadiness`, `EngineGovernanceReadiness`, `DocumentationConsistencyReadiness`
- `authorizationReadinessStatus`: `Declared`, `Compatible`, `DependencyReady`, `IdentityReady`, `BoundaryReady`, `Deferred`, `Warning`, `Blocked`
- `authorizationReadinessBoundaryKind`: `NoAuthorizationRuntime`, `NoAuthorizationTokens`, `NoPermissions`, `NoSessionApproval`, `NoRuntimeApproval`, `NoRuntimeRejection`, `NoExecutionRouting`, `NoDispatchQueues`, `NoSchedulers`, `FutureAuthorizationSeparate`, `FutureExecutionSeparate`

Every status and severity is metadata only. No enum value grants permission, creates authorization, causes operational rejection, approves work, rejects work, repairs data, blocks live work, routes work, dispatches work, queues work, schedules work, or executes assets.
