--!strict

local Diagnostics = require(script.Parent.AssetExecutionImplementationContractDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionImplementationContractSelfChecks)
local Serialization = require(script.Parent.AssetExecutionImplementationContractSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionImplementationContractSnapshots)
local State = require(script.Parent.AssetExecutionImplementationContractState)
local Types = require(script.Parent.AssetExecutionImplementationContractTypes)
local Validation = require(script.Parent.AssetExecutionImplementationContractValidation)

local AssetExecutionImplementationContractCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionImplementationContract")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetExecutionImplementationContract validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionImplementationContractCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetExecutionImplementationContractCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetExecutionImplementationContractCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Implementation Contract Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionImplementationContractCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Implementation Contract Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionImplementationContractCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionImplementationContractCoordinator.registerImplementationContract(schema: any)
	return register(schema, State.registerContract, "ImplementationContract")
end

function AssetExecutionImplementationContractCoordinator.registerImplementationContractResponsibility(
	schema: any
)
	return register(schema, State.registerResponsibility, "ImplementationContractResponsibility")
end

function AssetExecutionImplementationContractCoordinator.registerImplementationContractBoundary(
	schema: any
)
	return register(schema, State.registerBoundary, "ImplementationContractBoundary")
end

function AssetExecutionImplementationContractCoordinator.registerImplementationContractAudit(
	schema: any
)
	return register(schema, State.registerAudit, "ImplementationContractAudit")
end

function AssetExecutionImplementationContractCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionImplementationContractCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionImplementationContractCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionImplementationContractCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Execution Implementation Contract Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetExecutionImplementationContractCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionImplementationContractCoordinator
