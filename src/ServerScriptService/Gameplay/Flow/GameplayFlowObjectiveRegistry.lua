--!strict

local Serialization = require(script.Parent.GameplayFlowSerialization)
local Types = require(script.Parent.GameplayFlowTypes)
local Validation = require(script.Parent.GameplayFlowValidation)

local Registry = {}

local objectivesById: { [string]: any } = {}
local objectiveOrder: { string } = {}
local validationFailures: { any } = {}

local function rememberFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.deepCopy(payload),
	})
	if #validationFailures > Types.Limits.MaxValidationFailures then
		table.remove(validationFailures, 1)
	end
end

function Registry.registerAll(objectives: { any }): (boolean, string?)
	local ok, reason = Validation.graph(objectives)
	if not ok then
		rememberFailure(reason or "invalid objective graph", objectives)
		return false, reason
	end
	for _, objective in ipairs(objectives) do
		if objectivesById[objective.objectiveId] ~= nil then
			rememberFailure("duplicate objective", objective)
			return false, "duplicate objective"
		end
	end
	for _, objective in ipairs(objectives) do
		objectivesById[objective.objectiveId] = Serialization.freezeCopy(objective)
		table.insert(objectiveOrder, objective.objectiveId)
	end
	table.sort(objectiveOrder, function(left, right)
		local leftObjective = objectivesById[left]
		local rightObjective = objectivesById[right]
		if leftObjective.priority == rightObjective.priority then
			return left < right
		end
		return leftObjective.priority < rightObjective.priority
	end)
	return true, nil
end

function Registry.get(objectiveId: string): any?
	local objective = objectivesById[objectiveId]
	return if objective == nil then nil else Serialization.deepCopy(objective)
end

function Registry.getFrozen(objectiveId: string): any?
	return objectivesById[objectiveId]
end

function Registry.order(): { string }
	return table.clone(objectiveOrder)
end

function Registry.count(): number
	return #objectiveOrder
end

function Registry.exists(objectiveId: string): boolean
	return objectivesById[objectiveId] ~= nil
end

function Registry.validate(): (boolean, string?)
	local objectives = {}
	for _, objectiveId in ipairs(objectiveOrder) do
		table.insert(objectives, objectivesById[objectiveId])
	end
	return Validation.graph(objectives)
end

function Registry.inspect()
	return {
		objectiveCount = #objectiveOrder,
		objectiveIds = table.clone(objectiveOrder),
		validationFailureCount = #validationFailures,
		validationFailures = Serialization.deepCopy(validationFailures),
	}
end

function Registry.clear()
	table.clear(objectivesById)
	table.clear(objectiveOrder)
	table.clear(validationFailures)
end

return Registry
