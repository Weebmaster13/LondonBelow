--!strict

local Evidence = require(script.Parent.QueryEvidence)
local Serialization = require(script.Parent.QuerySerialization)
local Types = require(script.Parent.QueryTypes)
local Validation = require(script.Parent.QueryValidation)

local Registry = {}
local definitions: { [string]: any } = {}

function Registry.register(definition: any)
	if #Serialization.sortedKeys(definitions) >= Types.Limits.MaxQueryTypes then
		return { ok = false, code = "LimitExceeded", message = "query type limit reached" }
	end
	local ok, code, reason = Validation.definition(definition)
	if not ok then
		return { ok = false, code = code, message = reason }
	end
	if definitions[definition.queryType] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateQueryType,
			message = "duplicate query type",
		}
	end
	definitions[definition.queryType] = Serialization.deepCopy(definition)
	Evidence.record("query type registered", { queryType = definition.queryType })
	return { ok = true, code = "Ok", definition = Serialization.deepCopy(definition) }
end

function Registry.get(queryType: string): any?
	local definition = definitions[queryType]
	return if definition == nil then nil else Serialization.deepCopy(definition)
end

function Registry.has(queryType: string): boolean
	return definitions[queryType] ~= nil
end

function Registry.inspect()
	local output = {}
	for _, queryType in ipairs(Serialization.sortedKeys(definitions)) do
		output[queryType] = Serialization.deepCopy(definitions[queryType])
	end
	return table.freeze(output)
end

function Registry.clear()
	table.clear(definitions)
end

return Registry
