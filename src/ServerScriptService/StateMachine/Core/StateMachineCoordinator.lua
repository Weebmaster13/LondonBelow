--!strict
-- Main orchestrator for Phase 44 State Machine schema infrastructure.

local Diagnostics = require(script.Parent.StateMachineDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.StateMachineSelfChecks)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.StateMachineSnapshots)
local State = require(script.Parent.StateMachineState)
local Serialization = require(script.Parent.StateMachineSerialization)
local Validation = require(script.Parent.StateMachineValidation)

local StateMachineCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("StateMachine")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(reason or "unknown StateMachine validation failure", schema)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function StateMachineCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("stateMachineRuntime", function()
		return StateMachineCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("stateMachineRuntime", function()
		return StateMachineCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("State Machine Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function StateMachineCoordinator.start()
	if not lifecycle.initialized then
		return result(false, "NotInitialized", "State Machine Runtime must initialize before start")
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function StateMachineCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function StateMachineCoordinator.registerStateMachineDefinition(schema: any)
	return register(schema, State.registerDefinition, "StateMachineDefinition")
end
function StateMachineCoordinator.registerStateMachineState(schema: any)
	return register(schema, State.registerState, "StateMachineState")
end
function StateMachineCoordinator.registerStateMachineTransition(schema: any)
	return register(schema, State.registerTransition, "StateMachineTransition")
end
function StateMachineCoordinator.registerStateMachineGuard(schema: any)
	return register(schema, State.registerGuard, "StateMachineGuard")
end
function StateMachineCoordinator.registerStateMachineInput(schema: any)
	return register(schema, State.registerInput, "StateMachineInput")
end
function StateMachineCoordinator.registerStateMachineOutput(schema: any)
	return register(schema, State.registerOutput, "StateMachineOutput")
end
function StateMachineCoordinator.registerStateMachineGroup(schema: any)
	return register(schema, State.registerGroup, "StateMachineGroup")
end
function StateMachineCoordinator.registerStateMachineDependency(schema: any)
	return register(schema, State.registerDependency, "StateMachineDependency")
end
function StateMachineCoordinator.registerStateMachineOutcome(schema: any)
	return register(schema, State.registerOutcome, "StateMachineOutcome")
end
function StateMachineCoordinator.registerStateMachineAudit(schema: any)
	return register(schema, State.registerAudit, "StateMachineAudit")
end

function StateMachineCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function StateMachineCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function StateMachineCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function StateMachineCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"State Machine Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = StateMachineCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return StateMachineCoordinator
