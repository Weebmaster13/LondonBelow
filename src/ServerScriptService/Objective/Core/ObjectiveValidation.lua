--!strict
-- Validation boundary for server-owned objective schemas.

local Serialization = require(script.Parent.ObjectiveSerialization)
local Types = require(script.Parent.ObjectiveTypes)

local Validation = {}

local FORBIDDEN_FIELDS = {
	"audio",
	"camera",
	"chapter",
	"chapter0",
	"chapter1",
	"client",
	"completeObjective",
	"completionExecution",
	"cutscene",
	"dialogue",
	"execute",
	"gameplayExecution",
	"horrorPacing",
	"instance",
	"interactionExecution",
	"inventoryExecution",
	"lighting",
	"monsterAI",
	"narrative",
	"objectiveCompletionExecution",
	"puzzleExecution",
	"questExecution",
	"remote",
	"save",
	"savePersistence",
	"story",
	"ui",
	"workspace",
}

local FORBIDDEN_LOOKUP: { [string]: boolean } = {}

for _, field in ipairs(FORBIDDEN_FIELDS) do
	FORBIDDEN_LOOKUP[string.lower(field)] = true
end

local function validId(value: any): boolean
	return type(value) == "string"
		and value ~= ""
		and #value <= 150
		and string.match(value, "^[%w%._%-:]+$") ~= nil
end

local function supportedSchemaType(value: any): boolean
	for _, schemaType in pairs(Types.SchemaType) do
		if value == schemaType then
			return true
		end
	end
	return false
end

local function forbidden(payload: any, depth: number): (boolean, string?)
	if type(payload) ~= "table" then
		return true, nil
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return false, "objective payload depth exceeds limit"
	end
	for key in pairs(payload) do
		if type(key) == "string" and FORBIDDEN_LOOKUP[string.lower(key)] == true then
			return false, "objective payload contains forbidden field: " .. key
		end
	end
	for _, nested in pairs(payload) do
		local ok, reason = forbidden(nested, depth + 1)
		if not ok then
			return false, reason
		end
	end
	return true, nil
end

local function validateTags(tags: any): (boolean, string?)
	if tags == nil then
		return true, nil
	end
	if type(tags) ~= "table" then
		return false, "tags must be a table"
	end
	if #tags > Types.Limits.MaxTags then
		return false, "tag count exceeds limit"
	end
	for _, tag in ipairs(tags) do
		if not validId(tag) then
			return false, "tag is invalid"
		end
		if FORBIDDEN_LOOKUP[string.lower(tag)] == true then
			return false, "tag uses forbidden ownership domain: " .. tag
		end
	end
	return true, nil
end

local function validateList(
	list: any,
	idField: string,
	limit: number,
	malformedReason: string,
	duplicateReason: string
): (boolean, string?)
	if type(list) ~= "table" then
		return false, malformedReason
	end
	if #list > limit then
		return false, malformedReason .. " count exceeds limit"
	end
	local seen: { [string]: boolean } = {}
	for _, entry in ipairs(list) do
		if type(entry) ~= "table" or not validId(entry[idField]) then
			return false, malformedReason
		end
		if entry.schemaType ~= nil and not supportedSchemaType(entry.schemaType) then
			return false, "unsupported objective schema type"
		end
		if seen[entry[idField]] == true then
			return false, duplicateReason
		end
		seen[entry[idField]] = true
	end
	return Validation.safePayload(list)
end

function Validation.safePayload(payload: any): (boolean, string?)
	local ok, reason = Serialization.validateSerializable(payload)
	if not ok then
		return false, reason
	end
	return forbidden(payload, 0)
end

function Validation.id(value: any): boolean
	return validId(value)
end

function Validation.tasks(tasks: any): (boolean, string?)
	return validateList(
		tasks,
		"taskId",
		Types.Limits.MaxTasksPerObjective,
		"malformed tasks",
		"duplicate taskId"
	)
end

function Validation.requirements(requirements: any): (boolean, string?)
	return validateList(
		requirements,
		"requirementId",
		Types.Limits.MaxRequirementsPerObjective,
		"malformed requirements",
		"duplicate requirementId"
	)
end

function Validation.dependencies(dependencies: any): (boolean, string?)
	return validateList(
		dependencies,
		"dependencyId",
		Types.Limits.MaxDependenciesPerObjective,
		"malformed dependencies",
		"duplicate dependencyId"
	)
end

function Validation.state(state: any): (boolean, string?)
	if type(state) ~= "table" then
		return false, "malformed objective state"
	end
	if state.stateId ~= nil and not validId(state.stateId) then
		return false, "malformed objective state"
	end
	if state.schemaType ~= nil and not supportedSchemaType(state.schemaType) then
		return false, "unsupported objective state schema type"
	end
	return Validation.safePayload(state)
end

function Validation.objective(schema: any): (boolean, string?)
	if type(schema) ~= "table" then
		return false, "objective schema must be a table"
	end
	local safe, reason = Validation.safePayload(schema)
	if not safe then
		return false, reason
	end
	if not validId(schema.objectiveId) or not validId(schema.ownerSystem) then
		return false, "objective identity fields are invalid"
	end
	if not supportedSchemaType(schema.objectiveType) then
		return false, "unsupported objective type"
	end
	local tasksOk, tasksReason = Validation.tasks(schema.tasks)
	if not tasksOk then
		return false, tasksReason
	end
	local reqOk, reqReason = Validation.requirements(schema.requirements)
	if not reqOk then
		return false, reqReason
	end
	local depOk, depReason = Validation.dependencies(schema.dependencies)
	if not depOk then
		return false, depReason
	end
	local stateOk, stateReason = Validation.state(schema.state)
	if not stateOk then
		return false, stateReason
	end
	local tagsOk, tagsReason = validateTags(schema.tags)
	if not tagsOk then
		return false, tagsReason
	end
	return true, nil
end

function Validation.progress(record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "malformed progress record"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not validId(record.progressId) or not validId(record.objectiveId) then
		return false, "malformed progress record"
	end
	if record.schemaType ~= nil and not supportedSchemaType(record.schemaType) then
		return false, "unsupported progress schema type"
	end
	return true, nil
end

function Validation.validate(): (boolean, string?)
	if Types.Mode ~= "ServerAuthoritativeObjectiveSchemaRuntime" then
		return false, "Objective Runtime must remain server-authoritative schema runtime"
	end
	return true, nil
end

return Validation
