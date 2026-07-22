--!strict

local Evidence = require(script.Parent.EventEvidence)
local Serialization = require(script.Parent.EventSerialization)
local Types = require(script.Parent.EventTypes)
local Validation = require(script.Parent.EventValidation)

local Registry = {}
local subscriptions: { [string]: any } = {}
local byEventType: { [string]: { string } } = {}

local function removeFromIndexes(subscriptionId: string)
	for eventType, ids in pairs(byEventType) do
		for index = #ids, 1, -1 do
			if ids[index] == subscriptionId then
				table.remove(ids, index)
			end
		end
		if #ids == 0 then
			byEventType[eventType] = nil
		end
	end
end

function Registry.subscribe(subscription: any, hasEventType: (string) -> boolean)
	if #Serialization.sortedKeys(subscriptions) >= Types.Limits.MaxSubscribers then
		return { ok = false, code = "LimitExceeded", message = "subscription limit reached" }
	end
	local ok, code, reason = Validation.subscription(subscription, hasEventType)
	if not ok then
		return { ok = false, code = code, message = reason }
	end
	if subscriptions[subscription.subscriptionId] ~= nil then
		return { ok = false, code = "DuplicateSubscription", message = "duplicate subscription" }
	end
	local record = Serialization.deepCopy(subscription)
	subscriptions[subscription.subscriptionId] = record
	for _, eventType in ipairs(record.eventTypes) do
		byEventType[eventType] = byEventType[eventType] or {}
		table.insert(byEventType[eventType], record.subscriptionId)
		table.sort(byEventType[eventType])
	end
	Evidence.record("subscriber registered", { subscriptionId = record.subscriptionId })
	return { ok = true, code = "Ok", subscription = Serialization.deepCopy(record) }
end

function Registry.unsubscribe(subscriptionId: string)
	if subscriptions[subscriptionId] == nil then
		return { ok = false, code = "UnknownSubscription", message = "unknown subscription" }
	end
	subscriptions[subscriptionId] = nil
	removeFromIndexes(subscriptionId)
	Evidence.record("subscriber removed", { subscriptionId = subscriptionId })
	return { ok = true, code = "Ok" }
end

function Registry.get(subscriptionId: string): any?
	local subscription = subscriptions[subscriptionId]
	return if subscription == nil then nil else Serialization.deepCopy(subscription)
end

function Registry.listSubscribersForEvent(eventType: string): { any }
	local ids = byEventType[eventType] or {}
	local output = {}
	for _, subscriptionId in ipairs(ids) do
		local subscription = subscriptions[subscriptionId]
		if subscription ~= nil then
			table.insert(output, Serialization.deepCopy(subscription))
		end
	end
	return table.freeze(output)
end

function Registry.has(subscriptionId: string): boolean
	return subscriptions[subscriptionId] ~= nil
end

function Registry.inspect()
	local output = {}
	for _, subscriptionId in ipairs(Serialization.sortedKeys(subscriptions)) do
		output[subscriptionId] = Serialization.deepCopy(subscriptions[subscriptionId])
	end
	return table.freeze(output)
end

function Registry.clear()
	table.clear(subscriptions)
	table.clear(byEventType)
end

return Registry
