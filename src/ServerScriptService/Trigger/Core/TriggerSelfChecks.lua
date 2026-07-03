--!strict
-- Deterministic certification checks for the Trigger schema runtime.

local Types = require(script.Parent.TriggerTypes)

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

local function trigger(id: string)
	return { triggerId = id, triggerName = id, triggerDomain = "Core", ownerSystem = "SelfCheck" }
end

local function category(id: string)
	return { categoryId = id, categoryName = id, triggerDomain = "Core", ownerSystem = "SelfCheck" }
end

local function source(id: string)
	return { sourceId = id, sourceKind = "SchemaSource", ownerSystem = "SelfCheck" }
end

local function target(id: string)
	return { targetId = id, targetKind = "SchemaTarget", ownerSystem = "SelfCheck" }
end

local function event(id: string, triggerId: string?, kind: string?)
	return {
		eventId = id,
		triggerId = triggerId or "sc.trigger",
		eventKind = kind or "Enter",
		ownerSystem = "SelfCheck",
	}
end

local function filter(id: string, triggerId: string?)
	return {
		filterId = id,
		triggerId = triggerId or "sc.trigger",
		filterKind = "SchemaFilter",
		ownerSystem = "SelfCheck",
	}
end

local function condition(id: string, triggerId: string?)
	return {
		conditionId = id,
		triggerId = triggerId or "sc.trigger",
		conditionRefId = "condition.schema",
		ownerSystem = "SelfCheck",
	}
end

local function dependency(id: string, sourceId: string?, targetId: string?)
	return {
		dependencyId = id,
		sourceTriggerId = sourceId or "sc.trigger",
		targetTriggerId = targetId or "sc.trigger.two",
		dependencyKind = "Requires",
		ownerSystem = "SelfCheck",
	}
end

local function group(id: string, triggerIds: any?)
	return {
		groupId = id,
		groupType = "Sequential",
		triggerIds = triggerIds or { "sc.trigger" },
		ownerSystem = "SelfCheck",
	}
end

local function outcome(id: string, triggerId: string?, kind: string?)
	return {
		outcomeId = id,
		triggerId = triggerId or "sc.trigger",
		outcomeKind = kind or "Pending",
		ownerSystem = "SelfCheck",
	}
end

local function audit(id: string, triggerId: string?)
	return {
		auditId = id,
		triggerId = triggerId,
		auditKind = "SchemaReview",
		resultStatus = "Pass",
		findings = { "clean" },
		ownerSystem = "SelfCheck",
	}
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

	expectReject(results, "malformed definition rejects", service.registerTriggerDefinition({}))
	expectReject(
		results,
		"definition bad type rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.badtype",
			schemaType = "Bad",
			triggerName = "Bad",
			triggerDomain = "Core",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition bad domain rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.baddomain",
			triggerName = "Bad",
			triggerDomain = "Bad",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition bad reference rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.badref",
			triggerName = "Bad",
			triggerDomain = "Core",
			sourceIds = { "missing" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized refs reject",
		service.registerTriggerDefinition({
			triggerId = "sc.bigrefs",
			triggerName = "Big",
			triggerDomain = "Core",
			sourceIds = table.create(Types.Limits.MaxTriggerSources + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition run marker rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.runmarker",
			triggerName = "Bad",
			triggerDomain = "Core",
			metadata = { triggerExecution = true },
			ownerSystem = "SelfCheck",
		})
	)

	expectAccept(
		results,
		"valid category registers",
		service.registerTriggerCategory(category("sc.category"))
	)
	expectReject(results, "malformed category rejects", service.registerTriggerCategory({}))
	expectReject(
		results,
		"duplicate category rejects",
		service.registerTriggerCategory(category("sc.category"))
	)
	expectReject(
		results,
		"category bad domain rejects",
		service.registerTriggerCategory({
			categoryId = "sc.category.baddomain",
			categoryName = "Bad",
			triggerDomain = "Bad",
			ownerSystem = "SelfCheck",
		})
	)

	expectAccept(
		results,
		"valid source registers",
		service.registerTriggerSource(source("sc.source"))
	)
	expectReject(results, "malformed source rejects", service.registerTriggerSource({}))
	expectReject(
		results,
		"duplicate source rejects",
		service.registerTriggerSource(source("sc.source"))
	)
	expectAccept(
		results,
		"valid target registers",
		service.registerTriggerTarget(target("sc.target"))
	)
	expectReject(results, "malformed target rejects", service.registerTriggerTarget({}))
	expectReject(
		results,
		"duplicate target rejects",
		service.registerTriggerTarget(target("sc.target"))
	)

	expectAccept(
		results,
		"valid trigger registers",
		service.registerTriggerDefinition(trigger("sc.trigger"))
	)
	expectReject(
		results,
		"duplicate trigger rejects",
		service.registerTriggerDefinition(trigger("sc.trigger"))
	)
	expectAccept(
		results,
		"second trigger registers",
		service.registerTriggerDefinition(trigger("sc.trigger.two"))
	)
	expectReject(
		results,
		"trigger id rejects as category id",
		service.registerTriggerCategory(category("sc.trigger"))
	)
	expectReject(
		results,
		"category id rejects as source id",
		service.registerTriggerSource(source("sc.category"))
	)
	expectReject(
		results,
		"source id rejects as target id",
		service.registerTriggerTarget(target("sc.source"))
	)

	expectAccept(results, "valid event registers", service.registerTriggerEvent(event("sc.event")))
	expectReject(results, "malformed event rejects", service.registerTriggerEvent({}))
	expectReject(
		results,
		"duplicate event rejects",
		service.registerTriggerEvent(event("sc.event"))
	)
	expectReject(
		results,
		"event bad trigger ref rejects",
		service.registerTriggerEvent(event("sc.event.badtrigger", "missing"))
	)
	expectReject(
		results,
		"event bad kind rejects",
		service.registerTriggerEvent(event("sc.event.badkind", nil, "Bad"))
	)

	expectAccept(
		results,
		"valid filter registers",
		service.registerTriggerFilter(filter("sc.filter"))
	)
	expectReject(results, "malformed filter rejects", service.registerTriggerFilter({}))
	expectReject(
		results,
		"duplicate filter rejects",
		service.registerTriggerFilter(filter("sc.filter"))
	)
	expectReject(
		results,
		"filter bad trigger ref rejects",
		service.registerTriggerFilter(filter("sc.filter.badtrigger", "missing"))
	)

	expectAccept(
		results,
		"valid condition registers",
		service.registerTriggerCondition(condition("sc.condition"))
	)
	expectReject(results, "malformed condition rejects", service.registerTriggerCondition({}))
	expectReject(
		results,
		"duplicate condition rejects",
		service.registerTriggerCondition(condition("sc.condition"))
	)
	expectReject(
		results,
		"condition bad trigger ref rejects",
		service.registerTriggerCondition(condition("sc.condition.badtrigger", "missing"))
	)

	expectAccept(
		results,
		"valid dependency registers",
		service.registerTriggerDependency(dependency("sc.dependency"))
	)
	expectReject(results, "malformed dependency rejects", service.registerTriggerDependency({}))
	expectReject(
		results,
		"duplicate dependency rejects",
		service.registerTriggerDependency(dependency("sc.dependency"))
	)
	expectReject(
		results,
		"dependency bad source rejects",
		service.registerTriggerDependency(
			dependency("sc.dependency.badsource", "missing", "sc.trigger.two")
		)
	)
	expectReject(
		results,
		"dependency bad target rejects",
		service.registerTriggerDependency(
			dependency("sc.dependency.badtarget", "sc.trigger", "missing")
		)
	)
	expectReject(
		results,
		"self dependency rejects",
		service.registerTriggerDependency(
			dependency("sc.dependency.self", "sc.trigger", "sc.trigger")
		)
	)
	expectReject(
		results,
		"direct dependency cycle rejects",
		service.registerTriggerDependency(
			dependency("sc.dependency.cycle", "sc.trigger.two", "sc.trigger")
		)
	)

	expectAccept(results, "valid group registers", service.registerTriggerGroup(group("sc.group")))
	expectReject(results, "malformed group rejects", service.registerTriggerGroup({}))
	expectReject(
		results,
		"duplicate group rejects",
		service.registerTriggerGroup(group("sc.group"))
	)
	expectReject(
		results,
		"group bad type rejects",
		service.registerTriggerGroup({
			groupId = "sc.group.bad",
			groupType = "Bad",
			triggerIds = { "sc.trigger" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"group bad member rejects",
		service.registerTriggerGroup(group("sc.group.badmember", { "missing" }))
	)
	expectReject(
		results,
		"group oversized members reject",
		service.registerTriggerGroup(
			group("sc.group.big", table.create(Types.Limits.MaxGroupMembers + 1, "sc.trigger"))
		)
	)

	expectAccept(
		results,
		"valid outcome registers",
		service.registerTriggerOutcome(outcome("sc.outcome"))
	)
	expectReject(results, "malformed outcome rejects", service.registerTriggerOutcome({}))
	expectReject(
		results,
		"duplicate outcome rejects",
		service.registerTriggerOutcome(outcome("sc.outcome"))
	)
	expectReject(
		results,
		"outcome bad kind rejects",
		service.registerTriggerOutcome(outcome("sc.outcome.badkind", nil, "Bad"))
	)
	expectReject(
		results,
		"outcome bad trigger ref rejects",
		service.registerTriggerOutcome(outcome("sc.outcome.badtrigger", "missing"))
	)

	expectAccept(
		results,
		"valid audit registers",
		service.registerTriggerAudit(audit("sc.audit", "sc.trigger"))
	)
	expectReject(results, "malformed audit rejects", service.registerTriggerAudit({}))
	expectReject(
		results,
		"duplicate audit rejects",
		service.registerTriggerAudit(audit("sc.audit", "sc.trigger"))
	)
	expectReject(
		results,
		"audit bad trigger ref rejects",
		service.registerTriggerAudit(audit("sc.audit.badtrigger", "missing"))
	)
	expectReject(
		results,
		"audit oversized findings reject",
		service.registerTriggerAudit({
			auditId = "sc.audit.big",
			auditKind = "SchemaReview",
			resultStatus = "Warn",
			findings = table.create(Types.Limits.MaxAuditFindings + 1, "finding"),
			ownerSystem = "SelfCheck",
		})
	)

	local forbiddenMarkers = {
		"triggerExecution",
		"executeTrigger",
		"eventDispatch",
		"dispatchEvent",
		"fireEvent",
		"emitEvent",
		"callback",
		"listener",
		"listenerExecution",
		"condition" .. "Evaluation",
		"ruleEvaluation",
		"ruleExecution",
		"schedulerExecution",
		"lifecycleExecution",
		"runtimeExecution",
		"runtimeOrchestration",
		"gameplayExecution",
		"monsterAIExecution",
		"remote" .. "Event",
		"remote" .. "Function",
		"http" .. "Service",
		"messaging" .. "Service",
		"ana" .. "lytics",
		"tele" .. "metry",
		"chapterContent",
		"story",
		"dialogue",
		"cutscene",
		"execute",
		"run",
		"dispatch",
		"publish",
		"subscribe",
	}
	for index, marker in ipairs(forbiddenMarkers) do
		expectReject(
			results,
			"forbidden key marker rejects " .. tostring(index),
			service.registerTriggerCategory({
				categoryId = "sc.forbidden.key." .. tostring(index),
				categoryName = "Forbidden",
				triggerDomain = "Core",
				metadata = { [marker] = true },
				ownerSystem = "SelfCheck",
			})
		)
		expectReject(
			results,
			"forbidden value marker rejects " .. tostring(index),
			service.registerTriggerCategory({
				categoryId = "sc.forbidden.value." .. tostring(index),
				categoryName = "Forbidden",
				triggerDomain = "Core",
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
			return service.registerTriggerCategory(payload)
		end)()
	)
	expectReject(
		results,
		"thread payload rejects",
		service.registerTriggerCategory({
			categoryId = "sc.thread",
			categoryName = "Thread",
			triggerDomain = "Core",
			metadata = { worker = makeThread() },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"function payload rejects",
		service.registerTriggerCategory({
			categoryId = "sc.function",
			categoryName = "Function",
			triggerDomain = "Core",
			metadata = { callbackValue = function() end },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"oversized string rejects",
		service.registerTriggerCategory({
			categoryId = "sc.bigstring",
			categoryName = string.rep("x", Types.Limits.MaxPayloadStringLength + 1),
			triggerDomain = "Core",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"deep payload rejects",
		service.registerTriggerCategory({
			categoryId = "sc.deep",
			categoryName = "Deep",
			triggerDomain = "Core",
			metadata = { { { { { { { { { { tooDeep = true } } } } } } } } } },
			ownerSystem = "SelfCheck",
		})
	)

	fillLimit(
		results,
		"category",
		service,
		"registerTriggerCategory",
		"categoryCount",
		Types.Limits.MaxCategories,
		function(index)
			return category("sc.limit.category." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"source",
		service,
		"registerTriggerSource",
		"sourceCount",
		Types.Limits.MaxSources,
		function(index)
			return source("sc.limit.source." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"target",
		service,
		"registerTriggerTarget",
		"targetCount",
		Types.Limits.MaxTargets,
		function(index)
			return target("sc.limit.target." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"trigger",
		service,
		"registerTriggerDefinition",
		"triggerCount",
		Types.Limits.MaxTriggers,
		function(index)
			return trigger("sc.limit.trigger." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"event",
		service,
		"registerTriggerEvent",
		"eventCount",
		Types.Limits.MaxEvents,
		function(index)
			return event("sc.limit.event." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"filter",
		service,
		"registerTriggerFilter",
		"filterCount",
		Types.Limits.MaxFilters,
		function(index)
			return filter("sc.limit.filter." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"condition",
		service,
		"registerTriggerCondition",
		"conditionCount",
		Types.Limits.MaxConditions,
		function(index)
			return condition("sc.limit.condition." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"dependency",
		service,
		"registerTriggerDependency",
		"dependencyCount",
		Types.Limits.MaxDependencies,
		function(index)
			return dependency("sc.limit.dependency." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"group",
		service,
		"registerTriggerGroup",
		"groupCount",
		Types.Limits.MaxGroups,
		function(index)
			return group("sc.limit.group." .. tostring(index))
		end
	)
	fillLimit(
		results,
		"outcome",
		service,
		"registerTriggerOutcome",
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
		"registerTriggerAudit",
		"auditCount",
		Types.Limits.MaxAudits,
		function(index)
			return audit("sc.limit.audit." .. tostring(index))
		end
	)

	for _ = 1, Types.Limits.MaxValidationFailures + 8 do
		service.registerTriggerCategory({})
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
	local originalTriggerCount = diagnostics.triggerCount
	diagnostics.triggerCount = -10
	snapshot.counts.definitions = -10
	record(
		results,
		"diagnostics are isolated",
		service.inspect().triggerCount == originalTriggerCount,
		originalTriggerCount
	)
	record(
		results,
		"snapshots are isolated",
		service.getSnapshot().counts.definitions == originalTriggerCount,
		originalTriggerCount
	)

	local posture = service.inspect().noExecutionPosture
	record(
		results,
		"no run posture",
		posture.noTriggerRun == true and posture.noGameplayRun == true,
		posture
	)
	record(
		results,
		"no dispatch posture",
		posture.noEventDispatch == true
			and posture.noCallbackRun == true
			and posture.noListenerRun == true,
		posture
	)
	record(
		results,
		"no remote posture",
		posture.noRemotes == true and posture.noClientAuthority == true,
		posture
	)

	service.shutdown()
	local afterShutdown = service.inspect()
	record(
		results,
		"shutdown clears state",
		afterShutdown.triggerCount == 0 and afterShutdown.categoryCount == 0,
		afterShutdown
	)
	expectAccept(
		results,
		"global namespace clears on shutdown",
		service.registerTriggerDefinition(trigger("sc.trigger"))
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
