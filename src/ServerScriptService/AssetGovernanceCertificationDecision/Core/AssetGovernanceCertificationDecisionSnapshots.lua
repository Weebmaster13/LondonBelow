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
		postureKeys = dependencies.Serialization.deepCopy(Types.PostureKeys),
		noAuthorityPosture = noAuthorityPosture(),
		noExecutionPosture = "decision metadata never executes",
		noRepairPosture = "decision metadata never repairs",
		noMutationPosture = "decision metadata never mutates upstream runtime state",
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
