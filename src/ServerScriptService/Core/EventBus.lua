local Logger = require(script.Parent.Logger)

local EventBus = {}

local log = Logger.scope("EventBus")
local listeners = {}

function EventBus.subscribe(eventName, callback)
	assert(type(eventName) == "string", "eventName must be a string")
	assert(type(callback) == "function", "callback must be a function")

	local eventListeners = listeners[eventName]

	if eventListeners == nil then
		eventListeners = {}
		listeners[eventName] = eventListeners
	end

	table.insert(eventListeners, callback)

	return function()
		for index, listener in ipairs(eventListeners) do
			if listener == callback then
				table.remove(eventListeners, index)
				break
			end
		end
	end
end

function EventBus.publish(eventName, ...)
	assert(type(eventName) == "string", "eventName must be a string")

	local eventListeners = listeners[eventName]

	if eventListeners == nil then
		return
	end

	for _, callback in ipairs(table.clone(eventListeners)) do
		local ok, err = pcall(callback, ...)

		if not ok then
			log.warn("Listener for %s failed: %s", eventName, tostring(err))
		end
	end
end

function EventBus.clear(eventName)
	if eventName == nil then
		table.clear(listeners)
		return
	end

	listeners[eventName] = nil
end

return EventBus
