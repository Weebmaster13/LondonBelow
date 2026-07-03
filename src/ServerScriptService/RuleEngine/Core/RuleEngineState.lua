--!strict
-- Central bounded state store for the Rule Engine Foundation.

local Serialization = require(script.Parent.RuleEngineSerialization)
local Types = require(script.Parent.RuleEngineTypes)
local Validation = require(script.Parent.RuleEngineValidation)

local State = {}

local rules: { [string]: any } = {}
local categories: { [string]: any } = {}
local predicates: { [string]: any } = {}
local constraints: { [string]: any } = {}
local permissions: { [string]: any } = {}
local policies: { [string]: any } = {}
local groups: { [string]: any } = {}
local dependencies: { [string]: any } = {}
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

function State.registerRule(schema: any): (boolean, string?)
	local ok, reason = Validation.rule(schema)
	if not ok then
		return false, reason
	end
	local checks = {
		{ categories, schema.categoryIds, "category" },
		{ predicates, schema.predicateIds, "predicate" },
		{ constraints, schema.constraintIds, "constraint" },
		{ permissions, schema.permissionIds, "permission" },
		{ policies, schema.policyIds, "policy" },
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
		rules,
		schema.ruleId,
		schema,
		Types.Limits.MaxRules,
		"duplicate ruleId",
		"rule limit exceeded"
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

local function registerRuleChild(
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
	if rules[schema.ruleId] == nil then
		return false, "invalid rule reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerPredicate(schema: any): (boolean, string?)
	return registerRuleChild(
		schema,
		Validation.predicate,
		predicates,
		"predicateId",
		Types.Limits.MaxPredicates,
		"duplicate predicateId",
		"predicate limit exceeded"
	)
end

function State.registerConstraint(schema: any): (boolean, string?)
	return registerRuleChild(
		schema,
		Validation.constraint,
		constraints,
		"constraintId",
		Types.Limits.MaxConstraints,
		"duplicate constraintId",
		"constraint limit exceeded"
	)
end

function State.registerPermission(schema: any): (boolean, string?)
	return registerRuleChild(
		schema,
		Validation.permission,
		permissions,
		"permissionId",
		Types.Limits.MaxPermissions,
		"duplicate permissionId",
		"permission limit exceeded"
	)
end

function State.registerPolicy(schema: any): (boolean, string?)
	return registerRuleChild(
		schema,
		Validation.policy,
		policies,
		"policyId",
		Types.Limits.MaxPolicies,
		"duplicate policyId",
		"policy limit exceeded"
	)
end

function State.registerGroup(schema: any): (boolean, string?)
	local ok, reason = Validation.group(schema)
	if not ok then
		return false, reason
	end
	local refsOk, refsReason = hasAll(rules, schema.ruleIds, "rule")
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
	if rules[schema.sourceRuleId] == nil or rules[schema.targetRuleId] == nil then
		return false, "invalid dependency rule reference"
	end
	for _, existing in pairs(dependencies) do
		if
			existing.sourceRuleId == schema.targetRuleId
			and existing.targetRuleId == schema.sourceRuleId
		then
			return false, "direct rule dependency cycle"
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

function State.registerOutcome(schema: any): (boolean, string?)
	return registerRuleChild(
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
	if schema.ruleId ~= nil and rules[schema.ruleId] == nil then
		return false, "invalid audit rule reference"
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
		rules = rules,
		categories = categories,
		predicates = predicates,
		constraints = constraints,
		permissions = permissions,
		policies = policies,
		groups = groups,
		dependencies = dependencies,
		outcomes = outcomes,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			rules = countMap(rules),
			categories = countMap(categories),
			predicates = countMap(predicates),
			constraints = countMap(constraints),
			permissions = countMap(permissions),
			policies = countMap(policies),
			groups = countMap(groups),
			dependencies = countMap(dependencies),
			outcomes = countMap(outcomes),
			audits = countMap(audits),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function State.clear()
	table.clear(rules)
	table.clear(categories)
	table.clear(predicates)
	table.clear(constraints)
	table.clear(permissions)
	table.clear(policies)
	table.clear(groups)
	table.clear(dependencies)
	table.clear(outcomes)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
