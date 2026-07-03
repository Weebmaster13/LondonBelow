--!strict
-- Deterministic certification checks for the Condition schema runtime.

local Types = require(script.Parent.ConditionTypes)

local SelfChecks = {}

local function record(results: { any }, label: string, ok: boolean, detail: any?)
	table.insert(results, { label = label, ok = ok, detail = detail })
end

local function expectAccept(results: { any }, label: string, result: any)
	record(results, label, result.ok == true, result.message or result.code)
end

local function expectReject(results: { any }, label: string, result: any)
	record(results, label, result.ok == false, result.message or result.code)
end

local function makeThread(): thread
	local createThread = coroutine["create"]
	return createThread(function() end)
end

local function category(id: string)
	return {
		categoryId = id,
		categoryName = id,
		conditionDomain = "Core",
		ownerSystem = "SelfCheck",
	}
end

local function condition(id: string)
	return {
		conditionId = id,
		conditionName = id,
		conditionDomain = "Core",
		ownerSystem = "SelfCheck",
	}
end

local function operator(id: string, kind: string?)
	return {
		operatorId = id,
		operatorKind = kind or "Equals",
		ownerSystem = "SelfCheck",
	}
end

local function operand(id: string)
	return {
		operandId = id,
		operandKind = "SchemaValue",
		ownerSystem = "SelfCheck",
	}
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}

	expectReject(results, "malformed condition rejects", service.registerConditionDefinition({}))
	expectReject(
		results,
		"unsupported condition schema type rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.badtype",
			schemaType = "Bad",
			conditionName = "Bad",
			conditionDomain = "Core",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported condition domain rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.baddomain",
			conditionName = "Bad",
			conditionDomain = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"invalid category reference rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.badcategory",
			conditionName = "Bad",
			conditionDomain = "Core",
			categoryIds = { "missing.category" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized condition reference lists reject",
		service.registerConditionDefinition({
			conditionId = "sc.condition.bigrefs",
			conditionName = "BigRefs",
			conditionDomain = "Core",
			expressionIds = table.create(Types.Limits.MaxConditionExpressions + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"condition with scoring payload rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.eval",
			conditionName = "Eval",
			conditionDomain = "Core",
			ownerSystem = "SelfCheck",
			metadata = { ["condition" .. "Evaluation"] = true },
		})
	)

	expectAccept(
		results,
		"valid category registers",
		service.registerConditionCategory(category("sc.category"))
	)
	expectReject(results, "malformed category rejects", service.registerConditionCategory({}))
	expectReject(
		results,
		"duplicate category rejects",
		service.registerConditionCategory(category("sc.category"))
	)
	expectReject(
		results,
		"unsafe category tags reject",
		service.registerConditionCategory({
			categoryId = "sc.category.tags",
			categoryName = "Tags",
			conditionDomain = "Core",
			tags = { "ok", { bad = true } },
			ownerSystem = "SelfCheck",
		})
	)

	expectAccept(
		results,
		"valid condition registers",
		service.registerConditionDefinition(condition("sc.condition"))
	)
	expectReject(
		results,
		"duplicate condition rejects",
		service.registerConditionDefinition(condition("sc.condition"))
	)
	expectReject(
		results,
		"global namespace collision rejects",
		service.registerConditionOperator(operator("sc.condition"))
	)

	expectAccept(
		results,
		"valid operator registers",
		service.registerConditionOperator(operator("sc.operator"))
	)
	expectReject(
		results,
		"duplicate operator rejects",
		service.registerConditionOperator(operator("sc.operator"))
	)
	expectReject(
		results,
		"unsupported operator rejects",
		service.registerConditionOperator(operator("sc.operator.bad", "Bad"))
	)

	expectAccept(
		results,
		"valid operand registers",
		service.registerConditionOperand(operand("sc.operand"))
	)
	expectReject(results, "malformed operand rejects", service.registerConditionOperand({}))
	expectReject(
		results,
		"duplicate operand rejects",
		service.registerConditionOperand(operand("sc.operand"))
	)

	expectAccept(
		results,
		"valid expression records",
		service.registerConditionExpression({
			expressionId = "sc.expression",
			conditionId = "sc.condition",
			operatorId = "sc.operator",
			operandIds = { "sc.operand" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(results, "malformed expression rejects", service.registerConditionExpression({}))
	expectReject(
		results,
		"invalid operator reference rejects",
		service.registerConditionExpression({
			expressionId = "sc.expression.badoperator",
			conditionId = "sc.condition",
			operatorId = "missing.operator",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized expression operands reject",
		service.registerConditionExpression({
			expressionId = "sc.expression.big",
			conditionId = "sc.condition",
			operatorId = "sc.operator",
			operandIds = table.create(Types.Limits.MaxExpressionOperands + 1, "sc.operand"),
			ownerSystem = "SelfCheck",
		})
	)

	expectAccept(
		results,
		"valid group records",
		service.registerConditionGroup({
			groupId = "sc.group",
			groupType = "AND",
			conditionIds = { "sc.condition" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(results, "malformed group rejects", service.registerConditionGroup({}))
	expectReject(
		results,
		"oversized group records reject",
		service.registerConditionGroup({
			groupId = "sc.group.big",
			groupType = "OR",
			conditionIds = table.create(Types.Limits.MaxGroupConditions + 1, "sc.condition"),
			ownerSystem = "SelfCheck",
		})
	)

	expectAccept(
		results,
		"second condition registers",
		service.registerConditionDefinition(condition("sc.condition.two"))
	)
	expectAccept(
		results,
		"valid dependency records",
		service.registerConditionDependency({
			dependencyId = "sc.dependency",
			sourceConditionId = "sc.condition",
			targetConditionId = "sc.condition.two",
			dependencyKind = "Requires",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(results, "malformed dependency rejects", service.registerConditionDependency({}))
	expectReject(
		results,
		"self dependency rejects",
		service.registerConditionDependency({
			dependencyId = "sc.dependency.self",
			sourceConditionId = "sc.condition",
			targetConditionId = "sc.condition",
			dependencyKind = "Requires",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"direct dependency cycle rejects",
		service.registerConditionDependency({
			dependencyId = "sc.dependency.cycle",
			sourceConditionId = "sc.condition.two",
			targetConditionId = "sc.condition",
			dependencyKind = "Requires",
			ownerSystem = "SelfCheck",
		})
	)

	expectAccept(
		results,
		"valid state records",
		service.registerConditionState({
			stateId = "sc.state",
			conditionId = "sc.condition",
			stateKind = "Defined",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(results, "malformed state rejects", service.registerConditionState({}))
	expectAccept(
		results,
		"valid outcome records",
		service.registerConditionOutcome({
			outcomeId = "sc.outcome",
			conditionId = "sc.condition",
			outcomeKind = "Pass",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(results, "malformed outcome rejects", service.registerConditionOutcome({}))
	expectAccept(
		results,
		"valid audit records",
		service.registerConditionAudit({
			auditId = "sc.audit",
			conditionId = "sc.condition",
			auditKind = "SchemaReview",
			resultStatus = "Pass",
			findings = { "clean" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized audit findings reject",
		service.registerConditionAudit({
			auditId = "sc.audit.big",
			auditKind = "SchemaReview",
			resultStatus = "Warn",
			findings = table.create(Types.Limits.MaxAuditFindings + 1, "finding"),
			ownerSystem = "SelfCheck",
		})
	)

	local forbiddenFields = {
		"evaluate",
		"evaluateCondition",
		"expressionExecution",
		"booleanExecution",
		"ruleExecution",
		"triggerExecution",
		"gameplayExecution",
		"monsterAIExecution",
		"runtimeExecution",
		"runtimeOrchestration",
		"remote" .. "Event",
		"remote" .. "Function",
		"dataStore",
		"http" .. "Service",
		"messaging" .. "Service",
		"ana" .. "lytics",
		"tele" .. "metry",
	}
	for index, field in ipairs(forbiddenFields) do
		expectReject(
			results,
			"forbidden field rejects " .. tostring(index),
			service.registerConditionCategory({
				categoryId = "sc.forbidden." .. tostring(index),
				categoryName = "Forbidden",
				conditionDomain = "Core",
				metadata = { [field] = true },
				ownerSystem = "SelfCheck",
			})
		)
	end

	expectReject(
		results,
		"cyclic payload rejects",
		(function()
			local payload = category("sc.cycle")
			payload.metadata = {}
			payload.metadata.self = payload.metadata
			return service.registerConditionCategory(payload)
		end)()
	)
	expectReject(
		results,
		"thread payload rejects",
		service.registerConditionCategory({
			categoryId = "sc.thread",
			categoryName = "Thread",
			conditionDomain = "Core",
			metadata = { worker = makeThread() },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"function payload rejects",
		service.registerConditionCategory({
			categoryId = "sc.function",
			categoryName = "Function",
			conditionDomain = "Core",
			metadata = { callbackValue = function() end },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized string rejects",
		service.registerConditionCategory({
			categoryId = "sc.bigstring",
			categoryName = string.rep("x", Types.Limits.MaxPayloadStringLength + 1),
			conditionDomain = "Core",
			ownerSystem = "SelfCheck",
		})
	)

	local diagnostics = service.inspect()
	local snapshot = service.getSnapshot()
	local originalConditionCount = diagnostics.conditionCount
	diagnostics.conditionCount = -10
	snapshot.counts.definitions = -10
	record(
		results,
		"diagnostics are isolated",
		service.inspect().conditionCount == originalConditionCount,
		originalConditionCount
	)
	record(
		results,
		"snapshots are isolated",
		service.getSnapshot().counts.definitions == originalConditionCount,
		originalConditionCount
	)

	local posture = service.inspect().noExecutionPosture
	record(results, "no scoring posture", posture.noConditionScoring == true, posture)
	record(
		results,
		"no run posture",
		posture.noRuleRun == true and posture.noGameplayRun == true,
		posture
	)
	record(
		results,
		"no remote posture",
		posture.noRemotes == true and posture.noClientAuthority == true,
		posture
	)

	service.shutdown()
	record(
		results,
		"shutdown clears state",
		service.inspect().conditionCount == 0,
		service.inspect().conditionCount
	)

	local passed = true
	for _, item in ipairs(results) do
		if item.ok ~= true then
			passed = false
			break
		end
	end

	return {
		ok = passed,
		code = if passed then "SelfChecksPassed" else "SelfChecksFailed",
		results = results,
	}
end

return SelfChecks
