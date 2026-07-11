--!strict

local Diagnostics = require(script.Parent.AssetExecutionGovernanceDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionGovernanceSelfChecks)
local Serialization = require(script.Parent.AssetExecutionGovernanceSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionGovernanceSnapshots)
local State = require(script.Parent.AssetExecutionGovernanceState)
local Types = require(script.Parent.AssetExecutionGovernanceTypes)
local Validation = require(script.Parent.AssetExecutionGovernanceValidation)

local AssetExecutionGovernanceCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionGovernance")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetExecutionGovernance validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionGovernanceCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetExecutionGovernanceCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetExecutionGovernanceCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Governance Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionGovernanceCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Governance Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionGovernanceCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionGovernanceCoordinator.registerExecutionGovernance(schema: any)
	return register(schema, State.registerGovernance, "ExecutionGovernance")
end

function AssetExecutionGovernanceCoordinator.registerExecutionGovernanceRequirement(schema: any)
	return register(schema, State.registerRequirement, "ExecutionGovernanceRequirement")
end

function AssetExecutionGovernanceCoordinator.registerExecutionGovernanceAssessment(schema: any)
	return register(schema, State.registerAssessment, "ExecutionGovernanceAssessment")
end

function AssetExecutionGovernanceCoordinator.registerExecutionGovernanceFinding(schema: any)
	return register(schema, State.registerFinding, "ExecutionGovernanceFinding")
end

function AssetExecutionGovernanceCoordinator.registerExecutionGovernanceAudit(schema: any)
	return register(schema, State.registerAudit, "ExecutionGovernanceAudit")
end

function AssetExecutionGovernanceCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionGovernanceCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionGovernanceCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionGovernanceCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Execution Governance self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetExecutionGovernanceCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionGovernanceCoordinator
