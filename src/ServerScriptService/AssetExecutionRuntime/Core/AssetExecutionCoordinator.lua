--!strict

local Diagnostics = require(script.Parent.AssetExecutionDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionSelfChecks)
local Serialization = require(script.Parent.AssetExecutionSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionSnapshots)
local State = require(script.Parent.AssetExecutionState)
local Types = require(script.Parent.AssetExecutionTypes)
local Validation = require(script.Parent.AssetExecutionValidation)

local AssetExecutionCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionRuntime")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(reason or "unknown AssetExecution validation failure", schema)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetExecutionCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetExecutionCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionCoordinator.registerExecutionRuntime(schema: any)
	return register(schema, State.registerRuntime, "ExecutionRuntime")
end

function AssetExecutionCoordinator.registerExecutionRequest(schema: any)
	return register(schema, State.registerRequest, "ExecutionRequest")
end

function AssetExecutionCoordinator.registerExecutionBoundary(schema: any)
	return register(schema, State.registerBoundary, "ExecutionBoundary")
end

function AssetExecutionCoordinator.registerExecutionAudit(schema: any)
	return register(schema, State.registerAudit, "ExecutionAudit")
end

function AssetExecutionCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(false, "AlreadyStarted", "Asset Execution self-checks must run before start")
	end
	local checks = SelfChecks.run({ Service = AssetExecutionCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionCoordinator
