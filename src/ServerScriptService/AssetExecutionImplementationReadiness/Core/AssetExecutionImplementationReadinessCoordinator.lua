--!strict

local Diagnostics = require(script.Parent.AssetExecutionImplementationReadinessDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionImplementationReadinessSelfChecks)
local Serialization = require(script.Parent.AssetExecutionImplementationReadinessSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionImplementationReadinessSnapshots)
local State = require(script.Parent.AssetExecutionImplementationReadinessState)
local Types = require(script.Parent.AssetExecutionImplementationReadinessTypes)
local Validation = require(script.Parent.AssetExecutionImplementationReadinessValidation)

local AssetExecutionImplementationReadinessCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionImplementationReadiness")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetExecutionImplementationReadiness validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionImplementationReadinessCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetExecutionImplementationReadinessCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetExecutionImplementationReadinessCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Implementation Readiness Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionImplementationReadinessCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Implementation Readiness Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionImplementationReadinessCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionImplementationReadinessCoordinator.registerImplementationReadiness(
	schema: any
)
	return register(schema, State.registerReadiness, "ImplementationReadiness")
end

function AssetExecutionImplementationReadinessCoordinator.registerImplementationReadinessChecklist(
	schema: any
)
	return register(schema, State.registerChecklist, "ImplementationReadinessChecklist")
end

function AssetExecutionImplementationReadinessCoordinator.registerImplementationReadinessGap(
	schema: any
)
	return register(schema, State.registerGap, "ImplementationReadinessGap")
end

function AssetExecutionImplementationReadinessCoordinator.registerImplementationReadinessAudit(
	schema: any
)
	return register(schema, State.registerAudit, "ImplementationReadinessAudit")
end

function AssetExecutionImplementationReadinessCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionImplementationReadinessCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionImplementationReadinessCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionImplementationReadinessCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Execution Implementation Readiness Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetExecutionImplementationReadinessCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionImplementationReadinessCoordinator
