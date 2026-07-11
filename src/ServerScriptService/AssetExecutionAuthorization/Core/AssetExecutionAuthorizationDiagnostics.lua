--!strict

local Serialization = require(script.Parent.AssetExecutionAuthorizationSerialization)
local State = require(script.Parent.AssetExecutionAuthorizationState)
local Types = require(script.Parent.AssetExecutionAuthorizationTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

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
		["noData" .. "Store"] = true,
		noHttp = true,
		["noMessaging" .. "Service"] = true,
		noAnalytics = true,
		noTelemetry = true,
		["noWork" .. "spaceMutation"] = true,
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

function Diagnostics.capture(lifecycle: any, dependencies: any)
	local state = State.inspect()
	local counts = state.counts
	local validationOk, validationReason = dependencies.Validation.validate()
	return {
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
			authorizations = limitUsage(counts.authorizations, Types.Limits.MaxAuthorizations),
			requirements = limitUsage(counts.requirements, Types.Limits.MaxRequirements),
			evaluations = limitUsage(counts.evaluations, Types.Limits.MaxEvaluations),
			boundaries = limitUsage(counts.boundaries, Types.Limits.MaxBoundaries),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Serialization.deepCopy(Types.Limits),
		runtimeName = Types.RuntimeName,
		coordinatorName = Types.CoordinatorName,
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governanceSnapshotProviders = Serialization.deepCopy(Types.GovernanceSnapshotProviders),
		identityOrder = Serialization.deepCopy(Types.IdentityOrder),
		authorizationIntegrationDeclarationCount = #Types.AuthorizationIntegrationReadinessDeclarations,
		authorizationIntegrationDeclarationOrder = Serialization.deepCopy(
			Types.IntegrationReadinessDeclarationOrder
		),
		authorizationIntegrationReadinessDeclarations = Serialization.deepCopy(
			Types.AuthorizationIntegrationReadinessDeclarations
		),
		assetExecutionReadinessDeclarationCount = #Types.AssetExecutionReadinessDeclarations,
		assetExecutionReadinessDeclarationOrder = Serialization.deepCopy(
			Types.ExecutionReadinessDeclarationOrder
		),
		assetExecutionReadinessDeclarations = Serialization.deepCopy(
			Types.AssetExecutionReadinessDeclarations
		),
		assetExecutionAuthorizationPosture = "schema-only authorization metadata",
		authorizationRuntimePosture = "authorization records never execute assets",
		authorizationIsolationPosture = "diagnostics expose deep copies only",
		authorizationBoundaryPosture = "boundaries describe prohibited runtime surfaces only",
		authorizationEvaluationPosture = "evaluations are copied review metadata only",
		authorizationAuditPosture = "audits summarize copied authorization metadata only",
		authorizationRequirementPosture = "requirements describe implementation obligations only",
		authorizationIntegrationReadinessPosture = "copied integration-readiness declarations only",
		authorizationIntegrationCompatibilityPosture = "compatibility is metadata only and not permission",
		authorizationIntegrationHardeningPosture = "declarations validate exact fields, values, and order arrays",
		authorizationIntegrationOrderPosture = "each declaration index is checked against frozen order arrays",
		authorizationExecutionSeparationPosture = "future Asset Execution Runtime remains separate",
		authorizationGameplaySeparationPosture = "future gameplay integration remains separate",
		assetExecutionReadinessPosture = "copied execution-readiness declarations only",
		assetExecutionReadinessCompatibilityPosture = "readiness is metadata only and not permission",
		assetExecutionReadinessBoundaryPosture = "readiness proves boundaries without creating runtime surfaces",
		assetExecutionReadinessSeparationPosture = "future Asset Execution Runtime remains separately owned",
		assetExecutionReadinessOrderPosture = "readiness declaration order is deterministic",
		assetExecutionReadinessIsolationPosture = "readiness diagnostics expose deep copies only",
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
		postureKeys = Serialization.deepCopy(Types.PostureKeys),
		schemas = {
			authorizations = state.authorizations,
			requirements = state.requirements,
			evaluations = state.evaluations,
			boundaries = state.boundaries,
			audits = state.audits,
		},
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = Serialization.diagnosticCopy(lifecycle.lastSelfChecks),
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
