--!strict

local State = require(script.Parent.AssetGovernanceCertificationInspectionState)
local Types = require(script.Parent.AssetGovernanceCertificationInspectionTypes)

local Snapshots = {}

local function noAuthorityPosture()
	return {
		noAssetLoad = true,
		noAssetPreload = true,
		noAssetStreaming = true,
		noAssetApplication = true,
		noAssetPlayback = true,
		noModelSpawn = true,
		noUiCreation = true,
		noVfxCreation = true,
		noRemotes = true,
		noClientAuthority = true,
		["no" .. "Data" .. "Store"] = true,
		noHttp = true,
		noMessaging = true,
		noAnalytics = true,
		noTelemetry = true,
		noGameplayRun = true,
		noPresentationRun = true,
		noSaveRun = true,
		noChapterContent = true,
		noRepair = true,
		noMutation = true,
		noOrchestration = true,
		noScheduling = true,
		noExecutionAuthority = true,
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
			inspections = state.inspections,
			observations = state.observations,
			findings = state.findings,
			audits = state.audits,
		},
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		integrationReadinessPosture = dependencies.Serialization.deepCopy(
			Types.IntegrationReadinessDeclarations
		),
		inspectionPosture = "observes copied runtime health metadata only",
		observationPosture = "stores copied diagnostics and snapshot observation metadata only",
		findingPosture = "reports deterministic inconsistency metadata only",
		auditPosture = "records inspection audit metadata only",
		runtimeCompatibilityPosture = "compares copied provider and snapshot posture without authority expansion",
		providerCompatibilityPosture = "validates copied provider names against declared runtime names",
		snapshotCompatibilityPosture = "validates copied snapshot provider names against declared runtime names",
		bootstrapCompatibilityPosture = "remains registered immediately after AssetGovernanceCertificationIntegrationCoordinator",
		governanceCompatibilityPosture = "retains read-only Governance contract and snapshot provider",
		documentationCompatibilityPosture = "documents integration readiness without expanding authority",
		inspectionCoveragePosture = dependencies.Serialization.deepCopy(
			Types.CertifiedRuntimeOrder
		),
		documentationPosture = dependencies.Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = dependencies.Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governancePosture = "registered as read-only certification inspection metadata",
		postureKeys = dependencies.Serialization.deepCopy(Types.PostureKeys),
		noAuthorityPosture = noAuthorityPosture(),
		noRepairPosture = "inspection findings are reports only and never repair records",
		noExecutionPosture = "inspection metadata never authorizes or performs execution",
		noMutationPosture = "inspection state stores copied metadata only and never mutates upstream runtimes",
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
