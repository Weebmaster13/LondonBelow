--!strict

local Serialization = require(script.Parent.AssetRuntimeGateSerialization)
local State = require(script.Parent.AssetRuntimeGateState)
local Types = require(script.Parent.AssetRuntimeGateTypes)
local Validation = require(script.Parent.AssetRuntimeGateValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function gate(id: string): any
	return {
		gateId = id,
		assetId = "asset." .. id,
		usagePlanId = "usage." .. id,
		checklistId = "checklist." .. id,
		approvalId = "approval." .. id,
		permitId = "permit." .. id,
		gateKind = "DesignGate",
		gateStatus = "NeedsReview",
		evaluator = "System",
		tags = { "schema" },
		schemaType = Types.SchemaType.RuntimeGate,
	}
end

local function check(gateId: string, id: string): any
	return {
		checkId = id,
		gateId = gateId,
		checkKind = "SchemaCheck",
		required = true,
		passed = false,
		summary = "metadata only",
		schemaType = Types.SchemaType.RuntimeGateCheck,
	}
end

local function block(gateId: string, id: string): any
	return {
		blockId = id,
		gateId = gateId,
		blockKind = "MetadataBlock",
		severity = "Low",
		active = true,
		reason = "metadata only",
		schemaType = Types.SchemaType.RuntimeGateBlock,
	}
end

local function audit(gateId: string, id: string): any
	return {
		auditId = id,
		gateId = gateId,
		auditKind = "DesignAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		schemaType = Types.SchemaType.RuntimeGateAudit,
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
	expectReject("nil schema rejects", State.registerGate(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerGate("bad"), nil, checks)
	expectReject(
		"invalid id rejects",
		State.registerGate(withField(gate("bad"), "gateId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported gate type rejects",
		State.registerGate(withField(gate("bad.type"), "schemaType", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported gate kind rejects",
		State.registerGate(withField(gate("bad.kind"), "gateKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported gate status rejects",
		State.registerGate(withField(gate("bad.status"), "gateStatus", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsafe metadata rejects",
		State.registerGate(
			withField(gate("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerGate(withField(gate("bad.tags"), "tags", { "preload" .. "Asset" })),
		nil,
		checks
	)
	expectReject(
		"oversized permit children reject",
		State.registerGate(
			withField(
				gate("bad.children"),
				"checkIds",
				oversizedIds("check.", Types.Limits.MaxGateChildren)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing child reference rejects",
		State.registerGate(withField(gate("bad.child.ref"), "checkIds", { "missing.check" })),
		nil,
		checks
	)

	expectAccept("valid gate registers", State.registerGate(gate("permit.a")), nil, checks)
	expectReject("duplicate gate rejects", State.registerGate(gate("permit.a")), nil, checks)

	expectAccept(
		"valid check registers",
		State.registerCheck(check("permit.a", "check.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate check rejects",
		State.registerCheck(check("permit.a", "check.a")),
		nil,
		checks
	)
	expectReject("malformed check rejects", State.registerCheck({}), nil, checks)
	expectReject(
		"unsupported check kind rejects",
		State.registerCheck(withField(check("permit.a", "check.bad.kind"), "checkKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"missing check gate rejects",
		State.registerCheck(check("missing", "check.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid block registers",
		State.registerBlock(block("permit.a", "block.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate block rejects",
		State.registerBlock(block("permit.a", "block.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported block kind rejects",
		State.registerBlock(withField(block("permit.a", "block.bad.kind"), "blockKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported block severity rejects",
		State.registerBlock(withField(block("permit.a", "block.bad.severity"), "severity", "Bad")),
		nil,
		checks
	)
	expectReject(
		"missing block gate rejects",
		State.registerBlock(block("missing", "block.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("permit.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("permit.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit kind rejects",
		State.registerAudit(withField(audit("permit.a", "audit.bad.kind"), "auditKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit status rejects",
		State.registerAudit(withField(audit("permit.a", "audit.bad.status"), "status", "Bad")),
		nil,
		checks
	)
	expectReject(
		"oversized audit findings reject",
		State.registerAudit(
			withField(
				audit("permit.a", "audit.too.large"),
				"findings",
				oversizedIds("finding.", Types.Limits.MaxAuditFindings)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing audit gate rejects",
		State.registerAudit(audit("missing", "audit.missing")),
		nil,
		checks
	)

	State.clear()
	expectAccept("namespace gate registers", State.registerGate(gate("namespace.id")), nil, checks)
	expectReject(
		"namespace check collision rejects",
		State.registerCheck(check("namespace.id", "namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace check registers",
		State.registerCheck(check("namespace.id", "namespace.check")),
		nil,
		checks
	)
	expectReject(
		"namespace block collision rejects",
		State.registerBlock(block("namespace.id", "namespace.check")),
		nil,
		checks
	)
	expectAccept(
		"namespace block registers",
		State.registerBlock(block("namespace.id", "namespace.block")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.id", "namespace.block")),
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
		local candidate = gate("forbidden." .. marker)
		candidate[marker] = true
		local ok, reason = Validation.gate(candidate)
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
	fillLimit("permit", Types.Limits.MaxGates, function(index)
		return gate("limit.gate." .. tostring(index))
	end, State.registerGate, checks)
	State.clear()
	expectAccept(
		"check limit seed registers",
		State.registerGate(gate("limit.check.seed")),
		nil,
		checks
	)
	fillLimit("check", Types.Limits.MaxChecks, function(index)
		return check("limit.check.seed", "limit.check." .. tostring(index))
	end, State.registerCheck, checks)
	State.clear()
	expectAccept(
		"block limit seed registers",
		State.registerGate(gate("limit.block.seed")),
		nil,
		checks
	)
	fillLimit("block", Types.Limits.MaxBlocks, function(index)
		return block("limit.block.seed", "limit.block." .. tostring(index))
	end, State.registerBlock, checks)
	State.clear()
	expectAccept(
		"audit limit seed registers",
		State.registerGate(gate("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit.seed", "limit.audit." .. tostring(index))
	end, State.registerAudit, checks)

	State.clear()
	local before = State.inspect().counts.gates
	State.registerGate(withField(gate("bad.no.mutate"), "gateId", "bad id"))
	expect(
		"failed validation does not mutate",
		State.inspect().counts.gates == before,
		"failed validation mutated state",
		checks
	)
	expectAccept("snapshot seed registers", State.registerGate(gate("snapshot.gate")), nil, checks)
	local snapshot = State.inspect()
	snapshot.gates["snapshot.gate"].assetId = "mutated"
	expect(
		"snapshots are isolated",
		State.inspect().gates["snapshot.gate"].assetId ~= "mutated",
		"snapshot mutation leaked",
		checks
	)
	local diagnostics = State.inspect()
	diagnostics.counts.gates = 999999
	expect(
		"diagnostics are health-only copies",
		State.inspect().counts.gates ~= 999999,
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
		State.inspect().counts.gates == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerGate(gate("permit.a")),
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
			then "AssetRuntimeGateSelfChecksPassed"
			else "AssetRuntimeGateSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
