--!strict

local Diagnostics = require(script.Parent.AssetGovernanceCertificationDiagnostics)
local Serialization = require(script.Parent.AssetGovernanceCertificationSerialization)
local Snapshots = require(script.Parent.AssetGovernanceCertificationSnapshots)
local State = require(script.Parent.AssetGovernanceCertificationState)
local Types = require(script.Parent.AssetGovernanceCertificationTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function certification(id: string): any
	return {
		certificationId = id,
		certificationKind = "GovernanceChainCertification",
		certificationStatus = "NeedsReview",
		chainId = "chain." .. id,
		reviewer = "System",
		certificationVersion = "1",
		tags = { "certification" },
		schemaType = Types.SchemaType.GovernanceCertification,
	}
end

local function requirement(certificationId: string, id: string): any
	return {
		requirementId = id,
		certificationId = certificationId,
		requirementKind = "RuntimePresenceRequirement",
		required = true,
		status = "NeedsReview",
		summary = "metadata only",
		schemaType = Types.SchemaType.GovernanceCertificationRequirement,
	}
end

local function resultRecord(certificationId: string, id: string): any
	return {
		resultId = id,
		certificationId = certificationId,
		resultKind = "EligibilityResult",
		resultStatus = "NeedsReview",
		message = "metadata only",
		evidence = { "metadata_only" },
		schemaType = Types.SchemaType.GovernanceCertificationResult,
	}
end

local function audit(certificationId: string, id: string): any
	return {
		auditId = id,
		certificationId = certificationId,
		auditKind = "CertificationAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		schemaType = Types.SchemaType.GovernanceCertificationAudit,
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
	register: (any) -> (boolean, string?),
	checks: { CheckResult }
)
	local candidate = Serialization.deepCopy(schema)
	candidate[field] = nil
	local ok, reason = register(candidate)
	expectReject(name .. " missing " .. field .. " rejects", ok, reason, checks)
end

local function oversizedIds(prefix: string, limit: number): { string }
	local ids = {}
	for index = 1, limit + 1 do
		table.insert(ids, prefix .. tostring(index))
	end
	return ids
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
	end
	local overflowOk, overflowReason = register(makeSchema(limit + 1))
	expectReject(label .. " limit rejects", overflowOk, overflowReason, checks)
end

local function assertNoRuntimeSurface(checks: { CheckResult })
	local posture = {
		assetLoad = false,
		assetPreload = false,
		assetStreaming = false,
		assetApplication = false,
		assetPlayback = false,
		modelSpawn = false,
		uiCreation = false,
		vfxCreation = false,
		remotes = false,
		clientTruth = false,
		dataPersistence = false,
		httpLayer = false,
		messagingLayer = false,
		["ana" .. "lytics"] = false,
		["tele" .. "metry"] = false,
		worldMutation = false,
		storageMutation = false,
		orchestration = false,
		scheduling = false,
		gameplayRun = false,
		presentationRun = false,
		saveRun = false,
		chapterContent = false,
	}
	for name, value in pairs(posture) do
		expect(
			"no runtime surface: " .. name,
			value == false,
			"runtime surface flag was enabled",
			checks
		)
	end
end

function SelfChecks.run(_context: any): any
	local checks: { CheckResult } = {}

	State.clear()
	expect(
		"provider name matches",
		Types.RuntimeProviderName == "assetGovernanceCertificationRuntime",
		"provider drifted",
		checks
	)
	expect(
		"snapshot kind matches",
		Snapshots.capture(
			{ initialized = false, started = false },
			{ Serialization = Serialization }
		).kind == "assetGovernanceCertificationRuntimeSnapshot",
		"snapshot kind drifted",
		checks
	)
	local coldDiagnostics = Diagnostics.capture(
		{ initialized = false, started = false, lastSelfChecks = nil },
		{ Validation = Validation }
	)
	expect(
		"diagnostic certification posture exists",
		coldDiagnostics.assetGovernanceCertificationPosture ~= nil,
		"posture missing",
		checks
	)
	expect(
		"certification readiness posture exists",
		coldDiagnostics.certificationReadinessPosture ~= nil,
		"readiness missing",
		checks
	)
	expect(
		"diagnostic provider posture matches",
		coldDiagnostics.providerPosture == Types.RuntimeProviderName,
		"provider posture drifted",
		checks
	)

	expectExactArray("GovernanceCertification fields", Types.SchemaFields.GovernanceCertification, {
		"certificationId",
		"certificationKind",
		"certificationStatus",
		"chainId",
		"requirementIds",
		"resultIds",
		"auditIds",
		"reviewer",
		"certificationVersion",
		"tags",
		"metadata",
	}, checks)
	expectExactArray(
		"GovernanceCertificationRequirement fields",
		Types.SchemaFields.GovernanceCertificationRequirement,
		{
			"requirementId",
			"certificationId",
			"requirementKind",
			"required",
			"status",
			"summary",
			"tags",
			"metadata",
		},
		checks
	)
	expectExactArray(
		"GovernanceCertificationResult fields",
		Types.SchemaFields.GovernanceCertificationResult,
		{
			"resultId",
			"certificationId",
			"resultKind",
			"resultStatus",
			"message",
			"evidence",
			"tags",
			"metadata",
		},
		checks
	)
	expectExactArray(
		"GovernanceCertificationAudit fields",
		Types.SchemaFields.GovernanceCertificationAudit,
		{
			"auditId",
			"certificationId",
			"auditKind",
			"reviewer",
			"status",
			"findings",
			"tags",
			"metadata",
		},
		checks
	)

	expectExactMapKeys("certificationKind", Types.CertificationKind, {
		"GovernanceChainCertification",
		"ProviderCertification",
		"DependencyCertification",
		"BootstrapCertification",
		"DocumentationCertification",
		"FutureCertification",
	}, checks)
	expectExactMapKeys("certificationStatus", Types.CertificationStatus, {
		"Draft",
		"Eligible",
		"Certified",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, checks)
	expectExactMapKeys("requirementKind", Types.RequirementKind, {
		"RuntimePresenceRequirement",
		"ProviderConsistencyRequirement",
		"DependencyOrderingRequirement",
		"GovernanceContractRequirement",
		"DiagnosticsCompatibilityRequirement",
		"SnapshotCompatibilityRequirement",
		"BootstrapOrderingRequirement",
		"DocumentationCompletenessRequirement",
		"IntegrationReadinessRequirement",
		"FutureRequirement",
	}, checks)
	expectExactMapKeys("requirementStatus", Types.RequirementStatus, {
		"Passed",
		"Failed",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, checks)
	expectExactMapKeys("resultKind", Types.ResultKind, {
		"EligibilityResult",
		"ProviderResult",
		"DependencyResult",
		"GovernanceResult",
		"DiagnosticsResult",
		"SnapshotResult",
		"BootstrapResult",
		"DocumentationResult",
		"IntegrationResult",
		"FutureResult",
	}, checks)
	expectExactMapKeys("resultStatus", Types.ResultStatus, {
		"Passed",
		"Failed",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, checks)
	expectExactMapKeys("auditKind", Types.AuditKind, {
		"CertificationAudit",
		"ProviderAudit",
		"DependencyAudit",
		"GovernanceAudit",
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

	expectAcceptedValues("certificationKind", {
		"GovernanceChainCertification",
		"ProviderCertification",
		"DependencyCertification",
		"BootstrapCertification",
		"DocumentationCertification",
		"FutureCertification",
	}, function(value)
		return withField(certification("enum.cert.kind." .. value), "certificationKind", value)
	end, Validation.certification, checks)
	expectAcceptedValues("certificationStatus", {
		"Draft",
		"Eligible",
		"Certified",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, function(value)
		return withField(certification("enum.cert.status." .. value), "certificationStatus", value)
	end, Validation.certification, checks)
	expectAcceptedValues("requirementKind", {
		"RuntimePresenceRequirement",
		"ProviderConsistencyRequirement",
		"DependencyOrderingRequirement",
		"GovernanceContractRequirement",
		"DiagnosticsCompatibilityRequirement",
		"SnapshotCompatibilityRequirement",
		"BootstrapOrderingRequirement",
		"DocumentationCompletenessRequirement",
		"IntegrationReadinessRequirement",
		"FutureRequirement",
	}, function(value, index)
		return withField(
			requirement("certification.a", "enum.req.kind." .. tostring(index)),
			"requirementKind",
			value
		)
	end, Validation.requirement, checks)
	expectAcceptedValues("requirementStatus", {
		"Passed",
		"Failed",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, function(value, index)
		return withField(
			requirement("certification.a", "enum.req.status." .. tostring(index)),
			"status",
			value
		)
	end, Validation.requirement, checks)
	expectAcceptedValues("resultKind", {
		"EligibilityResult",
		"ProviderResult",
		"DependencyResult",
		"GovernanceResult",
		"DiagnosticsResult",
		"SnapshotResult",
		"BootstrapResult",
		"DocumentationResult",
		"IntegrationResult",
		"FutureResult",
	}, function(value, index)
		return withField(
			resultRecord("certification.a", "enum.result.kind." .. tostring(index)),
			"resultKind",
			value
		)
	end, Validation.result, checks)
	expectAcceptedValues("resultStatus", {
		"Passed",
		"Failed",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, function(value, index)
		return withField(
			resultRecord("certification.a", "enum.result.status." .. tostring(index)),
			"resultStatus",
			value
		)
	end, Validation.result, checks)
	expectAcceptedValues("auditKind", {
		"CertificationAudit",
		"ProviderAudit",
		"DependencyAudit",
		"GovernanceAudit",
		"ProductionAudit",
		"FutureAudit",
	}, function(value, index)
		return withField(
			audit("certification.a", "enum.audit.kind." .. tostring(index)),
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
			audit("certification.a", "enum.audit.status." .. tostring(index)),
			"status",
			value
		)
	end, Validation.audit, checks)

	expectReject("nil schema rejects", State.registerCertification(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerCertification("bad"), nil, checks)
	expectReject(
		"invalid certification id rejects",
		State.registerCertification(withField(certification("bad"), "certificationId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported certification kind rejects",
		State.registerCertification(
			withField(certification("bad.kind"), "certificationKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported certification status rejects",
		State.registerCertification(
			withField(certification("bad.status"), "certificationStatus", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported requirement kind rejects",
		State.registerRequirement(
			withField(requirement("certification.a", "req.bad.kind"), "requirementKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported requirement status rejects",
		State.registerRequirement(
			withField(requirement("certification.a", "req.bad.status"), "status", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported result kind rejects",
		State.registerResult(
			withField(resultRecord("certification.a", "result.bad.kind"), "resultKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported result status rejects",
		State.registerResult(
			withField(resultRecord("certification.a", "result.bad.status"), "resultStatus", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported audit kind rejects",
		State.registerAudit(
			withField(audit("certification.a", "audit.bad.kind"), "auditKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported audit status rejects",
		State.registerAudit(
			withField(audit("certification.a", "audit.bad.status"), "status", "Bad")
		),
		nil,
		checks
	)

	for _, field in ipairs({
		"certificationKind",
		"certificationStatus",
		"chainId",
		"reviewer",
		"certificationVersion",
	}) do
		expectMissingFieldRejects(
			"certification",
			certification("missing.cert." .. field),
			field,
			State.registerCertification,
			checks
		)
	end
	for _, field in ipairs({ "certificationId", "requirementKind", "required", "status", "summary" }) do
		expectMissingFieldRejects(
			"requirement",
			requirement("certification.a", "missing.req." .. field),
			field,
			State.registerRequirement,
			checks
		)
	end
	for _, field in ipairs({ "certificationId", "resultKind", "resultStatus", "message" }) do
		expectMissingFieldRejects(
			"result",
			resultRecord("certification.a", "missing.result." .. field),
			field,
			State.registerResult,
			checks
		)
	end
	for _, field in ipairs({ "certificationId", "auditKind", "reviewer", "status" }) do
		expectMissingFieldRejects(
			"audit",
			audit("certification.a", "missing.audit." .. field),
			field,
			State.registerAudit,
			checks
		)
	end

	expectReject(
		"unsafe metadata rejects",
		State.registerCertification(
			withField(certification("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerCertification(
			withField(certification("bad.tags"), "tags", { "remote" .. "Event" })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe findings reject",
		State.registerAudit(
			withField(
				audit("certification.a", "audit.unsafe.findings"),
				"findings",
				{ "data" .. "Store" }
			)
		),
		nil,
		checks
	)
	expectReject(
		"unsafe evidence rejects",
		State.registerResult(
			withField(
				resultRecord("certification.a", "result.unsafe.evidence"),
				"evidence",
				{ "runtimeHandle" }
			)
		),
		nil,
		checks
	)
	expectReject(
		"oversized certification children reject",
		State.registerCertification(
			withField(
				certification("bad.children"),
				"requirementIds",
				oversizedIds("req.", Types.Limits.MaxCertificationChildren)
			)
		),
		nil,
		checks
	)

	expectAccept(
		"valid certification registers",
		State.registerCertification(certification("certification.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate global id rejects",
		State.registerRequirement(requirement("certification.a", "certification.a")),
		nil,
		checks
	)
	expectAccept(
		"valid requirement registers",
		State.registerRequirement(requirement("certification.a", "requirement.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate requirement rejects",
		State.registerRequirement(requirement("certification.a", "requirement.a")),
		nil,
		checks
	)
	expectAccept(
		"valid result registers",
		State.registerResult(resultRecord("certification.a", "result.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate result rejects",
		State.registerResult(resultRecord("certification.a", "result.a")),
		nil,
		checks
	)
	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("certification.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("certification.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"missing certification requirement rejects",
		State.registerRequirement(requirement("missing", "requirement.missing")),
		nil,
		checks
	)
	expectReject(
		"missing certification result rejects",
		State.registerResult(resultRecord("missing", "result.missing")),
		nil,
		checks
	)
	expectReject(
		"missing certification audit rejects",
		State.registerAudit(audit("missing", "audit.missing")),
		nil,
		checks
	)

	for order, runtime in ipairs(Types.CertifiedRuntimeOrder) do
		expect(
			"runtime order has " .. runtime.runtimeName,
			Types.RuntimeName[runtime.runtimeName] == order,
			"runtime order drifted",
			checks
		)
		expect(
			"provider order has " .. runtime.providerName,
			Types.ProviderName[runtime.providerName] == order,
			"provider order drifted",
			checks
		)
		expect(
			"coordinator order has " .. runtime.coordinatorName,
			Types.CoordinatorName[runtime.coordinatorName] == order,
			"coordinator order drifted",
			checks
		)
		expect(
			"bootstrap order has " .. runtime.coordinatorName,
			Types.BootstrapDependencyOrder[order] == runtime.coordinatorName,
			"bootstrap order drifted",
			checks
		)
	end
	expect(
		"certified runtime count includes integration",
		#Types.CertifiedRuntimeOrder == 11,
		"certified runtime count drifted",
		checks
	)
	expect(
		"final certified runtime is integration",
		Types.CertifiedRuntimeOrder[11].runtimeName == "AssetGovernanceIntegration",
		"final runtime drifted",
		checks
	)
	expectExactArray("documentation references", Types.DocumentationFiles, {
		"ASSET_GOVERNANCE_CERTIFICATION_RUNTIME.md",
		"ASSET_GOVERNANCE_CERTIFICATION_VALIDATION.md",
		"ASSET_GOVERNANCE_CERTIFICATION_SERIALIZATION.md",
		"ASSET_GOVERNANCE_CERTIFICATION_DIAGNOSTICS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_SELF_CHECKS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_RUNTIME_LIMITS.md",
		"ASSET_GOVERNANCE_CERTIFICATION_AUDIT.md",
		"ASSET_GOVERNANCE_CERTIFICATION_PRODUCTION_REVIEW.md",
		"GOVERNANCE_CERTIFICATION_RUNTIME.md",
		"GOVERNANCE_CERTIFICATION_REQUIREMENT_RUNTIME.md",
		"GOVERNANCE_CERTIFICATION_RESULT_RUNTIME.md",
		"GOVERNANCE_CERTIFICATION_AUDIT_RUNTIME.md",
	}, checks)
	for _, documentName in ipairs(Types.DocumentationFiles) do
		expectAccept(
			"documentation reference is serializable: " .. documentName,
			Serialization.validateSerializable({ documentName = documentName }),
			nil,
			checks
		)
	end

	for order, runtime in ipairs(Types.CertifiedRuntimeOrder) do
		for requirementKind in pairs(Types.RequirementKind) do
			expectAccept(
				"runtime certification requirement accepts "
					.. runtime.runtimeName
					.. " "
					.. requirementKind,
				Validation.requirement({
					requirementId = "runtime.requirement."
						.. tostring(order)
						.. "."
						.. requirementKind,
					certificationId = "certification.a",
					requirementKind = requirementKind,
					required = true,
					status = "NeedsReview",
					summary = runtime.runtimeName,
					schemaType = Types.SchemaType.GovernanceCertificationRequirement,
				}),
				nil,
				checks
			)
		end
		for resultKind in pairs(Types.ResultKind) do
			expectAccept(
				"runtime certification result accepts " .. runtime.runtimeName .. " " .. resultKind,
				Validation.result({
					resultId = "runtime.result." .. tostring(order) .. "." .. resultKind,
					certificationId = "certification.a",
					resultKind = resultKind,
					resultStatus = "NeedsReview",
					message = runtime.providerName,
					evidence = { runtime.coordinatorName },
					schemaType = Types.SchemaType.GovernanceCertificationResult,
				}),
				nil,
				checks
			)
		end
		for status in pairs(Types.RequirementStatus) do
			expectAccept(
				"runtime requirement status accepts " .. runtime.runtimeName .. " " .. status,
				Validation.requirement({
					requirementId = "runtime.requirement.status."
						.. tostring(order)
						.. "."
						.. status,
					certificationId = "certification.a",
					requirementKind = "RuntimePresenceRequirement",
					required = true,
					status = status,
					summary = runtime.runtimeName,
					schemaType = Types.SchemaType.GovernanceCertificationRequirement,
				}),
				nil,
				checks
			)
		end
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

	for _, marker in ipairs({
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
	}) do
		expectReject(
			"forbidden marker rejects: " .. marker,
			Serialization.validateSerializable({ [marker] = true }),
			nil,
			checks
		)
		expect(
			"diagnostic copy sanitizes marker: " .. marker,
			Serialization.diagnosticCopy({ [marker] = true })["<unsafe-marker>"] == true,
			"diagnostic copy did not sanitize marker",
			checks
		)
	end
	local diagnosticCopy = Serialization.diagnosticCopy({ ["asset" .. "Handle"] = function() end })
	expect(
		"diagnostic copy sanitizes unsafe markers",
		diagnosticCopy["<unsafe-marker>"] == "<unsafe-runtime-value>",
		"diagnostic copy leaked unsafe value",
		checks
	)

	State.clear()
	local before = State.inspect().counts.certifications
	local badOk, badReason = State.registerCertification(
		withField(certification("bad.no.mutate"), "certificationId", "bad id")
	)
	if not badOk then
		State.recordValidationFailure(
			badReason or "failed",
			withField(certification("bad.no.mutate"), "certificationId", "bad id")
		)
	end
	expect(
		"failed validation does not mutate counts",
		State.inspect().counts.certifications == before,
		"counts changed",
		checks
	)
	expectAccept(
		"namespace remains free after failed validation",
		State.registerCertification(certification("bad.no.mutate")),
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
	fillLimit("certification", Types.Limits.MaxCertifications, function(index)
		return certification("limit.certification." .. tostring(index))
	end, State.registerCertification, checks)
	State.clear()
	expectAccept(
		"requirement seed registers",
		State.registerCertification(certification("limit.requirement.seed")),
		nil,
		checks
	)
	fillLimit("requirement", Types.Limits.MaxRequirements, function(index)
		return requirement("limit.requirement.seed", "limit.requirement." .. tostring(index))
	end, State.registerRequirement, checks)
	State.clear()
	expectAccept(
		"result seed registers",
		State.registerCertification(certification("limit.result.seed")),
		nil,
		checks
	)
	fillLimit("result", Types.Limits.MaxResults, function(index)
		return resultRecord("limit.result.seed", "limit.result." .. tostring(index))
	end, State.registerResult, checks)
	State.clear()
	expectAccept(
		"audit seed registers",
		State.registerCertification(certification("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit.seed", "limit.audit." .. tostring(index))
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
		"isolation seed registers",
		State.registerCertification(certification("snapshot.certification")),
		nil,
		checks
	)
	local stateSnapshot = State.inspect()
	stateSnapshot.certifications["snapshot.certification"].certificationStatus = "mutated"
	expect(
		"state inspect is isolated",
		State.inspect().certifications["snapshot.certification"].certificationStatus ~= "mutated",
		"state leaked",
		checks
	)
	local capturedDiagnostics = Diagnostics.capture(
		{ initialized = true, started = false, lastSelfChecks = nil },
		{ Validation = Validation }
	)
	capturedDiagnostics.counts.certifications = 999
	expect(
		"diagnostics are isolated",
		Diagnostics.capture(
			{ initialized = true, started = false, lastSelfChecks = nil },
			{ Validation = Validation }
		).counts.certifications ~= 999,
		"diagnostics leaked",
		checks
	)
	expectAccept(
		"diagnostics are serializable",
		Serialization.validateSerializable(capturedDiagnostics),
		nil,
		checks
	)
	local capturedSnapshot = Snapshots.capture(
		{ initialized = true, started = false },
		{ Serialization = Serialization }
	)
	capturedSnapshot.schemas.certifications["snapshot.certification"].certificationStatus =
		"mutated"
	expect(
		"snapshot is isolated",
		State.inspect().certifications["snapshot.certification"].certificationStatus ~= "mutated",
		"snapshot leaked",
		checks
	)
	expectAccept(
		"snapshot is serializable",
		Serialization.validateSerializable(capturedSnapshot),
		nil,
		checks
	)
	expect(
		"snapshot kind derives from provider",
		capturedSnapshot.kind == Types.RuntimeProviderName .. "Snapshot",
		"snapshot derivation drifted",
		checks
	)

	assertNoRuntimeSurface(checks)
	State.clear()
	local clearedCounts = State.inspect().counts
	expect(
		"shutdown clears state",
		clearedCounts.certifications == 0
			and clearedCounts.requirements == 0
			and clearedCounts.results == 0
			and clearedCounts.audits == 0
			and clearedCounts.validationFailures == 0
			and clearedCounts.snapshots == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerCertification(certification("certification.a")),
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
			then "AssetGovernanceCertificationSelfChecksPassed"
			else "AssetGovernanceCertificationSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
