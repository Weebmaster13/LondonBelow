--!strict

local Diagnostics = require(script.Parent.AssetExecutionImplementationReadinessDiagnostics)
local Serialization = require(script.Parent.AssetExecutionImplementationReadinessSerialization)
local Snapshots = require(script.Parent.AssetExecutionImplementationReadinessSnapshots)
local State = require(script.Parent.AssetExecutionImplementationReadinessState)
local Types = require(script.Parent.AssetExecutionImplementationReadinessTypes)
local Validation = require(script.Parent.AssetExecutionImplementationReadinessValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function readiness(id: string): any
	return {
		readinessId = id,
		proposedRuntimeName = "Runtime." .. id,
		contractId = "contract." .. id,
		reviewId = "review." .. id,
		assetId = "asset." .. id,
		usagePlanId = "usage." .. id,
		checklistId = "checklist." .. id,
		approvalId = "approval." .. id,
		permitId = "permit." .. id,
		gateId = "gate." .. id,
		readinessKind = "ImplementationPlan",
		readinessStatus = "NeedsReview",
		reviewer = "System",
		tags = { "schema" },
		schemaType = Types.SchemaType.ImplementationReadiness,
	}
end

local function checklist(readinessId: string, id: string): any
	return {
		checklistId = id,
		readinessId = readinessId,
		checklistKind = "OwnershipChecklist",
		required = true,
		passed = false,
		summary = "metadata only",
		schemaType = Types.SchemaType.ImplementationReadinessChecklist,
	}
end

local function gap(readinessId: string, id: string): any
	return {
		gapId = id,
		readinessId = readinessId,
		gapKind = "DesignGap",
		severity = "Low",
		resolved = false,
		summary = "metadata only",
		schemaType = Types.SchemaType.ImplementationReadinessGap,
	}
end

local function audit(readinessId: string, id: string): any
	return {
		auditId = id,
		readinessId = readinessId,
		auditKind = "DesignAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		schemaType = Types.SchemaType.ImplementationReadinessAudit,
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
		worldMutation = false,
		storageMutation = false,
		remotes = false,
		clientTruth = false,
		dataPersistence = false,
		httpLayer = false,
		messagingLayer = false,
		analytics = false,
		telemetry = false,
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
		Types.RuntimeProviderName == "assetExecutionImplementationReadinessRuntime",
		"runtime provider name drifted",
		checks
	)
	expect(
		"schema names use readiness terminology",
		Types.SchemaType.ImplementationReadiness == "ImplementationReadiness"
			and Types.SchemaType.ImplementationReadinessChecklist == "ImplementationReadinessChecklist"
			and Types.SchemaType.ImplementationReadinessGap == "ImplementationReadinessGap"
			and Types.SchemaType.ImplementationReadinessAudit == "ImplementationReadinessAudit",
		"schema names drifted",
		checks
	)
	expectReject("nil schema rejects", State.registerReadiness(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerReadiness("bad"), nil, checks)
	expectReject(
		"invalid id rejects",
		State.registerReadiness(withField(readiness("bad"), "readinessId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported readiness type rejects",
		State.registerReadiness(withField(readiness("bad.type"), "schemaType", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported readiness kind rejects",
		State.registerReadiness(withField(readiness("bad.kind"), "readinessKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported readiness status rejects",
		State.registerReadiness(withField(readiness("bad.status"), "readinessStatus", "Bad")),
		nil,
		checks
	)
	expectReject(
		"invalid readiness reviewer rejects",
		State.registerReadiness(withField(readiness("bad.reviewer"), "reviewer", nil)),
		nil,
		checks
	)
	expectReject(
		"unsafe metadata rejects",
		State.registerReadiness(
			withField(readiness("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerReadiness(withField(readiness("bad.tags"), "tags", { "preload" .. "Asset" })),
		nil,
		checks
	)
	expectReject(
		"oversized readiness children reject",
		State.registerReadiness(
			withField(
				readiness("bad.children"),
				"checklistIds",
				oversizedIds("checklist.", Types.Limits.MaxReadinessChildren)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing child reference rejects",
		State.registerReadiness(
			withField(readiness("bad.child.ref"), "checklistIds", { "missing.checklist" })
		),
		nil,
		checks
	)

	expectAccept(
		"valid readiness registers",
		State.registerReadiness(readiness("readiness.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate readiness rejects",
		State.registerReadiness(readiness("readiness.a")),
		nil,
		checks
	)

	expectAccept(
		"valid checklist registers",
		State.registerChecklist(checklist("readiness.a", "checklist.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate checklist rejects",
		State.registerChecklist(checklist("readiness.a", "checklist.a")),
		nil,
		checks
	)
	expectReject("malformed checklist rejects", State.registerChecklist({}), nil, checks)
	expectReject(
		"unsupported checklist kind rejects",
		State.registerChecklist(
			withField(checklist("readiness.a", "checklist.bad.kind"), "checklistKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing checklist readiness rejects",
		State.registerChecklist(checklist("missing", "checklist.missing")),
		nil,
		checks
	)
	expectReject(
		"invalid checklist required rejects",
		State.registerChecklist(
			withField(checklist("readiness.a", "checklist.bad.required"), "required", "yes")
		),
		nil,
		checks
	)

	expectAccept("valid gap registers", State.registerGap(gap("readiness.a", "gap.a")), nil, checks)
	expectReject(
		"duplicate gap rejects",
		State.registerGap(gap("readiness.a", "gap.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported gap kind rejects",
		State.registerGap(withField(gap("readiness.a", "gap.bad.kind"), "gapKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"invalid gap resolved rejects",
		State.registerGap(withField(gap("readiness.a", "gap.bad.resolved"), "resolved", "no")),
		nil,
		checks
	)
	expectReject(
		"missing gap readiness rejects",
		State.registerGap(gap("missing", "gap.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("readiness.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("readiness.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit kind rejects",
		State.registerAudit(withField(audit("readiness.a", "audit.bad.kind"), "auditKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit status rejects",
		State.registerAudit(withField(audit("readiness.a", "audit.bad.status"), "status", "Bad")),
		nil,
		checks
	)
	expectReject(
		"oversized audit findings reject",
		State.registerAudit(
			withField(
				audit("readiness.a", "audit.too.large"),
				"findings",
				oversizedIds("finding.", Types.Limits.MaxAuditFindings)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing audit readiness rejects",
		State.registerAudit(audit("missing", "audit.missing")),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"namespace contract registers",
		State.registerReadiness(readiness("namespace.id")),
		nil,
		checks
	)
	expectReject(
		"namespace checklist collision rejects",
		State.registerChecklist(checklist("namespace.id", "namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace checklist registers",
		State.registerChecklist(checklist("namespace.id", "namespace.checklist")),
		nil,
		checks
	)
	expectReject(
		"namespace gap collision rejects",
		State.registerGap(gap("namespace.id", "namespace.checklist")),
		nil,
		checks
	)
	expectAccept(
		"namespace gap registers",
		State.registerGap(gap("namespace.id", "namespace.gap")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.id", "namespace.gap")),
		nil,
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
		"clientAuthority",
		"gameplayExecution",
		"presentationExecution",
		"saveExecution",
		"chapterContent",
		"cutscene",
		"dialogue",
		"mapLoad",
		"roomLoad",
		"runtimeObject",
		"serviceHandle",
		"assetHandle",
		"loadedAsset",
		"moduleReference",
		"callback",
		"eventListener",
		"executionAdapter",
	}
	for _, marker in ipairs(forbiddenMarkers) do
		local candidate = readiness("forbidden." .. marker)
		candidate[marker] = true
		local ok, reason = Validation.readiness(candidate)
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
	fillLimit("readiness", Types.Limits.MaxReadinessRecords, function(index)
		return readiness("limit.readiness." .. tostring(index))
	end, State.registerReadiness, checks)
	State.clear()
	expectAccept(
		"checklist limit seed registers",
		State.registerReadiness(readiness("limit.checklist.seed")),
		nil,
		checks
	)
	fillLimit("checklist", Types.Limits.MaxChecklists, function(index)
		return checklist("limit.checklist.seed", "limit.checklist." .. tostring(index))
	end, State.registerChecklist, checks)
	State.clear()
	expectAccept(
		"gap limit seed registers",
		State.registerReadiness(readiness("limit.gap.seed")),
		nil,
		checks
	)
	fillLimit("gap", Types.Limits.MaxGaps, function(index)
		return gap("limit.gap.seed", "limit.gap." .. tostring(index))
	end, State.registerGap, checks)
	State.clear()
	expectAccept(
		"audit limit seed registers",
		State.registerReadiness(readiness("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit.seed", "limit.audit." .. tostring(index))
	end, State.registerAudit, checks)

	State.clear()
	local before = State.inspect().counts.readinessRecords
	State.registerReadiness(withField(readiness("bad.no.mutate"), "readinessId", "bad id"))
	expect(
		"failed validation does not mutate",
		State.inspect().counts.readinessRecords == before,
		"failed validation mutated state",
		checks
	)
	expectAccept(
		"snapshot seed registers",
		State.registerReadiness(readiness("snapshot.readiness")),
		nil,
		checks
	)
	local snapshot = State.inspect()
	snapshot.readinesss["snapshot.readiness"].assetId = "mutated"
	expect(
		"snapshots are isolated",
		State.inspect().readinessRecords["snapshot.readiness"].assetId ~= "mutated",
		"snapshot mutation leaked",
		checks
	)
	local diagnostics = State.inspect()
	diagnostics.counts.readinessRecords = 999999
	expect(
		"diagnostics are health-only copies",
		State.inspect().counts.readinessRecords ~= 999999,
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
		capturedDiagnostics.implementationReadinessPosture ~= nil
			and capturedDiagnostics["Execution" .. "ImplementationReadinessPosture"] == nil,
		"diagnostics posture key drifted",
		checks
	)
	local capturedSnapshot = Snapshots.capture(
		{ initialized = true, started = false },
		{ Serialization = Serialization }
	)
	expect(
		"snapshot posture key is lowerCamelCase",
		capturedSnapshot.implementationReadinessPosture ~= nil
			and capturedSnapshot["Execution" .. "ImplementationReadinessPosture"] == nil,
		"snapshot posture key drifted",
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
		State.inspect().counts.readinessRecords == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerReadiness(readiness("readiness.a")),
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
			then "AssetExecutionImplementationReadinessSelfChecksPassed"
			else "AssetExecutionImplementationReadinessSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
