--!strict
-- Bounded schema store for the Condition Runtime Foundation.

local Serialization = require(script.Parent.ConditionSerialization)
local Types = require(script.Parent.ConditionTypes)
local Validation = require(script.Parent.ConditionValidation)

local State = {}

local definitions: { [string]: any } = {}
local categories: { [string]: any } = {}
local expressions: { [string]: any } = {}
local operands: { [string]: any } = {}
local operators: { [string]: any } = {}
local groups: { [string]: any } = {}
local dependencies: { [string]: any } = {}
local states: { [string]: any } = {}
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
		{ expressions, schema.expressionIds, "expression" },
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
		schema.conditionId,
		schema,
		Types.Limits.MaxConditions,
		"duplicate conditionId",
		"condition limit exceeded"
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

function State.registerOperand(schema: any): (boolean, string?)
	local ok, reason = Validation.operand(schema)
	if not ok then
		return false, reason
	end
	return register(
		operands,
		schema.operandId,
		schema,
		Types.Limits.MaxOperands,
		"duplicate operandId",
		"operand limit exceeded"
	)
end

function State.registerOperator(schema: any): (boolean, string?)
	local ok, reason = Validation.operator(schema)
	if not ok then
		return false, reason
	end
	return register(
		operators,
		schema.operatorId,
		schema,
		Types.Limits.MaxOperators,
		"duplicate operatorId",
		"operator limit exceeded"
	)
end

function State.registerExpression(schema: any): (boolean, string?)
	local ok, reason = Validation.expression(schema)
	if not ok then
		return false, reason
	end
	if definitions[schema.conditionId] == nil then
		return false, "invalid condition reference"
	end
	if operators[schema.operatorId] == nil then
		return false, "invalid operator reference"
	end
	local refsOk, refsReason = hasAll(operands, schema.operandIds, "operand")
	if not refsOk then
		return false, refsReason
	end
	return register(
		expressions,
		schema.expressionId,
		schema,
		Types.Limits.MaxExpressions,
		"duplicate expressionId",
		"expression limit exceeded"
	)
end

function State.registerGroup(schema: any): (boolean, string?)
	local ok, reason = Validation.group(schema)
	if not ok then
		return false, reason
	end
	local refsOk, refsReason = hasAll(definitions, schema.conditionIds, "condition")
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

function State.registerDependency(schema: any): (boolean, string?)
	local ok, reason = Validation.dependency(schema)
	if not ok then
		return false, reason
	end
	if
		definitions[schema.sourceConditionId] == nil
		or definitions[schema.targetConditionId] == nil
	then
		return false, "invalid dependency condition reference"
	end
	for _, existing in pairs(dependencies) do
		if
			existing.sourceConditionId == schema.targetConditionId
			and existing.targetConditionId == schema.sourceConditionId
		then
			return false, "direct condition dependency cycle"
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

local function registerConditionChild(
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
	if definitions[schema.conditionId] == nil then
		return false, "invalid condition reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerState(schema: any): (boolean, string?)
	return registerConditionChild(
		schema,
		Validation.state,
		states,
		"stateId",
		Types.Limits.MaxStates,
		"duplicate stateId",
		"state limit exceeded"
	)
end

function State.registerOutcome(schema: any): (boolean, string?)
	return registerConditionChild(
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
	if schema.conditionId ~= nil and definitions[schema.conditionId] == nil then
		return false, "invalid audit condition reference"
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
		expressions = expressions,
		operands = operands,
		operators = operators,
		groups = groups,
		dependencies = dependencies,
		states = states,
		outcomes = outcomes,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			definitions = countMap(definitions),
			categories = countMap(categories),
			expressions = countMap(expressions),
			operands = countMap(operands),
			operators = countMap(operators),
			groups = countMap(groups),
			dependencies = countMap(dependencies),
			states = countMap(states),
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
	table.clear(expressions)
	table.clear(operands)
	table.clear(operators)
	table.clear(groups)
	table.clear(dependencies)
	table.clear(states)
	table.clear(outcomes)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
