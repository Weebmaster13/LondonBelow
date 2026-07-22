--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)
local Validation = require(script.Parent.CommandValidation)

local Registry = {}
local definitions: { [string]: any } = {}

function Registry.register(definition: any)
	if #Serialization.sortedKeys(definitions) >= Types.Limits.MaxCommandTypes then
		return { ok = false, code = "LimitExceeded", message = "command type limit reached" }
	end
	local ok, code, reason = Validation.commandDefinition(definition)
	if not ok then
		return { ok = false, code = code, message = reason }
	end
	if definitions[definition.commandType] ~= nil then
		return { ok = false, code = "DuplicateCommandType", message = "duplicate command type" }
	end
	definitions[definition.commandType] = Serialization.deepCopy(definition)
	Evidence.record("command type registered", { commandType = definition.commandType })
	return { ok = true, code = "Ok", definition = Serialization.deepCopy(definition) }
end

function Registry.get(commandType: string): any?
	local definition = definitions[commandType]
	return if definition == nil then nil else Serialization.deepCopy(definition)
end

function Registry.has(commandType: string): boolean
	return definitions[commandType] ~= nil
end

function Registry.inspect()
	local output = {}
	for _, commandType in ipairs(Serialization.sortedKeys(definitions)) do
		output[commandType] = Serialization.deepCopy(definitions[commandType])
	end
	return table.freeze(output)
end

function Registry.clear()
	table.clear(definitions)
end

return Registry
