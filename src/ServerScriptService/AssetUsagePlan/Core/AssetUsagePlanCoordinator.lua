--!strict

local Diagnostics = require(script.Parent.AssetUsagePlanDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetUsagePlanSelfChecks)
local Serialization = require(script.Parent.AssetUsagePlanSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetUsagePlanSnapshots)
local State = require(script.Parent.AssetUsagePlanState)
local Validation = require(script.Parent.AssetUsagePlanValidation)

local AssetUsagePlanCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetUsagePlan")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(reason or "unknown AssetUsagePlan validation failure", schema)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetUsagePlanCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("assetUsagePlanRuntime", function()
		return AssetUsagePlanCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("assetUsagePlanRuntime", function()
		return AssetUsagePlanCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Usage Plan Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetUsagePlanCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Usage Plan Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetUsagePlanCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetUsagePlanCoordinator.registerUsagePlanDefinition(schema: any)
	return register(schema, State.registerDefinition, "UsagePlanDefinition")
end
function AssetUsagePlanCoordinator.registerUsagePlanContext(schema: any)
	return register(schema, State.registerContext, "UsagePlanContext")
end
function AssetUsagePlanCoordinator.registerUsagePlanConstraint(schema: any)
	return register(schema, State.registerConstraint, "UsagePlanConstraint")
end
function AssetUsagePlanCoordinator.registerUsagePlanDependency(schema: any)
	return register(schema, State.registerDependency, "UsagePlanDependency")
end
function AssetUsagePlanCoordinator.registerUsagePlanBudget(schema: any)
	return register(schema, State.registerBudget, "UsagePlanBudget")
end
function AssetUsagePlanCoordinator.registerUsagePlanAccessibility(schema: any)
	return register(schema, State.registerAccessibility, "UsagePlanAccessibility")
end
function AssetUsagePlanCoordinator.registerUsagePlanAudit(schema: any)
	return register(schema, State.registerAudit, "UsagePlanAudit")
end

function AssetUsagePlanCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetUsagePlanCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetUsagePlanCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetUsagePlanCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Usage Plan Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetUsagePlanCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetUsagePlanCoordinator
