--!strict

local Evidence = require(script.Parent.EventEvidence)
local Serialization = require(script.Parent.EventSerialization)

local Router = {}

function Router.route(envelope: any, definition: any, subscriptions: { any })
	local matched = {}
	local filtered = 0
	for _, subscription in ipairs(subscriptions) do
		local priorityFilter = subscription.priorityFilter
		if priorityFilter ~= nil and priorityFilter ~= envelope.priority then
			filtered += 1
		else
			table.insert(matched, {
				subscriptionId = subscription.subscriptionId,
				subscriberId = subscription.subscriberId,
				runtimeId = subscription.runtimeId,
				handler = subscription.handler,
				failurePolicy = subscription.failurePolicy or "ContinueAfterSubscriberFailure",
			})
		end
	end
	table.sort(matched, function(left, right)
		if left.runtimeId == right.runtimeId then
			return left.subscriptionId < right.subscriptionId
		end
		return left.runtimeId < right.runtimeId
	end)
	local plan = {
		eventId = envelope.eventId,
		eventType = envelope.eventType,
		deliveryPolicy = definition.deliveryPolicy,
		noSubscriberPolicy = definition.noSubscriberPolicy or "AllowNoSubscribers",
		subscriberIds = {},
		deliveries = matched,
		routeCount = #matched,
		filteredCount = filtered,
		missingRoute = #matched == 0,
	}
	for _, delivery in ipairs(matched) do
		table.insert(plan.subscriberIds, delivery.subscriberId)
	end
	Evidence.record("event routed", {
		eventId = envelope.eventId,
		eventType = envelope.eventType,
		routeCount = plan.routeCount,
	})
	return Serialization.deepCopy(plan)
end

return Router
