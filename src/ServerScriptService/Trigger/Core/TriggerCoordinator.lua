--!strict
-- Main orchestrator for Phase 43 Trigger schema infrastructure.

local Diagnostics = require(script.Parent.TriggerDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.TriggerSelfChecks)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.TriggerSnapshots)
local State = require(script.Parent.TriggerState)
local Serialization = require(script.Parent.TriggerSerialization)
local Validation = require(script.Parent.TriggerValidation)

local TriggerCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("Trigger")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(reason or "unknown Trigger validation failure", schema)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function TriggerCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("triggerRuntime", function()
		return TriggerCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("triggerRuntime", function()
		return TriggerCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Trigger Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function TriggerCoordinator.start()
	if not lifecycle.initialized then
		return result(false, "NotInitialized", "Trigger Runtime must initialize before start")
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function TriggerCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function TriggerCoordinator.registerTriggerDefinition(schema: any)
	return register(schema, State.registerDefinition, "TriggerDefinition")
end
function TriggerCoordinator.registerTriggerCategory(schema: any)
	return register(schema, State.registerCategory, "TriggerCategory")
end
function TriggerCoordinator.registerTriggerSource(schema: any)
	return register(schema, State.registerSource, "TriggerSource")
end
function TriggerCoordinator.registerTriggerTarget(schema: any)
	return register(schema, State.registerTarget, "TriggerTarget")
end
function TriggerCoordinator.registerTriggerEvent(schema: any)
	return register(schema, State.registerEvent, "TriggerEvent")
end
function TriggerCoordinator.registerTriggerFilter(schema: any)
	return register(schema, State.registerFilter, "TriggerFilter")
end
function TriggerCoordinator.registerTriggerCondition(schema: any)
	return register(schema, State.registerCondition, "TriggerCondition")
end
function TriggerCoordinator.registerTriggerDependency(schema: any)
	return register(schema, State.registerDependency, "TriggerDependency")
end
function TriggerCoordinator.registerTriggerGroup(schema: any)
	return register(schema, State.registerGroup, "TriggerGroup")
end
function TriggerCoordinator.registerTriggerOutcome(schema: any)
	return register(schema, State.registerOutcome, "TriggerOutcome")
end
function TriggerCoordinator.registerTriggerAudit(schema: any)
	return register(schema, State.registerAudit, "TriggerAudit")
end

function TriggerCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function TriggerCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function TriggerCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function TriggerCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(false, "AlreadyStarted", "Trigger Runtime self-checks must run before start")
	end
	local checks = SelfChecks.run({ Service = TriggerCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return TriggerCoordinator
