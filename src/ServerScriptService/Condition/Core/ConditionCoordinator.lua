--!strict
-- Main orchestrator for Phase 42 Condition schema infrastructure.

local Diagnostics = require(script.Parent.ConditionDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.ConditionSelfChecks)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.ConditionSnapshots)
local State = require(script.Parent.ConditionState)
local Serialization = require(script.Parent.ConditionSerialization)
local Validation = require(script.Parent.ConditionValidation)

local ConditionCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("Condition")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(reason or "unknown Condition validation failure", schema)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function ConditionCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("conditionRuntime", function()
		return ConditionCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("conditionRuntime", function()
		return ConditionCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Condition Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function ConditionCoordinator.start()
	if not lifecycle.initialized then
		return result(false, "NotInitialized", "Condition Runtime must initialize before start")
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function ConditionCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function ConditionCoordinator.registerConditionDefinition(schema: any)
	return register(schema, State.registerDefinition, "ConditionDefinition")
end
function ConditionCoordinator.registerConditionCategory(schema: any)
	return register(schema, State.registerCategory, "ConditionCategory")
end
function ConditionCoordinator.registerConditionExpression(schema: any)
	return register(schema, State.registerExpression, "ConditionExpression")
end
function ConditionCoordinator.registerConditionOperand(schema: any)
	return register(schema, State.registerOperand, "ConditionOperand")
end
function ConditionCoordinator.registerConditionOperator(schema: any)
	return register(schema, State.registerOperator, "ConditionOperator")
end
function ConditionCoordinator.registerConditionGroup(schema: any)
	return register(schema, State.registerGroup, "ConditionGroup")
end
function ConditionCoordinator.registerConditionDependency(schema: any)
	return register(schema, State.registerDependency, "ConditionDependency")
end
function ConditionCoordinator.registerConditionState(schema: any)
	return register(schema, State.registerState, "ConditionState")
end
function ConditionCoordinator.registerConditionOutcome(schema: any)
	return register(schema, State.registerOutcome, "ConditionOutcome")
end
function ConditionCoordinator.registerConditionAudit(schema: any)
	return register(schema, State.registerAudit, "ConditionAudit")
end

function ConditionCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function ConditionCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function ConditionCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function ConditionCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Condition Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = ConditionCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return ConditionCoordinator
