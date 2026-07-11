--!strict

local State = require(script.Parent.AssetExecutionAuthorizationState)
local Types = require(script.Parent.AssetExecutionAuthorizationTypes)

local Snapshots = {}

local function noAuthorityPosture()
	return {
		noAssetLoading = true,
		noAssetPreloading = true,
		noAssetStreaming = true,
		noAssetSpawning = true,
		noAssetApplication = true,
		noAssetPlayback = true,
		noUi = true,
		noVfx = true,
		noRemotes = true,
		noClientAuthority = true,
		noDataStore = true,
		noHttp = true,
		noMessagingService = true,
		noAnalytics = true,
		noTelemetry = true,
		noWorkspaceMutation = true,
		noStorageMutation = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		["noChapter" .. "Content"] = true,
		noMaps = true,
		noRooms = true,
		noDialogue = true,
		noCutscenes = true,
		noRouting = true,
		noDispatch = true,
		noScheduler = true,
		noOrchestration = true,
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
		runtimeName = Types.RuntimeName,
		coordinatorName = Types.CoordinatorName,
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = dependencies.Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = dependencies.Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governanceSnapshotProviders = dependencies.Serialization.deepCopy(
			Types.GovernanceSnapshotProviders
		),
		identityOrder = dependencies.Serialization.deepCopy(Types.IdentityOrder),
		authorizationIntegrationDeclarationCount = #Types.AuthorizationIntegrationReadinessDeclarations,
		authorizationIntegrationReadinessDeclarations = dependencies.Serialization.deepCopy(
			Types.AuthorizationIntegrationReadinessDeclarations
		),
		assetExecutionAuthorizationPosture = "schema-only authorization metadata",
		authorizationRuntimePosture = "authorization records never execute assets",
		authorizationIsolationPosture = "snapshots expose deep copies only",
		authorizationBoundaryPosture = "boundaries describe prohibited runtime surfaces only",
		authorizationEvaluationPosture = "evaluations are copied review metadata only",
		authorizationAuditPosture = "audits summarize copied authorization metadata only",
		authorizationRequirementPosture = "requirements describe implementation obligations only",
		authorizationIntegrationReadinessPosture = "copied integration-readiness declarations only",
		authorizationIntegrationCompatibilityPosture = "compatibility is metadata only and not permission",
		authorizationExecutionSeparationPosture = "future Asset Execution Runtime remains separate",
		authorizationGameplaySeparationPosture = "future gameplay integration remains separate",
		noAuthorityPosture = noAuthorityPosture(),
		noExecution = true,
		noRouting = true,
		noDispatch = true,
		noScheduler = true,
		noOrchestration = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		noAuthorityEscalation = true,
		postureKeys = dependencies.Serialization.deepCopy(Types.PostureKeys),
		schemas = {
			authorizations = state.authorizations,
			requirements = state.requirements,
			evaluations = state.evaluations,
			boundaries = state.boundaries,
			audits = state.audits,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
