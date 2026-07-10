--!strict

local Diagnostics = require(script.Parent.AssetGovernanceCertificationIntegrationDiagnostics)
local Serialization = require(script.Parent.AssetGovernanceCertificationIntegrationSerialization)
local Signals = require(script.Parent.AssetGovernanceCertificationIntegrationSignals)
local Snapshots = require(script.Parent.AssetGovernanceCertificationIntegrationSnapshots)
local State = require(script.Parent.AssetGovernanceCertificationIntegrationState)
local Types = require(script.Parent.AssetGovernanceCertificationIntegrationTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationIntegrationValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function integration(id: string): any
	return {
		integrationId = id,
		integrationKind = "CertificationCoordination",
		integrationStatus = "NeedsReview",
		certificationId = "certification." .. id,
		chainId = "chain.seed",
		coordinator = "AssetGovernanceCertificationIntegrationCoordinator",
		integrationVersion = "1",
		reviewIds = {},
		auditIds = {},
		tags = { "certification-integration" },
		schemaType = Types.SchemaType.GovernanceCertificationIntegration,
	}
end

local function chain(id: string): any
	local runtimeNames = {}
	local providerNames = {}
	local readinessIds = {}
	for _, runtime in ipairs(Types.CertifiedRuntimeOrder) do
		table.insert(runtimeNames, runtime.runtimeName)
		table.insert(providerNames, runtime.providerName)
		table.insert(readinessIds, runtime.readinessId)
	end
	return {
		chainId = id,
		integrationId = "integration.seed",
		chainKind = "CertifiedGovernanceChain",
		chainStatus = "NeedsReview",
		runtimeNames = runtimeNames,
		providerNames = providerNames,
		readinessIds = readinessIds,
		required = true,
		summary = "copied metadata only",
		tags = { "certification-integration" },
		schemaType = Types.SchemaType.GovernanceCertificationIntegrationChain,
	}
end

local function review(integrationId: string, id: string, order: number?): any
	local runtime = Types.CertifiedRuntimeOrder[order or 1]
	return {
		reviewId = id,
		integrationId = integrationId,
		runtimeName = runtime.runtimeName,
		providerName = runtime.providerName,
		reviewKind = "CertificationMetadataReview",
		reviewStatus = "NeedsReview",
		summary = "copied metadata only",
		evidence = { runtime.readinessId },
		tags = { "certification-integration" },
		schemaType = Types.SchemaType.GovernanceCertificationIntegrationReview,
	}
end

local function audit(integrationId: string, id: string): any
	return {
		auditId = id,
		integrationId = integrationId,
		auditKind = "IntegrationAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		tags = { "certification-integration" },
		schemaType = Types.SchemaType.GovernanceCertificationIntegrationAudit,
	}
end

local function expect(
	name: string,
	conditionValue: boolean,
	reason: string?,
	checks: { CheckResult }
)
	table.insert(
		checks,
		{ name = name, ok = conditionValue, reason = if conditionValue then nil else reason }
	)
end

local function expectAccept(name: string, ok: boolean, reason: string?, checks: { CheckResult })
	expect(name, ok, reason or "expected acceptance", checks)
end

local function expectReject(name: string, ok: boolean, _reason: string?, checks: { CheckResult })
	expect(name, not ok, "expected rejection", checks)
end

local function withField(schema: any, field: string, value: any): any
	local copy = Serialization.deepCopy(schema)
	copy[field] = value
	return copy
end

local function mapCount(map: { [any]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function expectExactMapKeys(
	name: string,
	map: { [string]: boolean },
	values: { string },
	checks: { CheckResult }
)
	local exact = mapCount(map) == #values
	for _, value in ipairs(values) do
		exact = exact and map[value] == true
	end
	expect(name .. " exact surface matches", exact, "map surface drifted", checks)
end

local function expectExactArray(
	name: string,
	actual: { any },
	expected: { any },
	checks: { CheckResult }
)
	local exact = #actual == #expected
	for index, expectedValue in ipairs(expected) do
		exact = exact and actual[index] == expectedValue
	end
	expect(name .. " exact surface matches", exact, "array surface drifted", checks)
end

local function expectAcceptedValues(
	name: string,
	values: { string },
	makeSchema: (string, number) -> any,
	validate: (any) -> (boolean, string?),
	checks: { CheckResult }
)
	for index, value in ipairs(values) do
		local ok, reason = validate(makeSchema(value, index))
		expectAccept(name .. " accepts " .. value, ok, reason, checks)
	end
end

local function expectMissingFieldRejects(
	name: string,
	schema: any,
	field: string,
	validate: (any) -> (boolean, string?),
	checks: { CheckResult }
)
	local candidate = Serialization.deepCopy(schema)
	candidate[field] = nil
	local ok, reason = validate(candidate)
	expectReject(name .. " missing " .. field .. " rejects", ok, reason, checks)
end

local function makeDeepPayload(depth: number): any
	local root = {}
	local current = root
	for index = 1, depth do
		local nextNode = { index = index }
		current.next = nextNode
		current = nextNode
	end
	return root
end

local function makeWidePayload(nodes: number): any
	local root = {}
	for index = 1, nodes do
		root["node" .. tostring(index)] = { index = index }
	end
	return root
end

local function expectedForbiddenMarkers(): { string }
	return {
		"load" .. "Asset",
		"preload" .. "Asset",
		"content" .. "Provider",
		"preload" .. "Async",
		"insert" .. "Service",
		"marketplace" .. "Service",
		"stream" .. "Asset",
		"modelSpawn",
		"assetApplication",
		"assetPlayback",
		"createUI",
		"vfxCreate",
		"particleCreate",
		"animationLoad",
		"soundLoad",
		"meshLoad",
		"textureLoad",
		"materialLoad",
		"decalLoad",
		"work" .. "space",
		"replicated" .. "Storage",
		"server" .. "Storage",
		"remote" .. "Event",
		"remote" .. "Function",
		"fire" .. "Client",
		"fire" .. "AllClients",
		"invoke" .. "Client",
		"clientAuthority",
		"data" .. "Store",
		"http" .. "Service",
		"messaging" .. "Service",
		"ana" .. "lytics",
		"tele" .. "metry",
		"gameplayExecution",
		"presentationExecution",
		"saveExecution",
		"chapterContent",
		"mapLoad",
		"roomLoad",
		"dia" .. "logue",
		"cut" .. "scene",
		"callback",
		"eventListener",
		"serviceHandle",
		"runtimeHandle",
		"assetHandle",
		"loadedAsset",
		"moduleReference",
		"executionAdapter",
		"execute",
		"dispatch",
		"publish",
		"subscribe",
		"orchestrate",
		"schedule",
		"authorizeExecution",
		"repairRuntime",
		"liveInspection",
		"liveRuntime",
	}
end

local function fillLimit(
	label: string,
	limit: number,
	makeSchema: (number) -> any,
	register: (any) -> (boolean, string?),
	checks: { CheckResult }
)
	for index = 1, limit do
		local ok, reason = register(makeSchema(index))
		if not ok then
			expect(label .. " fill accepts " .. tostring(index), false, reason, checks)
			return
		end
		expect(label .. " fill accepts " .. tostring(index), true, nil, checks)
	end
	local overflowOk, overflowReason = register(makeSchema(limit + 1))
	expectReject(label .. " limit rejects", overflowOk, overflowReason, checks)
end

function SelfChecks.run(_context: any): any
	local checks: { CheckResult } = {}

	State.clear()
	expect(
		"provider name matches",
		Types.RuntimeProviderName == "assetGovernanceCertificationIntegrationRuntime",
		"provider drifted",
		checks
	)
	expect(
		"mode matches",
		Types.Mode == "ServerAuthoritativeAssetGovernanceCertificationIntegrationMetadataRuntime",
		"mode drifted",
		checks
	)
	expect(
		"snapshot kind matches",
		Types.SnapshotKind == Types.RuntimeProviderName .. "Snapshot",
		"snapshot kind drifted",
		checks
	)
	expect(
		"system schema type exists",
		Types.SchemaType.SystemAssetGovernanceCertificationIntegrationSchema
			== "SystemAssetGovernanceCertificationIntegrationSchema",
		"system schema type drifted",
		checks
	)

	local coldDiagnostics = Diagnostics.capture(
		{ initialized = false, started = false, lastSelfChecks = nil },
		{ Validation = Validation }
	)
	expect(
		"diagnostic provider posture matches",
		coldDiagnostics.providerPosture == Types.RuntimeProviderName,
		"diagnostic provider drifted",
		checks
	)
	expect(
		"diagnostic snapshot posture matches",
		coldDiagnostics.snapshotPosture == Types.SnapshotKind,
		"diagnostic snapshot posture drifted",
		checks
	)
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			"diagnostic posture key exists " .. key,
			coldDiagnostics[key] ~= nil,
			"diagnostic posture key missing",
			checks
		)
	end
	expect(
		"diagnostic certified governance chain is isolated",
		coldDiagnostics.certifiedGovernanceChain ~= Types.CertifiedRuntimeOrder,
		"diagnostic chain reused runtime table",
		checks
	)
	for index, runtime in ipairs(Types.CertifiedRuntimeOrder) do
		expect(
			"diagnostic chain runtime copy isolated " .. runtime.runtimeName,
			coldDiagnostics.certifiedGovernanceChain[index] ~= runtime,
			"diagnostic chain runtime reused table",
			checks
		)
	end
	expect(
		"diagnostic bootstrap posture is isolated",
		coldDiagnostics.bootstrapPosture ~= Types.BootstrapDependencyOrder,
		"diagnostic bootstrap reused table",
		checks
	)
	for index, coordinatorName in ipairs(Types.BootstrapDependencyOrder) do
		expect(
			"diagnostic bootstrap entry matches " .. coordinatorName,
			coldDiagnostics.bootstrapPosture[index] == coordinatorName,
			"diagnostic bootstrap entry drifted",
			checks
		)
	end
	expect(
		"diagnostic documentation posture is isolated",
		coldDiagnostics.documentationPosture ~= Types.DocumentationFiles,
		"diagnostic docs reused table",
		checks
	)
	for index, documentName in ipairs(Types.DocumentationFiles) do
		expect(
			"diagnostic documentation entry matches " .. documentName,
			coldDiagnostics.documentationPosture[index] == documentName,
			"diagnostic documentation entry drifted",
			checks
		)
	end
	expect(
		"diagnostic runtime limits are isolated",
		coldDiagnostics.runtimeLimits ~= Types.Limits,
		"diagnostic limits reused table",
		checks
	)
	for name, usage in pairs(coldDiagnostics.limitUsage) do
		expect(
			"diagnostic limit usage remaining non-negative: " .. name,
			usage.remaining >= 0 and usage.limit >= usage.count,
			"limit usage drifted",
			checks
		)
	end
	for key, expected in pairs({
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
		noLiveInspection = true,
		noRepair = true,
		noMutation = true,
		noOrchestration = true,
		noScheduling = true,
		noExecutionAuthorization = true,
	}) do
		expect(
			"diagnostic no-authority posture " .. key,
			coldDiagnostics.noAuthorityPosture[key] == expected,
			"diagnostic no-authority posture drifted",
			checks
		)
	end

	for name, signal in pairs({
		GovernanceCertificationIntegrationRegistered = "AssetGovernanceCertificationIntegration.GovernanceCertificationIntegrationRegistered",
		GovernanceCertificationIntegrationChainRegistered = "AssetGovernanceCertificationIntegration.GovernanceCertificationIntegrationChainRegistered",
		GovernanceCertificationIntegrationReviewRegistered = "AssetGovernanceCertificationIntegration.GovernanceCertificationIntegrationReviewRegistered",
		GovernanceCertificationIntegrationAuditRegistered = "AssetGovernanceCertificationIntegration.GovernanceCertificationIntegrationAuditRegistered",
		ValidationRejected = "AssetGovernanceCertificationIntegration.ValidationRejected",
		SnapshotCaptured = "AssetGovernanceCertificationIntegration.SnapshotCaptured",
	}) do
		expect("signal name matches " .. name, Signals[name] == signal, "signal drifted", checks)
	end

	expectExactArray("integration fields", Types.SchemaFields.GovernanceCertificationIntegration, {
		"integrationId",
		"integrationKind",
		"integrationStatus",
		"certificationId",
		"chainId",
		"reviewIds",
		"auditIds",
		"coordinator",
		"integrationVersion",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("chain fields", Types.SchemaFields.GovernanceCertificationIntegrationChain, {
		"chainId",
		"integrationId",
		"chainKind",
		"chainStatus",
		"runtimeNames",
		"providerNames",
		"readinessIds",
		"required",
		"summary",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("review fields", Types.SchemaFields.GovernanceCertificationIntegrationReview, {
		"reviewId",
		"integrationId",
		"runtimeName",
		"providerName",
		"reviewKind",
		"reviewStatus",
		"summary",
		"evidence",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("audit fields", Types.SchemaFields.GovernanceCertificationIntegrationAudit, {
		"auditId",
		"integrationId",
		"auditKind",
		"reviewer",
		"status",
		"findings",
		"tags",
		"metadata",
	}, checks)
	expectExactArray("posture keys", Types.PostureKeys, {
		"certificationIntegrationCoordinationPosture",
		"copiedCertificationMetadataPosture",
		"copiedDependencyMetadataPosture",
		"copiedReadinessMetadataPosture",
		"copiedProviderMetadataPosture",
		"copiedBootstrapMetadataPosture",
		"copiedDocumentationMetadataPosture",
		"copiedCompatibilityMetadataPosture",
		"certifiedGovernanceChain",
	}, checks)

	expectExactMapKeys("integrationKind", Types.IntegrationKind, {
		"CertificationCoordination",
		"DependencyCoordination",
		"ReadinessCoordination",
		"ProviderCoordination",
		"BootstrapCoordination",
		"DocumentationCoordination",
		"CompatibilityCoordination",
		"FutureCoordination",
	}, checks)
	expectExactMapKeys("integrationStatus", Types.IntegrationStatus, {
		"Draft",
		"Ready",
		"Coordinated",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, checks)
	expectExactMapKeys("chainKind", Types.ChainKind, {
		"CertifiedGovernanceChain",
		"CertificationDependencyChain",
		"CertificationReadinessChain",
		"ProviderMetadataChain",
		"BootstrapMetadataChain",
		"DocumentationMetadataChain",
		"CompatibilityMetadataChain",
		"FutureMetadataChain",
	}, checks)
	expectExactMapKeys("chainStatus", Types.ChainStatus, {
		"Ready",
		"Coordinated",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, checks)
	expectExactMapKeys("reviewKind", Types.ReviewKind, {
		"CertificationMetadataReview",
		"DependencyMetadataReview",
		"ReadinessMetadataReview",
		"ProviderMetadataReview",
		"BootstrapMetadataReview",
		"DocumentationMetadataReview",
		"CompatibilityMetadataReview",
		"FutureMetadataReview",
	}, checks)
	expectExactMapKeys("reviewStatus", Types.ReviewStatus, {
		"Passed",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, checks)
	expectExactMapKeys("auditKind", Types.AuditKind, {
		"IntegrationAudit",
		"ChainAudit",
		"CertificationAudit",
		"ReadinessAudit",
		"ProviderAudit",
		"ProductionAudit",
		"FutureAudit",
	}, checks)
	expectExactMapKeys("auditStatus", Types.AuditStatus, {
		"Passed",
		"Failed",
		"Warning",
		"Deferred",
		"Blocked",
	}, checks)

	expectAcceptedValues("integrationKind", {
		"CertificationCoordination",
		"DependencyCoordination",
		"ReadinessCoordination",
		"ProviderCoordination",
		"BootstrapCoordination",
		"DocumentationCoordination",
		"CompatibilityCoordination",
		"FutureCoordination",
	}, function(value)
		return withField(integration("enum.integration.kind." .. value), "integrationKind", value)
	end, Validation.integration, checks)
	expectAcceptedValues("integrationStatus", {
		"Draft",
		"Ready",
		"Coordinated",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, function(value)
		return withField(
			integration("enum.integration.status." .. value),
			"integrationStatus",
			value
		)
	end, Validation.integration, checks)
	expectAcceptedValues("chainKind", {
		"CertifiedGovernanceChain",
		"CertificationDependencyChain",
		"CertificationReadinessChain",
		"ProviderMetadataChain",
		"BootstrapMetadataChain",
		"DocumentationMetadataChain",
		"CompatibilityMetadataChain",
		"FutureMetadataChain",
	}, function(value)
		return withField(chain("enum.chain.kind." .. value), "chainKind", value)
	end, Validation.chain, checks)
	expectAcceptedValues("chainStatus", {
		"Ready",
		"Coordinated",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, function(value)
		return withField(chain("enum.chain.status." .. value), "chainStatus", value)
	end, Validation.chain, checks)
	expectAcceptedValues("reviewKind", {
		"CertificationMetadataReview",
		"DependencyMetadataReview",
		"ReadinessMetadataReview",
		"ProviderMetadataReview",
		"BootstrapMetadataReview",
		"DocumentationMetadataReview",
		"CompatibilityMetadataReview",
		"FutureMetadataReview",
	}, function(value, index)
		return withField(
			review("integration.seed", "enum.review.kind." .. tostring(index)),
			"reviewKind",
			value
		)
	end, Validation.review, checks)
	expectAcceptedValues("reviewStatus", {
		"Passed",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, function(value, index)
		return withField(
			review("integration.seed", "enum.review.status." .. tostring(index)),
			"reviewStatus",
			value
		)
	end, Validation.review, checks)
	expectAcceptedValues("auditKind", {
		"IntegrationAudit",
		"ChainAudit",
		"CertificationAudit",
		"ReadinessAudit",
		"ProviderAudit",
		"ProductionAudit",
		"FutureAudit",
	}, function(value, index)
		return withField(
			audit("integration.seed", "enum.audit.kind." .. tostring(index)),
			"auditKind",
			value
		)
	end, Validation.audit, checks)
	expectAcceptedValues("auditStatus", {
		"Passed",
		"Failed",
		"Warning",
		"Deferred",
		"Blocked",
	}, function(value, index)
		return withField(
			audit("integration.seed", "enum.audit.status." .. tostring(index)),
			"status",
			value
		)
	end, Validation.audit, checks)

	for _, field in ipairs(Types.SchemaFields.GovernanceCertificationIntegration) do
		if
			field ~= "reviewIds"
			and field ~= "auditIds"
			and field ~= "tags"
			and field ~= "metadata"
		then
			expectMissingFieldRejects(
				"integration",
				integration("missing.integration"),
				field,
				Validation.integration,
				checks
			)
		end
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceCertificationIntegrationChain) do
		if field ~= "tags" and field ~= "metadata" then
			expectMissingFieldRejects(
				"chain",
				chain("missing.chain"),
				field,
				Validation.chain,
				checks
			)
		end
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceCertificationIntegrationReview) do
		if field ~= "evidence" and field ~= "tags" and field ~= "metadata" then
			expectMissingFieldRejects(
				"review",
				review("integration.seed", "missing.review"),
				field,
				Validation.review,
				checks
			)
		end
	end
	for _, field in ipairs(Types.SchemaFields.GovernanceCertificationIntegrationAudit) do
		if field ~= "findings" and field ~= "tags" and field ~= "metadata" then
			expectMissingFieldRejects(
				"audit",
				audit("integration.seed", "missing.audit"),
				field,
				Validation.audit,
				checks
			)
		end
	end

	for order, runtime in ipairs(Types.CertifiedRuntimeOrder) do
		expect(
			"runtime order maps " .. runtime.runtimeName,
			Types.RuntimeName[runtime.runtimeName] == order,
			"runtime order drifted",
			checks
		)
		expect(
			"provider order maps " .. runtime.providerName,
			Types.ProviderName[runtime.providerName] == order,
			"provider order drifted",
			checks
		)
		expect(
			"coordinator order maps " .. runtime.coordinatorName,
			Types.CoordinatorName[runtime.coordinatorName] == order,
			"coordinator order drifted",
			checks
		)
		expect(
			"readiness order maps " .. runtime.readinessId,
			Types.ReadinessId[runtime.readinessId] == order,
			"readiness order drifted",
			checks
		)
		expect(
			"bootstrap order maps " .. runtime.coordinatorName,
			Types.BootstrapDependencyOrder[order] == runtime.coordinatorName,
			"Bootstrap order drifted",
			checks
		)
		expectAccept(
			"review accepts runtime/provider pair " .. runtime.runtimeName,
			Validation.review(review("integration.seed", "review." .. tostring(order), order)),
			nil,
			checks
		)
		expectReject(
			"review rejects provider mismatch " .. runtime.runtimeName,
			Validation.review(
				withField(
					review("integration.seed", "review.bad." .. tostring(order), order),
					"providerName",
					Types.CertifiedRuntimeOrder[(order % #Types.CertifiedRuntimeOrder) + 1].providerName
				)
			),
			nil,
			checks
		)
	end

	local baseChain = chain("chain.validation")
	expectAccept("chain validates", Validation.chain(baseChain), nil, checks)
	expectReject(
		"chain rejects runtime order drift",
		Validation.chain(
			withField(baseChain, "runtimeNames", { "AssetUsagePlan", "AssetManifest" })
		),
		nil,
		checks
	)
	expectReject(
		"chain rejects provider order drift",
		Validation.chain(
			withField(
				baseChain,
				"providerNames",
				{ "assetUsagePlanRuntime", "assetManifestRuntime" }
			)
		),
		nil,
		checks
	)
	expectReject(
		"chain rejects readiness order drift",
		Validation.chain(
			withField(
				baseChain,
				"readinessIds",
				{ "assetUsagePlan.integrationReadiness", "assetManifest.integrationReadiness" }
			)
		),
		nil,
		checks
	)
	local truncatedRuntimeNames = Serialization.deepCopy(baseChain.runtimeNames)
	table.remove(truncatedRuntimeNames, #truncatedRuntimeNames)
	expectReject(
		"chain rejects truncated runtimeNames",
		Validation.chain(withField(baseChain, "runtimeNames", truncatedRuntimeNames)),
		nil,
		checks
	)
	local truncatedProviderNames = Serialization.deepCopy(baseChain.providerNames)
	table.remove(truncatedProviderNames, #truncatedProviderNames)
	expectReject(
		"chain rejects truncated providerNames",
		Validation.chain(withField(baseChain, "providerNames", truncatedProviderNames)),
		nil,
		checks
	)
	local truncatedReadinessIds = Serialization.deepCopy(baseChain.readinessIds)
	table.remove(truncatedReadinessIds, #truncatedReadinessIds)
	expectReject(
		"chain rejects truncated readinessIds",
		Validation.chain(withField(baseChain, "readinessIds", truncatedReadinessIds)),
		nil,
		checks
	)
	expectReject(
		"integration rejects unsupported coordinator",
		Validation.integration(
			withField(
				integration("bad.coordinator"),
				"coordinator",
				"AssetGovernanceCertificationCoordinator"
			)
		),
		nil,
		checks
	)
	expectReject("integration rejects non-table schema", Validation.integration("bad"), nil, checks)
	expectReject(
		"chain rejects non-boolean required",
		Validation.chain(withField(baseChain, "required", "true")),
		nil,
		checks
	)
	expectReject(
		"review rejects unknown runtime",
		Validation.review(
			withField(review("integration.seed", "bad.runtime"), "runtimeName", "UnknownRuntime")
		),
		nil,
		checks
	)

	for limitName, expectedValue in pairs({
		MaxIntegrations = 40,
		MaxChains = 120,
		MaxReviews = 530,
		MaxAudits = 300,
		MaxValidationFailures = 240,
		MaxSnapshotHistory = 60,
		MaxPayloadDepth = 8,
		MaxPayloadNodes = 450,
		MaxStringLength = 280,
		MaxTags = 32,
		MaxAuditFindings = 40,
		MaxReviewEvidence = 40,
		MaxIntegrationChildren = 180,
		MaxChainEntries = 120,
	}) do
		expect(
			"runtime limit matches " .. limitName,
			Types.Limits[limitName] == expectedValue,
			"limit drifted",
			checks
		)
	end
	expectExactArray("documentation references", Types.DocumentationFiles, {
		"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_RUNTIME.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_VALIDATION.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_SERIALIZATION.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_DIAGNOSTICS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_SELF_CHECKS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_RUNTIME_LIMITS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_AUDIT.md",
		"ASSET_GOVERNANCE_CERTIFICATION_INTEGRATION_PRODUCTION_REVIEW.md",
		"GOVERNANCE_CERTIFICATION_INTEGRATION_RUNTIME.md",
		"GOVERNANCE_CERTIFICATION_INTEGRATION_CHAIN_RUNTIME.md",
		"GOVERNANCE_CERTIFICATION_INTEGRATION_REVIEW_RUNTIME.md",
		"GOVERNANCE_CERTIFICATION_INTEGRATION_AUDIT_RUNTIME.md",
	}, checks)
	local seenDocuments = {}
	for _, documentName in ipairs(Types.DocumentationFiles) do
		expectAccept(
			"documentation reference serializes " .. documentName,
			Serialization.validateSerializable({ documentName = documentName }),
			nil,
			checks
		)
		expect(
			"documentation reference unique " .. documentName,
			seenDocuments[documentName] ~= true,
			"duplicate documentation reference",
			checks
		)
		seenDocuments[documentName] = true
	end

	local cycle = {}
	cycle.self = cycle
	expectReject(
		"serialization rejects cycles",
		Serialization.validateSerializable(cycle),
		nil,
		checks
	)
	expectReject(
		"serialization rejects functions",
		Serialization.validateSerializable({ unsafe = function() end }),
		nil,
		checks
	)
	expectReject(
		"serialization rejects threads",
		Serialization.validateSerializable({ unsafe = coroutine.create(function() end) }),
		nil,
		checks
	)
	local userdataOk, userdataValue = pcall(function()
		return newproxy(false)
	end)
	if userdataOk then
		expectReject(
			"serialization rejects userdata",
			Serialization.validateSerializable({ unsafe = userdataValue }),
			nil,
			checks
		)
	else
		expect("serialization userdata check unavailable in runner", true, nil, checks)
	end
	expectReject(
		"serialization rejects instance-shaped tables",
		Serialization.validateSerializable({ ClassName = "Part", Parent = {} }),
		nil,
		checks
	)
	expectReject(
		"serialization rejects oversized strings",
		Serialization.validateSerializable({
			value = string.rep("x", Types.Limits.MaxStringLength + 1),
		}),
		nil,
		checks
	)
	expectReject(
		"serialization rejects deep payloads",
		Serialization.validateSerializable(makeDeepPayload(Types.Limits.MaxPayloadDepth + 2)),
		nil,
		checks
	)
	expectReject(
		"serialization rejects oversized node counts",
		Serialization.validateSerializable(makeWidePayload(Types.Limits.MaxPayloadNodes + 1)),
		nil,
		checks
	)
	for _, marker in ipairs(expectedForbiddenMarkers()) do
		expectReject(
			"forbidden marker key rejects " .. marker,
			Serialization.validateSerializable({ [marker] = true }),
			nil,
			checks
		)
		expectReject(
			"forbidden marker value rejects " .. marker,
			Serialization.validateSerializable({ marker = marker }),
			nil,
			checks
		)
		expect(
			"diagnostic copy sanitizes marker " .. marker,
			Serialization.diagnosticCopy({ [marker] = true })["<unsafe-marker>"] == true,
			"diagnostic copy leaked marker",
			checks
		)
		expectReject(
			"integration metadata rejects marker " .. marker,
			Validation.integration(
				withField(
					integration("marker.integration." .. marker),
					"metadata",
					{ [marker] = true }
				)
			),
			nil,
			checks
		)
		expectReject(
			"chain metadata rejects marker " .. marker,
			Validation.chain(
				withField(chain("marker.chain." .. marker), "metadata", { [marker] = true })
			),
			nil,
			checks
		)
		expectReject(
			"review metadata rejects marker " .. marker,
			Validation.review(
				withField(
					review("integration.seed", "marker.review." .. marker),
					"metadata",
					{ [marker] = true }
				)
			),
			nil,
			checks
		)
		expectReject(
			"audit metadata rejects marker " .. marker,
			Validation.audit(
				withField(
					audit("integration.seed", "marker.audit." .. marker),
					"metadata",
					{ [marker] = true }
				)
			),
			nil,
			checks
		)
	end

	State.clear()
	expectAccept("seed chain registers", State.registerChain(chain("chain.seed")), nil, checks)
	local before = State.inspect().counts.integrations
	local badOk, badReason = State.registerIntegration(
		withField(integration("bad.no.mutate"), "integrationId", "bad id")
	)
	if not badOk then
		State.recordValidationFailure(
			badReason or "failed",
			withField(integration("bad.no.mutate"), "integrationId", "bad id")
		)
	end
	expect(
		"failed validation does not mutate counts",
		State.inspect().counts.integrations == before,
		"counts changed",
		checks
	)
	expectAccept(
		"namespace reusable after failed validation",
		State.registerIntegration(integration("bad.no.mutate")),
		nil,
		checks
	)
	expect(
		"failed validation records failure",
		State.inspect().counts.validationFailures == 1,
		"failure missing",
		checks
	)

	State.clear()
	expectAccept(
		"limit seed chain registers",
		State.registerChain(chain("chain.seed")),
		nil,
		checks
	)
	fillLimit("integration", Types.Limits.MaxIntegrations, function(index)
		return integration("limit.integration." .. tostring(index))
	end, State.registerIntegration, checks)
	State.clear()
	fillLimit("chain", Types.Limits.MaxChains, function(index)
		return chain("limit.chain." .. tostring(index))
	end, State.registerChain, checks)
	State.clear()
	fillLimit("review", Types.Limits.MaxReviews, function(index)
		return review(
			"integration.seed",
			"limit.review." .. tostring(index),
			((index - 1) % #Types.CertifiedRuntimeOrder) + 1
		)
	end, State.registerReview, checks)
	State.clear()
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("integration.seed", "limit.audit." .. tostring(index))
	end, State.registerAudit, checks)
	for index = 1, Types.Limits.MaxValidationFailures + 10 do
		State.recordValidationFailure("failure." .. tostring(index), { index = index })
	end
	expect(
		"validation failures are bounded",
		State.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
		"failure history exceeded",
		checks
	)
	for index = 1, Types.Limits.MaxSnapshotHistory + 10 do
		State.recordSnapshot({ index = index })
	end
	expect(
		"snapshots are bounded",
		State.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
		"snapshot history exceeded",
		checks
	)

	State.clear()
	expectAccept(
		"isolation chain registers",
		State.registerChain(chain("snapshot.chain")),
		nil,
		checks
	)
	local stateSnapshot = State.inspect()
	stateSnapshot.chains["snapshot.chain"].chainStatus = "mutated"
	expect(
		"state inspect is isolated",
		State.inspect().chains["snapshot.chain"].chainStatus ~= "mutated",
		"state leaked",
		checks
	)
	local capturedDiagnostics = Diagnostics.capture(
		{ initialized = true, started = false, lastSelfChecks = nil },
		{ Validation = Validation }
	)
	capturedDiagnostics.counts.chains = 999
	expect(
		"diagnostics are isolated",
		Diagnostics.capture(
			{ initialized = true, started = false, lastSelfChecks = nil },
			{ Validation = Validation }
		).counts.chains ~= 999,
		"diagnostics leaked",
		checks
	)
	expectAccept(
		"diagnostics serialize",
		Serialization.validateSerializable(capturedDiagnostics),
		nil,
		checks
	)
	local capturedSnapshot = Snapshots.capture(
		{ initialized = true, started = false },
		{ Serialization = Serialization }
	)
	expect(
		"snapshot kind matches",
		capturedSnapshot.kind == Types.SnapshotKind,
		"snapshot kind drifted",
		checks
	)
	expect(
		"snapshot provider posture matches",
		capturedSnapshot.providerPosture == Types.RuntimeProviderName,
		"snapshot provider posture drifted",
		checks
	)
	expect(
		"snapshot snapshot posture matches",
		capturedSnapshot.snapshotPosture == Types.SnapshotKind,
		"snapshot posture drifted",
		checks
	)
	expect(
		"snapshot certified chain isolated",
		capturedSnapshot.certifiedGovernanceChain ~= Types.CertifiedRuntimeOrder,
		"snapshot chain reused table",
		checks
	)
	for index, runtime in ipairs(Types.CertifiedRuntimeOrder) do
		expect(
			"snapshot chain runtime copy isolated " .. runtime.runtimeName,
			capturedSnapshot.certifiedGovernanceChain[index] ~= runtime,
			"snapshot chain runtime reused table",
			checks
		)
	end
	for _, key in ipairs(Types.PostureKeys) do
		expect(
			"snapshot posture key exists " .. key,
			capturedSnapshot[key] ~= nil,
			"snapshot posture key missing",
			checks
		)
	end
	capturedSnapshot.schemas.chains["snapshot.chain"].chainStatus = "mutated"
	expect(
		"snapshot is isolated",
		State.inspect().chains["snapshot.chain"].chainStatus ~= "mutated",
		"snapshot leaked",
		checks
	)
	expectAccept(
		"snapshot serializes",
		Serialization.validateSerializable(capturedSnapshot),
		nil,
		checks
	)
	State.clear()
	local clearedCounts = State.inspect().counts
	expect(
		"shutdown clears state",
		clearedCounts.integrations == 0
			and clearedCounts.chains == 0
			and clearedCounts.reviews == 0
			and clearedCounts.audits == 0
			and clearedCounts.validationFailures == 0
			and clearedCounts.snapshots == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerChain(chain("chain.seed")),
		nil,
		checks
	)
	State.clear()

	local failed = {}
	for _, checkResult in ipairs(checks) do
		if not checkResult.ok then
			table.insert(failed, checkResult)
		end
	end
	return {
		ok = #failed == 0,
		code = if #failed == 0
			then "AssetGovernanceCertificationIntegrationSelfChecksPassed"
			else "AssetGovernanceCertificationIntegrationSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
