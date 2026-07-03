--!strict
-- Main orchestrator for Phase 41 Rule Engine schema infrastructure.

local Diagnostics = require(script.Parent.RuleEngineDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.RuleEngineSelfChecks)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.RuleEngineSnapshots)
local State = require(script.Parent.RuleEngineState)
local Serialization = require(script.Parent.RuleEngineSerialization)
local Validation = require(script.Parent.RuleEngineValidation)

local RuleEngineCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("RuleEngine")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(reason or "unknown Rule Engine validation failure", schema)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function RuleEngineCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("ruleEngine", function()
		return RuleEngineCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("ruleEngine", function()
		return RuleEngineCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Rule Engine Foundation initialized")
	return result(true, "Initialized", nil)
end

function RuleEngineCoordinator.start()
	if not lifecycle.initialized then
		return result(false, "NotInitialized", "Rule Engine must initialize before start")
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function RuleEngineCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function RuleEngineCoordinator.registerRuleDefinition(schema: any)
	return register(schema, State.registerRule, "RuleDefinition")
end
function RuleEngineCoordinator.registerRuleCategory(schema: any)
	return register(schema, State.registerCategory, "RuleCategory")
end
function RuleEngineCoordinator.registerRulePredicate(schema: any)
	return register(schema, State.registerPredicate, "RulePredicate")
end
function RuleEngineCoordinator.registerRuleConstraint(schema: any)
	return register(schema, State.registerConstraint, "RuleConstraint")
end
function RuleEngineCoordinator.registerRulePermission(schema: any)
	return register(schema, State.registerPermission, "RulePermission")
end
function RuleEngineCoordinator.registerRulePolicy(schema: any)
	return register(schema, State.registerPolicy, "RulePolicy")
end
function RuleEngineCoordinator.registerRuleGroup(schema: any)
	return register(schema, State.registerGroup, "RuleGroup")
end
function RuleEngineCoordinator.registerRuleDependency(schema: any)
	return register(schema, State.registerDependency, "RuleDependency")
end
function RuleEngineCoordinator.registerRuleOutcome(schema: any)
	return register(schema, State.registerOutcome, "RuleOutcome")
end
function RuleEngineCoordinator.registerRuleAudit(schema: any)
	return register(schema, State.registerAudit, "RuleAudit")
end

function RuleEngineCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function RuleEngineCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function RuleEngineCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function RuleEngineCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(false, "AlreadyStarted", "Rule Engine self-checks must run before start")
	end
	local checks = SelfChecks.run({ Service = RuleEngineCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return RuleEngineCoordinator
