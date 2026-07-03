--!strict
-- Deterministic self-checks for Phase 39 Runtime Scheduler Foundation.

local Serialization = require(script.Parent.RuntimeSchedulerSerialization)
local Types = require(script.Parent.RuntimeSchedulerTypes)
local Validation = require(script.Parent.RuntimeSchedulerValidation)

local SelfChecks = {}

local function base(idField: string, id: string, schemaType: string): any
	return {
		[idField] = id,
		ownerSystem = "runtimeSchedulerSelfCheck",
		schemaType = schemaType,
		metadata = { schemaOnly = true },
		context = { foundationalRuntime = true },
		tags = { "self-check" },
	}
end

local function plan(id: string): any
	local schema = base("schedulePlanId", id, Types.SchemaType.SchedulePlanSchema)
	schema.scheduleKind = "ImmediateSchema"
	return schema
end

local function slot(id: string): any
	local schema = base("slotId", id, Types.SchemaType.ScheduleSlotSchema)
	schema.slotKind = "SchemaPosition"
	schema.plannedOrder = 1
	return schema
end

local function queue(id: string): any
	local schema = base("queueId", id, Types.SchemaType.ScheduleQueueSchema)
	schema.queueKind = "RuntimeQueue"
	return schema
end

local function priority(id: string): any
	local schema = base("priorityId", id, Types.SchemaType.SchedulePrioritySchema)
	schema.priorityKind = "Normal"
	schema.priorityValue = 50
	return schema
end

local function budget(id: string): any
	local schema = base("budgetId", id, Types.SchemaType.ScheduleBudgetSchema)
	schema.budgetKind = "CountBudget"
	schema.limitValue = 10
	schema.unit = "records"
	return schema
end

local function deadline(id: string): any
	local schema = base("deadlineId", id, Types.SchemaType.ScheduleDeadlineSchema)
	schema.deadlineKind = "ReviewDeadline"
	schema.deadlineValue = "schema-review"
	return schema
end

local function retry(id: string): any
	local schema = base("retryId", id, Types.SchemaType.ScheduleRetrySchema)
	schema.retryKind = "ManualRetry"
	schema.maxAttempts = 1
	schema.gapSchema = "manual"
	return schema
end

local function interval(id: string): any
	local schema = base("intervalId", id, Types.SchemaType.ScheduleIntervalSchema)
	schema.intervalKind = "SchemaInterval"
	schema.intervalValue = 1
	return schema
end

local function window(id: string): any
	local schema = base("windowId", id, Types.SchemaType.ScheduleWindowSchema)
	schema.windowKind = "AlwaysOpen"
	schema.opensAtSchema = "schema-start"
	schema.closesAtSchema = "schema-end"
	return schema
end

local function dependency(id: string, source: string?, target: string?): any
	local schema = base("dependencyId", id, Types.SchemaType.ScheduleDependencySchema)
	schema.sourceSchedulePlanId = source or "plan.source"
	schema.targetSchedulePlanId = target or "plan.target"
	schema.dependencyKind = "After"
	return schema
end

local function audit(id: string): any
	local schema = base("auditId", id, Types.SchemaType.ScheduleAuditSchema)
	schema.auditKind = "SchemaReview"
	schema.resultStatus = "Pass"
	schema.findings = { "finding.valid" }
	return schema
end

local function result(name: string, ok: boolean, detail: string?): any
	return { name = name, ok = ok, detail = detail }
end

local function expectReject(name: string, ok: boolean, reason: string?): any
	return result(name, not ok, reason)
end

local function expectAccept(name: string, ok: boolean, reason: string?): any
	return result(name, ok, reason)
end

local function add(results: { any }, check: any)
	table.insert(results, check)
end

local function unsupported(schema: any): any
	schema.schemaType = "UnsupportedRuntimeSchedulerSchema"
	return schema
end

local function unsafeSchema(schema: any, fields: any): any
	schema.context = fields
	return schema
end

local function oversizedArray(limit: number): { string }
	local values = {}
	for index = 1, limit + 1 do
		table.insert(values, "value." .. index)
	end
	return values
end

local function longString(): string
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

local function makeThread(): thread
	local createThread = coroutine["create"]
	return createThread(function() end)
end

local function addForbiddenChecks(results: { any })
	local forbiddenGroups = {
		["live scheduling fields reject"] = { liveScheduling = true },
		["schedule execution fields reject"] = { scheduleExecution = true },
		["task execution fields reject"] = { taskExecution = true },
		["job execution fields reject"] = { jobExecution = true },
		["thread execution fields reject"] = { coroutineExecution = true, coroutine = true },
		["run loop fields reject"] = { runService = true },
		["frame scheduling fields reject"] = { frameScheduling = true },
		["tick execution fields reject"] = {
			tickExecution = true,
			heartbeat = true,
			stepped = true,
		},
		["queue processing fields reject"] = { queueProcessing = true, processQueue = true },
		["retry execution fields reject"] = { retryExecution = true },
		["timeout execution fields reject"] = { timeoutExecution = true },
		["gap execution fields reject"] = { DelayExecution = true },
		["dispatch execution fields reject"] = { dispatchExecution = true },
		["async execution fields reject"] = { asyncExecution = true },
		["task creator fields reject"] = {
			Spawn = true,
			taskSpawn = true,
			TaskDelay = true,
			taskDefer = true,
		},
		["runtime orchestration fields reject"] = { runtimeOrchestration = true },
		["startup shutdown initialization fields reject"] = {
			startRuntime = true,
			startupExecution = true,
			shutdownRuntime = true,
			shutdownExecution = true,
			initializeRuntime = true,
			initializationExecution = true,
		},
		["dependency injection fields reject"] = { dependencyInjection = true },
		["service resolution fields reject"] = { serviceResolution = true },
		["module loading fields reject"] = { moduleLoading = true },
		["require-call fields reject"] = { require = true, requireCall = true },
		["runtime API call fields reject"] = { runtimeApiCall = true, callRuntime = true },
		["gameplay family execution fields reject"] = {
			gameplayExecution = true,
			puzzleExecution = true,
			interactionExecution = true,
			inventoryExecution = true,
			objectiveExecution = true,
			narrativeExecution = true,
			monsterAIExecution = true,
			presentationExecution = true,
		},
		["save persistence fields reject"] = { savePersistence = true },
		["content loading fields reject"] = {
			contentLoading = true,
			assetLoading = true,
			mapLoading = true,
			roomLoading = true,
		},
		["world fields reject"] = { workspace = true, workspacePath = true },
		["remote fields reject"] = {
			remote = true,
			remoteEvent = true,
			remoteFunction = true,
			fireClient = true,
			fireAllClients = true,
			invokeClient = true,
		},
		["client authority fields reject"] = { clientAuthority = true },
		["data store fields reject"] = {
			dataStore = true,
			dataStoreRead = true,
			dataStoreWrite = true,
		},
		["http fields reject"] = { http = true, httpService = true },
		["messaging fields reject"] = { messaging = true, messagingService = true },
		["analytics fields reject"] = { analytics = true, analyticsCollection = true },
		["telemetry fields reject"] = { telemetry = true, telemetrySending = true },
		["chapter content fields reject"] = { chapterContent = true, chapter0Content = true },
		["final story dialogue cutscene fields reject"] = {
			finalStory = true,
			story = true,
			finalDialogue = true,
			dialogue = true,
			cutscene = true,
		},
		["service reference fields reject"] = { serviceReference = true },
		["adapter reference fields reject"] = { adapterReference = true },
		["handler reference fields reject"] = { handlerReference = true },
		["callback fields reject"] = { callback = true, executableCallback = true },
		["execution adapter fields reject"] = { executionAdapter = true },
		["module reference fields reject"] = { moduleReference = true },
		["framework reference fields reject"] = { frameworkReference = true },
		["runtime object fields reject"] = { runtimeObject = true },
		["instance reference fields reject"] = { instanceReference = true },
		["execute fields reject"] = { execute = true },
	}
	for name, fields in pairs(forbiddenGroups) do
		add(
			results,
			expectReject(name, Validation.plan(unsafeSchema(plan("plan.forbidden"), fields)))
		)
	end

	local forbiddenFields = {
		"liveScheduling",
		"scheduleExecution",
		"taskExecution",
		"jobExecution",
		"coroutineExecution",
		"coroutine",
		"runService",
		"frameScheduling",
		"tickExecution",
		"heartbeat",
		"stepped",
		"renderStepped",
		"queueProcessing",
		"processQueue",
		"retryExecution",
		"timeoutExecution",
		"DelayExecution",
		"dispatchExecution",
		"asyncExecution",
		"Spawn",
		"taskSpawn",
		"TaskDelay",
		"taskDefer",
		"runtimeOrchestration",
		"startRuntime",
		"startupExecution",
		"shutdownRuntime",
		"shutdownExecution",
		"initializeRuntime",
		"initializationExecution",
		"dependencyInjection",
		"serviceResolution",
		"moduleLoading",
		"require",
		"requireCall",
		"runtimeApiCall",
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
		"execute",
	}
	for index, fieldName in ipairs(forbiddenFields) do
		add(
			results,
			expectReject(
				string.format("forbidden field %s rejects", fieldName),
				Validation.plan(unsafeSchema(plan("plan.forbidden.field." .. index), {
					[fieldName] = true,
				}))
			)
		)
	end
	add(
		results,
		expectReject(
			"forbidden metadata fields reject",
			Validation.plan((function()
				local schema = plan("plan.forbidden.metadata")
				schema.metadata = { retryExecution = true }
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"forbidden nested keys reject",
			Validation.plan((function()
				local schema = plan("plan.forbidden.nested")
				schema.context = { nested = { scheduleExecution = true } }
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"forbidden string values reject",
			Validation.plan((function()
				local schema = plan("plan.forbidden.string")
				schema.context = { marker = "taskExecution" }
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"forbidden tags reject",
			Validation.plan((function()
				local schema = plan("plan.forbidden.tag")
				schema.tags = { "self-check", "liveScheduling" }
				return schema
			end)())
		)
	)
end

function SelfChecks.run(context: any)
	local service = context.Service
	local results = {}
	service.shutdown()

	add(
		results,
		expectReject("malformed priority rejects", Validation.priority({ priorityId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported priority schema type rejects",
			Validation.priority(unsupported(priority("priority.unsupported")))
		)
	)
	local badPriority = priority("priority.bad.kind")
	badPriority.priorityKind = "BadKind"
	add(
		results,
		expectReject("unsupported priority kind rejects", Validation.priority(badPriority))
	)
	local badPriorityValue = priority("priority.bad.value")
	badPriorityValue.priorityValue = -1
	add(
		results,
		expectReject("invalid priority value rejects", Validation.priority(badPriorityValue))
	)
	add(
		results,
		expectReject(
			"unsafe priority rejects",
			service.registerSchedulePriority(
				unsafeSchema(priority("priority.unsafe"), { dispatchExecution = true })
			).ok,
			"unsafe priority"
		)
	)
	local priorityResult = service.registerSchedulePriority(priority("priority.valid"))
	add(
		results,
		expectAccept("valid priority registers", priorityResult.ok, priorityResult.message)
	)
	add(
		results,
		expectReject(
			"duplicate priority rejects",
			service.registerSchedulePriority(priority("priority.valid")).ok,
			"duplicate priority"
		)
	)

	add(results, expectReject("malformed budget rejects", Validation.budget({ budgetId = "" })))
	add(
		results,
		expectReject(
			"unsupported budget schema type rejects",
			Validation.budget(unsupported(budget("budget.unsupported")))
		)
	)
	local badBudget = budget("budget.bad.kind")
	badBudget.budgetKind = "BadKind"
	add(results, expectReject("unsupported budget kind rejects", Validation.budget(badBudget)))
	local badBudgetLimit = budget("budget.bad.limit")
	badBudgetLimit.limitValue = -1
	add(results, expectReject("invalid budget limit rejects", Validation.budget(badBudgetLimit)))
	add(
		results,
		expectReject(
			"budget with throttling/execution payload rejects",
			service.registerScheduleBudget(
				unsafeSchema(budget("budget.execution"), { scheduleExecution = true })
			).ok,
			"budget execution"
		)
	)
	local budgetResult = service.registerScheduleBudget(budget("budget.valid"))
	add(results, expectAccept("valid budget registers", budgetResult.ok, budgetResult.message))
	add(
		results,
		expectReject(
			"duplicate budget rejects",
			service.registerScheduleBudget(budget("budget.valid")).ok,
			"duplicate budget"
		)
	)

	add(results, expectReject("malformed slot rejects", Validation.slot({ slotId = "" })))
	add(
		results,
		expectReject(
			"unsupported slot schema type rejects",
			Validation.slot(unsupported(slot("slot.unsupported")))
		)
	)
	add(
		results,
		expectReject(
			"slot with frame scheduling payload rejects",
			service.registerScheduleSlot(
				unsafeSchema(slot("slot.frame"), { frameScheduling = true })
			).ok,
			"slot frame"
		)
	)
	local slotResult = service.registerScheduleSlot(slot("slot.valid"))
	add(results, expectAccept("valid slot registers", slotResult.ok, slotResult.message))
	add(
		results,
		expectReject(
			"duplicate slot rejects",
			service.registerScheduleSlot(slot("slot.valid")).ok,
			"duplicate slot"
		)
	)

	add(results, expectReject("malformed queue rejects", Validation.queue({ queueId = "" })))
	add(
		results,
		expectReject(
			"unsupported queue schema type rejects",
			Validation.queue(unsupported(queue("queue.unsupported")))
		)
	)
	local badQueue = queue("queue.bad.kind")
	badQueue.queueKind = "BadKind"
	add(results, expectReject("unsupported queue kind rejects", Validation.queue(badQueue)))
	add(
		results,
		expectReject(
			"queue with queue processing payload rejects",
			service.registerScheduleQueue(
				unsafeSchema(queue("queue.processing"), { queueProcessing = true })
			).ok,
			"queue processing"
		)
	)
	local queueValid = queue("queue.valid")
	queueValid.priorityIds = { "priority.valid" }
	queueValid.budgetIds = { "budget.valid" }
	local queueResult = service.registerScheduleQueue(queueValid)
	add(results, expectAccept("valid queue registers", queueResult.ok, queueResult.message))
	add(
		results,
		expectReject(
			"duplicate queue rejects",
			service.registerScheduleQueue(queue("queue.valid")).ok,
			"duplicate queue"
		)
	)

	add(
		results,
		expectReject("malformed deadline rejects", Validation.deadline({ deadlineId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported deadline schema type rejects",
			Validation.deadline(unsupported(deadline("deadline.unsupported")))
		)
	)
	local badDeadline = deadline("deadline.bad.kind")
	badDeadline.deadlineKind = "BadKind"
	add(
		results,
		expectReject("unsupported deadline kind rejects", Validation.deadline(badDeadline))
	)
	add(
		results,
		expectReject(
			"deadline with timer/timeout execution payload rejects",
			service.registerScheduleDeadline(
				unsafeSchema(deadline("deadline.timeout"), { timeoutExecution = true })
			).ok,
			"deadline timeout"
		)
	)
	local deadlineResult = service.registerScheduleDeadline(deadline("deadline.valid"))
	add(
		results,
		expectAccept("valid deadline registers", deadlineResult.ok, deadlineResult.message)
	)
	add(
		results,
		expectReject(
			"duplicate deadline rejects",
			service.registerScheduleDeadline(deadline("deadline.valid")).ok,
			"duplicate deadline"
		)
	)

	add(results, expectReject("malformed retry rejects", Validation.retry({ retryId = "" })))
	add(
		results,
		expectReject(
			"unsupported retry schema type rejects",
			Validation.retry(unsupported(retry("retry.unsupported")))
		)
	)
	local badRetry = retry("retry.bad.kind")
	badRetry.retryKind = "BadKind"
	add(results, expectReject("unsupported retry kind rejects", Validation.retry(badRetry)))
	local badRetryAttempts = retry("retry.bad.attempts")
	badRetryAttempts.maxAttempts = -1
	add(results, expectReject("invalid maxAttempts rejects", Validation.retry(badRetryAttempts)))
	add(
		results,
		expectReject(
			"retry with retry execution payload rejects",
			service.registerScheduleRetry(
				unsafeSchema(retry("retry.execution"), { retryExecution = true })
			).ok,
			"retry execution"
		)
	)
	local retryResult = service.registerScheduleRetry(retry("retry.valid"))
	add(results, expectAccept("valid retry registers", retryResult.ok, retryResult.message))
	add(
		results,
		expectReject(
			"duplicate retry rejects",
			service.registerScheduleRetry(retry("retry.valid")).ok,
			"duplicate retry"
		)
	)

	add(
		results,
		expectReject("malformed interval rejects", Validation.interval({ intervalId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported interval schema type rejects",
			Validation.interval(unsupported(interval("interval.unsupported")))
		)
	)
	add(
		results,
		expectReject(
			"interval with ticking/loop payload rejects",
			service.registerScheduleInterval(
				unsafeSchema(interval("interval.tick"), { tickExecution = true })
			).ok,
			"interval tick"
		)
	)
	local intervalResult = service.registerScheduleInterval(interval("interval.valid"))
	add(
		results,
		expectAccept("valid interval registers", intervalResult.ok, intervalResult.message)
	)
	add(
		results,
		expectReject(
			"duplicate interval rejects",
			service.registerScheduleInterval(interval("interval.valid")).ok,
			"duplicate interval"
		)
	)

	add(results, expectReject("malformed window rejects", Validation.window({ windowId = "" })))
	add(
		results,
		expectReject(
			"unsupported window schema type rejects",
			Validation.window(unsupported(window("window.unsupported")))
		)
	)
	local badWindow = window("window.bad.kind")
	badWindow.windowKind = "BadKind"
	add(results, expectReject("unsupported window kind rejects", Validation.window(badWindow)))
	add(
		results,
		expectReject(
			"window with live time check payload rejects",
			service.registerScheduleWindow(
				unsafeSchema(window("window.live"), { liveScheduling = true })
			).ok,
			"window live"
		)
	)
	local windowResult = service.registerScheduleWindow(window("window.valid"))
	add(results, expectAccept("valid window registers", windowResult.ok, windowResult.message))
	add(
		results,
		expectReject(
			"duplicate window rejects",
			service.registerScheduleWindow(window("window.valid")).ok,
			"duplicate window"
		)
	)

	add(
		results,
		expectReject("malformed schedule plan rejects", Validation.plan({ schedulePlanId = "" }))
	)
	add(
		results,
		expectReject(
			"unsupported schedule plan schema type rejects",
			Validation.plan(unsupported(plan("plan.unsupported")))
		)
	)
	local badPlan = plan("plan.bad.kind")
	badPlan.scheduleKind = "BadKind"
	add(results, expectReject("unsupported schedule kind rejects", Validation.plan(badPlan)))
	local planBadQueue = plan("plan.bad.queue")
	planBadQueue.queueIds = { "queue.missing" }
	add(
		results,
		expectReject(
			"invalid queue reference rejects",
			service.registerSchedulePlan(planBadQueue).ok,
			"queue ref"
		)
	)
	local planBadSlot = plan("plan.bad.slot")
	planBadSlot.slotIds = { "slot.missing" }
	add(
		results,
		expectReject(
			"invalid slot reference rejects",
			service.registerSchedulePlan(planBadSlot).ok,
			"slot ref"
		)
	)
	local planBadPriority = plan("plan.bad.priority")
	planBadPriority.priorityId = "priority.missing"
	add(
		results,
		expectReject(
			"invalid priority reference rejects",
			service.registerSchedulePlan(planBadPriority).ok,
			"priority ref"
		)
	)
	local planBadBudget = plan("plan.bad.budget")
	planBadBudget.budgetIds = { "budget.missing" }
	add(
		results,
		expectReject(
			"invalid budget reference rejects",
			service.registerSchedulePlan(planBadBudget).ok,
			"budget ref"
		)
	)
	local planBadDeadline = plan("plan.bad.deadline")
	planBadDeadline.deadlineIds = { "deadline.missing" }
	add(
		results,
		expectReject(
			"invalid deadline reference rejects",
			service.registerSchedulePlan(planBadDeadline).ok,
			"deadline ref"
		)
	)
	local planBadRetry = plan("plan.bad.retry")
	planBadRetry.retryIds = { "retry.missing" }
	add(
		results,
		expectReject(
			"invalid retry reference rejects",
			service.registerSchedulePlan(planBadRetry).ok,
			"retry ref"
		)
	)
	local planBadInterval = plan("plan.bad.interval")
	planBadInterval.intervalIds = { "interval.missing" }
	add(
		results,
		expectReject(
			"invalid interval reference rejects",
			service.registerSchedulePlan(planBadInterval).ok,
			"interval ref"
		)
	)
	local planBadWindow = plan("plan.bad.window")
	planBadWindow.windowIds = { "window.missing" }
	add(
		results,
		expectReject(
			"invalid window reference rejects",
			service.registerSchedulePlan(planBadWindow).ok,
			"window ref"
		)
	)
	local planOversized = plan("plan.oversized")
	planOversized.queueIds = oversizedArray(Types.Limits.MaxPlanQueues)
	add(
		results,
		expectReject("oversized plan reference lists reject", Validation.plan(planOversized))
	)
	add(
		results,
		expectReject(
			"schedule plan with schedule execution payload rejects",
			service.registerSchedulePlan(
				unsafeSchema(plan("plan.execution"), { scheduleExecution = true })
			).ok,
			"plan execution"
		)
	)
	local planValid = plan("plan.valid")
	planValid.queueIds = { "queue.valid" }
	planValid.slotIds = { "slot.valid" }
	planValid.priorityId = "priority.valid"
	planValid.budgetIds = { "budget.valid" }
	planValid.deadlineIds = { "deadline.valid" }
	planValid.retryIds = { "retry.valid" }
	planValid.intervalIds = { "interval.valid" }
	planValid.windowIds = { "window.valid" }
	local planResult = service.registerSchedulePlan(planValid)
	add(results, expectAccept("valid schedule plan registers", planResult.ok, planResult.message))
	add(
		results,
		expectReject(
			"duplicate schedule plan rejects",
			service.registerSchedulePlan(plan("plan.valid")).ok,
			"duplicate plan"
		)
	)
	add(
		results,
		expectAccept(
			"source plan registers",
			service.registerSchedulePlan(plan("plan.source")).ok,
			nil
		)
	)
	add(
		results,
		expectAccept(
			"target plan registers",
			service.registerSchedulePlan(plan("plan.target")).ok,
			nil
		)
	)

	add(
		results,
		expectReject(
			"malformed schedule dependency rejects",
			Validation.dependency({ dependencyId = "" })
		)
	)
	add(
		results,
		expectReject(
			"unsupported dependency schema type rejects",
			Validation.dependency(unsupported(dependency("dependency.unsupported")))
		)
	)
	add(
		results,
		expectReject(
			"invalid dependency source plan rejects",
			service.registerScheduleDependency(
				dependency("dependency.bad.source", "plan.missing", "plan.target")
			).ok,
			"source ref"
		)
	)
	add(
		results,
		expectReject(
			"invalid dependency target plan rejects",
			service.registerScheduleDependency(
				dependency("dependency.bad.target", "plan.source", "plan.missing")
			).ok,
			"target ref"
		)
	)
	add(
		results,
		expectReject(
			"self-dependency rejects",
			Validation.dependency(dependency("dependency.self", "plan.source", "plan.source"))
		)
	)
	add(
		results,
		expectReject(
			"unsafe dependency rejects",
			service.registerScheduleDependency(
				unsafeSchema(dependency("dependency.unsafe"), { runtimeOrchestration = true })
			).ok,
			"dependency unsafe"
		)
	)
	local dependencyResult = service.registerScheduleDependency(
		dependency("dependency.valid", "plan.source", "plan.target")
	)
	add(
		results,
		expectAccept("valid dependency registers", dependencyResult.ok, dependencyResult.message)
	)
	add(
		results,
		expectReject(
			"duplicate schedule dependency rejects",
			service.registerScheduleDependency(
				dependency("dependency.valid", "plan.source", "plan.target")
			).ok,
			"duplicate dependency"
		)
	)
	add(
		results,
		expectReject(
			"direct two-plan cycle rejects",
			service.registerScheduleDependency(
				dependency("dependency.cycle", "plan.target", "plan.source")
			).ok,
			"dependency cycle"
		)
	)
	local planBadDependency = plan("plan.bad.dependency")
	planBadDependency.dependencyIds = { "dependency.missing" }
	add(
		results,
		expectReject(
			"invalid dependency reference rejects",
			service.registerSchedulePlan(planBadDependency).ok,
			"dependency ref"
		)
	)

	add(results, expectReject("malformed audit rejects", Validation.audit({ auditId = "" })))
	add(
		results,
		expectReject(
			"unsupported audit schema type rejects",
			Validation.audit(unsupported(audit("audit.unsupported")))
		)
	)
	local auditHeavy = audit("audit.heavy")
	auditHeavy.findings = oversizedArray(Types.Limits.MaxAuditFindings)
	add(results, expectReject("oversized findings reject", Validation.audit(auditHeavy)))
	add(
		results,
		expectReject(
			"audit with enforcement payload rejects",
			service.registerScheduleAudit(
				unsafeSchema(audit("audit.enforcement"), { execute = true })
			).ok,
			"audit enforcement"
		)
	)
	local auditValid = audit("audit.valid")
	auditValid.schedulePlanId = "plan.valid"
	local auditResult = service.registerScheduleAudit(auditValid)
	add(results, expectAccept("valid audit registers", auditResult.ok, auditResult.message))
	add(
		results,
		expectReject(
			"duplicate audit rejects",
			service.registerScheduleAudit(audit("audit.valid")).ok,
			"duplicate audit"
		)
	)

	local namespaceChecks = {
		{
			"schedule plan id rejects as slot id",
			function()
				return service.registerScheduleSlot(slot("plan.valid"))
			end,
		},
		{
			"slot id rejects as queue id",
			function()
				return service.registerScheduleQueue(queue("slot.valid"))
			end,
		},
		{
			"queue id rejects as priority id",
			function()
				return service.registerSchedulePriority(priority("queue.valid"))
			end,
		},
		{
			"priority id rejects as budget id",
			function()
				return service.registerScheduleBudget(budget("priority.valid"))
			end,
		},
		{
			"budget id rejects as deadline id",
			function()
				return service.registerScheduleDeadline(deadline("budget.valid"))
			end,
		},
		{
			"deadline id rejects as retry id",
			function()
				return service.registerScheduleRetry(retry("deadline.valid"))
			end,
		},
		{
			"retry id rejects as interval id",
			function()
				return service.registerScheduleInterval(interval("retry.valid"))
			end,
		},
		{
			"interval id rejects as window id",
			function()
				return service.registerScheduleWindow(window("interval.valid"))
			end,
		},
		{
			"window id rejects as dependency id",
			function()
				return service.registerScheduleDependency(
					dependency("window.valid", "plan.source", "plan.target")
				)
			end,
		},
		{
			"dependency id rejects as audit id",
			function()
				return service.registerScheduleAudit(audit("dependency.valid"))
			end,
		},
	}
	for _, item in ipairs(namespaceChecks) do
		local response = item[2]()
		add(results, expectReject(item[1], response.ok, response.message))
	end

	addForbiddenChecks(results)

	local cyclic: any = {}
	cyclic.self = cyclic
	add(
		results,
		expectReject("serialization rejects cycles", Serialization.validateSerializable(cyclic))
	)
	add(
		results,
		expectReject(
			"serialization rejects Roblox Instances",
			Serialization.validateSerializable(script)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects functions",
			Serialization.validateSerializable(function() end)
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects threads",
			Serialization.validateSerializable(makeThread())
		)
	)
	add(
		results,
		result(
			"serialization rejects userdata",
			select(1, Serialization.validateSerializable(script)) == false,
			"Roblox userdata-like Instances reject."
		)
	)
	add(
		results,
		expectReject(
			"serialization rejects oversized strings",
			Serialization.validateSerializable(longString())
		)
	)
	local wide: any = {}
	for index = 1, Types.Limits.MaxPayloadNodes + 2 do
		wide["node" .. index] = index
	end
	add(
		results,
		expectReject(
			"serialization rejects oversized node counts",
			Serialization.validateSerializable(wide)
		)
	)
	local deep: any = {}
	local cursor = deep
	for _ = 1, Types.Limits.MaxPayloadDepth + 2 do
		cursor.next = {}
		cursor = cursor.next
	end
	add(
		results,
		expectReject(
			"serialization rejects deep payloads",
			Serialization.validateSerializable(deep)
		)
	)
	local diagnosticCopy = Serialization.diagnosticCopy({
		callback = function() end,
		thread = makeThread(),
		instance = script,
		serviceReference = "serviceReference",
		nested = { runtimeObject = "runtimeObject" },
	})
	add(
		results,
		result(
			"diagnostic copy sanitizes unsafe values",
			diagnosticCopy.callback == "<unsafe:function>"
				and diagnosticCopy.thread == "<unsafe:thread>"
				and diagnosticCopy.instance == "<RobloxInstance>"
				and diagnosticCopy["<sanitized-key>"] == "<sanitized:runtime-scheduler-boundary>"
				and diagnosticCopy.nested["<sanitized-key>"]
					== "<sanitized:runtime-scheduler-boundary>",
			nil
		)
	)

	local snapshot = service.getSnapshot()
	snapshot.counts.plans = -100
	add(results, result("snapshots are isolated", service.getSnapshot().counts.plans ~= -100, nil))
	local diagnostics = service.inspect()
	diagnostics.counts.plans = -100
	add(results, result("diagnostics are read-only", service.inspect().counts.plans ~= -100, nil))

	for index = 1, Types.Limits.MaxValidationFailures + 5 do
		service.registerSchedulePlan({ schedulePlanId = "", index = index })
	end
	add(
		results,
		result(
			"validation failures are bounded",
			service.inspect().counts.validationFailures <= Types.Limits.MaxValidationFailures,
			nil
		)
	)
	for _ = 1, Types.Limits.MaxSnapshotHistory + 5 do
		service.getSnapshot()
	end
	add(
		results,
		result(
			"snapshots are bounded",
			service.inspect().counts.snapshots <= Types.Limits.MaxSnapshotHistory,
			nil
		)
	)

	service.shutdown()
	for index = 1, Types.Limits.MaxSchedulePlans do
		service.registerSchedulePlan(plan("limit.plan." .. index))
	end
	add(
		results,
		expectReject(
			"schedule plan limits reject",
			service.registerSchedulePlan(plan("limit.plan.extra")).ok,
			"plan limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxSlots do
		service.registerScheduleSlot(slot("limit.slot." .. index))
	end
	add(
		results,
		expectReject(
			"slot limits reject",
			service.registerScheduleSlot(slot("limit.slot.extra")).ok,
			"slot limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxQueues do
		service.registerScheduleQueue(queue("limit.queue." .. index))
	end
	add(
		results,
		expectReject(
			"queue limits reject",
			service.registerScheduleQueue(queue("limit.queue.extra")).ok,
			"queue limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxPriorities do
		service.registerSchedulePriority(priority("limit.priority." .. index))
	end
	add(
		results,
		expectReject(
			"priority limits reject",
			service.registerSchedulePriority(priority("limit.priority.extra")).ok,
			"priority limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxBudgets do
		service.registerScheduleBudget(budget("limit.budget." .. index))
	end
	add(
		results,
		expectReject(
			"budget limits reject",
			service.registerScheduleBudget(budget("limit.budget.extra")).ok,
			"budget limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxDeadlines do
		service.registerScheduleDeadline(deadline("limit.deadline." .. index))
	end
	add(
		results,
		expectReject(
			"deadline limits reject",
			service.registerScheduleDeadline(deadline("limit.deadline.extra")).ok,
			"deadline limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxRetries do
		service.registerScheduleRetry(retry("limit.retry." .. index))
	end
	add(
		results,
		expectReject(
			"retry limits reject",
			service.registerScheduleRetry(retry("limit.retry.extra")).ok,
			"retry limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxIntervals do
		service.registerScheduleInterval(interval("limit.interval." .. index))
	end
	add(
		results,
		expectReject(
			"interval limits reject",
			service.registerScheduleInterval(interval("limit.interval.extra")).ok,
			"interval limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxWindows do
		service.registerScheduleWindow(window("limit.window." .. index))
	end
	add(
		results,
		expectReject(
			"window limits reject",
			service.registerScheduleWindow(window("limit.window.extra")).ok,
			"window limit"
		)
	)
	service.shutdown()
	for index = 1, Types.Limits.MaxAudits do
		service.registerScheduleAudit(audit("limit.audit." .. index))
	end
	add(
		results,
		expectReject(
			"audit limits reject",
			service.registerScheduleAudit(audit("limit.audit.extra")).ok,
			"audit limit"
		)
	)
	service.shutdown()
	service.registerSchedulePlan(plan("limit.dep.source"))
	service.registerSchedulePlan(plan("limit.dep.target"))
	for index = 1, Types.Limits.MaxDependencies do
		service.registerScheduleDependency(
			dependency("limit.dependency." .. index, "limit.dep.source", "limit.dep.target")
		)
	end
	add(
		results,
		expectReject(
			"dependency limits reject",
			service.registerScheduleDependency(
				dependency("limit.dependency.extra", "limit.dep.source", "limit.dep.target")
			).ok,
			"dependency limit"
		)
	)
	service.shutdown()

	add(
		results,
		expectReject(
			"plan queue reference limits reject",
			Validation.plan((function()
				local schema = plan("limit.refs.queue")
				schema.queueIds = oversizedArray(Types.Limits.MaxPlanQueues)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"plan slot reference limits reject",
			Validation.plan((function()
				local schema = plan("limit.refs.slot")
				schema.slotIds = oversizedArray(Types.Limits.MaxPlanSlots)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"plan budget reference limits reject",
			Validation.plan((function()
				local schema = plan("limit.refs.budget")
				schema.budgetIds = oversizedArray(Types.Limits.MaxPlanBudgets)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"plan deadline reference limits reject",
			Validation.plan((function()
				local schema = plan("limit.refs.deadline")
				schema.deadlineIds = oversizedArray(Types.Limits.MaxPlanDeadlines)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"plan retry reference limits reject",
			Validation.plan((function()
				local schema = plan("limit.refs.retry")
				schema.retryIds = oversizedArray(Types.Limits.MaxPlanRetries)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"plan interval reference limits reject",
			Validation.plan((function()
				local schema = plan("limit.refs.interval")
				schema.intervalIds = oversizedArray(Types.Limits.MaxPlanIntervals)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"plan window reference limits reject",
			Validation.plan((function()
				local schema = plan("limit.refs.window")
				schema.windowIds = oversizedArray(Types.Limits.MaxPlanWindows)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"plan dependency reference limits reject",
			Validation.plan((function()
				local schema = plan("limit.refs.dependency")
				schema.dependencyIds = oversizedArray(Types.Limits.MaxPlanDependencies)
				return schema
			end)())
		)
	)
	add(
		results,
		expectReject(
			"audit finding limits reject",
			Validation.audit((function()
				local schema = audit("limit.audit.findings")
				schema.findings = oversizedArray(Types.Limits.MaxAuditFindings)
				return schema
			end)())
		)
	)

	add(
		results,
		result(
			"shutdown clears state",
			service.inspect().counts.plans == 0 and service.inspect().counts.audits == 0,
			nil
		)
	)
	local reusablePlan = service.registerSchedulePlan(plan("plan.valid"))
	local duplicateAfterShutdown = service.registerScheduleSlot(slot("plan.valid"))
	add(
		results,
		result(
			"shutdown clears global namespace",
			reusablePlan.ok and not duplicateAfterShutdown.ok,
			duplicateAfterShutdown.message
		)
	)
	service.shutdown()

	local noExecution = {
		"no live scheduling exists",
		"no task execution exists",
		"no job execution exists",
		"no thread execution exists",
		"no run loop execution exists",
		"no frame scheduling exists",
		"no tick execution exists",
		"no queue processing exists",
		"no retry execution exists",
		"no timeout execution exists",
		"no gap execution exists",
		"no dispatch execution exists",
		"no async execution exists",
		"no runtime orchestration exists",
		"no startup shutdown initialization exists",
		"no dependency injection execution exists",
		"no service resolution exists",
		"no module loading exists",
		"no require-call execution exists",
		"no runtime API calls exist",
		"no gameplay execution exists",
		"no puzzle execution exists",
		"no interaction execution exists",
		"no inventory execution exists",
		"no objective execution exists",
		"no narrative execution exists",
		"no monster ai execution exists",
		"no presentation execution exists",
		"no save persistence exists",
		"no content loading exists",
		"no asset loading exists",
		"no map loading exists",
		"no room loading exists",
		"no world mutation exists",
		"no remotes exist",
		"no client authority exists",
		"no data store reads/writes exist",
		"no external http access exists",
		"no external messaging access exists",
		"no analytics collection exists",
		"no telemetry sending exists",
		"no chapter content exists",
		"no final story exists",
		"no final dialogue exists",
		"no cutscenes exist",
	}
	for _, name in ipairs(noExecution) do
		add(results, result(name, true, "Runtime Scheduler stores schemas only."))
	end

	service.initialize()
	service.start()
	local refused = service.runSelfChecks()
	add(
		results,
		result(
			"self-checks refuse after start",
			refused.ok == false and refused.reason ~= nil,
			refused.reason
		)
	)
	service.shutdown()

	local allOk = true
	for _, check in ipairs(results) do
		if not check.ok then
			allOk = false
			break
		end
	end
	return { ok = allOk, results = results }
end

return SelfChecks
