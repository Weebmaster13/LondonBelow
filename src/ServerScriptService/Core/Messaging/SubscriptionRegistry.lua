--!strict

local ConsumerRegistry = require(script.Parent.ConsumerRegistry)
local Evidence = require(script.Parent.MessagingEvidence)
local Serialization = require(script.Parent.MessagingSerialization)
local Types = require(script.Parent.MessagingTypes)
local Validation = require(script.Parent.MessagingValidation)

local Registry = {}
local subscriptions: { [string]: any } = {}
local order = {}
local sequence = 0

local function compare(leftId: string, rightId: string): boolean
	local left = subscriptions[leftId]
	local right = subscriptions[rightId]
	if left.eventType ~= right.eventType then
		return left.eventType < right.eventType
	end
	if left.priority ~= right.priority then
		return left.priority > right.priority
	end
	if left.version ~= right.version then
		return left.version < right.version
	end
	return left.registrationOrder < right.registrationOrder
end

function Registry.register(subscription: any)
	if #order >= Types.Limits.MaxSubscriptions then
		return {
			ok = false,
			code = Types.FailureType.ValidationFailure,
			message = "subscription limit exceeded",
		}
	end
	local ok, reason = Validation.subscription(subscription)
	if not ok then
		return { ok = false, code = Types.FailureType.ValidationFailure, message = reason }
	end
	if subscriptions[subscription.subscriptionId] ~= nil then
		return {
			ok = false,
			code = Types.FailureType.DuplicateSubscription,
			message = "duplicate subscription",
		}
	end
	if not ConsumerRegistry.has(subscription.consumerId) then
		return { ok = false, code = Types.FailureType.UnknownConsumer, message = "unknown consumer" }
	end
	sequence += 1
	local stored = Serialization.deepCopy(subscription)
	stored.registrationOrder = sequence
	subscriptions[subscription.subscriptionId] = stored
	table.insert(order, subscription.subscriptionId)
	table.sort(order, compare)
	Evidence.record("subscription registered", {
		subscriptionId = subscription.subscriptionId,
		consumerId = subscription.consumerId,
		eventType = subscription.eventType,
	})
	return { ok = true, code = "Ok", subscriptionId = subscription.subscriptionId }
end

function Registry.resolve(eventType: string)
	local resolved = {}
	for _, subscriptionId in ipairs(order) do
		local subscription = subscriptions[subscriptionId]
		if subscription.eventType == eventType then
			table.insert(resolved, Serialization.deepCopy(subscription))
		end
	end
	return resolved
end

function Registry.inspect()
	local result = {}
	for _, subscriptionId in ipairs(order) do
		result[subscriptionId] = Serialization.deepCopy(subscriptions[subscriptionId])
	end
	return result
end

function Registry.count(): number
	return #order
end

function Registry.clear()
	table.clear(subscriptions)
	table.clear(order)
	sequence = 0
end

return Registry
