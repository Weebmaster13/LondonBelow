--!strict

local Types = require(script.Parent.QueryTypes)

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

function Validation.isValidConsistency(value: any): boolean
	return Types.Consistency[value] == value
end

function Validation.definition(definition: any): (boolean, string, string?)
	if type(definition) ~= "table" then
		return fail(Types.FailureType.ValidationFailure, "query definition must be a table")
	end
	if not validId(definition.queryType) or not validId(definition.namespace) then
		return fail(Types.FailureType.ValidationFailure, "query type and namespace are required")
	end
	if not validId(definition.schemaVersion) or not validId(definition.ownerRuntime) then
		return fail(Types.FailureType.AmbiguousOwner, "schemaVersion and ownerRuntime are required")
	end
	if not Validation.isValidPriority(definition.defaultPriority) then
		return fail(Types.FailureType.InvalidPriority, "defaultPriority is invalid")
	end
	if not Validation.isValidConsistency(definition.consistency) then
		return fail(Types.FailureType.InvalidConsistency, "consistency is invalid")
	end
	if
		type(definition.payloadValidator) ~= "function"
		or type(definition.responseValidator) ~= "function"
	then
		return fail(
			Types.FailureType.ValidationFailure,
			"payload and response validators are required"
		)
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
	if type(requester.allowedQueryTypes) ~= "table" or #requester.allowedQueryTypes == 0 then
		return fail(Types.FailureType.ValidationFailure, "allowedQueryTypes is required")
	end
	return true, "Ok", nil
end

function Validation.handler(
	handler: any,
	hasQueryType: (string) -> boolean
): (boolean, string, string?)
	if type(handler) ~= "table" then
		return fail(Types.FailureType.ValidationFailure, "handler must be a table")
	end
	if not validId(handler.handlerId) or not validId(handler.runtimeId) then
		return fail(Types.FailureType.ValidationFailure, "handler identity is required")
	end
	if not validId(handler.queryType) or not hasQueryType(handler.queryType) then
		return fail(Types.FailureType.UnknownQueryType, "unknown query type")
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
