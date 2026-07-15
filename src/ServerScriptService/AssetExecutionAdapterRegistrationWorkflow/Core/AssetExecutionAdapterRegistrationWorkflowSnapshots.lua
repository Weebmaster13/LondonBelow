--!strict

local State = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowState)
local Types = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowTypes)

local Snapshots = {}

local function noAuthorityPosture()
	return {
		noExecution = true,
		noAssetLoading = true,
		noAssetSpawning = true,
		noAssetPlayback = true,
		noClientAuthority = true,
		noNetworking = true,
		noRouting = true,
		noDispatch = true,
		noQueues = true,
		noScheduler = true,
		noOrchestration = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noChapter = true,
		noProcessing = true,
		noRegistryWrites = true,
	}
end

function Snapshots.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local snapshot = {
		kind = Types.SnapshotKind,
		mode = Types.Mode,
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		counts = state.counts,
		runtimeLimits = dependencies.Serialization.deepCopy(Types.Limits),
		processingReadinessDeclarationFields = dependencies.Serialization.deepCopy(
			Types.ProcessingReadinessDeclarationFields
		),
		processingReadinessDeclarationOrder = dependencies.Serialization.deepCopy(
			Types.ProcessingReadinessDeclarationOrder
		),
		processingReadinessDeclarations = dependencies.Serialization.deepCopy(
			Types.ProcessingReadinessDeclarations
		),
		runtimeName = Types.RuntimeName,
		coordinatorName = Types.CoordinatorName,
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = dependencies.Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = dependencies.Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governanceSnapshotProviders = dependencies.Serialization.deepCopy(
			Types.GovernanceSnapshotProviders
		),
		noAuthorityPosture = noAuthorityPosture(),
		postureKeys = dependencies.Serialization.deepCopy(Types.PostureKeys),
		assetExecutionAdapterRegistrationWorkflowRuntimePosture = "workflow runtime stores copied metadata only",
		assetExecutionAdapterRegistrationWorkflowWorkflowPosture = "workflow records describe future registration paperwork only",
		assetExecutionAdapterRegistrationWorkflowRegistrationPosture = "registration workflow metadata does not register adapters",
		assetExecutionAdapterRegistrationWorkflowTransitionPosture = "transitions are metadata links between copied stages",
		assetExecutionAdapterRegistrationWorkflowDecisionPosture = "decisions are copied certification metadata only",
		assetExecutionAdapterRegistrationWorkflowAuditPosture = "audits summarize copied workflow metadata",
		assetExecutionAdapterRegistrationWorkflowSnapshotPosture = "workflow snapshots expose isolated copied metadata",
		assetExecutionAdapterRegistrationWorkflowValidationPosture = "validation occurs before mutation",
		assetExecutionAdapterRegistrationWorkflowDocumentationPosture = "documentation references are exact",
		assetExecutionAdapterRegistrationWorkflowBootstrapPosture = "Bootstrap follows the adapter registry coordinator",
		assetExecutionAdapterRegistrationWorkflowGovernancePosture = "Governance snapshot provider is fixed",
		assetExecutionAdapterRegistrationWorkflowCertificationPosture = "foundation is non-executing metadata",
		assetExecutionAdapterRegistrationWorkflowHardeningPosture = "production hardening freezes deterministic workflow metadata surfaces",
		assetExecutionAdapterRegistrationWorkflowIdentityPosture = "runtime identities reject aliases and casing drift",
		assetExecutionAdapterRegistrationWorkflowOrderingPosture = "schema and child arrays remain ordered",
		assetExecutionAdapterRegistrationWorkflowMetadataPosture = "metadata remains serializable and non-executable",
		assetExecutionAdapterRegistrationWorkflowEvidencePosture = "evidence arrays remain ordered copied ids",
		assetExecutionAdapterRegistrationWorkflowTagPosture = "tag arrays remain ordered copied ids",
		assetExecutionAdapterRegistrationWorkflowRuntimeLimitPosture = "runtime-limit metadata is exact",
		assetExecutionAdapterRegistrationWorkflowNoImplementationPosture = "implementation records are not stored",
		assetExecutionAdapterRegistrationWorkflowNoActivationPosture = "activation is not exposed",
		assetExecutionAdapterRegistrationWorkflowNoExecutionPosture = "workflow metadata is never executed",
		assetExecutionAdapterRegistrationWorkflowNoAuthorizationPosture = "workflow metadata grants no authorization",
		assetExecutionAdapterRegistrationWorkflowNoWorkflowExecutionPosture = "no workflow engine is present",
		assetExecutionAdapterRegistrationWorkflowNoOperationPosture = "no asset operation surface is present",
		assetExecutionAdapterRegistrationWorkflowNoAuthorityPosture = "metadata grants no authority",
		assetExecutionAdapterRegistrationWorkflowProcessingReadinessPosture = "readiness declarations are static copied metadata",
		assetExecutionAdapterRegistrationWorkflowProcessingDeclarationPosture = "declaration order and terminology are exact",
		assetExecutionAdapterRegistrationWorkflowProcessorAbsencePosture = "future processor surfaces are absent",
		assetExecutionAdapterRegistrationWorkflowRegistryWriteSeparationPosture = "registry writes remain outside this runtime",
		assetExecutionAdapterRegistrationWorkflowProcessingSeparationPosture = "future processing obligations remain separated from runtime behavior",
		assetExecutionAdapterRegistrationWorkflowProcessingHardeningPosture = "production hardening freezes all processing-readiness metadata",
		assetExecutionAdapterRegistrationWorkflowProcessingIdentityPosture = "declaration identities reject aliases, duplicates, and drift",
		assetExecutionAdapterRegistrationWorkflowProcessingOrderingPosture = "declaration fields and records preserve exact dense ordering",
		assetExecutionAdapterRegistrationWorkflowProcessingPayloadPosture = "declaration payloads reject executable and processing surfaces",
		assetExecutionAdapterRegistrationWorkflowProcessingIsolationPosture = "diagnostics and snapshots expose isolated declaration copies",
		assetExecutionAdapterRegistrationWorkflowProcessingRegressionPosture = "Phase 107 readiness guarantees remain protected",
		noExecution = true,
		noAssetLoading = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noNetworking = true,
		noAnalytics = true,
		noTelemetry = true,
		schemas = {
			workflows = state.workflows,
			stages = state.stages,
			transitions = state.transitions,
			decisions = state.decisions,
			audits = state.audits,
			workflowSnapshots = state.workflowSnapshots,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
