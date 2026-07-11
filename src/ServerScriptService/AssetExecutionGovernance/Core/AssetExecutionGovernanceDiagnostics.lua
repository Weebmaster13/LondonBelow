--!strict

local Serialization = require(script.Parent.AssetExecutionGovernanceSerialization)
local State = require(script.Parent.AssetExecutionGovernanceState)
local Types = require(script.Parent.AssetExecutionGovernanceTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

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
			governance = limitUsage(counts.governance, Types.Limits.MaxGovernance),
			requirements = limitUsage(counts.requirements, Types.Limits.MaxRequirements),
			assessments = limitUsage(counts.assessments, Types.Limits.MaxAssessments),
			findings = limitUsage(counts.findings, Types.Limits.MaxFindings),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Serialization.deepCopy(Types.Limits),
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = Serialization.deepCopy(Types.BootstrapDependencyOrder),
		integrationReadinessDeclarationCount = #Types.IntegrationReadinessDeclarations,
		integrationReadinessDeclarations = Serialization.deepCopy(
			Types.IntegrationReadinessDeclarations
		),
		assetExecutionGovernancePosture = "metadata-only governance eligibility records",
		governanceMetadataPosture = "statuses are descriptive metadata and not permission",
		governanceRequirementPosture = "requirements describe copied obligations only",
		governanceAssessmentPosture = "assessments record copied review outcomes only",
		governanceFindingPosture = "findings are review metadata and not live blockers",
		governanceAuditPosture = "audits summarize copied governance metadata only",
		governanceBoundaryPosture = "future authorization and asset execution remain separate runtimes",
		governanceIsolationPosture = "diagnostics are deep-copied and contain no live handles",
		governanceValidationPosture = "validation occurs before state mutation",
		integrationReadinessPosture = "copied integration-readiness declarations only",
		integrationDeclarationPosture = "declarations are ordered static compatibility metadata",
		decisionRuntimeCompatibilityPosture = "decision runtime identity is copied for comparison",
		executionReadinessCompatibilityPosture = "future execution-readiness evidence remains copied metadata",
		executionGovernanceCompatibilityPosture = "execution governance identity matches this runtime",
		futureAuthorizationSeparationPosture = "future authorization remains a separate layer",
		futureExecutionSeparationPosture = "future execution remains a separate layer",
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
		postureKeys = Serialization.deepCopy(Types.PostureKeys),
		schemas = {
			governance = state.governance,
			requirements = state.requirements,
			assessments = state.assessments,
			findings = state.findings,
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
