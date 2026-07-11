--!strict

local State = require(script.Parent.AssetExecutionGovernanceState)
local Types = require(script.Parent.AssetExecutionGovernanceTypes)

local Snapshots = {}

local function noAuthorityPosture()
	return {
		noAssetLoading = true,
		noAssetApplication = true,
		noAssetPlayback = true,
		noAuthorization = true,
		noOperationalRejection = true,
		noPermission = true,
		noRouting = true,
		noDispatch = true,
		noQueueing = true,
		noScheduling = true,
		noOrchestration = true,
		noMutation = true,
		noNetworking = true,
		noPersistence = true,
		noClientAuthority = true,
		noGameplay = true,
		noPresentation = true,
		noSave = true,
		["noChapter" .. "Content"] = true,
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
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = dependencies.Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = dependencies.Serialization.deepCopy(Types.BootstrapDependencyOrder),
		integrationReadinessDeclarationCount = #Types.IntegrationReadinessDeclarations,
		integrationReadinessDeclarations = dependencies.Serialization.deepCopy(
			Types.IntegrationReadinessDeclarations
		),
		assetExecutionGovernancePosture = "metadata-only governance eligibility records",
		governanceMetadataPosture = "statuses are descriptive metadata and not permission",
		governanceRequirementPosture = "requirements describe copied obligations only",
		governanceAssessmentPosture = "assessments record copied review outcomes only",
		governanceFindingPosture = "findings are review metadata and not live blockers",
		governanceAuditPosture = "audits summarize copied governance metadata only",
		governanceBoundaryPosture = "future authorization and asset execution remain separate runtimes",
		governanceIsolationPosture = "snapshots are deep-copied and contain no live handles",
		governanceValidationPosture = "validation occurs before state mutation",
		integrationReadinessPosture = "copied integration-readiness declarations only",
		integrationDeclarationPosture = "declarations are ordered static compatibility metadata",
		decisionRuntimeCompatibilityPosture = "decision runtime identity is copied for comparison",
		executionReadinessCompatibilityPosture = "future execution-readiness evidence remains copied metadata",
		executionGovernanceCompatibilityPosture = "execution governance identity matches this runtime",
		futureAuthorizationSeparationPosture = "future authorization remains a separate layer",
		futureExecutionSeparationPosture = "future execution remains a separate layer",
		integrationHardeningPosture = "integration readiness is exact copied metadata only",
		declarationOrderingPosture = "declaration ids and compatibility ids follow fixed order",
		declarationImmutabilityPosture = "returned declarations are deep copies",
		compatibilityIdentityPosture = "runtime, provider, snapshot, and coordinator identities are exact",
		runtimeLimitIsolationPosture = "runtime limits are copied before exposure",
		noAuthorityPosture = noAuthorityPosture(),
		noAuthorizationPosture = "governance records never grant asset authority",
		noOperationalRejectionPosture = "unsatisfied and blocked statuses never reject live work",
		noPermissionPosture = "satisfied and passed statuses never grant permission",
		noRoutingPosture = "governance records never route runtime work",
		noDispatchPosture = "governance records never dispatch runtime work",
		noQueuePosture = "governance records never create runtime queues",
		noSchedulingPosture = "governance records never schedule runtime work",
		noOrchestrationPosture = "governance records never orchestrate systems",
		noExecutionPosture = "governance records never execute assets",
		noMutationPosture = "governance records never mutate external state",
		postureKeys = dependencies.Serialization.deepCopy(Types.PostureKeys),
		schemas = {
			governance = state.governance,
			requirements = state.requirements,
			assessments = state.assessments,
			findings = state.findings,
			audits = state.audits,
		},
		validationFailures = state.validationFailures,
	}
	State.recordSnapshot(snapshot)
	return dependencies.Serialization.deepCopy(snapshot)
end

return Snapshots
