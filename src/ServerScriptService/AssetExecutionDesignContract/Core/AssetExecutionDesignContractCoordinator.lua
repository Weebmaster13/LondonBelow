--!strict

local Diagnostics = require(script.Parent.AssetExecutionDesignContractDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionDesignContractSelfChecks)
local Serialization = require(script.Parent.AssetExecutionDesignContractSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionDesignContractSnapshots)
local State = require(script.Parent.AssetExecutionDesignContractState)
local Validation = require(script.Parent.AssetExecutionDesignContractValidation)

local AssetExecutionDesignContractCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionDesignContract")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetExecutionDesignContract validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionDesignContractCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("AssetExecutionDesignContractRuntime", function()
		return AssetExecutionDesignContractCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("AssetExecutionDesignContractRuntime", function()
		return AssetExecutionDesignContractCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Design Contract Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionDesignContractCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Design Contract Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionDesignContractCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionDesignContractCoordinator.registerExecutionDesignContract(schema: any)
	return register(schema, State.registerContract, "ExecutionDesignContract")
end

function AssetExecutionDesignContractCoordinator.registerExecutionDesignResponsibility(schema: any)
	return register(schema, State.registerResponsibility, "ExecutionDesignResponsibility")
end

function AssetExecutionDesignContractCoordinator.registerExecutionDesignBoundary(schema: any)
	return register(schema, State.registerBoundary, "ExecutionDesignBoundary")
end

function AssetExecutionDesignContractCoordinator.registerExecutionDesignAudit(schema: any)
	return register(schema, State.registerAudit, "ExecutionDesignAudit")
end

function AssetExecutionDesignContractCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionDesignContractCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionDesignContractCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionDesignContractCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Execution Design Contract Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetExecutionDesignContractCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionDesignContractCoordinator
