--!strict

local Evidence = require(script.Parent.WorkflowEvidence)
local Serialization = require(script.Parent.WorkflowSerialization)
local Types = require(script.Parent.WorkflowTypes)
local Validation = require(script.Parent.WorkflowValidation)

local Registry = {}
local definitions: { [string]: any } = {}
local order = {}

function Registry.register(definition: any)
	if #order >= Types.Limits.MaxWorkflowDefinitions then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "workflow definition limit exceeded",
		}
	end
	local ok, reason = Validation.definition(definition)
	if not ok then
		return { ok = false, code = Types.FailureType.ValidationFailure, message = reason }
	end
	if definitions[definition.workflowId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateWorkflow,
			message = "duplicate workflow id",
		}
	end
	definitions[definition.workflowId] = Validation.copy(definition)
	table.insert(order, definition.workflowId)
	table.sort(order)
	Evidence.record("workflow registered", { workflowId = definition.workflowId })
	return { ok = true, code = "Ok", workflowId = definition.workflowId }
end

function Registry.get(workflowId: string): any?
	local definition = definitions[workflowId]
	return if definition ~= nil then Serialization.deepCopy(definition) else nil
end

function Registry.has(workflowId: string): boolean
	return definitions[workflowId] ~= nil
end

function Registry.inspect()
	local result = {}
	for _, workflowId in ipairs(order) do
		result[workflowId] = Serialization.deepCopy(definitions[workflowId])
	end
	return result
end

function Registry.count(): number
	return #order
end

function Registry.clear()
	table.clear(definitions)
	table.clear(order)
end

return Registry
