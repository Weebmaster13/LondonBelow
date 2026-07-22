--!strict

local Evidence = require(script.Parent.CommandEvidence)
local Serialization = require(script.Parent.CommandSerialization)
local Types = require(script.Parent.CommandTypes)
local Validation = require(script.Parent.CommandValidation)

local Registry = {}
local handlersById: { [string]: any } = {}
local handlerByCommandType: { [string]: string } = {}

function Registry.register(handler: any, hasCommandType: (string) -> boolean)
	if #Serialization.sortedKeys(handlersById) >= Types.Limits.MaxHandlers then
		return { ok = false, code = "LimitExceeded", message = "handler limit reached" }
	end
	local ok, code, reason = Validation.handler(handler, hasCommandType)
	if not ok then
		return { ok = false, code = code, message = reason }
	end
	if handlersById[handler.handlerId] ~= nil then
		return { ok = false, code = "DuplicateHandler", message = "duplicate handler" }
	end
	if handlerByCommandType[handler.commandType] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.AmbiguousOwner,
			message = "command already has a handler",
		}
	end
	local record = Serialization.deepCopy(handler)
	handlersById[handler.handlerId] = record
	handlerByCommandType[handler.commandType] = handler.handlerId
	Evidence.record(
		"handler registered",
		{ handlerId = handler.handlerId, commandType = handler.commandType }
	)
	return { ok = true, code = "Ok", handler = Serialization.deepCopy(record) }
end

function Registry.resolve(commandType: string): any?
	local handlerId = handlerByCommandType[commandType]
	if handlerId == nil then
		return nil
	end
	local handler = handlersById[handlerId]
	return if handler == nil then nil else Serialization.deepCopy(handler)
end

function Registry.inspect()
	local output = {}
	for _, handlerId in ipairs(Serialization.sortedKeys(handlersById)) do
		output[handlerId] = Serialization.deepCopy(handlersById[handlerId])
	end
	return table.freeze(output)
end

function Registry.clear()
	table.clear(handlersById)
	table.clear(handlerByCommandType)
end

return Registry
