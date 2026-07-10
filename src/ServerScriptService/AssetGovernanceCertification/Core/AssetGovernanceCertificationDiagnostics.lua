--!strict

local State = require(script.Parent.AssetGovernanceCertificationState)
local Types = require(script.Parent.AssetGovernanceCertificationTypes)

local Diagnostics = {}

local function limitUsage(count: number, limit: number)
	return { count = count, limit = limit, remaining = math.max(limit - count, 0) }
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
			certifications = limitUsage(counts.certifications, Types.Limits.MaxCertifications),
			requirements = limitUsage(counts.requirements, Types.Limits.MaxRequirements),
			results = limitUsage(counts.results, Types.Limits.MaxResults),
			audits = limitUsage(counts.audits, Types.Limits.MaxAudits),
		},
		runtimeLimits = Types.Limits,
		assetGovernanceCertificationPosture = "certification metadata eligibility only",
		certificationReadinessPosture = "determines structural eligibility without granting execution permission",
		requirementPosture = "requirements are local certification evidence only",
		reviewPosture = "results and audits are copied review metadata only",
		providerPosture = Types.RuntimeProviderName,
		dependencyPosture = Types.CertifiedRuntimeOrder,
		bootstrapPosture = Types.BootstrapDependencyOrder,
		documentationPosture = Types.DocumentationFiles,
		integrationPosture = "depends on read-only Asset Governance Integration metadata only",
		validationPosture = "validation completes before mutation",
		noExecutionPosture = {
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
		},
		noMutationPosture = {
			noUpstreamMutation = true,
			noRepairMutation = true,
			noStorageMutation = true,
			noWorldMutation = true,
		},
		diagnosticsIsolationProof = "diagnostics expose copied health-only metadata",
		snapshotIsolationProof = "snapshots are isolated deep copies of certification metadata",
		recentValidationFailures = state.validationFailures,
		lastSelfCheckResult = lifecycle.lastSelfChecks,
	}
end

function Diagnostics.validate(dependencies: any): (boolean, string?)
	return dependencies.Validation.validate()
end

return Diagnostics
