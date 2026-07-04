--!strict

local Serialization = require(script.Parent.AssetUsagePlanSerialization)
local Types = require(script.Parent.AssetUsagePlanTypes)
local Validation = require(script.Parent.AssetUsagePlanValidation)

local State = {}

local definitions: { [string]: any } = {}
local contexts: { [string]: any } = {}
local constraints: { [string]: any } = {}
local dependencies: { [string]: any } = {}
local budgets: { [string]: any } = {}
local accessibility: { [string]: any } = {}
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
		{ contexts, schema.contextIds, "context" },
		{ constraints, schema.constraintIds, "constraint" },
		{ dependencies, schema.dependencyIds, "dependency" },
		{ budgets, schema.budgetIds, "budget" },
		{ accessibility, schema.accessibilityIds, "accessibility" },
		{ audits, schema.auditIds, "audit" },
	}
	for _, check in ipairs(checks) do
		local refsOk, refsReason = hasAll(check[1], check[2], check[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		definitions,
		schema.usagePlanId,
		schema,
		Types.Limits.MaxUsagePlans,
		"duplicate usagePlanId",
		"usage plan limit exceeded"
	)
end

local function registerPlanChild(
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
	if definitions[schema.usagePlanId] == nil then
		return false, "invalid usagePlanId reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerContext(schema: any): (boolean, string?)
	return registerPlanChild(
		schema,
		Validation.context,
		contexts,
		"contextId",
		Types.Limits.MaxContexts,
		"duplicate contextId",
		"context limit exceeded"
	)
end

function State.registerConstraint(schema: any): (boolean, string?)
	return registerPlanChild(
		schema,
		Validation.constraint,
		constraints,
		"constraintId",
		Types.Limits.MaxConstraints,
		"duplicate constraintId",
		"constraint limit exceeded"
	)
end

function State.registerDependency(schema: any): (boolean, string?)
	local ok, reason = Validation.dependency(schema)
	if not ok then
		return false, reason
	end
	if
		definitions[schema.usagePlanId] == nil
		or definitions[schema.dependsOnUsagePlanId] == nil
	then
		return false, "invalid dependency usage plan reference"
	end
	for _, existing in pairs(dependencies) do
		if
			existing.usagePlanId == schema.dependsOnUsagePlanId
			and existing.dependsOnUsagePlanId == schema.usagePlanId
		then
			return false, "direct usage plan dependency cycle"
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

function State.registerBudget(schema: any): (boolean, string?)
	return registerPlanChild(
		schema,
		Validation.budget,
		budgets,
		"budgetId",
		Types.Limits.MaxBudgets,
		"duplicate budgetId",
		"budget limit exceeded"
	)
end

function State.registerAccessibility(schema: any): (boolean, string?)
	return registerPlanChild(
		schema,
		Validation.accessibility,
		accessibility,
		"accessibilityId",
		Types.Limits.MaxAccessibilityRecords,
		"duplicate accessibilityId",
		"accessibility limit exceeded"
	)
end

function State.registerAudit(schema: any): (boolean, string?)
	return registerPlanChild(
		schema,
		Validation.audit,
		audits,
		"auditId",
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
		contexts = contexts,
		constraints = constraints,
		dependencies = dependencies,
		budgets = budgets,
		accessibility = accessibility,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			definitions = countMap(definitions),
			contexts = countMap(contexts),
			constraints = countMap(constraints),
			dependencies = countMap(dependencies),
			budgets = countMap(budgets),
			accessibility = countMap(accessibility),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(definitions)
	table.clear(contexts)
	table.clear(constraints)
	table.clear(dependencies)
	table.clear(budgets)
	table.clear(accessibility)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
