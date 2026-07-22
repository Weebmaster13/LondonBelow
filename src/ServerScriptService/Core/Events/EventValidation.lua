--!strict

local Serialization = require(script.Parent.EventSerialization)
local Types = require(script.Parent.EventTypes)

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

function Validation.isValidDeliveryPolicy(value: any): boolean
	return Types.DeliveryPolicy[value] ~= nil
end

function Validation.isValidReplayPolicy(value: any): boolean
	return Types.ReplayPolicy[value] ~= nil
end

function Validation.eventDefinition(definition: any): (boolean, string, string?)
	if type(definition) ~= "table" then
		return fail(Types.FailureType.ValidationFailure, "event definition must be a table")
	end
	if not validId(definition.eventType) then
		return fail(Types.FailureType.ValidationFailure, "eventType is required")
	end
	if not validId(definition.schemaVersion) then
		return fail(Types.FailureType.ValidationFailure, "schemaVersion is required")
	end
	if not validId(definition.ownerRuntime) then
		return fail(Types.FailureType.ValidationFailure, "ownerRuntime is required")
	end
	if not Validation.isValidPriority(definition.defaultPriority) then
		return fail(Types.FailureType.InvalidPriority, "defaultPriority is invalid")
	end
	if not Validation.isValidDeliveryPolicy(definition.deliveryPolicy) then
		return fail(Types.FailureType.ValidationFailure, "deliveryPolicy is invalid")
	end
	if not Validation.isValidReplayPolicy(definition.replayPolicy) then
		return fail(Types.FailureType.InvalidReplayPolicy, "replayPolicy is invalid")
	end
	if type(definition.payloadValidator) ~= "function" then
		return fail(Types.FailureType.ValidationFailure, "payloadValidator is required")
	end
	if type(definition.allowedPublishers) ~= "table" or #definition.allowedPublishers == 0 then
		return fail(Types.FailureType.ValidationFailure, "allowedPublishers is required")
	end
	return true, "Ok", nil
end

function Validation.publisher(publisher: any): (boolean, string, string?)
	if type(publisher) ~= "table" then
		return fail(Types.FailureType.ValidationFailure, "publisher must be a table")
	end
	if not validId(publisher.publisherId) or not validId(publisher.runtimeId) then
		return fail(Types.FailureType.ValidationFailure, "publisherId and runtimeId are required")
	end
	if publisher.authorityPolicy == "ClientAuthority" then
		return fail(Types.FailureType.PublisherNotAuthorized, "client authority is forbidden")
	end
	if type(publisher.allowedEventTypes) ~= "table" or #publisher.allowedEventTypes == 0 then
		return fail(Types.FailureType.ValidationFailure, "allowedEventTypes is required")
	end
	return true, "Ok", nil
end

function Validation.subscription(
	subscription: any,
	hasEventType: (string) -> boolean
): (boolean, string, string?)
	if type(subscription) ~= "table" then
		return fail(Types.FailureType.ValidationFailure, "subscription must be a table")
	end
	if
		not validId(subscription.subscriptionId)
		or not validId(subscription.subscriberId)
		or not validId(subscription.runtimeId)
	then
		return fail(Types.FailureType.ValidationFailure, "subscription identity is required")
	end
	if subscription.authorityPolicy == "ClientAuthority" then
		return fail(
			Types.FailureType.ValidationFailure,
			"client subscription authority is forbidden"
		)
	end
	if type(subscription.eventTypes) ~= "table" or #subscription.eventTypes == 0 then
		return fail(Types.FailureType.ValidationFailure, "eventTypes is required")
	end
	for _, eventType in ipairs(subscription.eventTypes) do
		if not hasEventType(eventType) then
			return fail(
				Types.FailureType.UnknownEventType,
				"unknown event type: " .. tostring(eventType)
			)
		end
	end
	if type(subscription.handler) ~= "function" then
		return fail(Types.FailureType.ValidationFailure, "handler is required")
	end
	return true, "Ok", nil
end

function Validation.payload(value: any): (boolean, string?)
	return validPayload(value)
end

function Validation.freeze(value: any): any
	return Serialization.deepCopy(value)
end

return Validation
