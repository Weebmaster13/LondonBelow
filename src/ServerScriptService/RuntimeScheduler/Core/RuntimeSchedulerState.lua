--!strict
-- Central bounded state store for the Runtime Scheduler Foundation.

local Serialization = require(script.Parent.RuntimeSchedulerSerialization)
local Types = require(script.Parent.RuntimeSchedulerTypes)
local Validation = require(script.Parent.RuntimeSchedulerValidation)

local State = {}

local plans: { [string]: any } = {}
local slots: { [string]: any } = {}
local queues: { [string]: any } = {}
local priorities: { [string]: any } = {}
local budgets: { [string]: any } = {}
local deadlines: { [string]: any } = {}
local retries: { [string]: any } = {}
local intervals: { [string]: any } = {}
local windows: { [string]: any } = {}
local dependencies: { [string]: any } = {}
local audits: { [string]: any } = {}
local schemaIds: { [string]: boolean } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function rejectDuplicate(schemaId: string, reason: string): (boolean, string?)
	if schemaIds[schemaId] == true then
		return false, reason
	end
	return true, nil
end

local function hasAll(map: { [string]: any }, values: any, label: string): (boolean, string?)
	if values == nil then
		return true, nil
	end
	for _, id in ipairs(values) do
		if map[id] == nil then
			return false, "invalid " .. label .. " reference"
		end
	end
	return true, nil
end

local function register(
	map: { [string]: any },
	id: string,
	schema: any,
	limit: number,
	duplicate: string,
	limitReason: string
): (boolean, string?)
	local unique, duplicateReason = rejectDuplicate(id, duplicate)
	if not unique then
		return false, duplicateReason
	end
	if countMap(map) >= limit then
		return false, limitReason
	end
	schemaIds[id] = true
	map[id] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerPlan(schema: any): (boolean, string?)
	local ok, reason = Validation.plan(schema)
	if not ok then
		return false, reason
	end
	local checks = {
		{ queues, schema.queueIds, "queue" },
		{ slots, schema.slotIds, "slot" },
		{ budgets, schema.budgetIds, "budget" },
		{ deadlines, schema.deadlineIds, "deadline" },
		{ retries, schema.retryIds, "retry" },
		{ intervals, schema.intervalIds, "interval" },
		{ windows, schema.windowIds, "window" },
		{ dependencies, schema.dependencyIds, "dependency" },
	}
	for _, check in ipairs(checks) do
		local refsOk, refsReason = hasAll(check[1], check[2], check[3])
		if not refsOk then
			return false, refsReason
		end
	end
	if schema.priorityId ~= nil and priorities[schema.priorityId] == nil then
		return false, "invalid priority reference"
	end
	return register(
		plans,
		schema.schedulePlanId,
		schema,
		Types.Limits.MaxSchedulePlans,
		"duplicate schedulePlanId",
		"schedule plan limit exceeded"
	)
end

function State.registerSlot(schema: any): (boolean, string?)
	local ok, reason = Validation.slot(schema)
	if not ok then
		return false, reason
	end
	return register(
		slots,
		schema.slotId,
		schema,
		Types.Limits.MaxSlots,
		"duplicate slotId",
		"slot limit exceeded"
	)
end

function State.registerQueue(schema: any): (boolean, string?)
	local ok, reason = Validation.queue(schema)
	if not ok then
		return false, reason
	end
	local prioritiesOk, prioritiesReason = hasAll(priorities, schema.priorityIds, "priority")
	if not prioritiesOk then
		return false, prioritiesReason
	end
	local budgetsOk, budgetsReason = hasAll(budgets, schema.budgetIds, "budget")
	if not budgetsOk then
		return false, budgetsReason
	end
	return register(
		queues,
		schema.queueId,
		schema,
		Types.Limits.MaxQueues,
		"duplicate queueId",
		"queue limit exceeded"
	)
end

function State.registerPriority(schema: any): (boolean, string?)
	local ok, reason = Validation.priority(schema)
	if not ok then
		return false, reason
	end
	return register(
		priorities,
		schema.priorityId,
		schema,
		Types.Limits.MaxPriorities,
		"duplicate priorityId",
		"priority limit exceeded"
	)
end

function State.registerBudget(schema: any): (boolean, string?)
	local ok, reason = Validation.budget(schema)
	if not ok then
		return false, reason
	end
	return register(
		budgets,
		schema.budgetId,
		schema,
		Types.Limits.MaxBudgets,
		"duplicate budgetId",
		"budget limit exceeded"
	)
end

function State.registerDeadline(schema: any): (boolean, string?)
	local ok, reason = Validation.deadline(schema)
	if not ok then
		return false, reason
	end
	return register(
		deadlines,
		schema.deadlineId,
		schema,
		Types.Limits.MaxDeadlines,
		"duplicate deadlineId",
		"deadline limit exceeded"
	)
end

function State.registerRetry(schema: any): (boolean, string?)
	local ok, reason = Validation.retry(schema)
	if not ok then
		return false, reason
	end
	return register(
		retries,
		schema.retryId,
		schema,
		Types.Limits.MaxRetries,
		"duplicate retryId",
		"retry limit exceeded"
	)
end

function State.registerInterval(schema: any): (boolean, string?)
	local ok, reason = Validation.interval(schema)
	if not ok then
		return false, reason
	end
	return register(
		intervals,
		schema.intervalId,
		schema,
		Types.Limits.MaxIntervals,
		"duplicate intervalId",
		"interval limit exceeded"
	)
end

function State.registerWindow(schema: any): (boolean, string?)
	local ok, reason = Validation.window(schema)
	if not ok then
		return false, reason
	end
	return register(
		windows,
		schema.windowId,
		schema,
		Types.Limits.MaxWindows,
		"duplicate windowId",
		"window limit exceeded"
	)
end

function State.registerDependency(schema: any): (boolean, string?)
	local ok, reason = Validation.dependency(schema)
	if not ok then
		return false, reason
	end
	if plans[schema.sourceSchedulePlanId] == nil or plans[schema.targetSchedulePlanId] == nil then
		return false, "invalid schedule plan reference"
	end
	for _, existing in pairs(dependencies) do
		if
			existing.sourceSchedulePlanId == schema.targetSchedulePlanId
			and existing.targetSchedulePlanId == schema.sourceSchedulePlanId
		then
			return false, "direct schedule dependency cycle"
		end
	end
	return register(
		dependencies,
		schema.dependencyId,
		schema,
		Types.Limits.MaxDependencies,
		"duplicate dependencyId",
		"dependency limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	if schema.schedulePlanId ~= nil and plans[schema.schedulePlanId] == nil then
		return false, "invalid audit schedule plan reference"
	end
	return register(
		audits,
		schema.auditId,
		schema,
		Types.Limits.MaxAudits,
		"duplicate auditId",
		"audit limit exceeded"
	)
end

function State.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function State.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function State.inspect()
	return Serialization.deepCopy({
		plans = plans,
		slots = slots,
		queues = queues,
		priorities = priorities,
		budgets = budgets,
		deadlines = deadlines,
		retries = retries,
		intervals = intervals,
		windows = windows,
		dependencies = dependencies,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			plans = countMap(plans),
			slots = countMap(slots),
			queues = countMap(queues),
			priorities = countMap(priorities),
			budgets = countMap(budgets),
			deadlines = countMap(deadlines),
			retries = countMap(retries),
			intervals = countMap(intervals),
			windows = countMap(windows),
			dependencies = countMap(dependencies),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(plans)
	table.clear(slots)
	table.clear(queues)
	table.clear(priorities)
	table.clear(budgets)
	table.clear(deadlines)
	table.clear(retries)
	table.clear(intervals)
	table.clear(windows)
	table.clear(dependencies)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
