--!strict

local Diagnostics = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowSelfChecks)
local Serialization = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowSnapshots)
local State = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowState)
local Types = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowTypes)
local Validation = require(script.Parent.AssetExecutionAdapterRegistrationWorkflowValidation)

local AssetExecutionAdapterRegistrationWorkflowCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionAdapterRegistrationWorkflow")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }
local DISPLAY_NAME = "Asset Execution Adapter " .. "Registration Workflow"

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown " .. DISPLAY_NAME .. " validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetExecutionAdapterRegistrationWorkflowCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetExecutionAdapterRegistrationWorkflowCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info(DISPLAY_NAME .. " Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.start()
	if not lifecycle.initialized then
		return result(false, "NotInitialized", DISPLAY_NAME .. " must initialize before start")
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.registerExecutionAdapterRegistrationWorkflow(
	schema: any
)
	return register(schema, State.registerWorkflow, "ExecutionAdapterRegistrationWorkflow")
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.registerExecutionAdapterRegistrationStage(
	schema: any
)
	return register(schema, State.registerStage, "ExecutionAdapterRegistrationStage")
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.registerExecutionAdapterRegistrationTransition(
	schema: any
)
	return register(schema, State.registerTransition, "ExecutionAdapterRegistrationTransition")
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.registerExecutionAdapterRegistrationDecision(
	schema: any
)
	return register(schema, State.registerDecision, "ExecutionAdapterRegistrationDecision")
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.registerExecutionAdapterRegistrationAudit(
	schema: any
)
	return register(schema, State.registerAudit, "ExecutionAdapterRegistrationAudit")
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.registerExecutionAdapterRegistrationWorkflowSnapshot(
	schema: any
)
	return register(
		schema,
		State.registerWorkflowSnapshot,
		"ExecutionAdapterRegistrationWorkflowSnapshot"
	)
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionAdapterRegistrationWorkflowCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(false, "AlreadyStarted", DISPLAY_NAME .. " self-checks must run before start")
	end
	local checks =
		SelfChecks.run({ Service = AssetExecutionAdapterRegistrationWorkflowCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionAdapterRegistrationWorkflowCoordinator
