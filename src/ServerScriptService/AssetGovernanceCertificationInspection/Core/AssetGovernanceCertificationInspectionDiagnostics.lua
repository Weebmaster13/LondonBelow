--!strict

local Serialization = require(script.Parent.AssetGovernanceCertificationInspectionSerialization)
local State = require(script.Parent.AssetGovernanceCertificationInspectionState)
local Types = require(script.Parent.AssetGovernanceCertificationInspectionTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
end

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
			inspections = limitUsage(counts.inspections, Types.Limits.MaxInspections),
			observations = limitUsage(counts.observations, Types.Limits.MaxObservations),
			findings = limitUsage(counts.findings, Types.Limits.MaxFindings),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Serialization.deepCopy(Types.Limits),
		providerPosture = Types.RuntimeProviderName,
		snapshotPosture = Types.SnapshotKind,
		integrationReadinessPosture = Serialization.deepCopy(
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
		inspectionCoveragePosture = Serialization.deepCopy(Types.CertifiedRuntimeOrder),
		documentationPosture = Serialization.deepCopy(Types.DocumentationFiles),
		bootstrapPosture = Serialization.deepCopy(Types.BootstrapDependencyOrder),
		governancePosture = "registered as read-only certification inspection metadata",
		postureKeys = Serialization.deepCopy(Types.PostureKeys),
		noAuthorityPosture = noAuthorityPosture(),
		noRepairPosture = "inspection findings are reports only and never repair records",
		noExecutionPosture = "inspection metadata never authorizes or performs execution",
		noMutationPosture = "inspection state stores copied metadata only and never mutates upstream runtimes",
		diagnosticsIsolationProof = "diagnostics expose copied metadata only",
		snapshotIsolationProof = "snapshots are isolated deep copies of copied inspection metadata",
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = lifecycle.lastSelfChecks,
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
