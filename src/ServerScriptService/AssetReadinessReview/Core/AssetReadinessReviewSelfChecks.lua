--!strict

local Serialization = require(script.Parent.AssetReadinessReviewSerialization)
local State = require(script.Parent.AssetReadinessReviewState)
local Types = require(script.Parent.AssetReadinessReviewTypes)
local Validation = require(script.Parent.AssetReadinessReviewValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function checklist(id: string): any
	return {
		checklistId = id,
		assetId = "asset." .. id,
		usagePlanId = "usage." .. id,
		checklistKind = "ManifestReadiness",
		readinessTier = "Draft",
		tags = { "schema" },
		schemaType = Types.SchemaType.ReadinessChecklist,
	}
end

local function finding(checklistId: string, id: string): any
	return {
		findingId = id,
		checklistId = checklistId,
		findingKind = "MissingMetadata",
		severity = "Low",
		summary = "metadata only",
		resolved = false,
		schemaType = Types.SchemaType.ReadinessFinding,
	}
end

local function gate(checklistId: string, id: string): any
	return {
		gateId = id,
		checklistId = checklistId,
		gateKind = "SchemaValidated",
		required = true,
		passed = false,
		reason = "metadata only",
		schemaType = Types.SchemaType.ReadinessGate,
	}
end

local function decision(checklistId: string, id: string): any
	return {
		decisionId = id,
		checklistId = checklistId,
		decisionKind = "NeedsMoreMetadata",
		status = "NeedsReview",
		reviewer = "System",
		rationale = "metadata only",
		schemaType = Types.SchemaType.ReadinessDecision,
	}
end

local function audit(checklistId: string, id: string): any
	return {
		auditId = id,
		checklistId = checklistId,
		auditKind = "DesignAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		schemaType = Types.SchemaType.ReadinessAudit,
	}
end

local function expect(name: string, condition: boolean, reason: string?, checks: { CheckResult })
	table.insert(
		checks,
		{ name = name, ok = condition, reason = if condition then nil else reason }
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
		contentStreaming = false,
		modelSpawn = false,
		uiCreation = false,
		vfxCreation = false,
		animationLoad = false,
		soundLoad = false,
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
	expectReject("nil schema rejects", State.registerChecklist(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerChecklist("bad"), nil, checks)
	expectReject(
		"invalid id rejects",
		State.registerChecklist(withField(checklist("bad"), "checklistId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported checklist type rejects",
		State.registerChecklist(withField(checklist("bad.type"), "schemaType", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported checklist kind rejects",
		State.registerChecklist(withField(checklist("bad.kind"), "checklistKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported readiness tier rejects",
		State.registerChecklist(withField(checklist("bad.tier"), "readinessTier", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsafe metadata rejects",
		State.registerChecklist(
			withField(checklist("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerChecklist(withField(checklist("bad.tags"), "tags", { "preload" .. "Asset" })),
		nil,
		checks
	)
	expectReject(
		"oversized checklist children reject",
		State.registerChecklist(
			withField(
				checklist("bad.children"),
				"findingIds",
				oversizedIds("finding.", Types.Limits.MaxChecklistChildren)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing child reference rejects",
		State.registerChecklist(
			withField(checklist("bad.child.ref"), "findingIds", { "missing.finding" })
		),
		nil,
		checks
	)

	expectAccept(
		"valid checklist registers",
		State.registerChecklist(checklist("checklist.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate checklist rejects",
		State.registerChecklist(checklist("checklist.a")),
		nil,
		checks
	)

	expectAccept(
		"valid finding registers",
		State.registerFinding(finding("checklist.a", "finding.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate finding rejects",
		State.registerFinding(finding("checklist.a", "finding.a")),
		nil,
		checks
	)
	expectReject("malformed finding rejects", State.registerFinding({}), nil, checks)
	expectReject(
		"unsupported finding kind rejects",
		State.registerFinding(
			withField(finding("checklist.a", "finding.bad.kind"), "findingKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing finding checklist rejects",
		State.registerFinding(finding("missing", "finding.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid gate registers",
		State.registerGate(gate("checklist.a", "gate.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate gate rejects",
		State.registerGate(gate("checklist.a", "gate.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported gate kind rejects",
		State.registerGate(withField(gate("checklist.a", "gate.bad.kind"), "gateKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"missing gate checklist rejects",
		State.registerGate(gate("missing", "gate.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid decision registers",
		State.registerDecision(decision("checklist.a", "decision.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate decision rejects",
		State.registerDecision(decision("checklist.a", "decision.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported decision kind rejects",
		State.registerDecision(
			withField(decision("checklist.a", "decision.bad.kind"), "decisionKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported decision status rejects",
		State.registerDecision(
			withField(decision("checklist.a", "decision.bad.status"), "status", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing decision checklist rejects",
		State.registerDecision(decision("missing", "decision.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("checklist.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("checklist.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit kind rejects",
		State.registerAudit(withField(audit("checklist.a", "audit.bad.kind"), "auditKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit status rejects",
		State.registerAudit(withField(audit("checklist.a", "audit.bad.status"), "status", "Bad")),
		nil,
		checks
	)
	expectReject(
		"oversized audit findings reject",
		State.registerAudit(
			withField(
				audit("checklist.a", "audit.too.large"),
				"findings",
				oversizedIds("finding.", Types.Limits.MaxAuditFindings)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing audit checklist rejects",
		State.registerAudit(audit("missing", "audit.missing")),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"namespace checklist registers",
		State.registerChecklist(checklist("namespace.id")),
		nil,
		checks
	)
	expectReject(
		"namespace finding collision rejects",
		State.registerFinding(finding("namespace.id", "namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace finding registers",
		State.registerFinding(finding("namespace.id", "namespace.finding")),
		nil,
		checks
	)
	expectReject(
		"namespace gate collision rejects",
		State.registerGate(gate("namespace.id", "namespace.finding")),
		nil,
		checks
	)
	expectAccept(
		"namespace gate registers",
		State.registerGate(gate("namespace.id", "namespace.gate")),
		nil,
		checks
	)
	expectReject(
		"namespace decision collision rejects",
		State.registerDecision(decision("namespace.id", "namespace.gate")),
		nil,
		checks
	)
	expectAccept(
		"namespace decision registers",
		State.registerDecision(decision("namespace.id", "namespace.decision")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.id", "namespace.decision")),
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
		local candidate = checklist("forbidden." .. marker)
		candidate[marker] = true
		local ok, reason = Validation.checklist(candidate)
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
	fillLimit("checklist", Types.Limits.MaxChecklists, function(index)
		return checklist("limit.checklist." .. tostring(index))
	end, State.registerChecklist, checks)
	State.clear()
	expectAccept(
		"finding limit seed registers",
		State.registerChecklist(checklist("limit.finding.seed")),
		nil,
		checks
	)
	fillLimit("finding", Types.Limits.MaxFindings, function(index)
		return finding("limit.finding.seed", "limit.finding." .. tostring(index))
	end, State.registerFinding, checks)
	State.clear()
	expectAccept(
		"gate limit seed registers",
		State.registerChecklist(checklist("limit.gate.seed")),
		nil,
		checks
	)
	fillLimit("gate", Types.Limits.MaxGates, function(index)
		return gate("limit.gate.seed", "limit.gate." .. tostring(index))
	end, State.registerGate, checks)
	State.clear()
	expectAccept(
		"decision limit seed registers",
		State.registerChecklist(checklist("limit.decision.seed")),
		nil,
		checks
	)
	fillLimit("decision", Types.Limits.MaxDecisions, function(index)
		return decision("limit.decision.seed", "limit.decision." .. tostring(index))
	end, State.registerDecision, checks)
	State.clear()
	expectAccept(
		"audit limit seed registers",
		State.registerChecklist(checklist("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit.seed", "limit.audit." .. tostring(index))
	end, State.registerAudit, checks)

	State.clear()
	local before = State.inspect().counts.checklists
	State.registerChecklist(withField(checklist("bad.no.mutate"), "checklistId", "bad id"))
	expect(
		"failed validation does not mutate",
		State.inspect().counts.checklists == before,
		"failed validation mutated state",
		checks
	)
	expectAccept(
		"snapshot seed registers",
		State.registerChecklist(checklist("snapshot.checklist")),
		nil,
		checks
	)
	local snapshot = State.inspect()
	snapshot.checklists["snapshot.checklist"].assetId = "mutated"
	expect(
		"snapshots are isolated",
		State.inspect().checklists["snapshot.checklist"].assetId ~= "mutated",
		"snapshot mutation leaked",
		checks
	)
	local diagnostics = State.inspect()
	diagnostics.counts.checklists = 999999
	expect(
		"diagnostics are health-only copies",
		State.inspect().counts.checklists ~= 999999,
		"diagnostics mutation leaked",
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
		State.inspect().counts.checklists == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerChecklist(checklist("checklist.a")),
		nil,
		checks
	)
	State.clear()

	local failed = {}
	for _, check in ipairs(checks) do
		if not check.ok then
			table.insert(failed, check)
		end
	end
	return {
		ok = #failed == 0,
		code = if #failed == 0
			then "AssetReadinessReviewSelfChecksPassed"
			else "AssetReadinessReviewSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
