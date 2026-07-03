--!strict
-- Bounded schema store for the State Machine Runtime Foundation.

local Serialization = require(script.Parent.StateMachineSerialization)
local Types = require(script.Parent.StateMachineTypes)
local Validation = require(script.Parent.StateMachineValidation)

local State = {}

local definitions: { [string]: any } = {}
local states: { [string]: any } = {}
local transitions: { [string]: any } = {}
local guards: { [string]: any } = {}
local inputs: { [string]: any } = {}
local outputs: { [string]: any } = {}
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

function State.registerDefinition(schema: any): (boolean, string?)
	local ok, reason = Validation.definition(schema)
	if not ok then
		return false, reason
	end
	local checks = {
		{ states, schema.stateIds, "state" },
		{ transitions, schema.transitionIds, "transition" },
		{ guards, schema.guardIds, "guard" },
		{ inputs, schema.inputIds, "input" },
		{ outputs, schema.outputIds, "output" },
	}
	for _, check in ipairs(checks) do
		local refsOk, refsReason = hasAll(check[1], check[2], check[3])
		if not refsOk then
			return false, refsReason
		end
	end
	return register(
		definitions,
		schema.machineId,
		schema,
		Types.Limits.MaxStateMachines,
		"duplicate machineId",
		"state machine limit exceeded"
	)
end

local function registerMachineChild(
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
	if definitions[schema.machineId] == nil then
		return false, "invalid machine reference"
	end
	return register(map, schema[idField], schema, limit, duplicate, limitReason)
end

function State.registerState(schema: any): (boolean, string?)
	return registerMachineChild(
		schema,
		Validation.state,
		states,
		"stateId",
		Types.Limits.MaxStates,
		"duplicate stateId",
		"state limit exceeded"
	)
end

function State.registerTransition(schema: any): (boolean, string?)
	local ok, reason = Validation.transition(schema)
	if not ok then
		return false, reason
	end
	if definitions[schema.machineId] == nil then
		return false, "invalid machine reference"
	end
	if states[schema.sourceStateId] == nil then
		return false, "missing transition source"
	end
	if states[schema.targetStateId] == nil then
		return false, "missing transition target"
	end
	return register(
		transitions,
		schema.transitionId,
		schema,
		Types.Limits.MaxTransitions,
		"duplicate transitionId",
		"transition limit exceeded"
	)
end

function State.registerGuard(schema: any): (boolean, string?)
	return registerMachineChild(
		schema,
		Validation.guard,
		guards,
		"guardId",
		Types.Limits.MaxGuards,
		"duplicate guardId",
		"guard limit exceeded"
	)
end

function State.registerInput(schema: any): (boolean, string?)
	return registerMachineChild(
		schema,
		Validation.input,
		inputs,
		"inputId",
		Types.Limits.MaxInputs,
		"duplicate inputId",
		"input limit exceeded"
	)
end

function State.registerOutput(schema: any): (boolean, string?)
	return registerMachineChild(
		schema,
		Validation.output,
		outputs,
		"outputId",
		Types.Limits.MaxOutputs,
		"duplicate outputId",
		"output limit exceeded"
	)
end

function State.registerGroup(schema: any): (boolean, string?)
	local ok, reason = Validation.group(schema)
	if not ok then
		return false, reason
	end
	local refsOk, refsReason = hasAll(definitions, schema.machineIds, "machine")
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
	if definitions[schema.sourceMachineId] == nil or definitions[schema.targetMachineId] == nil then
		return false, "invalid dependency machine reference"
	end
	for _, existing in pairs(dependencies) do
		if
			existing.sourceMachineId == schema.targetMachineId
			and existing.targetMachineId == schema.sourceMachineId
		then
			return false, "direct machine dependency cycle"
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
	return registerMachineChild(
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
	if schema.machineId ~= nil and definitions[schema.machineId] == nil then
		return false, "invalid audit machine reference"
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
		states = states,
		transitions = transitions,
		guards = guards,
		inputs = inputs,
		outputs = outputs,
		groups = groups,
		dependencies = dependencies,
		outcomes = outcomes,
		audits = audits,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			definitions = countMap(definitions),
			states = countMap(states),
			transitions = countMap(transitions),
			guards = countMap(guards),
			inputs = countMap(inputs),
			outputs = countMap(outputs),
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
	table.clear(definitions)
	table.clear(states)
	table.clear(transitions)
	table.clear(guards)
	table.clear(inputs)
	table.clear(outputs)
	table.clear(groups)
	table.clear(dependencies)
	table.clear(outcomes)
	table.clear(audits)
	table.clear(schemaIds)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return State
