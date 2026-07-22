--!strict

local Evidence = require(script.Parent.DialogueEvidence)
local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueTypes)
local Validation = require(script.Parent.DialogueValidation)

local Registry = {}
local definitions = {}
local order = {}

function Registry.register(definition: any)
	if #order >= Types.Limits.MaxDialogueDefinitions then
		return {
			ok = false,
			code = Types.FailureType.LimitExceeded,
			message = "dialogue definition limit exceeded",
		}
	end
	local validation = Validation.validateDialogueDefinition(definition)
	if not validation.ok then
		return validation
	end
	if definitions[definition.dialogueId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateDialogue,
			message = "duplicate dialogue",
		}
	end
	definitions[definition.dialogueId] = validation.definition
	order[#order + 1] = definition.dialogueId
	Evidence.record("dialogue definition registered", { dialogueId = definition.dialogueId })
	return { ok = true, code = "Ok", dialogueId = definition.dialogueId }
end

function Registry.get(dialogueId: string): any?
	local definition = definitions[dialogueId]
	if definition == nil then
		return nil
	end
	return Serialization.deepCopy(definition)
end

function Registry.inspect()
	local items = {}
	for index, dialogueId in ipairs(order) do
		local definition = definitions[dialogueId]
		items[index] = {
			dialogueId = dialogueId,
			version = definition.version,
			entryNodeId = definition.entryNodeId,
			participantCount = #definition.participants,
			nodeCount = #definition.nodes,
			variableCount = #definition.variables,
			conditionCount = #definition.conditions,
		}
	end
	return items
end

function Registry.count(): number
	return #order
end

function Registry.clear()
	table.clear(definitions)
	table.clear(order)
end

return Registry
