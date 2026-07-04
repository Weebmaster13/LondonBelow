--!strict

local Serialization = require(script.Parent.AssetApprovalLedgerSerialization)
local State = require(script.Parent.AssetApprovalLedgerState)
local Types = require(script.Parent.AssetApprovalLedgerTypes)
local Validation = require(script.Parent.AssetApprovalLedgerValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function approval(id: string): any
	return {
		approvalId = id,
		assetId = "asset." .. id,
		usagePlanId = "usage." .. id,
		checklistId = "checklist." .. id,
		approvalKind = "DesignApproval",
		approvalStatus = "NeedsReview",
		approver = "System",
		tags = { "schema" },
		schemaType = Types.SchemaType.ApprovalRecord,
	}
end

local function condition(approvalId: string, id: string): any
	return {
		conditionId = id,
		approvalId = approvalId,
		conditionKind = "MetadataCondition",
		required = true,
		satisfied = false,
		summary = "metadata only",
		schemaType = Types.SchemaType.ApprovalCondition,
	}
end

local function revocation(approvalId: string, id: string): any
	return {
		revocationId = id,
		approvalId = approvalId,
		revocationKind = "PolicyRevocation",
		revokedBy = "System",
		reason = "metadata only",
		active = false,
		schemaType = Types.SchemaType.ApprovalRevocation,
	}
end

local function audit(approvalId: string, id: string): any
	return {
		auditId = id,
		approvalId = approvalId,
		auditKind = "DesignAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		schemaType = Types.SchemaType.ApprovalAudit,
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
	expectReject("nil schema rejects", State.registerApproval(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerApproval("bad"), nil, checks)
	expectReject(
		"invalid id rejects",
		State.registerApproval(withField(approval("bad"), "approvalId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported approval type rejects",
		State.registerApproval(withField(approval("bad.type"), "schemaType", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported approval kind rejects",
		State.registerApproval(withField(approval("bad.kind"), "approvalKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported approval status rejects",
		State.registerApproval(withField(approval("bad.status"), "approvalStatus", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsafe metadata rejects",
		State.registerApproval(
			withField(approval("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerApproval(withField(approval("bad.tags"), "tags", { "preload" .. "Asset" })),
		nil,
		checks
	)
	expectReject(
		"oversized approval children reject",
		State.registerApproval(
			withField(
				approval("bad.children"),
				"conditionIds",
				oversizedIds("condition.", Types.Limits.MaxApprovalChildren)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing child reference rejects",
		State.registerApproval(
			withField(approval("bad.child.ref"), "conditionIds", { "missing.condition" })
		),
		nil,
		checks
	)

	expectAccept(
		"valid approval registers",
		State.registerApproval(approval("approval.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate approval rejects",
		State.registerApproval(approval("approval.a")),
		nil,
		checks
	)

	expectAccept(
		"valid condition registers",
		State.registerCondition(condition("approval.a", "condition.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate condition rejects",
		State.registerCondition(condition("approval.a", "condition.a")),
		nil,
		checks
	)
	expectReject("malformed condition rejects", State.registerCondition({}), nil, checks)
	expectReject(
		"unsupported condition kind rejects",
		State.registerCondition(
			withField(condition("approval.a", "condition.bad.kind"), "conditionKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing condition approval rejects",
		State.registerCondition(condition("missing", "condition.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid revocation registers",
		State.registerRevocation(revocation("approval.a", "revocation.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate revocation rejects",
		State.registerRevocation(revocation("approval.a", "revocation.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported revocation kind rejects",
		State.registerRevocation(
			withField(revocation("approval.a", "revocation.bad.kind"), "revocationKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing revocation approval rejects",
		State.registerRevocation(revocation("missing", "revocation.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("approval.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("approval.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit kind rejects",
		State.registerAudit(withField(audit("approval.a", "audit.bad.kind"), "auditKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit status rejects",
		State.registerAudit(withField(audit("approval.a", "audit.bad.status"), "status", "Bad")),
		nil,
		checks
	)
	expectReject(
		"oversized audit findings reject",
		State.registerAudit(
			withField(
				audit("approval.a", "audit.too.large"),
				"findings",
				oversizedIds("finding.", Types.Limits.MaxAuditFindings)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing audit approval rejects",
		State.registerAudit(audit("missing", "audit.missing")),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"namespace approval registers",
		State.registerApproval(approval("namespace.id")),
		nil,
		checks
	)
	expectReject(
		"namespace condition collision rejects",
		State.registerCondition(condition("namespace.id", "namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace condition registers",
		State.registerCondition(condition("namespace.id", "namespace.condition")),
		nil,
		checks
	)
	expectReject(
		"namespace revocation collision rejects",
		State.registerRevocation(revocation("namespace.id", "namespace.condition")),
		nil,
		checks
	)
	expectAccept(
		"namespace revocation registers",
		State.registerRevocation(revocation("namespace.id", "namespace.revocation")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.id", "namespace.revocation")),
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
		local candidate = approval("forbidden." .. marker)
		candidate[marker] = true
		local ok, reason = Validation.approval(candidate)
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
	fillLimit("approval", Types.Limits.MaxApprovals, function(index)
		return approval("limit.approval." .. tostring(index))
	end, State.registerApproval, checks)
	State.clear()
	expectAccept(
		"condition limit seed registers",
		State.registerApproval(approval("limit.condition.seed")),
		nil,
		checks
	)
	fillLimit("condition", Types.Limits.MaxConditions, function(index)
		return condition("limit.condition.seed", "limit.condition." .. tostring(index))
	end, State.registerCondition, checks)
	State.clear()
	expectAccept(
		"revocation limit seed registers",
		State.registerApproval(approval("limit.revocation.seed")),
		nil,
		checks
	)
	fillLimit("revocation", Types.Limits.MaxRevocations, function(index)
		return revocation("limit.revocation.seed", "limit.revocation." .. tostring(index))
	end, State.registerRevocation, checks)
	State.clear()
	expectAccept(
		"audit limit seed registers",
		State.registerApproval(approval("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit.seed", "limit.audit." .. tostring(index))
	end, State.registerAudit, checks)

	State.clear()
	local before = State.inspect().counts.approvals
	State.registerApproval(withField(approval("bad.no.mutate"), "approvalId", "bad id"))
	expect(
		"failed validation does not mutate",
		State.inspect().counts.approvals == before,
		"failed validation mutated state",
		checks
	)
	expectAccept(
		"snapshot seed registers",
		State.registerApproval(approval("snapshot.approval")),
		nil,
		checks
	)
	local snapshot = State.inspect()
	snapshot.approvals["snapshot.approval"].assetId = "mutated"
	expect(
		"snapshots are isolated",
		State.inspect().approvals["snapshot.approval"].assetId ~= "mutated",
		"snapshot mutation leaked",
		checks
	)
	local diagnostics = State.inspect()
	diagnostics.counts.approvals = 999999
	expect(
		"diagnostics are health-only copies",
		State.inspect().counts.approvals ~= 999999,
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
		State.inspect().counts.approvals == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerApproval(approval("approval.a")),
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
			then "AssetApprovalLedgerSelfChecksPassed"
			else "AssetApprovalLedgerSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
