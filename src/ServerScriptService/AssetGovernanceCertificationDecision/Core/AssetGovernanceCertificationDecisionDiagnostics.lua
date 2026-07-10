--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationDecisionSerialization)
local State = require(script.Parent.AssetGovernanceCertificationDecisionState)
local Types = require(script.Parent.AssetGovernanceCertificationDecisionTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

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
		["noChapter" .. "Content"] = true,
		noAssetLoading = true,
		noMutableReferences = true,
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
			decisions = limitUsage(counts.decisions, Types.Limits.MaxDecisions),
			requirements = limitUsage(counts.requirements, Types.Limits.MaxRequirements),
			evaluations = limitUsage(counts.evaluations, Types.Limits.MaxEvaluations),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Serialization.deepCopy(Types.Limits),
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		documentationPosture = Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governancePosture = "registered as deterministic decision metadata only",
		decisionRuntimePosture = "evaluates copied governance evidence into metadata only",
		decisionEvaluationPosture = "evaluation records are deterministic metadata and not commands",
		decisionRequirementPosture = "requirement records describe copied evidence obligations only",
		decisionAuditPosture = "audit records review decision metadata only",
		decisionEvidencePosture = Serialization.deepCopy(Types.CertifiedRuntimeOrder),
		decisionIsolationPosture = "diagnostics expose deep-copied decision metadata without handles",
		decisionValidationPosture = "validation occurs before mutation and rejects unsafe payloads",
		decisionMetadataPosture = "decision metadata is evidence only and never permission",
		decisionDocumentationPosture = Serialization.deepCopy(Types.DocumentationFiles),
		decisionIntegrationPosture = "integration readiness metadata is copied evidence only",
		decisionIntegrationHardeningPosture = "integration readiness ordering is exact and self-verifying",
		integrationOrderingPosture = "declarations match certified runtime ordering exactly",
		integrationDeterminismPosture = "declarations compare exact copied evidence, tags, and metadata",
		integrationConsistencyPosture = "runtime, provider, snapshot, Bootstrap, Governance, documentation, and decision identifiers align",
		integrationCompatibilityPosture = "certified governance chain compatibility is declared metadata",
		integrationEvidencePosture = Serialization.deepCopy(Types.IntegrationReadinessDeclarations),
		integrationIsolationPosture = "integration metadata is deep-copied and contains no handles",
		integrationCoveragePosture = "integration readiness covers every certified runtime through inspection",
		integrationValidationPosture = "integration declarations validate before runtime health reports healthy",
		integrationDocumentationPosture = "integration readiness documentation is declared metadata",
		executionReadinessPosture = "future governed execution readiness is copied evidence only",
		executionCompatibilityPosture = "future execution compatibility is structural metadata and not permission",
		executionEvidencePosture = Serialization.deepCopy(Types.ExecutionReadinessDeclarations),
		executionIsolationPosture = "execution-readiness metadata is deep-copied and contains no handles",
		executionCoveragePosture = "execution readiness covers the certified governance chain and Decision Runtime",
		executionValidationPosture = "execution-readiness declarations validate before runtime health reports healthy",
		executionDocumentationPosture = "execution readiness documentation is declared metadata",
		executionReadinessHardeningPosture = "execution-readiness declarations reject drift, reordering, partial coverage, and authority contamination",
		executionOrderingPosture = "execution-readiness declarations match explicit indexed runtime order",
		executionDeterminismPosture = "execution-readiness declarations compare exact copied evidence, tags, metadata, and required flags",
		executionConsistencyPosture = "runtime, provider, snapshot, coordinator, diagnostics, Bootstrap, Governance, documentation, and Decision identifiers align exactly",
		executionBoundaryPosture = "execution readiness remains evidence-only and separate from governance, authorization, routing, dispatch, scheduling, and execution",
		noExecutionAuthorityPosture = "execution readiness never authorizes execution",
		noExecutionRoutingPosture = "execution readiness never routes execution",
		noExecutionDispatchPosture = "execution readiness never dispatches runtime work",
		noExecutionQueuePosture = "execution readiness never creates queues",
		noExecutionMutationPosture = "execution readiness never mutates upstream runtimes",
		integrationReadinessDeclarations = Serialization.deepCopy(
			Types.IntegrationReadinessDeclarations
		),
		executionReadinessDeclarations = Serialization.deepCopy(
			Types.ExecutionReadinessDeclarations
		),
		executionReadinessDeclarationCount = #Types.ExecutionReadinessDeclarations,
		postureKeys = Serialization.deepCopy(Types.PostureKeys),
		noAuthorityPosture = noAuthorityPosture(),
		noAuthorizationPosture = "decision metadata never authorizes execution",
		noApprovalPosture = "decision metadata never approves execution",
		noRejectionPosture = "decision metadata never rejects execution",
		noExecutionPosture = "decision metadata never executes",
		noRepairPosture = "decision metadata never repairs",
		noOrchestrationPosture = "decision metadata never orchestrates systems",
		noSchedulingPosture = "decision metadata never schedules work",
		noMutationPosture = "decision metadata never mutates upstream runtime state",
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = Serialization.diagnosticCopy(lifecycle.lastSelfChecks),
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
