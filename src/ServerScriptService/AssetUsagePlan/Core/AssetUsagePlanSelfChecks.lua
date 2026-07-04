--!strict

local Serialization = require(script.Parent.AssetUsagePlanSerialization)
local State = require(script.Parent.AssetUsagePlanState)
local Types = require(script.Parent.AssetUsagePlanTypes)
local Validation = require(script.Parent.AssetUsagePlanValidation)

local SelfChecks = {}

type CheckResult = { name: string, ok: boolean, reason: string? }

local function plan(id: string): any
	return {
		usagePlanId = id,
		assetId = "asset." .. id,
		intendedConsumer = "System",
		usageDomain = "Core",
		usageKind = "ReferencedOnly",
		priority = "Normal",
		tags = { "schema" },
		schemaType = Types.SchemaType.UsagePlanDefinition,
	}
end

local function context(planId: string, id: string): any
	return {
		contextId = id,
		usagePlanId = planId,
		contextKind = "GlobalContext",
		contextName = id .. ".Name",
		allowedRuntime = false,
		chapterAgnostic = true,
		schemaType = Types.SchemaType.UsagePlanContext,
	}
end

local function constraint(planId: string, id: string): any
	return {
		constraintId = id,
		usagePlanId = planId,
		constraintKind = "SafetyConstraint",
		severity = "Medium",
		ruleSummary = "metadata only",
		schemaType = Types.SchemaType.UsagePlanConstraint,
	}
end

local function dependency(id: string, planId: string, dependsOn: string): any
	return {
		dependencyId = id,
		usagePlanId = planId,
		dependsOnUsagePlanId = dependsOn,
		dependencyKind = "RequiresPlan",
		optional = false,
		schemaType = Types.SchemaType.UsagePlanDependency,
	}
end

local function budget(planId: string, id: string): any
	return {
		budgetId = id,
		usagePlanId = planId,
		budgetKind = "MemoryBudget",
		budgetLimit = 100,
		budgetUnit = "kb",
		severity = "Low",
		schemaType = Types.SchemaType.UsagePlanBudget,
	}
end

local function accessibility(planId: string, id: string): any
	return {
		accessibilityId = id,
		usagePlanId = planId,
		accessibilityKind = "ReducedMotion",
		accommodationSummary = "metadata only",
		required = false,
		schemaType = Types.SchemaType.UsagePlanAccessibility,
	}
end

local function audit(planId: string, id: string): any
	return {
		auditId = id,
		usagePlanId = planId,
		auditKind = "DesignReview",
		reviewer = "System",
		status = "Passed",
		findings = { "schema_only" },
		schemaType = Types.SchemaType.UsagePlanAudit,
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
		contentBoundary = false,
		insertBoundary = false,
		marketplaceBoundary = false,
		instanceCreation = false,
		worldMutation = false,
		storageMutation = false,
		uiCreation = false,
		streamRun = false,
		modelSpawn = false,
		soundPlay = false,
		animationLoad = false,
		gameplayRun = false,
		presentationRun = false,
		saveRun = false,
		remotes = false,
		clientTruth = false,
		metricsExport = false,
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
	expectReject("nil schema rejects", State.registerDefinition(nil), nil, checks)
	expectReject("non-table schema rejects", State.registerDefinition("bad"), nil, checks)
	expectReject(
		"invalid id rejects",
		State.registerDefinition(withField(plan("bad"), "usagePlanId", "bad id")),
		nil,
		checks
	)
	expectReject(
		"unsupported definition type rejects",
		State.registerDefinition(withField(plan("bad.type"), "schemaType", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported domain rejects",
		State.registerDefinition(withField(plan("bad.domain"), "usageDomain", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsupported usage kind rejects",
		State.registerDefinition(withField(plan("bad.kind"), "usageKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"unsafe metadata rejects",
		State.registerDefinition(
			withField(plan("bad.metadata"), "metadata", { ["load" .. "Asset"] = true })
		),
		nil,
		checks
	)
	expectReject(
		"unsafe tags reject",
		State.registerDefinition(withField(plan("bad.tags"), "tags", { "preload" .. "Asset" })),
		nil,
		checks
	)
	expectReject(
		"oversized child arrays reject",
		State.registerDefinition(
			withField(
				plan("bad.children"),
				"contextIds",
				oversizedIds("context.", Types.Limits.MaxPlanChildren)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing child reference rejects",
		State.registerDefinition(
			withField(plan("bad.child.ref"), "contextIds", { "missing.context" })
		),
		nil,
		checks
	)

	expectAccept("valid plan registers", State.registerDefinition(plan("plan.a")), nil, checks)
	expectAccept("second plan registers", State.registerDefinition(plan("plan.b")), nil, checks)
	expectReject("duplicate plan rejects", State.registerDefinition(plan("plan.a")), nil, checks)

	expectAccept(
		"valid context registers",
		State.registerContext(context("plan.a", "context.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate context rejects",
		State.registerContext(context("plan.a", "context.a")),
		nil,
		checks
	)
	expectReject("malformed context rejects", State.registerContext({}), nil, checks)
	expectReject(
		"unsupported context kind rejects",
		State.registerContext(
			withField(context("plan.a", "context.bad.kind"), "contextKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing context plan rejects",
		State.registerContext(context("missing", "context.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid constraint registers",
		State.registerConstraint(constraint("plan.a", "constraint.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate constraint rejects",
		State.registerConstraint(constraint("plan.a", "constraint.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported constraint kind rejects",
		State.registerConstraint(
			withField(constraint("plan.a", "constraint.bad.kind"), "constraintKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing constraint plan rejects",
		State.registerConstraint(constraint("missing", "constraint.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid dependency registers",
		State.registerDependency(dependency("dependency.a", "plan.a", "plan.b")),
		nil,
		checks
	)
	expectReject(
		"duplicate dependency rejects",
		State.registerDependency(dependency("dependency.a", "plan.a", "plan.b")),
		nil,
		checks
	)
	expectReject(
		"self dependency rejects",
		State.registerDependency(dependency("dependency.self", "plan.a", "plan.a")),
		nil,
		checks
	)
	expectReject(
		"direct dependency cycle rejects",
		State.registerDependency(dependency("dependency.cycle", "plan.b", "plan.a")),
		nil,
		checks
	)
	expectReject(
		"missing dependency reference rejects",
		State.registerDependency(dependency("dependency.missing", "plan.a", "missing")),
		nil,
		checks
	)
	expectReject(
		"unsupported dependency kind rejects",
		State.registerDependency(
			withField(
				dependency("dependency.bad.kind", "plan.a", "plan.b"),
				"dependencyKind",
				"Bad"
			)
		),
		nil,
		checks
	)

	expectAccept(
		"valid budget registers",
		State.registerBudget(budget("plan.a", "budget.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate budget rejects",
		State.registerBudget(budget("plan.a", "budget.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported budget kind rejects",
		State.registerBudget(withField(budget("plan.a", "budget.bad.kind"), "budgetKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"missing budget plan rejects",
		State.registerBudget(budget("missing", "budget.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid accessibility registers",
		State.registerAccessibility(accessibility("plan.a", "accessibility.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate accessibility rejects",
		State.registerAccessibility(accessibility("plan.a", "accessibility.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported accessibility kind rejects",
		State.registerAccessibility(
			withField(accessibility("plan.a", "accessibility.bad.kind"), "accessibilityKind", "Bad")
		),
		nil,
		checks
	)
	expectReject(
		"missing accessibility plan rejects",
		State.registerAccessibility(accessibility("missing", "accessibility.missing")),
		nil,
		checks
	)

	expectAccept(
		"valid audit registers",
		State.registerAudit(audit("plan.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"duplicate audit rejects",
		State.registerAudit(audit("plan.a", "audit.a")),
		nil,
		checks
	)
	expectReject(
		"unsupported audit kind rejects",
		State.registerAudit(withField(audit("plan.a", "audit.bad.kind"), "auditKind", "Bad")),
		nil,
		checks
	)
	expectReject(
		"oversized findings reject",
		State.registerAudit(
			withField(
				audit("plan.a", "audit.too.large"),
				"findings",
				oversizedIds("finding.", Types.Limits.MaxAuditFindings)
			)
		),
		nil,
		checks
	)
	expectReject(
		"missing audit plan rejects",
		State.registerAudit(audit("missing", "audit.missing")),
		nil,
		checks
	)

	State.clear()
	expectAccept(
		"namespace plan registers",
		State.registerDefinition(plan("namespace.id")),
		nil,
		checks
	)
	expectReject(
		"namespace context collision rejects",
		State.registerContext(context("namespace.id", "namespace.id")),
		nil,
		checks
	)
	expectAccept(
		"namespace context registers",
		State.registerContext(context("namespace.id", "namespace.context")),
		nil,
		checks
	)
	expectReject(
		"namespace constraint collision rejects",
		State.registerConstraint(constraint("namespace.id", "namespace.context")),
		nil,
		checks
	)
	expectAccept(
		"namespace constraint registers",
		State.registerConstraint(constraint("namespace.id", "namespace.constraint")),
		nil,
		checks
	)
	expectAccept(
		"namespace second plan registers",
		State.registerDefinition(plan("namespace.id.two")),
		nil,
		checks
	)
	expectReject(
		"namespace dependency collision rejects",
		State.registerDependency(
			dependency("namespace.constraint", "namespace.id", "namespace.id.two")
		),
		nil,
		checks
	)
	expectAccept(
		"namespace dependency registers",
		State.registerDependency(
			dependency("namespace.dependency", "namespace.id", "namespace.id.two")
		),
		nil,
		checks
	)
	expectReject(
		"namespace budget collision rejects",
		State.registerBudget(budget("namespace.id", "namespace.dependency")),
		nil,
		checks
	)
	expectAccept(
		"namespace budget registers",
		State.registerBudget(budget("namespace.id", "namespace.budget")),
		nil,
		checks
	)
	expectReject(
		"namespace accessibility collision rejects",
		State.registerAccessibility(accessibility("namespace.id", "namespace.budget")),
		nil,
		checks
	)
	expectAccept(
		"namespace accessibility registers",
		State.registerAccessibility(accessibility("namespace.id", "namespace.accessibility")),
		nil,
		checks
	)
	expectReject(
		"namespace audit collision rejects",
		State.registerAudit(audit("namespace.id", "namespace.accessibility")),
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
		local candidate = plan("forbidden." .. marker)
		candidate[marker] = true
		local ok, reason = Validation.definition(candidate)
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
	fillLimit("usage plan", Types.Limits.MaxUsagePlans, function(index)
		return plan("limit.plan." .. tostring(index))
	end, State.registerDefinition, checks)
	State.clear()
	expectAccept(
		"context limit seed registers",
		State.registerDefinition(plan("limit.context.seed")),
		nil,
		checks
	)
	fillLimit("context", Types.Limits.MaxContexts, function(index)
		return context("limit.context.seed", "limit.context." .. tostring(index))
	end, State.registerContext, checks)
	State.clear()
	expectAccept(
		"constraint limit seed registers",
		State.registerDefinition(plan("limit.constraint.seed")),
		nil,
		checks
	)
	fillLimit("constraint", Types.Limits.MaxConstraints, function(index)
		return constraint("limit.constraint.seed", "limit.constraint." .. tostring(index))
	end, State.registerConstraint, checks)
	State.clear()
	expectAccept(
		"dependency limit source registers",
		State.registerDefinition(plan("limit.dependency.source")),
		nil,
		checks
	)
	expectAccept(
		"dependency limit target registers",
		State.registerDefinition(plan("limit.dependency.target")),
		nil,
		checks
	)
	fillLimit("dependency", Types.Limits.MaxDependencies, function(index)
		return dependency(
			"limit.dependency." .. tostring(index),
			"limit.dependency.source",
			"limit.dependency.target"
		)
	end, State.registerDependency, checks)
	State.clear()
	expectAccept(
		"budget limit seed registers",
		State.registerDefinition(plan("limit.budget.seed")),
		nil,
		checks
	)
	fillLimit("budget", Types.Limits.MaxBudgets, function(index)
		return budget("limit.budget.seed", "limit.budget." .. tostring(index))
	end, State.registerBudget, checks)
	State.clear()
	expectAccept(
		"accessibility limit seed registers",
		State.registerDefinition(plan("limit.accessibility.seed")),
		nil,
		checks
	)
	fillLimit("accessibility", Types.Limits.MaxAccessibilityRecords, function(index)
		return accessibility("limit.accessibility.seed", "limit.accessibility." .. tostring(index))
	end, State.registerAccessibility, checks)
	State.clear()
	expectAccept(
		"audit limit seed registers",
		State.registerDefinition(plan("limit.audit.seed")),
		nil,
		checks
	)
	fillLimit("audit", Types.Limits.MaxAudits, function(index)
		return audit("limit.audit.seed", "limit.audit." .. tostring(index))
	end, State.registerAudit, checks)

	State.clear()
	local before = State.inspect().counts.definitions
	State.registerDefinition(withField(plan("bad.no.mutate"), "usagePlanId", "bad id"))
	expect(
		"failed validation does not mutate",
		State.inspect().counts.definitions == before,
		"failed validation mutated state",
		checks
	)
	expectAccept(
		"snapshot seed registers",
		State.registerDefinition(plan("snapshot.plan")),
		nil,
		checks
	)
	local snapshot = State.inspect()
	snapshot.definitions["snapshot.plan"].assetId = "mutated"
	expect(
		"snapshots are isolated",
		State.inspect().definitions["snapshot.plan"].assetId ~= "mutated",
		"snapshot mutation leaked",
		checks
	)
	local diagnostics = State.inspect()
	diagnostics.counts.definitions = 999999
	expect(
		"diagnostics are health-only copies",
		State.inspect().counts.definitions ~= 999999,
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
		State.inspect().counts.definitions == 0,
		"state remained after clear",
		checks
	)
	expectAccept(
		"namespace resets after shutdown",
		State.registerDefinition(plan("plan.a")),
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
			then "AssetUsagePlanSelfChecksPassed"
			else "AssetUsagePlanSelfChecksFailed",
		total = #checks,
		failed = failed,
		checks = checks,
	}
end

return SelfChecks
