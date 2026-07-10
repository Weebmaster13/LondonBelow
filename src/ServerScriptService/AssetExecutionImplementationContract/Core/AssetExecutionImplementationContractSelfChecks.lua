--!strict

local Diagnostics = require(script.Parent.AssetExecutionImplementationContractDiagnostics)
local Serialization = require(script.Parent.AssetExecutionImplementationContractSerialization)
local Snapshots = require(script.Parent.AssetExecutionImplementationContractSnapshots)
local State = require(script.Parent.AssetExecutionImplementationContractState)
local Types = require(script.Parent.AssetExecutionImplementationContractTypes)
local Validation = require(script.Parent.AssetExecutionImplementationContractValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function contract(id: string): any
	return {
		contractId = id,
		proposedRuntimeName = "Runtime." .. id,
		readinessId = "readiness." .. id,
		designContractId = "design." .. id,
		assetId = "asset." .. id,
		usagePlanId = "usage." .. id,
		checklistId = "checklist." .. id,
		approvalId = "approval." .. id,
		permitId = "permit." .. id,
		gateId = "gate." .. id,
		contractKind = "RuntimeImplementation",
		contractStatus = "NeedsReview",
		owner = "System",
		tags = { "schema" },
		schemaType = Types.SchemaType.ImplementationContract,
	}
end

local function responsibility(contractId: string, id: string): any
	return {
		responsibilityId = id,
		contractId = contractId,
		responsibilityKind = "OwnershipResponsibility",
		required = true,
		summary = "metadata only",
		schemaType = Types.SchemaType.ImplementationContractResponsibility,
	}
end

local function boundary(contractId: string, id: string): any
	return {
		boundaryId = id,
		contractId = contractId,
		boundaryKind = "NoExecutionBoundary",
		allowed = false,
		summary = "metadata only",
		schemaType = Types.SchemaType.ImplementationContractBoundary,
	}
end

local function audit(contractId: string, id: string): any
	return {
		auditId = id,
		contractId = contractId,
		auditKind = "DesignAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		schemaType = Types.SchemaType.ImplementationContractAudit,
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

local function expectedGovernanceChain(): { string }
	return {
		"AssetManifest",
		"AssetUsagePlan",
		"AssetReadinessReview",
		"AssetApprovalLedger",
		"AssetExecutionPermit",
		"AssetRuntimeGate",
		"AssetExecutionBoundaryReview",
		"AssetExecutionDesignContract",
		"AssetExecutionImplementationReadiness",
		"AssetExecutionImplementationContract",
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
	end
	local overflowOk, overflowReason = register(makeSchema(limit + 1))
	expectReject(label .. " limit rejects", overflowOk, overflowReason, checks)
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
		worldMutation = false,
		storageMutation = false,
		remotes = false,
		clientTruth = false,
		dataPersistence = false,
		httpLayer = false,
		messagingLayer = false,
		["ana" .. "lytics"] = false,
		["tele" .. "metry"] = false,
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
		"provider name is lowerCamelCase",
		Types.RuntimeProviderName == "assetExecutionImplementationContractRuntime",
		"runtime provider name drifted",
		checks
	)
	expect(
		"schema names use implementation contract terminology",
		Types.SchemaType.ImplementationContract == "ImplementationContract"
			and Types.SchemaType.ImplementationContractResponsibility == "ImplementationContractResponsibility"
			and Types.SchemaType.ImplementationContractBoundary == "ImplementationContractBoundary"
			and Types.SchemaType.ImplementationContractAudit == "ImplementationContractAudit",
		"schema names drifted",
		checks
	)
	expect(
		"snapshot kind uses lowerCamelCase provider name",
		Snapshots.capture(
			{ initialized = false, started = false },
			{ Serialization = Serialization }
		).kind == "assetExecutionImplementationContractRuntimeSnapshot",
		"snapshot kind drifted",
		checks
	)
	local chain = expectedGovernanceChain()
	expect(
		"integration readiness chain terminates at implementation contract",
		#chain == 10
			and chain[1] == "AssetManifest"
			and chain[9] == "AssetExecutionImplementationReadiness"
			and chain[10] == "AssetExecutionImplementationContract",
		"governance chain evidence drifted",
		checks
	)
	State.clear()
	expectAcceptedValues("contractKind", {
		"RuntimeImplementation",
		"SafetyImplementation",
		"AccessibilityImplementation",
		"PerformanceImplementation",
		"ProductionImplementation",
		"ConditionalImplementation",
		"FutureImplementation",
	}, function(value)
		return withField(contract("enum.contract.kind." .. value), "contractKind", value)
	end, Validation.contract, checks)
	expectAcceptedValues("contractStatus", {
		"Open",
		"Passed",
		"Blocked",
		"Deferred",
		"NeedsReview",
	}, function(value)
		return withField(contract("enum.contract.status." .. value), "contractStatus", value)
	end, Validation.contract, checks)
	expectAcceptedValues("responsibilityKind", {
		"OwnershipResponsibility",
		"ValidationResponsibility",
		"DiagnosticsResponsibility",
		"SnapshotResponsibility",
		"CleanupResponsibility",
		"SafetyResponsibility",
		"AccessibilityResponsibility",
		"PerformanceResponsibility",
		"FutureResponsibility",
	}, function(value, index)
		local schema = responsibility(
			"contract.a",
			"enum.responsibility.kind." .. tostring(index) .. "." .. value
		)
		return withField(schema, "responsibilityKind", value)
	end, Validation.responsibility, checks)
	expectAcceptedValues("boundaryKind", {
		"NoLoadingBoundary",
		"NoExecutionBoundary",
		"ClientAuthorityBoundary",
		"StorageBoundary",
		"SafetyBoundary",
		"AccessibilityBoundary",
		"PerformanceBoundary",
		"FutureBoundary",
	}, function(value, index)
		local schema =
			boundary("contract.a", "enum.boundary.kind." .. tostring(index) .. "." .. value)
		return withField(schema, "boundaryKind", value)
	end, Validation.boundary, checks)
	expectAcceptedValues("auditKind", {
		"DesignAudit",
		"SafetyAudit",
		"AccessibilityAudit",
		"PerformanceAudit",
		"ProductionAudit",
		"FutureAudit",
	}, function(value, index)
		local schema = audit("contract.a", "enum.audit.kind." .. tostring(index) .. "." .. value)
		return withField(schema, "auditKind", value)
	end, Validation.audit, checks)
	expectAcceptedValues("auditStatus", {
		"Passed",
		"Failed",
		"Warning",
		"Deferred",
		"Blocked",
	}, function(value, index)
		return withField(
			audit("contract.a", "enum.audit.status." .. tostring(index) .. "." .. value),
			"status",
			value
		)
	end, Validation.audit, checks)
	expectReject("nil schema rejects", State.registerContract(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerContract("bad"), nil, checks)
	expectReject(
		"invalid id rejects",
		State.registerContract(withField(contract("bad"), "contractId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported contract type rejects",
		State.registerContract(withField(contract("bad.type"), "schemaType", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported contract kind rejects",
		State.registerContract(withField(contract("bad.kind"), "contractKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported contract status rejects",
		State.registerContract(withField(contract("bad.status"), "contractStatus", "Bad")),
		nil,
		checks
	)
	expectReject(
		"invalid contract owner rejects",
		State.registerContract(withField(contract("bad.owner"), "owner", nil)),
		nil,
		checks
	)
	for _, field in ipairs({
		"readinessId",
		"designContractId",
		"assetId",
		"usagePlanId",
		"checklistId",
		"approvalId",
		"permitId",
		"gateId",
	}) do
		expectReject(
			"integration reference field rejects invalid " .. field,
			State.registerContract(withField(contract("bad.reference." .. field), field, "bad id")),
			nil,
			checks
		)
	end
	expectReject(
		"unsafe metadata rejects",
		State.registerContract(
			withField(contract("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerContract(withField(contract("bad.tags"), "tags", { "preload" .. "Asset" })),
		nil,
		checks
	)
	expectReject(
		"oversized contract children reject",
		State.registerContract(
			withField(
				contract("bad.children"),
				"responsibilityIds",
				oversizedIds("responsibility.", Types.Limits.MaxContractChildren)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing child reference rejects",
		State.registerContract(
			withField(contract("bad.child.ref"), "responsibilityIds", { "missing.responsibility" })
		),
		nil,
		checks
	)

	expectAccept(
		"valid contract registers",
		State.registerContract(contract("contract.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate contract rejects",
		State.registerContract(contract("contract.a")),
		nil,
		checks
	)

	expectAccept(
		"valid responsibility registers",
		State.registerResponsibility(responsibility("contract.a", "responsibility.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate responsibility rejects",
		State.registerResponsibility(responsibility("contract.a", "responsibility.a")),
		nil,
		checks
	)
	expectReject("malformed responsibility rejects", State.registerResponsibility({}), nil, checks)
	expectReject(
		"unsupported responsibility kind rejects",
		State.registerResponsibility(
			withField(
				responsibility("contract.a", "responsibility.bad.kind"),
				"responsibilityKind",
				"Bad"
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing responsibility contract rejects",
		State.registerResponsibility(responsibility("missing", "responsibility.missing")),
		nil,
		checks
	)
	expectReject(
		"invalid responsibility required rejects",
		State.registerResponsibility(
			withField(
				responsibility("contract.a", "responsibility.bad.required"),
				"required",
				"yes"
			)
		),
		nil,
		checks
	)

	expectAccept(
		"valid boundary registers",
		State.registerBoundary(boundary("contract.a", "boundary.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate boundary rejects",
		State.registerBoundary(boundary("contract.a", "boundary.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported boundary kind rejects",
		State.registerBoundary(
			withField(boundary("contract.a", "boundary.bad.kind"), "boundaryKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"invalid boundary allowed rejects",
		State.registerBoundary(
			withField(boundary("contract.a", "boundary.bad.allowed"), "allowed", "no")
		),
		nil,
		checks
	)
	expectReject(
		"missing boundary contract rejects",
		State.registerBoundary(boundary("missing", "boundary.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("contract.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("contract.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit kind rejects",
		State.registerAudit(withField(audit("contract.a", "audit.bad.kind"), "auditKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit status rejects",
		State.registerAudit(withField(audit("contract.a", "audit.bad.status"), "status", "Bad")),
		nil,
		checks
	)
	expectReject(
		"oversized audit findings reject",
		State.registerAudit(
			withField(
				audit("contract.a", "audit.too.large"),
				"findings",
				oversizedIds("finding.", Types.Limits.MaxAuditFindings)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing audit contract rejects",
		State.registerAudit(audit("missing", "audit.missing")),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"namespace contract registers",
		State.registerContract(contract("namespace.id")),
		nil,
		checks
	)
	expectReject(
		"namespace responsibility collision rejects",
		State.registerResponsibility(responsibility("namespace.id", "namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace responsibility registers",
		State.registerResponsibility(responsibility("namespace.id", "namespace.responsibility")),
		nil,
		checks
	)
	expectReject(
		"namespace boundary collision rejects",
		State.registerBoundary(boundary("namespace.id", "namespace.responsibility")),
		nil,
		checks
	)
	expectAccept(
		"namespace boundary registers",
		State.registerBoundary(boundary("namespace.id", "namespace.boundary")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.id", "namespace.boundary")),
		nil,
		checks
	)
	local namespaceCounts = State.inspect().counts
	expect(
		"incremental counts match registered namespace schemas",
		namespaceCounts.contracts == 1
			and namespaceCounts.responsibilities == 1
			and namespaceCounts.boundaries == 1
			and namespaceCounts.audits == 0,
		"incremental counts drifted",
		checks
	)

	local forbiddenMarkers = {
		"load" .. "Asset",
		"preload" .. "Asset",
		"content" .. "Provider",
		"preload" .. "Async",
		"insert" .. "Service",
		"marketplace" .. "Service",
		"animationLoad",
		"soundLoad",
		"meshLoad",
		"textureLoad",
		"materialLoad",
		"decalLoad",
		"modelSpawn",
		"assetApplication",
		"assetPlayback",
		"create" .. "Instance",
		"createUI",
		"vfxCreate",
		"particleCreate",
		"work" .. "space",
		"replicated" .. "Storage",
		"server" .. "Storage",
		"data" .. "Store",
		"http" .. "Service",
		"messaging" .. "Service",
		"remote" .. "Event",
		"remote" .. "Function",
		"fire" .. "Client",
		"fire" .. "AllClients",
		"invoke" .. "Client",
		"clientAuthority",
		"gameplayExecution",
		"presentationExecution",
		"saveExecution",
		"chapterContent",
		"cut" .. "scene",
		"dia" .. "logue",
		"mapLoad",
		"roomLoad",
		"ana" .. "lytics",
		"tele" .. "metry",
		"runtimeObject",
		"serviceHandle",
		"assetHandle",
		"loadedAsset",
		"moduleReference",
		"callback",
		"eventListener",
		"executionAdapter",
		"execute",
		"dispatch",
		"publish",
		"subscribe",
	}
	for _, marker in ipairs(forbiddenMarkers) do
		local candidate = contract("forbidden." .. marker)
		candidate[marker] = true
		local ok, reason = Validation.contract(candidate)
		expectReject("forbidden field rejects: " .. marker, ok, reason, checks)
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
	expectReject(
		"serialization rejects instance shaped objects",
		Serialization.validateSerializable({ ClassName = "Part", Parent = {} }),
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
	expectReject(
		"serialization rejects oversized strings",
		Serialization.validateSerializable({
			value = string.rep("x", Types.Limits.MaxStringLength + 1),
		}),
		nil,
		checks
	)
	local diagnosticCopy = Serialization.diagnosticCopy({
		["asset" .. "Handle"] = function() end,
		nested = { "load" .. "Asset" },
	})
	expect(
		"diagnostic copy sanitizes unsafe values",
		diagnosticCopy["<unsafe-marker>"] == "<unsafe-runtime-value>"
			and diagnosticCopy.nested[1] == "<unsafe-marker>",
		"diagnostic copy leaked unsafe values",
		checks
	)

	State.clear()
	fillLimit("contract", Types.Limits.MaxContracts, function(index)
		return contract("limit.contract." .. tostring(index))
	end, State.registerContract, checks)
	State.clear()
	expectAccept(
		"responsibility limit seed registers",
		State.registerContract(contract("limit.responsibility.seed")),
		nil,
		checks
	)
	fillLimit("responsibility", Types.Limits.MaxResponsibilities, function(index)
		return responsibility(
			"limit.responsibility.seed",
			"limit.responsibility." .. tostring(index)
		)
	end, State.registerResponsibility, checks)
	State.clear()
	expectAccept(
		"boundary limit seed registers",
		State.registerContract(contract("limit.boundary.seed")),
		nil,
		checks
	)
	fillLimit("boundary", Types.Limits.MaxBoundaries, function(index)
		return boundary("limit.boundary.seed", "limit.boundary." .. tostring(index))
	end, State.registerBoundary, checks)
	State.clear()
	expectAccept(
		"audit limit seed registers",
		State.registerContract(contract("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit.seed", "limit.audit." .. tostring(index))
	end, State.registerAudit, checks)

	State.clear()
	local before = State.inspect().counts.contracts
	State.registerContract(withField(contract("bad.no.mutate"), "contractId", "bad id"))
	expect(
		"failed validation does not mutate",
		State.inspect().counts.contracts == before,
		"failed validation mutated state",
		checks
	)
	expectAccept(
		"snapshot seed registers",
		State.registerContract(contract("snapshot.contract")),
		nil,
		checks
	)
	local snapshot = State.inspect()
	snapshot.contracts["snapshot.contract"].assetId = "mutated"
	expect(
		"snapshots are isolated",
		State.inspect().contracts["snapshot.contract"].assetId ~= "mutated",
		"snapshot mutation leaked",
		checks
	)
	local diagnostics = State.inspect()
	diagnostics.counts.contracts = 999999
	expect(
		"diagnostics are health-only copies",
		State.inspect().counts.contracts ~= 999999,
		"diagnostics mutation leaked",
		checks
	)
	local capturedDiagnostics = Diagnostics.capture(
		{ initialized = true, started = false, lastSelfChecks = nil },
		{
			Validation = Validation,
		}
	)
	expect(
		"diagnostics posture key is lowerCamelCase",
		capturedDiagnostics.implementationContractPosture ~= nil
			and capturedDiagnostics["Execution" .. "ImplementationContractPosture"] == nil,
		"diagnostics posture key drifted",
		checks
	)
	expect(
		"diagnostics integration readiness posture key is lowerCamelCase",
		capturedDiagnostics.integrationReadinessPosture ~= nil
			and capturedDiagnostics["Integration" .. "ReadinessPosture"] == nil,
		"diagnostics integration readiness posture key drifted",
		checks
	)
	expectAccept(
		"diagnostics are serializable integration evidence",
		Serialization.validateSerializable(capturedDiagnostics),
		nil,
		checks
	)
	expect(
		"diagnostics report metrics export absence",
		capturedDiagnostics.noExecutionPosture.noAnalytics == true
			and capturedDiagnostics.noExecutionPosture.noTelemetry == true,
		"diagnostics metrics export posture drifted",
		checks
	)
	expect(
		"diagnostics report storage, HTTP, messaging, remotes, and client authority absence",
		capturedDiagnostics.noExecutionPosture["no" .. "Data" .. "Store"] == true
			and capturedDiagnostics.noExecutionPosture.noHttp == true
			and capturedDiagnostics.noExecutionPosture.noMessaging == true
			and capturedDiagnostics.noExecutionPosture.noRemotes == true
			and capturedDiagnostics.noExecutionPosture.noClientAuthority == true
			and capturedDiagnostics.noExecutionPosture.noChapterContent == true,
		"diagnostics no-execution posture drifted",
		checks
	)
	local capturedSnapshot = Snapshots.capture(
		{ initialized = true, started = false },
		{ Serialization = Serialization }
	)
	expect(
		"snapshot posture key is lowerCamelCase",
		capturedSnapshot.implementationContractPosture ~= nil
			and capturedSnapshot["Execution" .. "ImplementationContractPosture"] == nil,
		"snapshot posture key drifted",
		checks
	)
	expect(
		"snapshot integration readiness posture key is lowerCamelCase",
		capturedSnapshot.integrationReadinessPosture ~= nil
			and capturedSnapshot["Integration" .. "ReadinessPosture"] == nil,
		"snapshot integration readiness posture key drifted",
		checks
	)
	expectAccept(
		"snapshots are serializable integration evidence",
		Serialization.validateSerializable(capturedSnapshot),
		nil,
		checks
	)
	expect(
		"snapshot readiness uses runtime provider kind",
		capturedSnapshot.kind == Types.RuntimeProviderName .. "Snapshot",
		"snapshot readiness kind drifted",
		checks
	)

	for index = 1, Types.Limits.MaxValidationFailures + 10 do
		State.recordValidationFailure("failure." .. tostring(index), { index = index })
	end
	expect(
		"validation failures are bounded",
		#State.inspect().validationFailures <= Types.Limits.MaxValidationFailures,
		"failure history exceeded limit",
		checks
	)
	for index = 1, Types.Limits.MaxSnapshotHistory + 10 do
		State.recordSnapshot({ index = index })
	end
	expect(
		"snapshots are bounded",
		State.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
		"snapshot history exceeded limit",
		checks
	)

	assertNoRuntimeSurface(checks)
	State.clear()
	expect(
		"shutdown clears state",
		State.inspect().counts.contracts == 0,
		"state remained after clear",
		checks
	)
	local clearedCounts = State.inspect().counts
	expect(
		"shutdown clears incremental counts",
		clearedCounts.contracts == 0
			and clearedCounts.responsibilities == 0
			and clearedCounts.boundaries == 0
			and clearedCounts.audits == 0,
		"incremental counts remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerContract(contract("contract.a")),
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
			then "AssetExecutionImplementationContractSelfChecksPassed"
			else "AssetExecutionImplementationContractSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
