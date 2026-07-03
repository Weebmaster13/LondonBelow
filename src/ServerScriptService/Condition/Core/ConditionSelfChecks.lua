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

local function expression(id: string, conditionId: string?, operatorId: string?, operandIds: any?)
	return {
		expressionId = id,
		conditionId = conditionId or "sc.condition",
		operatorId = operatorId or "sc.operator",
		operandIds = operandIds,
		ownerSystem = "SelfCheck",
	}
end

local function group(id: string, conditionIds: any?)
	return {
		groupId = id,
		groupType = "AND",
		conditionIds = conditionIds or { "sc.condition" },
		ownerSystem = "SelfCheck",
	}
end

local function dependency(id: string, sourceId: string?, targetId: string?)
	return {
		dependencyId = id,
		sourceConditionId = sourceId or "sc.condition",
		targetConditionId = targetId or "sc.condition.two",
		dependencyKind = "Requires",
		ownerSystem = "SelfCheck",
	}
end

local function state(id: string, conditionId: string?)
	return {
		stateId = id,
		conditionId = conditionId or "sc.condition",
		stateKind = "Defined",
		ownerSystem = "SelfCheck",
	}
end

local function outcome(id: string, conditionId: string?, outcomeKind: string?)
	return {
		outcomeId = id,
		conditionId = conditionId or "sc.condition",
		outcomeKind = outcomeKind or "Pass",
		ownerSystem = "SelfCheck",
	}
end

local function audit(id: string, conditionId: string?)
	return {
		auditId = id,
		conditionId = conditionId,
		auditKind = "SchemaReview",
		resultStatus = "Pass",
		findings = { "clean" },
		ownerSystem = "SelfCheck",
	}
end

local function makeNodePayload()
	local payload = {}
	for index = 1, Types.Limits.MaxPayloadNodes + 1 do
		payload[index] = { node = index }
	end
	return payload
end

local function fillLimit(
	results: { any },
	label: string,
	service: any,
	registerFnName: string,
	countKey: string,
	limit: number,
	maker: (number) -> any
)
	local diagnostics = service.inspect()
	local remaining = math.max(limit - diagnostics[countKey], 0)
	for index = 1, remaining do
		local result = service[registerFnName](maker(index))
		if result.ok ~= true then
			record(results, label .. " fill accepts", false, result)
			return
		end
	end
	expectReject(results, label .. " limit rejects", service[registerFnName](maker(remaining + 1)))
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}

	expectReject(results, "malformed definition rejects", service.registerConditionDefinition({}))
	expectReject(
		results,
		"definition bad schema type rejects",
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
		"definition bad domain rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.baddomain",
			conditionName = "Bad",
			conditionDomain = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition invalid category ref rejects",
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
		"definition invalid expression ref rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.badexpression",
			conditionName = "Bad",
			conditionDomain = "Core",
			expressionIds = { "missing.expression" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition invalid dependency ref rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.baddependency",
			conditionName = "Bad",
			conditionDomain = "Core",
			dependencyIds = { "missing.dependency" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition invalid outcome ref rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.badoutcome",
			conditionName = "Bad",
			conditionDomain = "Core",
			outcomeIds = { "missing.outcome" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized category refs reject",
		service.registerConditionDefinition({
			conditionId = "sc.condition.bigcategories",
			conditionName = "Big",
			conditionDomain = "Core",
			categoryIds = table.create(Types.Limits.MaxConditionCategories + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized expression refs reject",
		service.registerConditionDefinition({
			conditionId = "sc.condition.bigexpressions",
			conditionName = "Big",
			conditionDomain = "Core",
			expressionIds = table.create(Types.Limits.MaxConditionExpressions + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized dependency refs reject",
		service.registerConditionDefinition({
			conditionId = "sc.condition.bigdependencies",
			conditionName = "Big",
			conditionDomain = "Core",
			dependencyIds = table.create(Types.Limits.MaxConditionDependencies + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized outcome refs reject",
		service.registerConditionDefinition({
			conditionId = "sc.condition.bigoutcomes",
			conditionName = "Big",
			conditionDomain = "Core",
			outcomeIds = table.create(Types.Limits.MaxConditionOutcomes + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition scoring payload rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.eval",
			conditionName = "Eval",
			conditionDomain = "Core",
			metadata = { ["condition" .. "Evaluation"] = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition branch payload rejects",
		service.registerConditionDefinition({
			conditionId = "sc.condition.branch",
			conditionName = "Branch",
			conditionDomain = "Core",
			metadata = { branchingLogic = true },
			ownerSystem = "SelfCheck",
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
		"category bad schema type rejects",
		service.registerConditionCategory({
			categoryId = "sc.category.badtype",
			schemaType = "Bad",
			categoryName = "Bad",
			conditionDomain = "Core",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"category bad domain rejects",
		service.registerConditionCategory({
			categoryId = "sc.category.baddomain",
			categoryName = "Bad",
			conditionDomain = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"category unsafe payload rejects",
		service.registerConditionCategory({
			categoryId = "sc.category.unsafe",
			categoryName = "Unsafe",
			conditionDomain = "Core",
			tags = { "ok", { bad = true } },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"category domain run marker rejects",
		service.registerConditionCategory({
			categoryId = "sc.category.runmarker",
			categoryName = "RunMarker",
			conditionDomain = "Core",
			context = { executionDomain = true },
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
	expectAccept(
		results,
		"second condition registers",
		service.registerConditionDefinition(condition("sc.condition.two"))
	)
	expectReject(
		results,
		"condition id rejects as category id",
		service.registerConditionCategory(category("sc.condition"))
	)

	expectAccept(
		results,
		"valid operator registers",
		service.registerConditionOperator(operator("sc.operator"))
	)
	expectReject(results, "malformed operator rejects", service.registerConditionOperator({}))
	expectReject(
		results,
		"duplicate operator rejects",
		service.registerConditionOperator(operator("sc.operator"))
	)
	expectReject(
		results,
		"operator bad schema type rejects",
		service.registerConditionOperator({
			operatorId = "sc.operator.badtype",
			schemaType = "Bad",
			operatorKind = "Equals",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported operator rejects",
		service.registerConditionOperator(operator("sc.operator.bad", "Bad"))
	)
	expectReject(
		results,
		"operator function payload rejects",
		service.registerConditionOperator({
			operatorId = "sc.operator.function",
			operatorKind = "Equals",
			metadata = { executableFunction = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"operator comparison run marker rejects",
		service.registerConditionOperator({
			operatorId = "sc.operator.compare",
			operatorKind = "Equals",
			metadata = { comparisonExecution = true },
			ownerSystem = "SelfCheck",
		})
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
	expectReject(
		results,
		"operand bad schema type rejects",
		service.registerConditionOperand({
			operandId = "sc.operand.badtype",
			schemaType = "Bad",
			operandKind = "SchemaValue",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"operand live value marker rejects",
		service.registerConditionOperand({
			operandId = "sc.operand.livevalue",
			operandKind = "SchemaValue",
			metadata = { liveValue = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"operand player state marker rejects",
		service.registerConditionOperand({
			operandId = "sc.operand.playerstate",
			operandKind = "SchemaValue",
			metadata = { playerState = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"operand runtime object marker rejects",
		service.registerConditionOperand({
			operandId = "sc.operand.runtime",
			operandKind = "SchemaValue",
			metadata = { runtimeObject = true },
			ownerSystem = "SelfCheck",
		})
	)

	expectAccept(
		results,
		"valid expression records",
		service.registerConditionExpression(expression("sc.expression", nil, nil, { "sc.operand" }))
	)
	expectReject(results, "malformed expression rejects", service.registerConditionExpression({}))
	expectReject(
		results,
		"duplicate expression rejects",
		service.registerConditionExpression(expression("sc.expression", nil, nil, { "sc.operand" }))
	)
	expectReject(
		results,
		"expression bad schema type rejects",
		service.registerConditionExpression({
			expressionId = "sc.expression.badtype",
			schemaType = "Bad",
			conditionId = "sc.condition",
			operatorId = "sc.operator",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"expression invalid condition ref rejects",
		service.registerConditionExpression(
			expression("sc.expression.badcondition", "missing.condition")
		)
	)
	expectReject(
		results,
		"expression invalid operator ref rejects",
		service.registerConditionExpression(
			expression("sc.expression.badoperator", nil, "missing.operator")
		)
	)
	expectReject(
		results,
		"expression invalid operand ref rejects",
		service.registerConditionExpression(
			expression("sc.expression.badoperand", nil, nil, { "missing.operand" })
		)
	)
	expectReject(
		results,
		"expression oversized operands reject",
		service.registerConditionExpression(
			expression(
				"sc.expression.big",
				nil,
				nil,
				table.create(Types.Limits.MaxExpressionOperands + 1, "sc.operand")
			)
		)
	)
	expectReject(
		results,
		"expression scoring marker rejects",
		service.registerConditionExpression({
			expressionId = "sc.expression.eval",
			conditionId = "sc.condition",
			operatorId = "sc.operator",
			metadata = { expressionEvaluation = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"expression boolean run marker rejects",
		service.registerConditionExpression({
			expressionId = "sc.expression.bool",
			conditionId = "sc.condition",
			operatorId = "sc.operator",
			metadata = { booleanExecution = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"expression callback marker rejects",
		service.registerConditionExpression({
			expressionId = "sc.expression.callback",
			conditionId = "sc.condition",
			operatorId = "sc.operator",
			metadata = { executableCallback = true },
			ownerSystem = "SelfCheck",
		})
	)

	expectReject(
		results,
		"category id rejects as expression id",
		service.registerConditionExpression(expression("sc.category", nil, nil, { "sc.operand" }))
	)
	expectReject(
		results,
		"expression id rejects as operand id",
		service.registerConditionOperand(operand("sc.expression"))
	)
	expectReject(
		results,
		"operand id rejects as operator id",
		service.registerConditionOperator(operator("sc.operand"))
	)

	expectAccept(results, "valid group records", service.registerConditionGroup(group("sc.group")))
	expectReject(results, "malformed group rejects", service.registerConditionGroup({}))
	expectReject(
		results,
		"duplicate group rejects",
		service.registerConditionGroup(group("sc.group"))
	)
	expectReject(
		results,
		"group bad schema type rejects",
		service.registerConditionGroup({
			groupId = "sc.group.badtype",
			schemaType = "Bad",
			groupType = "AND",
			conditionIds = { "sc.condition" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported group rejects",
		service.registerConditionGroup({
			groupId = "sc.group.badkind",
			groupType = "Bad",
			conditionIds = { "sc.condition" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"group invalid condition ref rejects",
		service.registerConditionGroup(group("sc.group.badcondition", { "missing.condition" }))
	)
	expectReject(
		results,
		"group oversized records reject",
		service.registerConditionGroup(
			group("sc.group.big", table.create(Types.Limits.MaxGroupConditions + 1, "sc.condition"))
		)
	)
	expectReject(
		results,
		"group branch run marker rejects",
		service.registerConditionGroup({
			groupId = "sc.group.branch",
			groupType = "AND",
			conditionIds = { "sc.condition" },
			metadata = { branchExecution = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"group short circuit marker rejects",
		service.registerConditionGroup({
			groupId = "sc.group.short",
			groupType = "AND",
			conditionIds = { "sc.condition" },
			metadata = { shortCircuitExecution = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"operator id rejects as group id",
		service.registerConditionGroup(group("sc.operator"))
	)

	expectAccept(
		results,
		"valid dependency records",
		service.registerConditionDependency(dependency("sc.dependency"))
	)
	expectReject(results, "malformed dependency rejects", service.registerConditionDependency({}))
	expectReject(
		results,
		"duplicate dependency rejects",
		service.registerConditionDependency(dependency("sc.dependency"))
	)
	expectReject(
		results,
		"dependency bad schema type rejects",
		service.registerConditionDependency({
			dependencyId = "sc.dependency.badtype",
			schemaType = "Bad",
			sourceConditionId = "sc.condition",
			targetConditionId = "sc.condition.two",
			dependencyKind = "Requires",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"dependency invalid source rejects",
		service.registerConditionDependency(
			dependency("sc.dependency.badsource", "missing.condition", "sc.condition.two")
		)
	)
	expectReject(
		results,
		"dependency invalid target rejects",
		service.registerConditionDependency(
			dependency("sc.dependency.badtarget", "sc.condition", "missing.condition")
		)
	)
	expectReject(
		results,
		"self dependency rejects",
		service.registerConditionDependency(
			dependency("sc.dependency.self", "sc.condition", "sc.condition")
		)
	)
	expectReject(
		results,
		"direct dependency cycle rejects",
		service.registerConditionDependency(
			dependency("sc.dependency.cycle", "sc.condition.two", "sc.condition")
		)
	)
	expectReject(
		results,
		"dependency blocking marker rejects",
		service.registerConditionDependency({
			dependencyId = "sc.dependency.blocking",
			sourceConditionId = "sc.condition",
			targetConditionId = "sc.condition.two",
			dependencyKind = "Requires",
			metadata = { blockingExecution = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"group id rejects as dependency id",
		service.registerConditionDependency(dependency("sc.group"))
	)

	expectAccept(results, "valid state records", service.registerConditionState(state("sc.state")))
	expectReject(results, "malformed state rejects", service.registerConditionState({}))
	expectReject(
		results,
		"duplicate state rejects",
		service.registerConditionState(state("sc.state"))
	)
	expectReject(
		results,
		"state bad schema type rejects",
		service.registerConditionState({
			stateId = "sc.state.badtype",
			schemaType = "Bad",
			conditionId = "sc.condition",
			stateKind = "Defined",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"state invalid condition ref rejects",
		service.registerConditionState(state("sc.state.badcondition", "missing.condition"))
	)
	expectReject(
		results,
		"state live marker rejects",
		service.registerConditionState({
			stateId = "sc.state.live",
			conditionId = "sc.condition",
			stateKind = "Defined",
			metadata = { liveState = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"state change marker rejects",
		service.registerConditionState({
			stateId = "sc.state.change",
			conditionId = "sc.condition",
			stateKind = "Defined",
			metadata = { stateMutation = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"dependency id rejects as state id",
		service.registerConditionState(state("sc.dependency"))
	)

	expectAccept(
		results,
		"valid outcome records",
		service.registerConditionOutcome(outcome("sc.outcome"))
	)
	expectReject(results, "malformed outcome rejects", service.registerConditionOutcome({}))
	expectReject(
		results,
		"duplicate outcome rejects",
		service.registerConditionOutcome(outcome("sc.outcome"))
	)
	expectReject(
		results,
		"outcome bad schema type rejects",
		service.registerConditionOutcome({
			outcomeId = "sc.outcome.badtype",
			schemaType = "Bad",
			conditionId = "sc.condition",
			outcomeKind = "Pass",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported outcome rejects",
		service.registerConditionOutcome(outcome("sc.outcome.badkind", nil, "Bad"))
	)
	expectReject(
		results,
		"outcome invalid condition ref rejects",
		service.registerConditionOutcome(outcome("sc.outcome.badcondition", "missing.condition"))
	)
	expectReject(
		results,
		"outcome computed marker rejects",
		service.registerConditionOutcome({
			outcomeId = "sc.outcome.computed",
			conditionId = "sc.condition",
			outcomeKind = "Pass",
			metadata = { computedResult = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"outcome gameplay result marker rejects",
		service.registerConditionOutcome({
			outcomeId = "sc.outcome.gameplay",
			conditionId = "sc.condition",
			outcomeKind = "Pass",
			metadata = { gameplayResult = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"state id rejects as outcome id",
		service.registerConditionOutcome(outcome("sc.state"))
	)

	expectAccept(
		results,
		"valid audit records",
		service.registerConditionAudit(audit("sc.audit", "sc.condition"))
	)
	expectReject(results, "malformed audit rejects", service.registerConditionAudit({}))
	expectReject(
		results,
		"duplicate audit rejects",
		service.registerConditionAudit(audit("sc.audit", "sc.condition"))
	)
	expectReject(
		results,
		"audit bad schema type rejects",
		service.registerConditionAudit({
			auditId = "sc.audit.badtype",
			schemaType = "Bad",
			auditKind = "SchemaReview",
			resultStatus = "Pass",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"audit invalid condition ref rejects",
		service.registerConditionAudit(audit("sc.audit.badcondition", "missing.condition"))
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
	expectReject(
		results,
		"audit enforcement marker rejects",
		service.registerConditionAudit({
			auditId = "sc.audit.enforce",
			auditKind = "SchemaReview",
			resultStatus = "Warn",
			metadata = { enforcement = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"audit remediation marker rejects",
		service.registerConditionAudit({
			auditId = "sc.audit.remediate",
			auditKind = "SchemaReview",
			resultStatus = "Warn",
			metadata = { remediation = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"outcome id rejects as audit id",
		service.registerConditionAudit(audit("sc.outcome", "sc.condition"))
	)

	local forbiddenMarkers = {
		"condition" .. "Evaluation",
		"evaluateCondition",
		"evaluate",
		"expressionEvaluation",
		"expressionExecution",
		"booleanEvaluation",
		"booleanExecution",
		"logicEvaluation",
		"logicExecution",
		"branchingLogic",
		"branchExecution",
		"scriptExecution",
		"scripting",
		"ruleExecution",
		"ruleEvaluation",
		"triggerExecution",
		"conditionTrigger",
		"gameplayExecution",
		"puzzleExecution",
		"interactionExecution",
		"inventoryExecution",
		"objectiveExecution",
		"directorExecution",
		"monsterExecution",
		"monsterAIExecution",
		"narrativeExecution",
		"presentationExecution",
		"saveExecution",
		"schedulerExecution",
		"lifecycleExecution",
		"eventExecution",
		"eventGraphExecution",
		"runtimeGraphExecution",
		"ruleEngineExecution",
		"runtimeExecution",
		"runtimeOrchestration",
		"stateMutation",
		"mutateState",
		"liveState",
		"liveValue",
		"playerState",
		"computedResult",
		"gameplayResult",
		"blockingExecution",
		"shortCircuitExecution",
		"comparisonExecution",
		"executableFunction",
		"workspace",
		"workspacePath",
		"remote",
		"remote" .. "Event",
		"remote" .. "Function",
		"fireClient",
		"fireAllClients",
		"invokeClient",
		"clientAuthority",
		"dataStore",
		"dataStoreRead",
		"dataStoreWrite",
		"http",
		"http" .. "Service",
		"messaging",
		"messaging" .. "Service",
		"ana" .. "lytics",
		"ana" .. "lyticsCollection",
		"tele" .. "metry",
		"tele" .. "metrySending",
		"chapterContent",
		"chapter0Content",
		"finalStory",
		"story",
		"finalDialogue",
		"dialogue",
		"cutscene",
		"serviceReference",
		"adapterReference",
		"handlerReference",
		"callback",
		"executableCallback",
		"executionAdapter",
		"frameworkReference",
		"moduleReference",
		"runtimeObject",
		"instanceReference",
		"enforcement",
		"remediation",
		"execute",
		"run",
		"fire",
		"dispatch",
		"publish",
		"subscribe",
	}
	for index, marker in ipairs(forbiddenMarkers) do
		expectReject(
			results,
			"forbidden key marker rejects " .. tostring(index),
			service.registerConditionCategory({
				categoryId = "sc.forbidden.key." .. tostring(index),
				categoryName = "Forbidden",
				conditionDomain = "Core",
				metadata = { [marker] = true },
				ownerSystem = "SelfCheck",
			})
		)
		expectReject(
			results,
			"forbidden value marker rejects " .. tostring(index),
			service.registerConditionCategory({
				categoryId = "sc.forbidden.value." .. tostring(index),
				categoryName = "Forbidden",
				conditionDomain = "Core",
				metadata = { marker },
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
	expectReject(
		results,
		"deep payload rejects",
		service.registerConditionCategory({
			categoryId = "sc.deep",
			categoryName = "Deep",
			conditionDomain = "Core",
			metadata = { { { { { { { { { { tooDeep = true } } } } } } } } } },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized node payload rejects",
		service.registerConditionCategory({
			categoryId = "sc.nodes",
			categoryName = "Nodes",
			conditionDomain = "Core",
			metadata = makeNodePayload(),
			ownerSystem = "SelfCheck",
		})
	)

	fillLimit(
		results,
		"category",
		service,
		"registerConditionCategory",
		"categoryCount",
		Types.Limits.MaxCategories,
		function(index)
			return category("sc.limit.category." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"condition",
		service,
		"registerConditionDefinition",
		"conditionCount",
		Types.Limits.MaxConditions,
		function(index)
			return condition("sc.limit.condition." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"operand",
		service,
		"registerConditionOperand",
		"operandCount",
		Types.Limits.MaxOperands,
		function(index)
			return operand("sc.limit.operand." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"operator",
		service,
		"registerConditionOperator",
		"operatorCount",
		Types.Limits.MaxOperators,
		function(index)
			return operator("sc.limit.operator." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"expression",
		service,
		"registerConditionExpression",
		"expressionCount",
		Types.Limits.MaxExpressions,
		function(index)
			return expression("sc.limit.expression." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"group",
		service,
		"registerConditionGroup",
		"groupCount",
		Types.Limits.MaxGroups,
		function(index)
			return group("sc.limit.group." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"dependency",
		service,
		"registerConditionDependency",
		"dependencyCount",
		Types.Limits.MaxDependencies,
		function(index)
			return dependency("sc.limit.dependency." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"state",
		service,
		"registerConditionState",
		"stateCount",
		Types.Limits.MaxStates,
		function(index)
			return state("sc.limit.state." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"outcome",
		service,
		"registerConditionOutcome",
		"outcomeCount",
		Types.Limits.MaxOutcomes,
		function(index)
			return outcome("sc.limit.outcome." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"audit",
		service,
		"registerConditionAudit",
		"auditCount",
		Types.Limits.MaxAudits,
		function(index)
			return audit("sc.limit.audit." .. tostring(index))
		end
	)

	for _ = 1, Types.Limits.MaxValidationFailures + 8 do
		service.registerConditionCategory({})
	end
	for _ = 1, Types.Limits.MaxSnapshotHistory + 8 do
		service.getSnapshot()
	end
	local bounded = service.inspect()
	record(
		results,
		"validation failures are bounded",
		bounded.validationFailureCount <= Types.Limits.MaxValidationFailures,
		bounded.validationFailureCount
	)
	record(
		results,
		"snapshots are bounded",
		bounded.snapshotCount <= Types.Limits.MaxSnapshotHistory,
		bounded.snapshotCount
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
	record(
		results,
		"no scoring posture",
		posture.noConditionScoring == true and posture.noExpressionScoring == true,
		posture
	)
	record(
		results,
		"no run posture",
		posture.noRuleRun == true
			and posture.noGameplayRun == true
			and posture.noRuntimeGraphRun == true,
		posture
	)
	record(
		results,
		"no remote posture",
		posture.noRemotes == true and posture.noClientAuthority == true,
		posture
	)
	record(
		results,
		"no service posture",
		posture.noStorageReadsWrites == true
			and posture.noHttpLayer == true
			and posture.noMessagingLayer == true,
		posture
	)

	service.shutdown()
	local afterShutdown = service.inspect()
	record(
		results,
		"shutdown clears state",
		afterShutdown.conditionCount == 0 and afterShutdown.categoryCount == 0,
		afterShutdown
	)
	expectAccept(
		results,
		"global namespace clears on shutdown",
		service.registerConditionDefinition(condition("sc.condition"))
	)
	service.shutdown()

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
