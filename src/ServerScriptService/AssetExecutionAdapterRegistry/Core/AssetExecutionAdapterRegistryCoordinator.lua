--!strict

local Diagnostics = require(script.Parent.AssetExecutionAdapterRegistryDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionAdapterRegistrySelfChecks)
local Serialization = require(script.Parent.AssetExecutionAdapterRegistrySerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionAdapterRegistrySnapshots)
local State = require(script.Parent.AssetExecutionAdapterRegistryState)
local Types = require(script.Parent.AssetExecutionAdapterRegistryTypes)
local Validation = require(script.Parent.AssetExecutionAdapterRegistryValidation)

local AssetExecutionAdapterRegistryCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionAdapterRegistry")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetExecutionAdapterRegistry validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionAdapterRegistryCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetExecutionAdapterRegistryCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetExecutionAdapterRegistryCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Adapter Registry Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionAdapterRegistryCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Adapter Registry must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionAdapterRegistryCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionAdapterRegistryCoordinator.registerExecutionAdapterRegistry(schema: any)
	return register(schema, State.registerRegistry, "ExecutionAdapterRegistry")
end

function AssetExecutionAdapterRegistryCoordinator.registerExecutionAdapterRegistration(schema: any)
	return register(schema, State.registerRegistration, "ExecutionAdapterRegistration")
end

function AssetExecutionAdapterRegistryCoordinator.registerExecutionAdapterRegistrationBoundary(
	schema: any
)
	return register(schema, State.registerBoundary, "ExecutionAdapterRegistrationBoundary")
end

function AssetExecutionAdapterRegistryCoordinator.registerExecutionAdapterRegistryCompatibility(
	schema: any
)
	return register(schema, State.registerCompatibility, "ExecutionAdapterRegistryCompatibility")
end

function AssetExecutionAdapterRegistryCoordinator.registerExecutionAdapterRegistrationAudit(
	schema: any
)
	return register(schema, State.registerAudit, "ExecutionAdapterRegistrationAudit")
end

function AssetExecutionAdapterRegistryCoordinator.registerExecutionAdapterRegistrySnapshot(
	schema: any
)
	return register(schema, State.registerRegistrySnapshot, "ExecutionAdapterRegistrySnapshot")
end

function AssetExecutionAdapterRegistryCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionAdapterRegistryCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionAdapterRegistryCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionAdapterRegistryCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Execution Adapter Registry self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetExecutionAdapterRegistryCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionAdapterRegistryCoordinator
