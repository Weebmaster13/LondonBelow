--!strict

local Diagnostics = require(script.Parent.AssetExecutionPermitDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionPermitSelfChecks)
local Serialization = require(script.Parent.AssetExecutionPermitSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionPermitSnapshots)
local State = require(script.Parent.AssetExecutionPermitState)
local Validation = require(script.Parent.AssetExecutionPermitValidation)

local AssetExecutionPermitCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionPermit")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetExecutionPermit validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionPermitCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("assetExecutionPermitRuntime", function()
		return AssetExecutionPermitCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("assetExecutionPermitRuntime", function()
		return AssetExecutionPermitCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Permit Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionPermitCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Permit Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionPermitCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionPermitCoordinator.registerExecutionPermit(schema: any)
	return register(schema, State.registerPermit, "ExecutionPermit")
end

function AssetExecutionPermitCoordinator.registerExecutionPermitScope(schema: any)
	return register(schema, State.registerScope, "ExecutionPermitScope")
end

function AssetExecutionPermitCoordinator.registerExecutionPermitRestriction(schema: any)
	return register(schema, State.registerRestriction, "ExecutionPermitRestriction")
end

function AssetExecutionPermitCoordinator.registerExecutionPermitAudit(schema: any)
	return register(schema, State.registerAudit, "ExecutionPermitAudit")
end

function AssetExecutionPermitCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionPermitCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionPermitCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionPermitCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Execution Permit Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetExecutionPermitCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionPermitCoordinator
