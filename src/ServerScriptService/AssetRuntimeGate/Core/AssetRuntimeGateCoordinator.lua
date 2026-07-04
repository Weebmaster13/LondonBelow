--!strict

local Diagnostics = require(script.Parent.AssetRuntimeGateDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetRuntimeGateSelfChecks)
local Serialization = require(script.Parent.AssetRuntimeGateSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetRuntimeGateSnapshots)
local State = require(script.Parent.AssetRuntimeGateState)
local Validation = require(script.Parent.AssetRuntimeGateValidation)

local AssetRuntimeGateCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetRuntimeGate")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetRuntimeGate validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetRuntimeGateCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("assetRuntimeGateRuntime", function()
		return AssetRuntimeGateCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("assetRuntimeGateRuntime", function()
		return AssetRuntimeGateCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Runtime Gate Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetRuntimeGateCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Runtime Gate Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetRuntimeGateCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetRuntimeGateCoordinator.registerRuntimeGate(schema: any)
	return register(schema, State.registerGate, "RuntimeGate")
end

function AssetRuntimeGateCoordinator.registerRuntimeGateCheck(schema: any)
	return register(schema, State.registerCheck, "RuntimeGateCheck")
end

function AssetRuntimeGateCoordinator.registerRuntimeGateBlock(schema: any)
	return register(schema, State.registerBlock, "RuntimeGateBlock")
end

function AssetRuntimeGateCoordinator.registerRuntimeGateAudit(schema: any)
	return register(schema, State.registerAudit, "RuntimeGateAudit")
end

function AssetRuntimeGateCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetRuntimeGateCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetRuntimeGateCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetRuntimeGateCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Runtime Gate Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetRuntimeGateCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetRuntimeGateCoordinator
