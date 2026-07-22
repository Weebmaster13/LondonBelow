--!strict

local Evidence = require(script.Parent.EventEvidence)
local Serialization = require(script.Parent.EventSerialization)
local Types = require(script.Parent.EventTypes)

local Dispatcher = {}
local history: { any } = {}
local deliveredPairs: { [string]: boolean } = {}
local dispatchSequence = 0

local function trim()
	while #history > Types.Limits.MaxDispatchHistory do
		table.remove(history, 1)
	end
end

function Dispatcher.dispatch(envelope: any, plan: any)
	dispatchSequence += 1
	Evidence.record(
		"dispatch started",
		{ eventId = envelope.eventId, routeCount = plan.routeCount }
	)
	if
		plan.missingRoute
		and plan.noSubscriberPolicy == Types.NoSubscriberPolicy.RequireSubscriber
	then
		local failed = {
			ok = false,
			code = Types.FailureType.NoSubscribers,
			eventId = envelope.eventId,
			eventType = envelope.eventType,
			status = Types.Status.Failed,
			deliveredCount = 0,
			failedDeliveries = 0,
			failureReason = "event requires at least one subscriber",
		}
		table.insert(history, Serialization.deepCopy(failed))
		trim()
		return failed
	end
	local deliveredCount = 0
	local failedDeliveries = 0
	local failures = {}
	for index, delivery in ipairs(plan.deliveries) do
		local pair = envelope.eventId .. ":" .. delivery.subscriptionId
		if deliveredPairs[pair] then
			failedDeliveries += 1
			table.insert(failures, "duplicate delivery rejected: " .. delivery.subscriptionId)
		else
			deliveredPairs[pair] = true
			local ok, response = pcall(delivery.handler, Serialization.deepCopy(envelope), {
				subscriptionId = delivery.subscriptionId,
				subscriberId = delivery.subscriberId,
				deliveryAttempt = 1,
				dispatchSequence = dispatchSequence,
			})
			if ok and (response == nil or response.success ~= false) then
				deliveredCount += 1
				Evidence.record("delivery succeeded", {
					eventId = envelope.eventId,
					subscriptionId = delivery.subscriptionId,
					index = index,
				})
			else
				failedDeliveries += 1
				local reason = if ok
					then tostring(response.failureReason or "malformed subscriber result")
					else tostring(response)
				table.insert(failures, reason)
				Evidence.record("delivery failed", {
					eventId = envelope.eventId,
					subscriptionId = delivery.subscriptionId,
					reason = reason,
				})
				if delivery.failurePolicy == Types.FailurePolicy.FailFast then
					break
				end
			end
		end
	end
	local status = if failedDeliveries > 0 then Types.Status.Failed else Types.Status.Delivered
	local result = {
		ok = failedDeliveries == 0,
		code = if failedDeliveries == 0 then "Ok" else Types.FailureType.SubscriberFailure,
		eventId = envelope.eventId,
		eventType = envelope.eventType,
		status = status,
		deliveredCount = deliveredCount,
		failedDeliveries = failedDeliveries,
		failures = failures,
	}
	table.insert(history, Serialization.deepCopy(result))
	trim()
	Evidence.record(if result.ok then "event delivered" else "event failed", {
		eventId = envelope.eventId,
		deliveredCount = deliveredCount,
		failedDeliveries = failedDeliveries,
	})
	return Serialization.deepCopy(result)
end

function Dispatcher.inspect()
	return {
		dispatchSequence = dispatchSequence,
		history = Serialization.copyArray(history),
	}
end

function Dispatcher.clear()
	table.clear(history)
	table.clear(deliveredPairs)
	dispatchSequence = 0
end

return Dispatcher
