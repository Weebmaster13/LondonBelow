--!strict
-- Central bounded state store for Objective Runtime Foundation.

local Serialization = require(script.Parent.ObjectiveSerialization)
local Types = require(script.Parent.ObjectiveTypes)
local Validation = require(script.Parent.ObjectiveValidation)

local Runtime = {}

local objectives: { [string]: any } = {}
local objectiveOrder: { string } = {}
local tasks: { [string]: any } = {}
local requirements: { [string]: any } = {}
local dependencies: { [string]: any } = {}
local states: { [string]: any } = {}
local progressRecords: { [string]: any } = {}
local progressOrder: { string } = {}
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

function Runtime.hasObjective(objectiveId: string): boolean
	return objectives[objectiveId] ~= nil
end

function Runtime.register(schema: any): (boolean, string?)
	local ok, reason = Validation.objective(schema)
	if not ok then
		return false, reason
	end
	if Runtime.hasObjective(schema.objectiveId) then
		return false, "duplicate objectiveId"
	end
	if countMap(objectives) >= Types.Limits.MaxObjectives then
		return false, "objective limit exceeded"
	end
	if countMap(tasks) + #schema.tasks > Types.Limits.MaxTasks then
		return false, "task limit exceeded"
	end
	if countMap(requirements) + #schema.requirements > Types.Limits.MaxRequirements then
		return false, "requirement limit exceeded"
	end
	if countMap(dependencies) + #schema.dependencies > Types.Limits.MaxDependencies then
		return false, "dependency limit exceeded"
	end

	local copy = Serialization.deepCopy(schema)
	objectives[copy.objectiveId] = copy
	boundedInsert(objectiveOrder, copy.objectiveId, Types.Limits.MaxObjectives)
	states[copy.objectiveId] = Serialization.deepCopy(copy.state)
	for _, task in ipairs(copy.tasks) do
		tasks[copy.objectiveId .. ":" .. task.taskId] = Serialization.deepCopy(task)
	end
	for _, requirement in ipairs(copy.requirements) do
		requirements[copy.objectiveId .. ":" .. requirement.requirementId] =
			Serialization.deepCopy(requirement)
	end
	for _, dependency in ipairs(copy.dependencies) do
		dependencies[copy.objectiveId .. ":" .. dependency.dependencyId] =
			Serialization.deepCopy(dependency)
	end
	return true, nil
end

function Runtime.recordProgress(record: any): (boolean, string?)
	local ok, reason = Validation.progress(record)
	if not ok then
		return false, reason
	end
	if not Runtime.hasObjective(record.objectiveId) then
		return false, "unknown objective progress"
	end
	if progressRecords[record.progressId] ~= nil then
		return false, "duplicate progressId"
	end
	if countMap(progressRecords) >= Types.Limits.MaxProgressRecords then
		return false, "progress record limit exceeded"
	end
	progressRecords[record.progressId] = Serialization.deepCopy(record)
	boundedInsert(progressOrder, record.progressId, Types.Limits.MaxProgressRecords)
	return true, nil
end

function Runtime.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function Runtime.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function Runtime.inspect()
	return Serialization.deepCopy({
		objectives = objectives,
		objectiveOrder = objectiveOrder,
		tasks = tasks,
		requirements = requirements,
		dependencies = dependencies,
		states = states,
		progressRecords = progressRecords,
		progressOrder = progressOrder,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			objectives = countMap(objectives),
			tasks = countMap(tasks),
			requirements = countMap(requirements),
			dependencies = countMap(dependencies),
			states = countMap(states),
			progressRecords = countMap(progressRecords),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function Runtime.clear()
	table.clear(objectives)
	table.clear(objectiveOrder)
	table.clear(tasks)
	table.clear(requirements)
	table.clear(dependencies)
	table.clear(states)
	table.clear(progressRecords)
	table.clear(progressOrder)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return Runtime
