--!strict

local Serialization = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowSerialization)
local State = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowState)
local Types = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

local function noAuthorityPosture()
	return {
		noExecution = true,
		noAssetLoading = true,
		noAssetStreaming = true,
		noAssetSpawning = true,
		noAssetPlayback = true,
		noAnimationPlayback = true,
		noAudioPlayback = true,
		noUi = true,
		noVfx = true,
		noWorldMutation = true,
		noStorageMutation = true,
		noClientAuthority = true,
		noRouting = true,
		noDispatch = true,
		noQueues = true,
		noScheduler = true,
		noOrchestration = true,
		noPersistence = true,
		noHttp = true,
		noMessaging = true,
		noAnalytics = true,
		noTelemetry = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noChapter = true,
		noProcessing = true,
		noRegistryWrites = true,
	}
end

local function posture()
	return {
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
		noExecution = true,
		noAssetLoading = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noNetworking = true,
		noAnalytics = true,
		noTelemetry = true,
	}
end

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local counts = state.counts
	local validationOk, validationReason = dependencies.Validation.validate()
	local report = {
		initialized = lifecycle.initialized,
		started = lifecycle.started,
		lifecycleState = if lifecycle.started
			then "Started"
			elseif lifecycle.initialized then "Initialized"
			else "Cold",
		health = if validationOk then "Healthy" else "Unhealthy",
		validationOk = validationOk,
		validationReason = validationReason,
		counts = counts,
		limitUsage = {
			workflows = limitUsage(counts.workflows, Types.Limits.MaxWorkflows),
			stages = limitUsage(counts.stages, Types.Limits.MaxStages),
			transitions = limitUsage(counts.transitions, Types.Limits.MaxTransitions),
			decisions = limitUsage(counts.decisions, Types.Limits.MaxDecisions),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
			workflowSnapshots = limitUsage(
				counts.workflowSnapshots,
				Types.Limits.MaxWorkflowSnapshots
			),
		},
		runtimeLimits = Serialization.deepCopy(Types.Limits),
		processingReadinessDeclarationFields = Serialization.deepCopy(
			Types.ProcessingReadinessDeclarationFields
		),
		processingReadinessDeclarationOrder = Serialization.deepCopy(
			Types.ProcessingReadinessDeclarationOrder
		),
		processingReadinessDeclarations = Serialization.deepCopy(
			Types.ProcessingReadinessDeclarations
		),
		runtimeName = Types.RuntimeName,
		coordinatorName = Types.CoordinatorName,
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governanceSnapshotProviders = Serialization.deepCopy(Types.GovernanceSnapshotProviders),
		noAuthorityPosture = noAuthorityPosture(),
		postureKeys = Serialization.deepCopy(Types.PostureKeys),
		schemas = {
			workflows = state.workflows,
			stages = state.stages,
			transitions = state.transitions,
			decisions = state.decisions,
			audits = state.audits,
			workflowSnapshots = state.workflowSnapshots,
		},
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = Serialization.diagnosticCopy(lifecycle.lastSelfChecks),
	}
	for key, value in pairs(posture()) do
		report[key] = value
	end
	return report
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
