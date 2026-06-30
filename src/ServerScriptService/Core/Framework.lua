local EventBus = require(script.Parent.EventBus)
local Logger = require(script.Parent.Logger)
local ServiceLocator = require(script.Parent.ServiceLocator)

local Framework = {}

local log = Logger.scope("Framework")
local initialized = false
local started = false

local function registerCoreServices()
	ServiceLocator.register("Logger", Logger)
	ServiceLocator.register("EventBus", EventBus)
end

function Framework.initialize()
	if initialized then
		return
	end

	registerCoreServices()
	initialized = true

	log.info("Core services initialized")
end

function Framework.start()
	if started then
		return
	end

	if not initialized then
		Framework.initialize()
	end

	started = true
	EventBus.publish("FrameworkStarted")

	log.info("Framework started")
end

function Framework.isInitialized()
	return initialized
end

function Framework.isStarted()
	return started
end

return Framework
