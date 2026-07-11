--!strict

local Diagnostics = require(script.Parent.AssetExecutionAuthorizationDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionAuthorizationSelfChecks)
local Serialization = require(script.Parent.AssetExecutionAuthorizationSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionAuthorizationSnapshots)
local State = require(script.Parent.AssetExecutionAuthorizationState)
local Types = require(script.Parent.AssetExecutionAuthorizationTypes)
local Validation = require(script.Parent.AssetExecutionAuthorizationValidation)

local AssetExecutionAuthorizationCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionAuthorization")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetExecutionAuthorization validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionAuthorizationCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetExecutionAuthorizationCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetExecutionAuthorizationCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Authorization Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionAuthorizationCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Authorization Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionAuthorizationCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionAuthorizationCoordinator.registerExecutionAuthorization(schema: any)
	return register(schema, State.registerAuthorization, "ExecutionAuthorization")
end

function AssetExecutionAuthorizationCoordinator.registerExecutionAuthorizationRequirement(
	schema: any
)
	return register(schema, State.registerRequirement, "ExecutionAuthorizationRequirement")
end

function AssetExecutionAuthorizationCoordinator.registerExecutionAuthorizationEvaluation(
	schema: any
)
	return register(schema, State.registerEvaluation, "ExecutionAuthorizationEvaluation")
end

function AssetExecutionAuthorizationCoordinator.registerExecutionAuthorizationBoundary(schema: any)
	return register(schema, State.registerBoundary, "ExecutionAuthorizationBoundary")
end

function AssetExecutionAuthorizationCoordinator.registerExecutionAuthorizationAudit(schema: any)
	return register(schema, State.registerAudit, "ExecutionAuthorizationAudit")
end

function AssetExecutionAuthorizationCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionAuthorizationCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionAuthorizationCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionAuthorizationCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Execution Authorization self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetExecutionAuthorizationCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionAuthorizationCoordinator
