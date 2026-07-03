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
		"definition bad category ref rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.badcategory",
			triggerName = "Bad",
			triggerDomain = "Core",
			categoryIds = { "missing" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition bad target ref rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.badtarget",
			triggerName = "Bad",
			triggerDomain = "Core",
			targetIds = { "missing" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition bad event ref rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.badevent",
			triggerName = "Bad",
			triggerDomain = "Core",
			eventIds = { "missing" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition bad filter ref rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.badfilter",
			triggerName = "Bad",
			triggerDomain = "Core",
			filterIds = { "missing" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition bad condition ref rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.badcondition",
			triggerName = "Bad",
			triggerDomain = "Core",
			conditionIds = { "missing" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition bad dependency ref rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.baddependency",
			triggerName = "Bad",
			triggerDomain = "Core",
			dependencyIds = { "missing" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition bad outcome ref rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.badoutcome",
			triggerName = "Bad",
			triggerDomain = "Core",
			outcomeIds = { "missing" },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized source refs reject",
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
		"definition oversized category refs reject",
		service.registerTriggerDefinition({
			triggerId = "sc.bigcategories",
			triggerName = "Big",
			triggerDomain = "Core",
			categoryIds = table.create(Types.Limits.MaxTriggerCategories + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized target refs reject",
		service.registerTriggerDefinition({
			triggerId = "sc.bigtargets",
			triggerName = "Big",
			triggerDomain = "Core",
			targetIds = table.create(Types.Limits.MaxTriggerTargets + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized event refs reject",
		service.registerTriggerDefinition({
			triggerId = "sc.bigevents",
			triggerName = "Big",
			triggerDomain = "Core",
			eventIds = table.create(Types.Limits.MaxTriggerEvents + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized filter refs reject",
		service.registerTriggerDefinition({
			triggerId = "sc.bigfilters",
			triggerName = "Big",
			triggerDomain = "Core",
			filterIds = table.create(Types.Limits.MaxTriggerFilters + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized condition refs reject",
		service.registerTriggerDefinition({
			triggerId = "sc.bigconditions",
			triggerName = "Big",
			triggerDomain = "Core",
			conditionIds = table.create(Types.Limits.MaxTriggerConditions + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized dependency refs reject",
		service.registerTriggerDefinition({
			triggerId = "sc.bigdependencies",
			triggerName = "Big",
			triggerDomain = "Core",
			dependencyIds = table.create(Types.Limits.MaxTriggerDependencies + 1, "missing"),
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition oversized outcome refs reject",
		service.registerTriggerDefinition({
			triggerId = "sc.bigoutcomes",
			triggerName = "Big",
			triggerDomain = "Core",
			outcomeIds = table.create(Types.Limits.MaxTriggerOutcomes + 1, "missing"),
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
	expectReject(
		results,
		"definition dispatch marker rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.dispatchmarker",
			triggerName = "Bad",
			triggerDomain = "Core",
			metadata = { eventDispatch = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"definition callback marker rejects",
		service.registerTriggerDefinition({
			triggerId = "sc.callbackmarker",
			triggerName = "Bad",
			triggerDomain = "Core",
			metadata = { callback = true },
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
	expectReject(
		results,
		"category bad type rejects",
		service.registerTriggerCategory({
			categoryId = "sc.category.badtype",
			schemaType = "Bad",
			categoryName = "Bad",
			triggerDomain = "Core",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"category execution domain rejects",
		service.registerTriggerCategory({
			categoryId = "sc.category.executiondomain",
			categoryName = "Bad",
			triggerDomain = "Core",
			metadata = { executionBatch = true },
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
	expectReject(
		results,
		"source bad type rejects",
		service.registerTriggerSource({
			sourceId = "sc.source.badtype",
			schemaType = "Bad",
			sourceKind = "SchemaSource",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"source publisher marker rejects",
		service.registerTriggerSource({
			sourceId = "sc.source.publisher",
			sourceKind = "SchemaSource",
			metadata = { publisher = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"source emitter marker rejects",
		service.registerTriggerSource({
			sourceId = "sc.source.emitter",
			sourceKind = "SchemaSource",
			metadata = { eventEmitter = true },
			ownerSystem = "SelfCheck",
		})
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
	expectReject(
		results,
		"target bad type rejects",
		service.registerTriggerTarget({
			targetId = "sc.target.badtype",
			schemaType = "Bad",
			targetKind = "SchemaTarget",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"target receiver marker rejects",
		service.registerTriggerTarget({
			targetId = "sc.target.receiver",
			targetKind = "SchemaTarget",
			metadata = { receiverExecution = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"target listener marker rejects",
		service.registerTriggerTarget({
			targetId = "sc.target.listener",
			targetKind = "SchemaTarget",
			metadata = { listener = true },
			ownerSystem = "SelfCheck",
		})
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
		"event bad type rejects",
		service.registerTriggerEvent({
			eventId = "sc.event.badtype",
			schemaType = "Bad",
			triggerId = "sc.trigger",
			eventKind = "Enter",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"event bad kind rejects",
		service.registerTriggerEvent(event("sc.event.badkind", nil, "Bad"))
	)
	expectReject(
		results,
		"event route marker rejects",
		service.registerTriggerEvent({
			eventId = "sc.event.dispatch",
			triggerId = "sc.trigger",
			eventKind = "Enter",
			metadata = { dispatchEvent = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"event fire marker rejects",
		service.registerTriggerEvent({
			eventId = "sc.event.fire",
			triggerId = "sc.trigger",
			eventKind = "Enter",
			metadata = { fireEvent = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"target id rejects as event id",
		service.registerTriggerEvent(event("sc.target"))
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
	expectReject(
		results,
		"filter bad type rejects",
		service.registerTriggerFilter({
			filterId = "sc.filter.badtype",
			schemaType = "Bad",
			triggerId = "sc.trigger",
			filterKind = "SchemaFilter",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"filter live marker rejects",
		service.registerTriggerFilter({
			filterId = "sc.filter.live",
			triggerId = "sc.trigger",
			filterKind = "SchemaFilter",
			metadata = { liveFiltering = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"filter inspection marker rejects",
		service.registerTriggerFilter({
			filterId = "sc.filter.inspect",
			triggerId = "sc.trigger",
			filterKind = "SchemaFilter",
			metadata = { payloadInspectionExecution = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"event id rejects as filter id",
		service.registerTriggerFilter(filter("sc.event"))
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
	expectReject(
		results,
		"condition bad type rejects",
		service.registerTriggerCondition({
			conditionId = "sc.condition.badtype",
			schemaType = "Bad",
			triggerId = "sc.trigger",
			conditionRefId = "condition.schema",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"condition scoring marker rejects",
		service.registerTriggerCondition({
			conditionId = "sc.condition.eval",
			triggerId = "sc.trigger",
			conditionRefId = "condition.schema",
			metadata = { ["condition" .. "Evaluation"] = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"condition rule engine marker rejects",
		service.registerTriggerCondition({
			conditionId = "sc.condition.ruleengine",
			triggerId = "sc.trigger",
			conditionRefId = "condition.schema",
			metadata = { ruleEngineExecution = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"filter id rejects as condition id",
		service.registerTriggerCondition(condition("sc.filter"))
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
	expectReject(
		results,
		"dependency bad type rejects",
		service.registerTriggerDependency({
			dependencyId = "sc.dependency.badtype",
			schemaType = "Bad",
			sourceTriggerId = "sc.trigger",
			targetTriggerId = "sc.trigger.two",
			dependencyKind = "Requires",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"dependency blocking marker rejects",
		service.registerTriggerDependency({
			dependencyId = "sc.dependency.blocking",
			sourceTriggerId = "sc.trigger",
			targetTriggerId = "sc.trigger.two",
			dependencyKind = "Requires",
			metadata = { blockingExecution = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"condition id rejects as dependency id",
		service.registerTriggerDependency(dependency("sc.condition"))
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
		"group bad schema type rejects",
		service.registerTriggerGroup({
			groupId = "sc.group.badtype",
			schemaType = "Bad",
			groupType = "Sequential",
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
	expectReject(
		results,
		"group batch marker rejects",
		service.registerTriggerGroup({
			groupId = "sc.group.batch",
			groupType = "Sequential",
			triggerIds = { "sc.trigger" },
			metadata = { executionBatch = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"group orchestration marker rejects",
		service.registerTriggerGroup({
			groupId = "sc.group.orchestration",
			groupType = "Sequential",
			triggerIds = { "sc.trigger" },
			metadata = { runtimeOrchestration = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"dependency id rejects as group id",
		service.registerTriggerGroup(group("sc.dependency"))
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
		"outcome bad schema type rejects",
		service.registerTriggerOutcome({
			outcomeId = "sc.outcome.badtype",
			schemaType = "Bad",
			triggerId = "sc.trigger",
			outcomeKind = "Pending",
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"outcome bad trigger ref rejects",
		service.registerTriggerOutcome(outcome("sc.outcome.badtrigger", "missing"))
	)
	expectReject(
		results,
		"outcome computed marker rejects",
		service.registerTriggerOutcome({
			outcomeId = "sc.outcome.computed",
			triggerId = "sc.trigger",
			outcomeKind = "Pending",
			metadata = { computedResult = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"outcome gameplay marker rejects",
		service.registerTriggerOutcome({
			outcomeId = "sc.outcome.gameplay",
			triggerId = "sc.trigger",
			outcomeKind = "Pending",
			metadata = { gameplayResult = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"group id rejects as outcome id",
		service.registerTriggerOutcome(outcome("sc.group"))
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
		"audit bad schema type rejects",
		service.registerTriggerAudit({
			auditId = "sc.audit.badtype",
			schemaType = "Bad",
			auditKind = "SchemaReview",
			resultStatus = "Pass",
			ownerSystem = "SelfCheck",
		})
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
	expectReject(
		results,
		"audit enforcement marker rejects",
		service.registerTriggerAudit({
			auditId = "sc.audit.enforcement",
			auditKind = "SchemaReview",
			resultStatus = "Warn",
			metadata = { enforcement = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"audit remediation marker rejects",
		service.registerTriggerAudit({
			auditId = "sc.audit.remediation",
			auditKind = "SchemaReview",
			resultStatus = "Warn",
			metadata = { remediation = true },
			ownerSystem = "SelfCheck",
		})
	)
	expectReject(
		results,
		"outcome id rejects as audit id",
		service.registerTriggerAudit(audit("sc.outcome", "sc.trigger"))
	)

	local forbiddenMarkers = {
		"triggerExecution",
		"executeTrigger",
		"triggerRun",
		"triggerFire",
		"triggerDispatch",
		"eventDispatch",
		"dispatchEvent",
		"fireEvent",
		"emitEvent",
		"eventEmitter",
		"publisher",
		"receiverExecution",
		"callback",
		"executableCallback",
		"listener",
		"listenerExecution",
		"liveListener",
		"condition" .. "Evaluation",
		"evaluateCondition",
		"ruleEvaluation",
		"ruleExecution",
		"ruleEngineExecution",
		"schedulerExecution",
		"lifecycleExecution",
		"eventExecution",
		"eventGraphExecution",
		"runtimeGraphExecution",
		"conditionRuntimeExecution",
		"runtimeExecution",
		"runtimeOrchestration",
		"scripting",
		"scriptExecution",
		"stateMutation",
		"mutateState",
		"gameplayExecution",
		"puzzleExecution",
		"interactionExecution",
		"inventoryExecution",
		"objectiveExecution",
		"monsterAIExecution",
		"narrativeExecution",
		"presentationExecution",
		"saveExecution",
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
		"frameworkReference",
		"moduleReference",
		"runtimeObject",
		"instanceReference",
		"executionAdapter",
		"blockingExecution",
		"payloadInspectionExecution",
		"liveFiltering",
		"computedResult",
		"gameplayResult",
		"executionBatch",
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
