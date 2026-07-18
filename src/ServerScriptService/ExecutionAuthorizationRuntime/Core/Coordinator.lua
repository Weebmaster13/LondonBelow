--!strict

local Core = script.Parent.Parent.Parent.Core
local EngineDiagnostics = require(Core.Diagnostics)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Diagnostics = require(script.Parent.Diagnostics)
local Runtime = require(script.Parent.Runtime)
local SelfChecks = require(script.Parent.SelfChecks)
local Snapshots = require(script.Parent.Snapshots)
local State = require(script.Parent.State)
local Types = require(script.Parent.Types)
local Validation = require(script.Parent.Validation)

local Coordinator = {}

local lifecycle = {
	initialized = false,
	started = false,
	lastSelfChecks = nil :: any,
}

local log = Logger.scope("ExecutionAuthorizationRuntime")

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

function Coordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return Coordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return Coordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Execution Authorization Runtime initialized")
	return result(true, "Initialized", nil)
end

function Coordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Execution Authorization Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function Coordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function Coordinator.authorize(input: any)
	return Runtime.authorize(input)
end

function Coordinator.inspect()
	return Diagnostics.capture(lifecycle)
end

function Coordinator.getSnapshot()
	return Snapshots.capture(lifecycle)
end

function Coordinator.validate(): (boolean, string?)
	return Diagnostics.validate()
end

function Coordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Execution Authorization self-checks must run before start"
		)
	end
	lifecycle.lastSelfChecks = SelfChecks.run({ Service = Coordinator })
	return lifecycle.lastSelfChecks
end

return Coordinator
