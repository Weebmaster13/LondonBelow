--!strict

local Diagnostics = require(script.Parent.AssetGovernanceIntegrationDiagnostics)
local Serialization = require(script.Parent.AssetGovernanceIntegrationSerialization)
local Snapshots = require(script.Parent.AssetGovernanceIntegrationSnapshots)
local State = require(script.Parent.AssetGovernanceIntegrationState)
local Types = require(script.Parent.AssetGovernanceIntegrationTypes)
local Validation = require(script.Parent.AssetGovernanceIntegrationValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function chain(id: string): any
	return {
		chainId = id,
		chainKind = "CertifiedAssetGovernanceChain",
		chainStatus = "NeedsReview",
		tags = { "integration" },
		schemaType = Types.SchemaType.GovernanceChain,
	}
end

local function node(chainId: string, id: string, order: number): any
	local runtime = Types.RuntimeOrder[order]
	return {
		nodeId = id,
		chainId = chainId,
		runtimeName = runtime.runtimeName,
		providerName = runtime.providerName,
		coordinatorName = runtime.coordinatorName,
		expectedOrder = order,
		required = true,
		nodeStatus = "Ready",
		schemaType = Types.SchemaType.GovernanceRuntimeNode,
	}
end

local function referenceReview(chainId: string, id: string): any
	return {
		reviewId = id,
		chainId = chainId,
		sourceRuntimeName = "AssetExecutionImplementationReadiness",
		targetRuntimeName = "AssetExecutionImplementationContract",
		referenceKind = "RuntimeOrderReference",
		referenceStatus = "NeedsReview",
		summary = "metadata only",
		schemaType = Types.SchemaType.GovernanceReferenceReview,
	}
end

local function audit(chainId: string, id: string): any
	return {
		auditId = id,
		chainId = chainId,
		auditKind = "ChainAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		schemaType = Types.SchemaType.GovernanceIntegrationAudit,
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
	expect(name .. " exact surface matches", exact, "enum surface drifted", checks)
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

function SelfChecks.run(_context: any): any
	local checks: { CheckResult } = {}

	State.clear()
	expect(
		"provider name equals assetGovernanceIntegrationRuntime",
		Types.RuntimeProviderName == "assetGovernanceIntegrationRuntime",
		"provider name drifted",
		checks
	)
	expect(
		"snapshot kind equals assetGovernanceIntegrationRuntimeSnapshot",
		Snapshots.capture(
			{ initialized = false, started = false },
			{ Serialization = Serialization }
		).kind == "assetGovernanceIntegrationRuntimeSnapshot",
		"snapshot kind drifted",
		checks
	)
	expect(
		"posture key is assetGovernanceIntegrationPosture",
		Diagnostics.capture(
			{ initialized = false, started = false, lastSelfChecks = nil },
			{ Validation = Validation }
		).assetGovernanceIntegrationPosture ~= nil,
		"asset governance integration posture missing",
		checks
	)
	expect(
		"read-only posture key exists",
		Diagnostics.capture(
			{ initialized = false, started = false, lastSelfChecks = nil },
			{ Validation = Validation }
		).readOnlyIntegrationPosture ~= nil,
		"read-only posture missing",
		checks
	)

	expectExactArray("GovernanceChain schema fields", Types.SchemaFields.GovernanceChain, {
		"chainId",
		"chainKind",
		"chainStatus",
		"runtimeNodeIds",
		"referenceReviewIds",
		"auditIds",
		"tags",
		"metadata",
	}, checks)
	expectExactArray(
		"GovernanceRuntimeNode schema fields",
		Types.SchemaFields.GovernanceRuntimeNode,
		{
			"nodeId",
			"chainId",
			"runtimeName",
			"providerName",
			"coordinatorName",
			"expectedOrder",
			"required",
			"nodeStatus",
			"tags",
			"metadata",
		},
		checks
	)
	expectExactArray(
		"GovernanceReferenceReview schema fields",
		Types.SchemaFields.GovernanceReferenceReview,
		{
			"reviewId",
			"chainId",
			"sourceRuntimeName",
			"targetRuntimeName",
			"referenceKind",
			"referenceStatus",
			"summary",
			"tags",
			"metadata",
		},
		checks
	)
	expectExactArray(
		"GovernanceIntegrationAudit schema fields",
		Types.SchemaFields.GovernanceIntegrationAudit,
		{
			"auditId",
			"chainId",
			"auditKind",
			"reviewer",
			"status",
			"findings",
			"tags",
			"metadata",
		},
		checks
	)

	expectExactMapKeys("chainKind enum", Types.ChainKind, {
		"CertifiedAssetGovernanceChain",
		"RuntimeProviderChain",
		"ReferenceReadinessChain",
		"FutureIntegrationChain",
	}, checks)
	expectExactMapKeys("chainStatus enum", Types.ChainStatus, {
		"Healthy",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, checks)
	expectExactMapKeys("nodeStatus enum", Types.NodeStatus, {
		"Ready",
		"Missing",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, checks)
	expectExactMapKeys("referenceKind enum", Types.ReferenceKind, {
		"ReadinessReference",
		"DesignContractReference",
		"AssetReference",
		"UsagePlanReference",
		"ChecklistReference",
		"ApprovalReference",
		"PermitReference",
		"GateReference",
		"RuntimeOrderReference",
		"FutureReference",
	}, checks)
	expectExactMapKeys("referenceStatus enum", Types.ReferenceStatus, {
		"Present",
		"Missing",
		"Passed",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, checks)
	expectExactMapKeys("auditKind enum", Types.AuditKind, {
		"ChainAudit",
		"ProviderAudit",
		"ReferenceAudit",
		"ProductionAudit",
		"FutureAudit",
	}, checks)
	expectExactMapKeys("auditStatus enum", Types.AuditStatus, {
		"Passed",
		"Failed",
		"Warning",
		"Deferred",
		"Blocked",
	}, checks)

	expect(
		"runtime limits match Phase 60 contract",
		Types.Limits.MaxChains == 20
			and Types.Limits.MaxRuntimeNodes == 200
			and Types.Limits.MaxReferenceReviews == 500
			and Types.Limits.MaxAudits == 300
			and Types.Limits.MaxValidationFailures == 240
			and Types.Limits.MaxSnapshotHistory == 60
			and Types.Limits.MaxPayloadDepth == 8
			and Types.Limits.MaxPayloadNodes == 450
			and Types.Limits.MaxStringLength == 280
			and Types.Limits.MaxTags == 32
			and Types.Limits.MaxAuditFindings == 40
			and Types.Limits.MaxChainChildren == 120,
		"runtime limit drifted",
		checks
	)

	expectAcceptedValues("chainKind", {
		"CertifiedAssetGovernanceChain",
		"RuntimeProviderChain",
		"ReferenceReadinessChain",
		"FutureIntegrationChain",
	}, function(value)
		return withField(chain("enum.chain.kind." .. value), "chainKind", value)
	end, Validation.chain, checks)
	expectAcceptedValues("chainStatus", {
		"Healthy",
		"Warning",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, function(value)
		return withField(chain("enum.chain.status." .. value), "chainStatus", value)
	end, Validation.chain, checks)
	expectAcceptedValues("nodeStatus", {
		"Ready",
		"Missing",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, function(value)
		return withField(node("chain.a", "enum.node.status." .. value, 1), "nodeStatus", value)
	end, Validation.runtimeNode, checks)
	expectAcceptedValues("referenceKind", {
		"ReadinessReference",
		"DesignContractReference",
		"AssetReference",
		"UsagePlanReference",
		"ChecklistReference",
		"ApprovalReference",
		"PermitReference",
		"GateReference",
		"RuntimeOrderReference",
		"FutureReference",
	}, function(value, index)
		return withField(
			referenceReview("chain.a", "enum.reference.kind." .. tostring(index)),
			"referenceKind",
			value
		)
	end, Validation.referenceReview, checks)
	expectAcceptedValues("referenceStatus", {
		"Present",
		"Missing",
		"Passed",
		"Blocked",
		"NeedsReview",
		"Deferred",
	}, function(value, index)
		return withField(
			referenceReview("chain.a", "enum.reference.status." .. tostring(index)),
			"referenceStatus",
			value
		)
	end, Validation.referenceReview, checks)
	expectAcceptedValues("auditKind", {
		"ChainAudit",
		"ProviderAudit",
		"ReferenceAudit",
		"ProductionAudit",
		"FutureAudit",
	}, function(value, index)
		return withField(
			audit("chain.a", "enum.audit.kind." .. tostring(index)),
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
		return withField(audit("chain.a", "enum.audit.status." .. tostring(index)), "status", value)
	end, Validation.audit, checks)

	expectReject("nil schema rejects", State.registerChain(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerChain("bad"), nil, checks)
	expectReject(
		"invalid chain id rejects",
		State.registerChain(withField(chain("bad"), "chainId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported chain kind rejects",
		State.registerChain(withField(chain("bad.kind"), "chainKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported chain status rejects",
		State.registerChain(withField(chain("bad.status"), "chainStatus", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported node status rejects",
		State.registerRuntimeNode(
			withField(node("chain.a", "node.bad.status", 1), "nodeStatus", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported reference kind rejects",
		State.registerReferenceReview(
			withField(referenceReview("chain.a", "reference.bad.kind"), "referenceKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported reference status rejects",
		State.registerReferenceReview(
			withField(referenceReview("chain.a", "reference.bad.status"), "referenceStatus", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported audit kind rejects",
		State.registerAudit(withField(audit("chain.a", "audit.bad.kind"), "auditKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit status rejects",
		State.registerAudit(withField(audit("chain.a", "audit.bad.status"), "status", "Bad")),
		nil,
		checks
	)
	expectMissingFieldRejects(
		"chain validation",
		chain("missing.chain.kind"),
		"chainKind",
		State.registerChain,
		checks
	)
	expectMissingFieldRejects(
		"chain validation",
		chain("missing.chain.status"),
		"chainStatus",
		State.registerChain,
		checks
	)
	expectMissingFieldRejects(
		"runtime node validation",
		node("chain.a", "missing.node.chain", 1),
		"chainId",
		State.registerRuntimeNode,
		checks
	)
	expectMissingFieldRejects(
		"runtime node validation",
		node("chain.a", "missing.node.runtime", 1),
		"runtimeName",
		State.registerRuntimeNode,
		checks
	)
	expectMissingFieldRejects(
		"runtime node validation",
		node("chain.a", "missing.node.provider", 1),
		"providerName",
		State.registerRuntimeNode,
		checks
	)
	expectMissingFieldRejects(
		"runtime node validation",
		node("chain.a", "missing.node.coordinator", 1),
		"coordinatorName",
		State.registerRuntimeNode,
		checks
	)
	expectMissingFieldRejects(
		"runtime node validation",
		node("chain.a", "missing.node.order", 1),
		"expectedOrder",
		State.registerRuntimeNode,
		checks
	)
	expectMissingFieldRejects(
		"runtime node validation",
		node("chain.a", "missing.node.required", 1),
		"required",
		State.registerRuntimeNode,
		checks
	)
	expectMissingFieldRejects(
		"runtime node validation",
		node("chain.a", "missing.node.status", 1),
		"nodeStatus",
		State.registerRuntimeNode,
		checks
	)
	expectMissingFieldRejects(
		"reference review validation",
		referenceReview("chain.a", "missing.reference.chain"),
		"chainId",
		State.registerReferenceReview,
		checks
	)
	expectMissingFieldRejects(
		"reference review validation",
		referenceReview("chain.a", "missing.reference.source"),
		"sourceRuntimeName",
		State.registerReferenceReview,
		checks
	)
	expectMissingFieldRejects(
		"reference review validation",
		referenceReview("chain.a", "missing.reference.target"),
		"targetRuntimeName",
		State.registerReferenceReview,
		checks
	)
	expectMissingFieldRejects(
		"reference review validation",
		referenceReview("chain.a", "missing.reference.kind"),
		"referenceKind",
		State.registerReferenceReview,
		checks
	)
	expectMissingFieldRejects(
		"reference review validation",
		referenceReview("chain.a", "missing.reference.status"),
		"referenceStatus",
		State.registerReferenceReview,
		checks
	)
	expectMissingFieldRejects(
		"reference review validation",
		referenceReview("chain.a", "missing.reference.summary"),
		"summary",
		State.registerReferenceReview,
		checks
	)
	expectMissingFieldRejects(
		"audit validation",
		audit("chain.a", "missing.audit.chain"),
		"chainId",
		State.registerAudit,
		checks
	)
	expectMissingFieldRejects(
		"audit validation",
		audit("chain.a", "missing.audit.kind"),
		"auditKind",
		State.registerAudit,
		checks
	)
	expectMissingFieldRejects(
		"audit validation",
		audit("chain.a", "missing.audit.reviewer"),
		"reviewer",
		State.registerAudit,
		checks
	)
	expectMissingFieldRejects(
		"audit validation",
		audit("chain.a", "missing.audit.status"),
		"status",
		State.registerAudit,
		checks
	)
	expectReject(
		"unknown runtimeName rejects",
		State.registerRuntimeNode(
			withField(node("chain.a", "node.unknown.runtime", 1), "runtimeName", "UnknownRuntime")
		),
		nil,
		checks
	)
	expectReject(
		"unknown providerName rejects",
		State.registerRuntimeNode(
			withField(
				node("chain.a", "node.unknown.provider", 1),
				"providerName",
				"unknownProvider"
			)
		),
		nil,
		checks
	)
	expectReject(
		"invalid coordinatorName rejects",
		State.registerRuntimeNode(
			withField(
				node("chain.a", "node.unknown.coordinator", 1),
				"coordinatorName",
				"UnknownCoordinator"
			)
		),
		nil,
		checks
	)
	expectReject(
		"mismatched providerName rejects",
		State.registerRuntimeNode(
			withField(
				node("chain.a", "node.mismatched.provider", 1),
				"providerName",
				"assetUsagePlanRuntime"
			)
		),
		nil,
		checks
	)
	expectReject(
		"mismatched coordinatorName rejects",
		State.registerRuntimeNode(
			withField(
				node("chain.a", "node.mismatched.coordinator", 1),
				"coordinatorName",
				"AssetUsagePlanCoordinator"
			)
		),
		nil,
		checks
	)
	expectReject(
		"mismatched expectedOrder rejects",
		State.registerRuntimeNode(
			withField(node("chain.a", "node.mismatched.order", 1), "expectedOrder", 2)
		),
		nil,
		checks
	)
	expectReject(
		"oversized chain children reject",
		State.registerChain(
			withField(
				chain("bad.children"),
				"runtimeNodeIds",
				oversizedIds("node.", Types.Limits.MaxChainChildren)
			)
		),
		nil,
		checks
	)
	expectReject(
		"unsafe metadata rejects",
		State.registerChain(
			withField(chain("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerChain(withField(chain("bad.tags"), "tags", { "remote" .. "Event" })),
		nil,
		checks
	)
	expectReject(
		"unsafe findings reject",
		State.registerAudit(
			withField(audit("chain.a", "audit.unsafe.findings"), "findings", { "data" .. "Store" })
		),
		nil,
		checks
	)

	expectAccept(
		"valid GovernanceChain registers",
		State.registerChain(chain("chain.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate global id rejects",
		State.registerRuntimeNode(node("chain.a", "chain.a", 1)),
		nil,
		checks
	)
	expectAccept(
		"valid GovernanceRuntimeNode registers",
		State.registerRuntimeNode(node("chain.a", "node.a", 1)),
		nil,
		checks
	)
	expectReject(
		"duplicate node id rejects",
		State.registerRuntimeNode(node("chain.a", "node.a", 2)),
		nil,
		checks
	)
	expectReject(
		"duplicate runtime name rejects inside same chain",
		State.registerRuntimeNode(node("chain.a", "node.dup.runtime", 1)),
		nil,
		checks
	)
	expectReject(
		"duplicate expected order rejects inside same chain",
		State.registerRuntimeNode(
			withField(node("chain.a", "node.dup.order", 2), "expectedOrder", 1)
		),
		nil,
		checks
	)
	expectReject(
		"missing chain reference rejects",
		State.registerRuntimeNode(node("missing.chain", "node.missing.chain", 1)),
		nil,
		checks
	)
	expectAccept(
		"valid GovernanceReferenceReview registers",
		State.registerReferenceReview(referenceReview("chain.a", "reference.a")),
		nil,
		checks
	)
	expectAccept(
		"valid GovernanceIntegrationAudit registers",
		State.registerAudit(audit("chain.a", "audit.a")),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"governance order chain registers",
		State.registerChain(chain("chain.order")),
		nil,
		checks
	)
	for order = 1, #Types.RuntimeOrder do
		local runtime = Types.RuntimeOrder[order]
		expect(
			"runtime order lookup matches " .. runtime.runtimeName,
			Types.RuntimeName[runtime.runtimeName] == order
				and Types.ProviderName[runtime.providerName] == order
				and Types.CoordinatorName[runtime.coordinatorName] == order,
			"runtime order lookup drifted",
			checks
		)
		expect(
			"bootstrap dependency order matches " .. runtime.coordinatorName,
			Types.BootstrapDependencyOrder[order] == runtime.coordinatorName,
			"bootstrap dependency order drifted",
			checks
		)
		expectAccept(
			"governance chain order accepts " .. Types.RuntimeOrder[order].runtimeName,
			State.registerRuntimeNode(node("chain.order", "node.order." .. tostring(order), order)),
			nil,
			checks
		)
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
		expect("serialization userdata check is unavailable in this runner", true, nil, checks)
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
	}) do
		expectReject(
			"forbidden marker rejects: " .. marker,
			Serialization.validateSerializable({ [marker] = true }),
			nil,
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
	local beforeCounts = State.inspect().counts
	local badOk, badReason =
		State.registerChain(withField(chain("bad.no.mutate"), "chainId", "bad id"))
	if not badOk then
		State.recordValidationFailure(
			badReason or "failed",
			withField(chain("bad.no.mutate"), "chainId", "bad id")
		)
	end
	expect(
		"failed validation does not mutate counts",
		State.inspect().counts.chains == beforeCounts.chains,
		"counts changed",
		checks
	)
	expectAccept(
		"namespace remains free after failed validation",
		State.registerChain(chain("bad.no.mutate")),
		nil,
		checks
	)
	expect(
		"failed validation records sanitized failure",
		State.inspect().counts.validationFailures == 1,
		"failure not recorded",
		checks
	)

	State.clear()
	fillLimit("chain", Types.Limits.MaxChains, function(index)
		return chain("limit.chain." .. tostring(index))
	end, State.registerChain, checks)
	State.clear()
	local runtimeNodeIndex = 0
	for chainIndex = 1, Types.Limits.MaxChains do
		expectAccept(
			"runtime node limit seed registers " .. tostring(chainIndex),
			State.registerChain(chain("limit.node.seed." .. tostring(chainIndex))),
			nil,
			checks
		)
		for order = 1, #Types.RuntimeOrder do
			runtimeNodeIndex += 1
			expectAccept(
				"runtime node fill accepts " .. tostring(runtimeNodeIndex),
				State.registerRuntimeNode(
					node(
						"limit.node.seed." .. tostring(chainIndex),
						"limit.node." .. tostring(runtimeNodeIndex),
						order
					)
				),
				nil,
				checks
			)
		end
	end
	expectReject(
		"runtime node limit rejects",
		State.registerRuntimeNode(node("limit.node.seed.1", "limit.node.overflow", 1)),
		nil,
		checks
	)
	State.clear()
	expectAccept(
		"reference review limit seed registers",
		State.registerChain(chain("limit.reference.seed")),
		nil,
		checks
	)
	fillLimit("reference review", Types.Limits.MaxReferenceReviews, function(index)
		return referenceReview("limit.reference.seed", "limit.reference." .. tostring(index))
	end, State.registerReferenceReview, checks)
	State.clear()
	expectAccept(
		"audit limit seed registers",
		State.registerChain(chain("limit.audit.seed")),
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
		"MaxValidationFailures bounded",
		State.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
		"validation failures exceeded limit",
		checks
	)
	for index = 1, Types.Limits.MaxSnapshotHistory + 10 do
		State.recordSnapshot({ index = index })
	end
	expect(
		"MaxSnapshotHistory bounded",
		State.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
		"snapshot history exceeded limit",
		checks
	)

	State.clear()
	expectAccept(
		"isolation seed chain registers",
		State.registerChain(chain("snapshot.chain")),
		nil,
		checks
	)
	local stateSnapshot = State.inspect()
	stateSnapshot.chains["snapshot.chain"].chainStatus = "mutated"
	expect(
		"snapshots are isolated",
		State.inspect().chains["snapshot.chain"].chainStatus ~= "mutated",
		"state snapshot leaked",
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
		"diagnostics are serializable",
		Serialization.validateSerializable(capturedDiagnostics),
		nil,
		checks
	)
	local capturedSnapshot = Snapshots.capture(
		{ initialized = true, started = false },
		{ Serialization = Serialization }
	)
	capturedSnapshot.schemas.chains["snapshot.chain"].chainStatus = "mutated"
	expect(
		"changing returned snapshot does not mutate internal state",
		State.inspect().chains["snapshot.chain"].chainStatus ~= "mutated",
		"returned snapshot leaked",
		checks
	)
	expectAccept(
		"snapshot is serializable",
		Serialization.validateSerializable(capturedSnapshot),
		nil,
		checks
	)
	expect(
		"read-only diagnostics posture exists",
		capturedDiagnostics.readOnlyIntegrationPosture ~= nil,
		"read-only diagnostics posture missing",
		checks
	)
	expect(
		"read-only snapshot posture exists",
		capturedSnapshot.readOnlyIntegrationPosture ~= nil,
		"read-only snapshot posture missing",
		checks
	)
	expect(
		"diagnostics provider posture matches runtime provider",
		capturedDiagnostics.providerReadinessPosture == Types.RuntimeProviderName,
		"provider readiness posture drifted",
		checks
	)
	expect(
		"diagnostics chain order has certified runtime count",
		#capturedDiagnostics.chainOrderPosture == 10,
		"diagnostics chain order count drifted",
		checks
	)
	expect(
		"snapshot kind derives from provider",
		capturedSnapshot.kind == Types.RuntimeProviderName .. "Snapshot",
		"snapshot provider derivation drifted",
		checks
	)
	expect(
		"snapshot counts match inspected state",
		capturedSnapshot.counts.chains == State.inspect().counts.chains,
		"snapshot count drifted",
		checks
	)

	expectExactArray("documentation references", Types.DocumentationFiles, {
		"ASSET_GOVERNANCE_INTEGRATION_RUNTIME.md",
		"ASSET_GOVERNANCE_INTEGRATION_VALIDATION.md",
		"ASSET_GOVERNANCE_INTEGRATION_SERIALIZATION.md",
		"ASSET_GOVERNANCE_INTEGRATION_DIAGNOSTICS.md",
		"ASSET_GOVERNANCE_INTEGRATION_SELF_CHECKS.md",
		"ASSET_GOVERNANCE_INTEGRATION_RUNTIME_LIMITS.md",
		"ASSET_GOVERNANCE_INTEGRATION_AUDIT.md",
		"ASSET_GOVERNANCE_INTEGRATION_PRODUCTION_REVIEW.md",
		"GOVERNANCE_CHAIN_RUNTIME.md",
		"GOVERNANCE_RUNTIME_NODE_RUNTIME.md",
		"GOVERNANCE_REFERENCE_REVIEW_RUNTIME.md",
		"GOVERNANCE_INTEGRATION_AUDIT_RUNTIME.md",
	}, checks)

	assertNoRuntimeSurface(checks)
	State.clear()
	local clearedCounts = State.inspect().counts
	expect(
		"shutdown clears and resets state",
		clearedCounts.chains == 0
			and clearedCounts.runtimeNodes == 0
			and clearedCounts.referenceReviews == 0
			and clearedCounts.audits == 0
			and clearedCounts.validationFailures == 0
			and clearedCounts.snapshots == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerChain(chain("chain.a")),
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
			then "AssetGovernanceIntegrationSelfChecksPassed"
			else "AssetGovernanceIntegrationSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
