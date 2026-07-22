--!strict

local Types = require(script.Parent.CommandTypes)

local Validation = {}

local function fail(code: string, reason: string)
	return false, code, reason
end

local function validId(value: any): boolean
	return type(value) == "string" and value ~= "" and #value <= 160
end

local function validPayload(
	value: any,
	depth: number?,
	nodes: { count: number }?
): (boolean, string?)
	local currentDepth = depth or 0
	local currentNodes = nodes or { count = 0 }
	if currentDepth > Types.Limits.MaxPayloadDepth then
		return false, "payload depth exceeds limit"
	end
	local kind = type(value)
	if kind == "function" or kind == "thread" or kind == "userdata" then
		return false, "payload contains unsafe value"
	end
	if kind == "string" and #value > Types.Limits.MaxStringLength then
		return false, "payload string exceeds limit"
	end
	if kind ~= "table" then
		return true, nil
	end
	currentNodes.count += 1
	if currentNodes.count > Types.Limits.MaxPayloadNodes then
		return false, "payload node count exceeds limit"
	end
	for key, item in pairs(value) do
		local keyOk, keyReason = validPayload(key, currentDepth + 1, currentNodes)
		if not keyOk then
			return false, keyReason
		end
		local valueOk, valueReason = validPayload(item, currentDepth + 1, currentNodes)
		if not valueOk then
			return false, valueReason
		end
	end
	return true, nil
end

function Validation.isValidPriority(value: any): boolean
	return Types.PriorityRank[value] ~= nil
end

function Validation.commandDefinition(definition: any): (boolean, string, string?)
	if type(definition) ~= "table" then
		return fail(Types.FailureType.ValidationFailure, "command definition must be a table")
	end
	if not validId(definition.commandType) then
		return fail(Types.FailureType.ValidationFailure, "commandType is required")
	end
	if not validId(definition.schemaVersion) then
		return fail(Types.FailureType.ValidationFailure, "schemaVersion is required")
	end
	if not validId(definition.ownerRuntime) then
		return fail(Types.FailureType.AmbiguousOwner, "ownerRuntime is required")
	end
	if not Validation.isValidPriority(definition.defaultPriority) then
		return fail(Types.FailureType.InvalidPriority, "defaultPriority is invalid")
	end
	if definition.executionPolicy ~= Types.ExecutionPolicy.AuthoritativeSingleOwner then
		return fail(
			Types.FailureType.AmbiguousOwner,
			"commands require exactly one authoritative owner"
		)
	end
	if type(definition.payloadValidator) ~= "function" then
		return fail(Types.FailureType.ValidationFailure, "payloadValidator is required")
	end
	if type(definition.allowedRequesters) ~= "table" or #definition.allowedRequesters == 0 then
		return fail(Types.FailureType.ValidationFailure, "allowedRequesters is required")
	end
	return true, "Ok", nil
end

function Validation.requester(requester: any): (boolean, string, string?)
	if type(requester) ~= "table" then
		return fail(Types.FailureType.ValidationFailure, "requester must be a table")
	end
	if not validId(requester.requesterId) or not validId(requester.runtimeId) then
		return fail(Types.FailureType.ValidationFailure, "requester identity is required")
	end
	if requester.authorityPolicy == "ClientAuthority" then
		return fail(Types.FailureType.RequesterNotAuthorized, "client authority is forbidden")
	end
	if type(requester.allowedCommandTypes) ~= "table" or #requester.allowedCommandTypes == 0 then
		return fail(Types.FailureType.ValidationFailure, "allowedCommandTypes is required")
	end
	return true, "Ok", nil
end

function Validation.handler(
	handler: any,
	hasCommandType: (string) -> boolean
): (boolean, string, string?)
	if type(handler) ~= "table" then
		return fail(Types.FailureType.ValidationFailure, "handler must be a table")
	end
	if not validId(handler.handlerId) or not validId(handler.runtimeId) then
		return fail(Types.FailureType.ValidationFailure, "handler identity is required")
	end
	if not validId(handler.commandType) or not hasCommandType(handler.commandType) then
		return fail(Types.FailureType.UnknownCommandType, "unknown command type")
	end
	if type(handler.execute) ~= "function" then
		return fail(Types.FailureType.ValidationFailure, "execute handler is required")
	end
	return true, "Ok", nil
end

function Validation.payload(value: any): (boolean, string?)
	return validPayload(value)
end

return Validation
