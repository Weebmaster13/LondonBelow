--!strict

local State = require(script.Parent.AssetGovernanceCertificationDecisionState)
local Types = require(script.Parent.AssetGovernanceCertificationDecisionTypes)

local Snapshots = {}

local function noAuthorityPosture()
	return {
		noExecution = true,
		noAuthorization = true,
		noApproval = true,
		noRejectionAuthority = true,
		noRepair = true,
		noMutation = true,
		noScheduling = true,
		noOrchestration = true,
		noNetworking = true,
		noPersistence = true,
		noRemotes = true,
		noClientAuthority = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noChapterContent = true,
		noAssetLoading = true,
		noMutableReferences = true,
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
		schemas = {
			decisions = state.decisions,
			requirements = state.requirements,
			evaluations = state.evaluations,
			audits = state.audits,
		},
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = dependencies.Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = dependencies.Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governancePosture = "registered as deterministic decision metadata only",
		decisionRuntimePosture = "evaluates copied governance evidence into metadata only",
		decisionEvaluationPosture = "evaluation records are deterministic metadata and not commands",
		decisionRequirementPosture = "requirement records describe copied evidence obligations only",
		decisionAuditPosture = "audit records review decision metadata only",
		decisionEvidencePosture = dependencies.Serialization.deepCopy(Types.CertifiedRuntimeOrder),
		decisionIsolationPosture = "snapshots expose deep-copied decision metadata without handles",
		decisionValidationPosture = "validation occurs before mutation and rejects unsafe payloads",
		decisionMetadataPosture = "decision metadata is evidence only and never permission",
		decisionDocumentationPosture = dependencies.Serialization.deepCopy(
			Types.DocumentationFiles
		),
		decisionIntegrationPosture = "integration readiness metadata is copied evidence only",
		decisionIntegrationHardeningPosture = "integration readiness ordering is exact and self-verifying",
		integrationOrderingPosture = "declarations match certified runtime ordering exactly",
		integrationDeterminismPosture = "declarations compare exact copied evidence, tags, and metadata",
		integrationConsistencyPosture = "runtime, provider, snapshot, Bootstrap, Governance, documentation, and decision identifiers align",
		integrationCompatibilityPosture = "certified governance chain compatibility is declared metadata",
		integrationEvidencePosture = dependencies.Serialization.deepCopy(
			Types.IntegrationReadinessDeclarations
		),
		integrationIsolationPosture = "integration metadata is deep-copied and contains no handles",
		integrationCoveragePosture = "integration readiness covers every certified runtime through inspection",
		integrationValidationPosture = "integration declarations validate before runtime health reports healthy",
		integrationDocumentationPosture = "integration readiness documentation is declared metadata",
		integrationReadinessDeclarations = dependencies.Serialization.deepCopy(
			Types.IntegrationReadinessDeclarations
		),
		postureKeys = dependencies.Serialization.deepCopy(Types.PostureKeys),
		noAuthorityPosture = noAuthorityPosture(),
		noAuthorizationPosture = "decision metadata never authorizes execution",
		noApprovalPosture = "decision metadata never approves execution",
		noRejectionPosture = "decision metadata never rejects execution",
		noExecutionPosture = "decision metadata never executes",
		noRepairPosture = "decision metadata never repairs",
		noOrchestrationPosture = "decision metadata never orchestrates systems",
		noSchedulingPosture = "decision metadata never schedules work",
		noMutationPosture = "decision metadata never mutates upstream runtime state",
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
