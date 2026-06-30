--!strict
--[[
	Framework owns the London Engine lifecycle.

	It is responsible for startup, shutdown, service registration, dependency
	validation, health tracking, module registry, readiness, engine mode, and
	future extension points such as plugins and hot reload.
]]

local DependencyManager = require(script.Parent.DependencyManager)
local Diagnostics = require(script.Parent.Diagnostics)
local EventBus = require(script.Parent.EventBus)
local Logger = require(script.Parent.Logger)
local RemoteManager = require(script.Parent.RemoteManager)
local Scheduler = require(script.Parent.Scheduler)
local ServiceLocator = require(script.Parent.ServiceLocator)
local SnapshotManager = require(script.Parent.SnapshotManager)

local Framework = {}

export type EngineMode = "Development" | "Production"
export type EngineState =
	"Created"
	| "Initializing"
	| "Initialized"
	| "Starting"
	| "Ready"
	| "Stopping"
	| "Stopped"
	| "Failed"
export type ModuleRecord = {
	name: string,
	module: any,
	dependencies: { string },
	optionalDependencies: { string },
	registeredAt: number,
	initialized: boolean,
	started: boolean,
}

local VERSION = "1.0.0"
local ENGINE_NAME = "London Engine"
local REQUIRED_CORE_SERVICES = {
	"Logger",
	"EventBus",
	"ServiceLocator",
	"Scheduler",
	"DependencyManager",
	"Diagnostics",
	"SnapshotManager",
	"RemoteManager",
}

local log = Logger.scope("Framework")
local state: EngineState = "Created"
local mode: EngineMode = "Development"
local initialized = false
local started = false
local ready = false
local startupStartedAt = 0
local startupCompletedAt = 0
local moduleRegistry: { [string]: ModuleRecord } = {}
local startupErrors: { string } = {}
local startupWarnings: { string } = {}
local extensionPoints: { [string]: { (any) -> () } } = {}

local CORE_MODULES = {
	{
		name = "Logger",
		module = Logger,
		dependencies = {},
	},
	{
		name = "EventBus",
		module = EventBus,
		dependencies = { "Logger" },
	},
	{
		name = "ServiceLocator",
		module = ServiceLocator,
		dependencies = {},
	},
	{
		name = "Scheduler",
		module = Scheduler,
		dependencies = { "Logger" },
	},
	{
		name = "DependencyManager",
		module = DependencyManager,
		dependencies = { "Logger" },
	},
	{
		name = "Diagnostics",
		module = Diagnostics,
		dependencies = { "Logger" },
	},
	{
		name = "SnapshotManager",
		module = SnapshotManager,
		dependencies = { "Logger" },
	},
	{
		name = "RemoteManager",
		module = RemoteManager,
		dependencies = { "Logger" },
	},
}

local function transition(nextState: EngineState)
	state = nextState
	EventBus.publishDeferred("Framework.StateChanged", {
		state = nextState,
	})
end

local function copyArray(values: { string }): { string }
	local copied = {}

	for _, value in ipairs(values) do
		table.insert(copied, value)
	end

	return copied
end

local function listRegisteredServices(): { string }
	local names = {}

	for name in pairs(moduleRegistry) do
		table.insert(names, name)
	end

	table.sort(names)

	return names
end

local function recordError(message: string)
	table.insert(startupErrors, message)
	Diagnostics.incrementError()
	log.error(message)
end

local function recordWarning(message: string)
	table.insert(startupWarnings, message)
	Diagnostics.incrementWarning()
	log.warn(message)
end

local function runModuleValidation(name: string, module: any): (boolean, string?)
	if type(module) ~= "table" then
		return true, nil
	end

	local validate = module.validate

	if type(validate) ~= "function" then
		return true, nil
	end

	local ok, valid, err = pcall(validate)

	if not ok then
		return false, tostring(valid)
	end

	if not valid then
		return false, tostring(err or ("Module validation failed: " .. name))
	end

	return true, nil
end

local function registerModule(
	name: string,
	module: any,
	dependencies: { string }?,
	optionalDependencies: { string }?
)
	assert(type(name) == "string" and name ~= "", "module name must be a non-empty string")
	assert(module ~= nil, "module cannot be nil")

	if moduleRegistry[name] ~= nil then
		error("Module already registered: " .. name, 2)
	end

	local required = dependencies or {}
	local optional = optionalDependencies or {}

	moduleRegistry[name] = {
		name = name,
		module = module,
		dependencies = copyArray(required),
		optionalDependencies = copyArray(optional),
		registeredAt = os.clock(),
		initialized = false,
		started = false,
	}

	DependencyManager.register(name, required, optional)
	ServiceLocator.register(name, module, required, optional)
end

local function registerCoreServices()
	for _, core in ipairs(CORE_MODULES) do
		registerModule(core.name, core.module, core.dependencies, {})
	end

	Diagnostics.configure(listRegisteredServices, Framework.getStartupDuration)

	SnapshotManager.registerProvider("diagnostics", Diagnostics.capture)
	SnapshotManager.registerProvider("events", EventBus.inspect)
	SnapshotManager.registerProvider("scheduler", Scheduler.inspect)
	SnapshotManager.registerProvider("services", ServiceLocator.inspect)
	SnapshotManager.registerProvider("remotes", RemoteManager.inspect)
end

local function rollbackInitialization()
	if not ServiceLocator.isFrozen() then
		ServiceLocator.clear()
	end

	DependencyManager.clear()
	table.clear(moduleRegistry)
	initialized = false
	started = false
	ready = false
end

local function validateRequiredServices(): (boolean, string?)
	for _, serviceName in ipairs(REQUIRED_CORE_SERVICES) do
		if not ServiceLocator.exists(serviceName) then
			return false, "Required core service missing: " .. serviceName
		end
	end

	local locatorOk, locatorErr = ServiceLocator.validate()

	if not locatorOk then
		return false, locatorErr
	end

	local dependencyOk, dependencyErr = DependencyManager.validate()

	if not dependencyOk then
		return false, dependencyErr
	end

	for name, record in pairs(moduleRegistry) do
		local moduleOk, moduleErr = runModuleValidation(name, record.module)

		if not moduleOk then
			return false, moduleErr
		end
	end

	return true, nil
end

local function getStartupOrder(): { string }
	local order = {}

	for _, spec in ipairs(DependencyManager.generateStartupGraph()) do
		if moduleRegistry[spec.name] ~= nil then
			table.insert(order, spec.name)
		end
	end

	return order
end

local function callLifecycleHook(record: ModuleRecord, hookName: string)
	local hook = record.module[hookName]

	if type(hook) ~= "function" then
		return
	end

	local ok, err = pcall(hook)

	if not ok then
		error(string.format("Module '%s' %s failed: %s", record.name, hookName, tostring(err)), 0)
	end
end

function Framework.configure(config: { mode: EngineMode?, debug: boolean? }?)
	if config == nil then
		return
	end

	if config.mode ~= nil then
		mode = config.mode
	end

	if config.debug ~= nil then
		Logger.setDebugEnabled(config.debug)
	end
end

function Framework.initialize(config: { mode: EngineMode?, debug: boolean? }?)
	if initialized then
		return true
	end

	startupStartedAt = os.clock()
	Framework.configure(config)
	transition("Initializing")
	Logger.startTimer("Framework.Initialize", "Framework", "Startup")

	local ok, err = pcall(function()
		registerCoreServices()

		local valid, validationErr = validateRequiredServices()

		if not valid then
			error(validationErr, 0)
		end

		for _, name in ipairs(getStartupOrder()) do
			local record = moduleRegistry[name]

			if record ~= nil then
				callLifecycleHook(record, "initialize")
				record.initialized = true
				DependencyManager.markInitialized(name)
			end
		end

		ServiceLocator.freeze()

		initialized = true
		transition("Initialized")
	end)

	local duration = Logger.endTimer("Framework.Initialize")

	if not ok then
		rollbackInitialization()
		transition("Failed")
		recordError("Framework initialization failed: " .. tostring(err))
		Logger.enterPanicMode(tostring(err))
		return false
	end

	log.withContext("SUCCESS", "Framework initialized", {
		durationMs = if duration ~= nil then math.floor(duration * 1000) else nil,
		services = listRegisteredServices(),
		mode = mode,
		version = VERSION,
	})

	return true
end

function Framework.start()
	if started then
		return true
	end

	if not initialized then
		local initializedOk = Framework.initialize()

		if not initializedOk then
			return false
		end
	end

	transition("Starting")
	Logger.startTimer("Framework.Start", "Framework", "Startup")

	local ok, err = pcall(function()
		local valid, validationErr = validateRequiredServices()

		if not valid then
			error(validationErr, 0)
		end

		for _, name in ipairs(getStartupOrder()) do
			local record = moduleRegistry[name]

			if record ~= nil then
				callLifecycleHook(record, "start")
				record.started = true
			end
		end

		started = true
		ready = true
		startupCompletedAt = os.clock()
		transition("Ready")

		EventBus.publishDeferred("Framework.Ready", {
			version = VERSION,
			mode = mode,
			startupDuration = Framework.getStartupDuration(),
		})
	end)

	local duration = Logger.endTimer("Framework.Start")

	if not ok then
		ready = false
		started = false
		transition("Failed")
		recordError("Framework startup failed: " .. tostring(err))
		Logger.enterPanicMode(tostring(err))
		return false
	end

	log.withContext("SUCCESS", "Framework ready", {
		durationMs = if duration ~= nil then math.floor(duration * 1000) else nil,
		startupMs = math.floor(Framework.getStartupDuration() * 1000),
		services = #listRegisteredServices(),
	})

	SnapshotManager.capture("FrameworkReady", Framework.getState(), listRegisteredServices())

	return true
end

function Framework.shutdown(reason: string?)
	if state == "Stopped" then
		return true
	end

	transition("Stopping")

	local ok, err = pcall(function()
		Scheduler.cleanup()
		EventBus.publishSync("Framework.Shutdown", {
			reason = reason or "No reason provided",
		})

		ready = false
		started = false

		for _, record in pairs(moduleRegistry) do
			record.started = false
		end

		transition("Stopped")
	end)

	if not ok then
		transition("Failed")
		recordError("Framework shutdown failed: " .. tostring(err))
		return false
	end

	log.withContext("WARN", "Framework stopped", {
		reason = reason or "No reason provided",
	})

	return true
end

function Framework.registerExtensionPoint(name: string, callback: (any) -> ())
	assert(type(name) == "string" and name ~= "", "name must be a non-empty string")
	assert(type(callback) == "function", "callback must be a function")

	local callbacks = extensionPoints[name]

	if callbacks == nil then
		callbacks = {}
		extensionPoints[name] = callbacks
	end

	table.insert(callbacks, callback)
end

function Framework.runExtensionPoint(name: string, payload: any)
	local callbacks = extensionPoints[name]

	if callbacks == nil then
		return
	end

	for _, callback in ipairs(callbacks) do
		local ok, err = pcall(callback, payload)

		if not ok then
			recordWarning(string.format("Extension point '%s' failed: %s", name, tostring(err)))
		end
	end
end

function Framework.registerModule(
	name: string,
	module: any,
	dependencies: { string }?,
	optionalDependencies: { string }?
)
	if initialized then
		error("Cannot register modules after Framework initialization", 2)
	end

	registerModule(name, module, dependencies, optionalDependencies)
end

function Framework.validate(): (boolean, string?)
	return validateRequiredServices()
end

function Framework.getVersion(): string
	return VERSION
end

function Framework.getEngineName(): string
	return ENGINE_NAME
end

function Framework.getMode(): EngineMode
	return mode
end

function Framework.isDeveloperMode(): boolean
	return mode == "Development"
end

function Framework.isProductionMode(): boolean
	return mode == "Production"
end

function Framework.isInitialized(): boolean
	return initialized
end

function Framework.isStarted(): boolean
	return started
end

function Framework.isReady(): boolean
	return ready
end

function Framework.getStartupDuration(): number
	if startupStartedAt == 0 then
		return 0
	end

	if startupCompletedAt == 0 then
		return os.clock() - startupStartedAt
	end

	return startupCompletedAt - startupStartedAt
end

function Framework.getState()
	return {
		name = ENGINE_NAME,
		version = VERSION,
		state = state,
		mode = mode,
		initialized = initialized,
		started = started,
		ready = ready,
		startupDuration = Framework.getStartupDuration(),
		services = listRegisteredServices(),
		errors = table.clone(startupErrors),
		warnings = table.clone(startupWarnings),
	}
end

function Framework.getHealth()
	local valid, validationErr = Framework.validate()
	local diagnostics = Diagnostics.capture()

	return {
		healthy = valid and diagnostics.healthy and ready,
		validationError = validationErr,
		diagnostics = diagnostics,
		state = Framework.getState(),
	}
end

function Framework.getModuleRegistry()
	local registry = {}

	for name, record in pairs(moduleRegistry) do
		registry[name] = {
			dependencies = copyArray(record.dependencies),
			optionalDependencies = copyArray(record.optionalDependencies),
			registeredAt = record.registeredAt,
			initialized = record.initialized,
			started = record.started,
		}
	end

	return registry
end

function Framework.printStartupSummary()
	local health = Framework.getHealth()

	Diagnostics.printSummary()
	log.withContext(if health.healthy then "SUCCESS" else "ERROR", "Startup summary", {
		engine = ENGINE_NAME,
		version = VERSION,
		state = state,
		mode = mode,
		ready = ready,
		services = listRegisteredServices(),
		startupMs = math.floor(Framework.getStartupDuration() * 1000),
		errors = startupErrors,
		warnings = startupWarnings,
	})

	return health
end

return Framework
