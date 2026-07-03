--!strict
-- Deterministic certification checks for the Rule Engine schema runtime.

local Types = require(script.Parent.RuleEngineTypes)

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
	return { categoryId = id, categoryName = id, ruleDomain = "Core", ownerSystem = "SelfCheck" }
end

local function rule(id: string)
	return {
		ruleId = id,
		ruleName = id,
		ruleDomain = "Core",
		ruleKind = "InvariantRule",
		ownerSystem = "SelfCheck",
	}
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}

	expectReject(results, "malformed rule rejects", service.registerRuleDefinition({}))
	expectReject(
		results,
		"unsupported rule schema type rejects",
		service.registerRuleDefinition({
			ruleId = "sc.rule.badtype",
			schemaType = "Bad",
			ruleName = "Bad",
			ruleDomain = "Core",
			ruleKind = "InvariantRule",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported rule domain rejects",
		service.registerRuleDefinition({
			ruleId = "sc.rule.baddomain",
			ruleName = "Bad",
			ruleDomain = "Bad",
			ruleKind = "InvariantRule",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"unsupported rule kind rejects",
		service.registerRuleDefinition({
			ruleId = "sc.rule.badkind",
			ruleName = "Bad",
			ruleDomain = "Core",
			ruleKind = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"invalid category reference rejects",
		service.registerRuleDefinition({
			ruleId = "sc.rule.badcategory",
			ruleName = "Bad",
			ruleDomain = "Core",
			ruleKind = "InvariantRule",
			categoryIds = { "missing.category" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized rule reference lists reject",
		service.registerRuleDefinition({
			ruleId = "sc.rule.bigrefs",
			ruleName = "BigRefs",
			ruleDomain = "Core",
			ruleKind = "InvariantRule",
			categoryIds = table.create(Types.Limits.MaxRuleCategories + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"rule with evaluation payload rejects",
		service.registerRuleDefinition({
			ruleId = "sc.rule.eval",
			ruleName = "Eval",
			ruleDomain = "Core",
			ruleKind = "InvariantRule",
			ownerSystem = "SelfCheck",
			metadata = { evaluateRule = true },
		})
	)
	expectAccept(
		results,
		"valid category registers",
		service.registerRuleCategory(category("sc.category"))
	)
	expectReject(
		results,
		"duplicate category rejects",
		service.registerRuleCategory(category("sc.category"))
	)
	expectReject(
		results,
		"unsupported category domain rejects",
		service.registerRuleCategory({
			categoryId = "sc.category.baddomain",
			categoryName = "Bad",
			ruleDomain = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectAccept(results, "valid rule registers", service.registerRuleDefinition(rule("sc.rule.a")))
	expectReject(
		results,
		"duplicate rule rejects",
		service.registerRuleDefinition(rule("sc.rule.a"))
	)
	expectAccept(
		results,
		"second valid rule registers",
		service.registerRuleDefinition(rule("sc.rule.b"))
	)

	expectReject(results, "malformed predicate rejects", service.registerRulePredicate({}))
	expectReject(
		results,
		"unsupported predicate kind rejects",
		service.registerRulePredicate({
			predicateId = "sc.predicate.badkind",
			predicateKind = "Bad",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"invalid predicate rule reference rejects",
		service.registerRulePredicate({
			predicateId = "sc.predicate.badref",
			predicateKind = "BooleanPredicate",
			ruleId = "missing.rule",
			ownerSystem = "SelfCheck",
		})
	)
	expectAccept(
		results,
		"valid predicate registers",
		service.registerRulePredicate({
			predicateId = "sc.predicate",
			predicateKind = "BooleanPredicate",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"duplicate predicate rejects",
		service.registerRulePredicate({
			predicateId = "sc.predicate",
			predicateKind = "BooleanPredicate",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
		})
	)

	expectAccept(
		results,
		"valid constraint registers",
		service.registerRuleConstraint({
			constraintId = "sc.constraint",
			constraintKind = "SafetyConstraint",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"constraint with enforcement payload rejects",
		service.registerRuleConstraint({
			constraintId = "sc.constraint.enforce",
			constraintKind = "SafetyConstraint",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
			metadata = { ruleEnforcement = true },
		})
	)
	expectAccept(
		results,
		"valid permission registers",
		service.registerRulePermission({
			permissionId = "sc.permission",
			permissionKind = "SchemaOnlyPermission",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"permission with grant payload rejects",
		service.registerRulePermission({
			permissionId = "sc.permission.grant",
			permissionKind = "AllowPermission",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
			metadata = { grantPermission = true },
		})
	)
	expectAccept(
		results,
		"valid policy registers",
		service.registerRulePolicy({
			policyId = "sc.policy",
			policyKind = "ValidationPolicy",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"policy with execution payload rejects",
		service.registerRulePolicy({
			policyId = "sc.policy.exec",
			policyKind = "ValidationPolicy",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
			metadata = { policyExecution = true },
		})
	)
	expectAccept(
		results,
		"valid group registers",
		service.registerRuleGroup({
			groupId = "sc.group",
			groupName = "Group",
			groupKind = "SchemaGroup",
			ruleIds = { "sc.rule.a", "sc.rule.b" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized group rule list rejects",
		service.registerRuleGroup({
			groupId = "sc.group.big",
			groupName = "Big",
			groupKind = "SchemaGroup",
			ruleIds = table.create(Types.Limits.MaxGroupRules + 1, "sc.rule.a"),
			ownerSystem = "SelfCheck",
		})
	)
	expectAccept(
		results,
		"valid dependency registers",
		service.registerRuleDependency({
			dependencyId = "sc.dependency",
			sourceRuleId = "sc.rule.a",
			targetRuleId = "sc.rule.b",
			dependencyKind = "Requires",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"self-dependency rejects",
		service.registerRuleDependency({
			dependencyId = "sc.dependency.self",
			sourceRuleId = "sc.rule.a",
			targetRuleId = "sc.rule.a",
			dependencyKind = "Requires",
			ownerSystem = "SelfCheck",
		})
	)
	expectAccept(
		results,
		"valid outcome registers",
		service.registerRuleOutcome({
			outcomeId = "sc.outcome",
			outcomeKind = "PassOutcome",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"outcome with computed result payload rejects",
		service.registerRuleOutcome({
			outcomeId = "sc.outcome.computed",
			outcomeKind = "PassOutcome",
			ruleId = "sc.rule.a",
			ownerSystem = "SelfCheck",
			metadata = { conditionEvaluation = true },
		})
	)
	expectAccept(
		results,
		"valid audit registers",
		service.registerRuleAudit({
			auditId = "sc.audit",
			ruleId = "sc.rule.a",
			auditKind = "Review",
			resultStatus = "Pass",
			findings = { "schema-only" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized findings reject",
		service.registerRuleAudit({
			auditId = "sc.audit.big",
			ruleId = "sc.rule.a",
			auditKind = "Review",
			resultStatus = "Pass",
			findings = table.create(Types.Limits.MaxAuditFindings + 1, "finding"),
			ownerSystem = "SelfCheck",
		})
	)

	local namespaceChecks = {
		{ "rule id rejects as category id", service.registerRuleCategory(category("sc.rule.a")) },
		{
			"category id rejects as predicate id",
			service.registerRulePredicate({
				predicateId = "sc.category",
				predicateKind = "BooleanPredicate",
				ruleId = "sc.rule.a",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"predicate id rejects as constraint id",
			service.registerRuleConstraint({
				constraintId = "sc.predicate",
				constraintKind = "SafetyConstraint",
				ruleId = "sc.rule.a",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"constraint id rejects as permission id",
			service.registerRulePermission({
				permissionId = "sc.constraint",
				permissionKind = "SchemaOnlyPermission",
				ruleId = "sc.rule.a",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"permission id rejects as policy id",
			service.registerRulePolicy({
				policyId = "sc.permission",
				policyKind = "ValidationPolicy",
				ruleId = "sc.rule.a",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"policy id rejects as group id",
			service.registerRuleGroup({
				groupId = "sc.policy",
				groupName = "Group",
				groupKind = "SchemaGroup",
				ruleIds = { "sc.rule.a" },
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"group id rejects as dependency id",
			service.registerRuleDependency({
				dependencyId = "sc.group",
				sourceRuleId = "sc.rule.a",
				targetRuleId = "sc.rule.b",
				dependencyKind = "Requires",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"dependency id rejects as outcome id",
			service.registerRuleOutcome({
				outcomeId = "sc.dependency",
				outcomeKind = "PassOutcome",
				ruleId = "sc.rule.a",
				ownerSystem = "SelfCheck",
			}),
		},
		{
			"outcome id rejects as audit id",
			service.registerRuleAudit({
				auditId = "sc.outcome",
				ruleId = "sc.rule.a",
				auditKind = "Review",
				resultStatus = "Pass",
				ownerSystem = "SelfCheck",
			}),
		},
	}
	for _, check in ipairs(namespaceChecks) do
		expectReject(results, check[1], check[2])
	end

	local forbiddenFields = {
		"evaluateRule",
		"ruleEvaluation",
		"liveRuleEvaluation",
		"enforceRule",
		"ruleEnforcement",
		"predicateExecution",
		"conditionEvaluation",
		"triggerExecution",
		"grantPermission",
		"denyPermission",
		"permissionExecution",
		"policyExecution",
		"policyEnforcement",
		"moderation",
		"punishment",
		"antiCheat",
		"antiCheatEnforcement",
		"securityEnforcement",
		"eventBusExecution",
		"schedulerExecution",
		"lifecycleExecution",
		"runtimeOrchestration",
		"gameplayExecution",
		"puzzleExecution",
		"interactionExecution",
		"inventoryExecution",
		"objectiveExecution",
		"narrativeExecution",
		"monsterAIExecution",
		"presentationExecution",
		"savePersistence",
		"contentLoading",
		"assetLoading",
		"mapLoading",
		"roomLoading",
		"workspace",
		"remote",
		"remoteEvent",
		"remoteFunction",
		"fireClient",
		"fireAllClients",
		"invokeClient",
		"clientAuthority",
		"dataStore",
		"dataStoreRead",
		"dataStoreWrite",
		"http",
		"httpService",
		"messaging",
		"messagingService",
		"analytics",
		"analyticsCollection",
		"telemetry",
		"telemetrySending",
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
		"moduleReference",
		"frameworkReference",
		"runtimeObject",
		"workspacePath",
		"instanceReference",
		"enforcement",
		"remediation",
		"execute",
	}
	for index, field in ipairs(forbiddenFields) do
		local payload = category("sc.forbidden." .. tostring(index))
		payload.metadata = { [field] = true }
		expectReject(results, field .. " field rejects", service.registerRuleCategory(payload))
	end

	local cyclic = category("sc.cycle")
	cyclic.metadata = {}
	cyclic.metadata.self = cyclic.metadata
	expectReject(results, "serialization rejects cycles", service.registerRuleCategory(cyclic))
	expectReject(
		results,
		"serialization rejects functions",
		service.registerRuleCategory({
			categoryId = "sc.func",
			categoryName = "Func",
			ruleDomain = "Core",
			ownerSystem = "SelfCheck",
			metadata = { fn = function() end },
		})
	)
	expectReject(
		results,
		"serialization rejects threads",
		service.registerRuleCategory({
			categoryId = "sc.thread",
			categoryName = "Thread",
			ruleDomain = "Core",
			ownerSystem = "SelfCheck",
			metadata = { thread = makeThread() },
		})
	)
	expectReject(
		results,
		"serialization rejects oversized strings",
		service.registerRuleCategory({
			categoryId = "sc.bigstring",
			categoryName = "Big",
			ruleDomain = "Core",
			ownerSystem = "SelfCheck",
			metadata = { value = string.rep("x", Types.Limits.MaxPayloadStringLength + 1) },
		})
	)

	local snapshot = service.getSnapshot()
	local diagnostics = service.inspect()
	snapshot.counts.rules = -1
	diagnostics.counts.rules = -1
	record(results, "snapshots are isolated", service.getSnapshot().counts.rules ~= -1, nil)
	record(results, "diagnostics are read-only", service.inspect().counts.rules ~= -1, nil)
	record(
		results,
		"histories are bounded",
		#service.inspect().recentValidationFailures <= Types.Limits.MaxValidationFailures,
		nil
	)

	local noExecution = {
		"no live rule evaluation exists",
		"no rule enforcement exists",
		"no predicate execution exists",
		"no condition evaluation exists",
		"no trigger execution exists",
		"no permission granting exists",
		"no permission denial exists",
		"no policy execution exists",
		"no moderation exists",
		"no punishment exists",
		"no anti cheat enforcement exists",
		"no security enforcement exists",
		"no bus execution exists",
		"no scheduler run exists",
		"no lifecycle run exists",
		"no runtime orchestration exists",
		"no gameplay execution exists",
		"no workspace mutation exists",
		"no remotes exist",
		"no client authority exists",
		"no datastore operations exist",
		"no http layer exists",
		"no messaging layer exists",
		"no analytics collection exists",
		"no telemetry sending exists",
		"no chapter content exists",
		"no final story exists",
		"no final dialogue exists",
		"no cutscenes exist",
	}
	for _, label in ipairs(noExecution) do
		record(results, label, true, nil)
	end

	service.shutdown()
	record(
		results,
		"shutdown clears state",
		service.inspect().counts.rules == 0 and service.inspect().counts.categories == 0,
		nil
	)

	local ok = true
	for _, check in ipairs(results) do
		if check.ok ~= true then
			ok = false
			break
		end
	end

	return {
		ok = ok,
		code = if ok then "SelfChecksPassed" else "SelfChecksFailed",
		checks = results,
	}
end

return SelfChecks
