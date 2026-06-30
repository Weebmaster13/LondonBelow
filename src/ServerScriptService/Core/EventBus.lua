--!strict
--[[
	EventBus is the server-process messaging backbone for London Engine.

	It supports namespaced events, wildcard listeners, priority ordering,
	one-shot listeners, synchronous dispatch, asynchronous dispatch, deferred
	dispatch, cancellation, and debug inspection. It is not a networking layer.
]]

local Logger = require(script.Parent.Logger)

local EventBus = {}

export type EventPayload = { [string]: any }
export type Event = {
	name: string,
	namespace: string,
	payload: EventPayload?,
	cancelled: boolean,
	cancel: (self: Event) -> (),
}
export type Listener = {
	id: number,
	eventName: string,
	callback: (Event, ...any) -> (),
	priority: number,
	once: boolean,
	active: boolean,
}

local log = Logger.scope("EventBus")
local listenersByEvent: { [string]: { Listener } } = {}
local nextListenerId = 0
local publishedCount = 0
local cancelledCount = 0

local function namespaceOf(eventName: string): string
	local namespace = string.match(eventName, "^([^%.]+)%.")

	return namespace or eventName
end

local function makeEvent(eventName: string, payload: EventPayload?): Event
	local event = {
		name = eventName,
		namespace = namespaceOf(eventName),
		payload = payload,
		cancelled = false,
	} :: Event

	function event:cancel()
		self.cancelled = true
	end

	return event
end

local function sortListeners(eventListeners: { Listener })
	table.sort(eventListeners, function(left, right)
		if left.priority == right.priority then
			return left.id < right.id
		end

		return left.priority > right.priority
	end)
end

local function removeListenerById(listenerId: number): boolean
	for eventName, eventListeners in pairs(listenersByEvent) do
		for index, listener in ipairs(eventListeners) do
			if listener.id == listenerId then
				listener.active = false
				table.remove(eventListeners, index)

				if #eventListeners == 0 then
					listenersByEvent[eventName] = nil
				end

				return true
			end
		end
	end

	return false
end

local function collectListeners(eventName: string): { Listener }
	local collected = {}
	local namespace = namespaceOf(eventName)
	local direct = listenersByEvent[eventName]
	local globalWildcard = listenersByEvent["*"]
	local namespaceWildcard = listenersByEvent[namespace .. ".*"]

	if direct ~= nil then
		for _, listener in ipairs(direct) do
			table.insert(collected, listener)
		end
	end

	if namespaceWildcard ~= nil then
		for _, listener in ipairs(namespaceWildcard) do
			table.insert(collected, listener)
		end
	end

	if globalWildcard ~= nil then
		for _, listener in ipairs(globalWildcard) do
			table.insert(collected, listener)
		end
	end

	sortListeners(collected)

	return collected
end

function EventBus.subscribe(
	eventName: string,
	callback: (Event, ...any) -> (),
	priority: number?
): () -> ()
	assert(type(eventName) == "string", "eventName must be a string")
	assert(type(callback) == "function", "callback must be a function")

	nextListenerId += 1

	local listener: Listener = {
		id = nextListenerId,
		eventName = eventName,
		callback = callback,
		priority = priority or 0,
		once = false,
		active = true,
	}

	local eventListeners = listenersByEvent[eventName]

	if eventListeners == nil then
		eventListeners = {}
		listenersByEvent[eventName] = eventListeners
	end

	table.insert(eventListeners, listener)
	sortListeners(eventListeners)

	return function()
		EventBus.unsubscribe(listener.id)
	end
end

function EventBus.subscribeOnce(
	eventName: string,
	callback: (Event, ...any) -> (),
	priority: number?
): () -> ()
	local unsubscribe = EventBus.subscribe(eventName, callback, priority)
	local eventListeners = listenersByEvent[eventName]

	if eventListeners ~= nil then
		for _, listener in ipairs(eventListeners) do
			if listener.id == nextListenerId then
				listener.once = true
				break
			end
		end
	end

	return unsubscribe
end

function EventBus.unsubscribe(listenerIdOrDisconnect: any): boolean
	if type(listenerIdOrDisconnect) == "function" then
		listenerIdOrDisconnect()
		return true
	end

	if type(listenerIdOrDisconnect) ~= "number" then
		return false
	end

	return removeListenerById(listenerIdOrDisconnect)
end

function EventBus.publishSync(eventName: string, payload: EventPayload?, ...: any): Event
	assert(type(eventName) == "string", "eventName must be a string")

	publishedCount += 1

	local event = makeEvent(eventName, payload)
	local listeners = collectListeners(eventName)

	for _, listener in ipairs(listeners) do
		if listener.active then
			local ok, err = pcall(listener.callback, event, ...)

			if not ok then
				log.withContext("ERROR", "Listener failed", {
					eventName = eventName,
					listenerId = listener.id,
					error = tostring(err),
				})
			end

			if listener.once then
				removeListenerById(listener.id)
			end

			if event.cancelled then
				cancelledCount += 1
				break
			end
		end
	end

	return event
end

function EventBus.publishAsync(eventName: string, payload: EventPayload?, ...: any)
	local args = { ... }

	task.spawn(function()
		EventBus.publishSync(eventName, payload, table.unpack(args))
	end)
end

function EventBus.publishDeferred(eventName: string, payload: EventPayload?, ...: any)
	local args = { ... }

	task.defer(function()
		EventBus.publishSync(eventName, payload, table.unpack(args))
	end)
end

function EventBus.listenerCount(eventName: string?): number
	if eventName ~= nil then
		return #(listenersByEvent[eventName] or {})
	end

	local count = 0

	for _, eventListeners in pairs(listenersByEvent) do
		count += #eventListeners
	end

	return count
end

function EventBus.inspect()
	local snapshot = {}

	for eventName, eventListeners in pairs(listenersByEvent) do
		snapshot[eventName] = #eventListeners
	end

	return {
		publishedCount = publishedCount,
		cancelledCount = cancelledCount,
		listenerCount = EventBus.listenerCount(),
		events = snapshot,
	}
end

function EventBus.cleanup()
	for eventName, eventListeners in pairs(listenersByEvent) do
		for index = #eventListeners, 1, -1 do
			if not eventListeners[index].active then
				table.remove(eventListeners, index)
			end
		end

		if #eventListeners == 0 then
			listenersByEvent[eventName] = nil
		end
	end
end

function EventBus.clear(eventName: string?)
	if eventName == nil then
		table.clear(listenersByEvent)
		return
	end

	listenersByEvent[eventName] = nil
end

function EventBus.validate(): (boolean, string?)
	for eventName, eventListeners in pairs(listenersByEvent) do
		for _, listener in ipairs(eventListeners) do
			if listener.eventName ~= eventName then
				return false, "Listener registered under mismatched event name"
			end
		end
	end

	return true, nil
end

EventBus.publish = EventBus.publishSync

return EventBus
