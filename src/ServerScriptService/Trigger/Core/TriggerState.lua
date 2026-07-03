--!strict
-- Bounded schema store for the Trigger Runtime Foundation.

local Serialization = require(script.Parent.TriggerSerialization)
local Types = require(script.Parent.TriggerTypes)
local Validation = require(script.Parent.TriggerValidation)

local State = {}

local definitions: { [string]: any } = {}
local categories: { [string]: any } = {}
local sources: { [string]: any } = {}
local targets: { [string]: any } = {}
local events: { [string]: any } = {}
local filters: { [string]: any } = {}
local conditions: { [string]: any } = {}
local dependencies: { [string]: any } = {}
local groups: { [string]: any } = {}
local outcomes: { [string]: any } = {}
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
	if schemaIds[id] == true then
		return false, duplicate
	end
	if countMap(map) >= limit then
		return false, limitReason
	end
	schemaIds[id] = true
	map[id] = Serialization.deepCopy(schema)
	return true, nil
end

function State.registerDefinition(schema: any): (boolean, string?)
	local ok, reason = Validation.definition(schema)
	if not ok then
		return false, reason
	end
	local checks = {
		{ categories, schema.categoryIds, "category" },
		{ sources, schema.sourceIds, "source" },
		{ targets, schema.targetIds, "target" },
		{ events, schema.eventIds, "event" },
		{ filters, schema.filterIds, "filter" },
		{ conditions, schema.conditionIds, "condition" },
		{ dependencies, schema.dependencyIds, "dependency" },
		{ outcomes, schema.outcomeIds, "outcome" },
	}
	for _, check in ipairs(checks) do
		local refsOk, refsReason = hasAll(check[1], check[2], check[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		definitions,
		schema.triggerId,
		schema,
		Types.Limits.MaxTriggers,
		"duplicate triggerId",
		"trigger limit exceeded"
	)
end

function State.registerCategory(schema: any): (boolean, string?)
	local ok, reason = Validation.category(schema)
	if not ok then
		return false, reason
	end
	return register(
		categories,
		schema.categoryId,
		schema,
		Types.Limits.MaxCategories,
		"duplicate categoryId",
		"category limit exceeded"
	)
end

function State.registerSource(schema: any): (boolean, string?)
	local ok, reason = Validation.source(schema)
	if not ok then
		return false, reason
	end
	return register(
		sources,
		schema.sourceId,
		schema,
		Types.Limits.MaxSources,
		"duplicate sourceId",
		"source limit exceeded"
	)
end

function State.registerTarget(schema: any): (boolean, string?)
	local ok, reason = Validation.target(schema)
	if not ok then
		return false, reason
	end
	return register(
		targets,
		schema.targetId,
		schema,
		Types.Limits.MaxTargets,
		"duplicate targetId",
		"target limit exceeded"
	)
end

local function registerTriggerChild(
	schema: any,
	validate: (any) -> (boolean, string?),
	map: { [string]: any },
	idField: string,
	limit: number,
	duplicate: string,
	limitReason: string
): (boolean, string?)
	local ok, reason = validate(schema)
	if not ok then
		return false, reason
	end
	if definitions[schema.triggerId] == nil then
		return false, "invalid trigger reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerEvent(schema: any): (boolean, string?)
	return registerTriggerChild(
		schema,
		Validation.event,
		events,
		"eventId",
		Types.Limits.MaxEvents,
		"duplicate eventId",
		"event limit exceeded"
	)
end

function State.registerFilter(schema: any): (boolean, string?)
	return registerTriggerChild(
		schema,
		Validation.filter,
		filters,
		"filterId",
		Types.Limits.MaxFilters,
		"duplicate filterId",
		"filter limit exceeded"
	)
end

function State.registerCondition(schema: any): (boolean, string?)
	return registerTriggerChild(
		schema,
		Validation.condition,
		conditions,
		"conditionId",
		Types.Limits.MaxConditions,
		"duplicate conditionId",
		"condition limit exceeded"
	)
end

function State.registerDependency(schema: any): (boolean, string?)
	local ok, reason = Validation.dependency(schema)
	if not ok then
		return false, reason
	end
	if definitions[schema.sourceTriggerId] == nil or definitions[schema.targetTriggerId] == nil then
		return false, "invalid dependency trigger reference"
	end
	for _, existing in pairs(dependencies) do
		if
			existing.sourceTriggerId == schema.targetTriggerId
			and existing.targetTriggerId == schema.sourceTriggerId
		then
			return false, "direct trigger dependency cycle"
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

function State.registerGroup(schema: any): (boolean, string?)
	local ok, reason = Validation.group(schema)
	if not ok then
		return false, reason
	end
	local refsOk, refsReason = hasAll(definitions, schema.triggerIds, "trigger")
	if not refsOk then
		return false, refsReason
	end
	return register(
		groups,
		schema.groupId,
		schema,
		Types.Limits.MaxGroups,
		"duplicate groupId",
		"group limit exceeded"
	)
end

function State.registerOutcome(schema: any): (boolean, string?)
	return registerTriggerChild(
		schema,
		Validation.outcome,
		outcomes,
		"outcomeId",
		Types.Limits.MaxOutcomes,
		"duplicate outcomeId",
		"outcome limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	local ok, reason = Validation.audit(schema)
	if not ok then
		return false, reason
	end
	if schema.triggerId ~= nil and definitions[schema.triggerId] == nil then
		return false, "invalid audit trigger reference"
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
	boundedInsert(
		validationFailures,
		{ reason = reason, payload = Serialization.diagnosticCopy(payload) },
		Types.Limits.MaxValidationFailures
	)
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
		definitions = definitions,
		categories = categories,
		sources = sources,
		targets = targets,
		events = events,
		filters = filters,
		conditions = conditions,
		dependencies = dependencies,
		groups = groups,
		outcomes = outcomes,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			definitions = countMap(definitions),
			categories = countMap(categories),
			sources = countMap(sources),
			targets = countMap(targets),
			events = countMap(events),
			filters = countMap(filters),
			conditions = countMap(conditions),
			dependencies = countMap(dependencies),
			groups = countMap(groups),
			outcomes = countMap(outcomes),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(definitions)
	table.clear(categories)
	table.clear(sources)
	table.clear(targets)
	table.clear(events)
	table.clear(filters)
	table.clear(conditions)
	table.clear(dependencies)
	table.clear(groups)
	table.clear(outcomes)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
