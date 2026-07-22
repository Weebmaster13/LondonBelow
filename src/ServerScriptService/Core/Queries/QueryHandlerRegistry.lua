--!strict

local Evidence = require(script.Parent.QueryEvidence)
local Serialization = require(script.Parent.QuerySerialization)
local Types = require(script.Parent.QueryTypes)
local Validation = require(script.Parent.QueryValidation)

local Registry = {}
local handlers: { [string]: any } = {}

function Registry.register(handler: any, hasQueryType: (string) -> boolean)
	if #Serialization.sortedKeys(handlers) >= Types.Limits.MaxHandlers then
		return { ok = false, code = "LimitExceeded", message = "handler limit reached" }
	end
	local ok, code, reason = Validation.handler(handler, hasQueryType)
	if not ok then
		return { ok = false, code = code, message = reason }
	end
	if handlers[handler.queryType] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateHandler,
			message = "duplicate handler",
		}
	end
	handlers[handler.queryType] = Serialization.deepCopy(handler)
	Evidence.record("query handler registered", { queryType = handler.queryType })
	return { ok = true, code = "Ok" }
end

function Registry.resolve(queryType: string): any?
	local handler = handlers[queryType]
	return if handler == nil then nil else Serialization.deepCopy(handler)
end

function Registry.inspect()
	return Serialization.deepCopy(handlers)
end

function Registry.clear()
	table.clear(handlers)
end

return Registry
