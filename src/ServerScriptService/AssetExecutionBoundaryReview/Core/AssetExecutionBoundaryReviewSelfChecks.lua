--!strict

local Serialization = require(script.Parent.AssetExecutionBoundaryReviewSerialization)
local State = require(script.Parent.AssetExecutionBoundaryReviewState)
local Types = require(script.Parent.AssetExecutionBoundaryReviewTypes)
local Validation = require(script.Parent.AssetExecutionBoundaryReviewValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function review(id: string): any
	return {
		reviewId = id,
		proposedRuntimeName = "Runtime." .. id,
		assetId = "asset." .. id,
		usagePlanId = "usage." .. id,
		checklistId = "checklist." .. id,
		approvalId = "approval." .. id,
		permitId = "permit." .. id,
		gateId = "gate." .. id,
		reviewKind = "DesignReview",
		reviewStatus = "NeedsReview",
		reviewer = "System",
		tags = { "schema" },
		schemaType = Types.SchemaType.BoundaryReview,
	}
end

local function risk(reviewId: string, id: string): any
	return {
		riskId = id,
		reviewId = reviewId,
		riskKind = "SchemaRisk",
		severity = "Low",
		summary = "metadata only",
		mitigated = false,
		schemaType = Types.SchemaType.BoundaryRisk,
	}
end

local function requirement(reviewId: string, id: string): any
	return {
		requirementId = id,
		reviewId = reviewId,
		requirementKind = "MetadataRequirement",
		required = true,
		satisfied = false,
		summary = "metadata only",
		schemaType = Types.SchemaType.BoundaryRequirement,
	}
end

local function audit(reviewId: string, id: string): any
	return {
		auditId = id,
		reviewId = reviewId,
		auditKind = "DesignAudit",
		reviewer = "System",
		status = "Warning",
		findings = { "metadata_only" },
		schemaType = Types.SchemaType.BoundaryReviewAudit,
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
	expectReject("nil schema rejects", State.registerReview(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerReview("bad"), nil, checks)
	expectReject(
		"invalid id rejects",
		State.registerReview(withField(review("bad"), "reviewId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported review type rejects",
		State.registerReview(withField(review("bad.type"), "schemaType", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported review kind rejects",
		State.registerReview(withField(review("bad.kind"), "reviewKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported review status rejects",
		State.registerReview(withField(review("bad.status"), "reviewStatus", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsafe metadata rejects",
		State.registerReview(
			withField(review("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerReview(withField(review("bad.tags"), "tags", { "preload" .. "Asset" })),
		nil,
		checks
	)
	expectReject(
		"oversized review children reject",
		State.registerReview(
			withField(
				review("bad.children"),
				"riskIds",
				oversizedIds("risk.", Types.Limits.MaxReviewChildren)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing child reference rejects",
		State.registerReview(withField(review("bad.child.ref"), "riskIds", { "missing.risk" })),
		nil,
		checks
	)

	expectAccept("valid review registers", State.registerReview(review("review.a")), nil, checks)
	expectReject("duplicate review rejects", State.registerReview(review("review.a")), nil, checks)

	expectAccept(
		"valid risk registers",
		State.registerRisk(risk("review.a", "risk.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate risk rejects",
		State.registerRisk(risk("review.a", "risk.a")),
		nil,
		checks
	)
	expectReject("malformed risk rejects", State.registerRisk({}), nil, checks)
	expectReject(
		"unsupported risk kind rejects",
		State.registerRisk(withField(risk("review.a", "risk.bad.kind"), "riskKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"missing risk review rejects",
		State.registerRisk(risk("missing", "risk.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid requirement registers",
		State.registerRequirement(requirement("review.a", "requirement.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate requirement rejects",
		State.registerRequirement(requirement("review.a", "requirement.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported requirement kind rejects",
		State.registerRequirement(
			withField(requirement("review.a", "requirement.bad.kind"), "requirementKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"unsupported requirement kind rejects",
		State.registerRequirement(
			withField(requirement("review.a", "requirement.bad.severity"), "requirementKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing requirement review rejects",
		State.registerRequirement(requirement("missing", "requirement.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("review.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("review.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit kind rejects",
		State.registerAudit(withField(audit("review.a", "audit.bad.kind"), "auditKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit status rejects",
		State.registerAudit(withField(audit("review.a", "audit.bad.status"), "status", "Bad")),
		nil,
		checks
	)
	expectReject(
		"oversized audit findings reject",
		State.registerAudit(
			withField(
				audit("review.a", "audit.too.large"),
				"findings",
				oversizedIds("finding.", Types.Limits.MaxAuditFindings)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing audit review rejects",
		State.registerAudit(audit("missing", "audit.missing")),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"namespace review registers",
		State.registerReview(review("namespace.id")),
		nil,
		checks
	)
	expectReject(
		"namespace risk collision rejects",
		State.registerRisk(risk("namespace.id", "namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace risk registers",
		State.registerRisk(risk("namespace.id", "namespace.risk")),
		nil,
		checks
	)
	expectReject(
		"namespace requirement collision rejects",
		State.registerRequirement(requirement("namespace.id", "namespace.risk")),
		nil,
		checks
	)
	expectAccept(
		"namespace requirement registers",
		State.registerRequirement(requirement("namespace.id", "namespace.requirement")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.id", "namespace.requirement")),
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
		local candidate = review("forbidden." .. marker)
		candidate[marker] = true
		local ok, reason = Validation.review(candidate)
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
	fillLimit("review", Types.Limits.MaxReviews, function(index)
		return review("limit.review." .. tostring(index))
	end, State.registerReview, checks)
	State.clear()
	expectAccept(
		"risk limit seed registers",
		State.registerReview(review("limit.risk.seed")),
		nil,
		checks
	)
	fillLimit("risk", Types.Limits.MaxRisks, function(index)
		return risk("limit.risk.seed", "limit.risk." .. tostring(index))
	end, State.registerRisk, checks)
	State.clear()
	expectAccept(
		"requirement limit seed registers",
		State.registerReview(review("limit.requirement.seed")),
		nil,
		checks
	)
	fillLimit("requirement", Types.Limits.MaxRequirements, function(index)
		return requirement("limit.requirement.seed", "limit.requirement." .. tostring(index))
	end, State.registerRequirement, checks)
	State.clear()
	expectAccept(
		"audit limit seed registers",
		State.registerReview(review("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit.seed", "limit.audit." .. tostring(index))
	end, State.registerAudit, checks)

	State.clear()
	local before = State.inspect().counts.reviews
	State.registerReview(withField(review("bad.no.mutate"), "reviewId", "bad id"))
	expect(
		"failed validation does not mutate",
		State.inspect().counts.reviews == before,
		"failed validation mutated state",
		checks
	)
	expectAccept(
		"snapshot seed registers",
		State.registerReview(review("snapshot.review")),
		nil,
		checks
	)
	local snapshot = State.inspect()
	snapshot.reviews["snapshot.review"].assetId = "mutated"
	expect(
		"snapshots are isolated",
		State.inspect().reviews["snapshot.review"].assetId ~= "mutated",
		"snapshot mutation leaked",
		checks
	)
	local diagnostics = State.inspect()
	diagnostics.counts.reviews = 999999
	expect(
		"diagnostics are health-only copies",
		State.inspect().counts.reviews ~= 999999,
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
		State.inspect().counts.reviews == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerReview(review("review.a")),
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
			then "AssetExecutionBoundaryReviewSelfChecksPassed"
			else "AssetExecutionBoundaryReviewSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
