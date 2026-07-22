--!strict
-- Compatibility facade over the typed Runtime Event Bus foundation.

local Runtime = require(script.Parent.Events.RuntimeEventBus)

local EventBus = {}

function EventBus.subscribe(eventName: string, callback: (any, ...any) -> (), priority: number?)
	local listenerId, disconnect = Runtime.legacySubscribe(eventName, callback, priority, false)
	return function()
		EventBus.unsubscribe(listenerId)
		disconnect()
	end
end

function EventBus.subscribeOnce(eventName: string, callback: (any, ...any) -> (), priority: number?)
	local listenerId, disconnect = Runtime.legacySubscribe(eventName, callback, priority, true)
	return function()
		EventBus.unsubscribe(listenerId)
		disconnect()
	end
end

function EventBus.unsubscribe(listenerIdOrDisconnect: any): boolean
	if type(listenerIdOrDisconnect) == "function" then
		listenerIdOrDisconnect()
		return true
	end
	return false
end

function EventBus.publishSync(eventName: string, payload: any?, ...: any)
	local _args = { ... }
	return Runtime.legacyPublish(eventName, payload or {})
end

function EventBus.publishAsync(eventName: string, payload: any?, ...: any)
	local args = { ... }
	task.spawn(function()
		EventBus.publishSync(eventName, payload, table.unpack(args))
	end)
end

function EventBus.publishDeferred(eventName: string, payload: any?, ...: any)
	local args = { ... }
	task.defer(function()
		EventBus.publishSync(eventName, payload, table.unpack(args))
	end)
end

function EventBus.listenerCount(_eventName: string?): number
	return Runtime.getCounters().subscribers
end

function EventBus.inspect()
	return Runtime.inspect()
end

function EventBus.cleanup() end

function EventBus.clear(_eventName: string?)
	Runtime.reset()
end

function EventBus.validate(): (boolean, string?)
	return Runtime.validate()
end

EventBus.publish = EventBus.publishSync

return EventBus
