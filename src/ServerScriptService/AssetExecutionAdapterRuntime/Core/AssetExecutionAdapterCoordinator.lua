--!strict

local Diagnostics = require(script.Parent.AssetExecutionAdapterDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionAdapterSelfChecks)
local Serialization = require(script.Parent.AssetExecutionAdapterSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionAdapterSnapshots)
local State = require(script.Parent.AssetExecutionAdapterState)
local Types = require(script.Parent.AssetExecutionAdapterTypes)
local Validation = require(script.Parent.AssetExecutionAdapterValidation)

local AssetExecutionAdapterCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionAdapterRuntime")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetExecutionAdapter validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionAdapterCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetExecutionAdapterCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetExecutionAdapterCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Adapter Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionAdapterCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Adapter Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionAdapterCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionAdapterCoordinator.registerExecutionAdapter(schema: any)
	return register(schema, State.registerAdapter, "ExecutionAdapter")
end

function AssetExecutionAdapterCoordinator.registerExecutionAdapterCapability(schema: any)
	return register(schema, State.registerCapability, "ExecutionAdapterCapability")
end

function AssetExecutionAdapterCoordinator.registerExecutionAdapterCompatibility(schema: any)
	return register(schema, State.registerCompatibility, "ExecutionAdapterCompatibility")
end

function AssetExecutionAdapterCoordinator.registerExecutionAdapterBoundary(schema: any)
	return register(schema, State.registerBoundary, "ExecutionAdapterBoundary")
end

function AssetExecutionAdapterCoordinator.registerExecutionAdapterAudit(schema: any)
	return register(schema, State.registerAudit, "ExecutionAdapterAudit")
end

function AssetExecutionAdapterCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionAdapterCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionAdapterCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionAdapterCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Execution Adapter self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetExecutionAdapterCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionAdapterCoordinator
