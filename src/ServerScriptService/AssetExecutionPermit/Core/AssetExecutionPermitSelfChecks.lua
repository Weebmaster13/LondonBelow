--!strict

local Serialization = require(script.Parent.AssetExecutionPermitSerialization)
local State = require(script.Parent.AssetExecutionPermitState)
local Types = require(script.Parent.AssetExecutionPermitTypes)
local Validation = require(script.Parent.AssetExecutionPermitValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function permit(id: string): any
	return {
		permitId = id,
		assetId = "asset." .. id,
		usagePlanId = "usage." .. id,
		checklistId = "checklist." .. id,
		approvalId = "approval." .. id,
		permitKind = "DesignPermit",
		permitStatus = "NeedsReview",
		issuedBy = "System",
		tags = { "schema" },
		schemaType = Types.SchemaType.ExecutionPermit,
	}
end

local function scope(permitId: string, id: string): any
	return {
		scopeId = id,
		permitId = permitId,
		scopeKind = "RuntimeScope",
		runtimeName = "FutureRuntime",
		allowed = false,
		summary = "metadata only",
		schemaType = Types.SchemaType.ExecutionPermitScope,
	}
end

local function restriction(permitId: string, id: string): any
	return {
		restrictionId = id,
		permitId = permitId,
		restrictionKind = "MetadataRestriction",
		severity = "Low",
		summary = "metadata only",
		active = true,
		schemaType = Types.SchemaType.ExecutionPermitRestriction,
	}
end

local function audit(permitId: string, id: string): any
	return {
		auditId = id,
		permitId = permitId,
		auditKind = "DesignAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		schemaType = Types.SchemaType.ExecutionPermitAudit,
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
	expectReject("nil schema rejects", State.registerPermit(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerPermit("bad"), nil, checks)
	expectReject(
		"invalid id rejects",
		State.registerPermit(withField(permit("bad"), "permitId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported permit type rejects",
		State.registerPermit(withField(permit("bad.type"), "schemaType", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported permit kind rejects",
		State.registerPermit(withField(permit("bad.kind"), "permitKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported permit status rejects",
		State.registerPermit(withField(permit("bad.status"), "permitStatus", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsafe metadata rejects",
		State.registerPermit(
			withField(permit("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerPermit(withField(permit("bad.tags"), "tags", { "preload" .. "Asset" })),
		nil,
		checks
	)
	expectReject(
		"oversized permit children reject",
		State.registerPermit(
			withField(
				permit("bad.children"),
				"scopeIds",
				oversizedIds("scope.", Types.Limits.MaxPermitChildren)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing child reference rejects",
		State.registerPermit(withField(permit("bad.child.ref"), "scopeIds", { "missing.scope" })),
		nil,
		checks
	)

	expectAccept("valid permit registers", State.registerPermit(permit("permit.a")), nil, checks)
	expectReject("duplicate permit rejects", State.registerPermit(permit("permit.a")), nil, checks)

	expectAccept(
		"valid scope registers",
		State.registerScope(scope("permit.a", "scope.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate scope rejects",
		State.registerScope(scope("permit.a", "scope.a")),
		nil,
		checks
	)
	expectReject("malformed scope rejects", State.registerScope({}), nil, checks)
	expectReject(
		"unsupported scope kind rejects",
		State.registerScope(withField(scope("permit.a", "scope.bad.kind"), "scopeKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"missing scope permit rejects",
		State.registerScope(scope("missing", "scope.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid restriction registers",
		State.registerRestriction(restriction("permit.a", "restriction.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate restriction rejects",
		State.registerRestriction(restriction("permit.a", "restriction.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported restriction kind rejects",
		State.registerRestriction(
			withField(restriction("permit.a", "restriction.bad.kind"), "restrictionKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported restriction severity rejects",
		State.registerRestriction(
			withField(restriction("permit.a", "restriction.bad.severity"), "severity", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing restriction permit rejects",
		State.registerRestriction(restriction("missing", "restriction.missing")),
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
		"missing audit permit rejects",
		State.registerAudit(audit("missing", "audit.missing")),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"namespace permit registers",
		State.registerPermit(permit("namespace.id")),
		nil,
		checks
	)
	expectReject(
		"namespace scope collision rejects",
		State.registerScope(scope("namespace.id", "namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace scope registers",
		State.registerScope(scope("namespace.id", "namespace.scope")),
		nil,
		checks
	)
	expectReject(
		"namespace restriction collision rejects",
		State.registerRestriction(restriction("namespace.id", "namespace.scope")),
		nil,
		checks
	)
	expectAccept(
		"namespace restriction registers",
		State.registerRestriction(restriction("namespace.id", "namespace.restriction")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.id", "namespace.restriction")),
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
		local candidate = permit("forbidden." .. marker)
		candidate[marker] = true
		local ok, reason = Validation.permit(candidate)
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
	fillLimit("permit", Types.Limits.MaxPermits, function(index)
		return permit("limit.permit." .. tostring(index))
	end, State.registerPermit, checks)
	State.clear()
	expectAccept(
		"scope limit seed registers",
		State.registerPermit(permit("limit.scope.seed")),
		nil,
		checks
	)
	fillLimit("scope", Types.Limits.MaxScopes, function(index)
		return scope("limit.scope.seed", "limit.scope." .. tostring(index))
	end, State.registerScope, checks)
	State.clear()
	expectAccept(
		"restriction limit seed registers",
		State.registerPermit(permit("limit.restriction.seed")),
		nil,
		checks
	)
	fillLimit("restriction", Types.Limits.MaxRestrictions, function(index)
		return restriction("limit.restriction.seed", "limit.restriction." .. tostring(index))
	end, State.registerRestriction, checks)
	State.clear()
	expectAccept(
		"audit limit seed registers",
		State.registerPermit(permit("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit.seed", "limit.audit." .. tostring(index))
	end, State.registerAudit, checks)

	State.clear()
	local before = State.inspect().counts.permits
	State.registerPermit(withField(permit("bad.no.mutate"), "permitId", "bad id"))
	expect(
		"failed validation does not mutate",
		State.inspect().counts.permits == before,
		"failed validation mutated state",
		checks
	)
	expectAccept(
		"snapshot seed registers",
		State.registerPermit(permit("snapshot.permit")),
		nil,
		checks
	)
	local snapshot = State.inspect()
	snapshot.permits["snapshot.permit"].assetId = "mutated"
	expect(
		"snapshots are isolated",
		State.inspect().permits["snapshot.permit"].assetId ~= "mutated",
		"snapshot mutation leaked",
		checks
	)
	local diagnostics = State.inspect()
	diagnostics.counts.permits = 999999
	expect(
		"diagnostics are health-only copies",
		State.inspect().counts.permits ~= 999999,
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
		State.inspect().counts.permits == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerPermit(permit("permit.a")),
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
			then "AssetExecutionPermitSelfChecksPassed"
			else "AssetExecutionPermitSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
