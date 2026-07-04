--!strict

local Diagnostics = require(script.Parent.AssetReadinessReviewDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetReadinessReviewSelfChecks)
local Serialization = require(script.Parent.AssetReadinessReviewSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetReadinessReviewSnapshots)
local State = require(script.Parent.AssetReadinessReviewState)
local Validation = require(script.Parent.AssetReadinessReviewValidation)

local AssetReadinessReviewCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetReadinessReview")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetReadinessReview validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetReadinessReviewCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("assetReadinessReviewRuntime", function()
		return AssetReadinessReviewCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("assetReadinessReviewRuntime", function()
		return AssetReadinessReviewCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Readiness Review Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetReadinessReviewCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Readiness Review Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetReadinessReviewCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetReadinessReviewCoordinator.registerReadinessChecklist(schema: any)
	return register(schema, State.registerChecklist, "ReadinessChecklist")
end

function AssetReadinessReviewCoordinator.registerReadinessFinding(schema: any)
	return register(schema, State.registerFinding, "ReadinessFinding")
end

function AssetReadinessReviewCoordinator.registerReadinessGate(schema: any)
	return register(schema, State.registerGate, "ReadinessGate")
end

function AssetReadinessReviewCoordinator.registerReadinessDecision(schema: any)
	return register(schema, State.registerDecision, "ReadinessDecision")
end

function AssetReadinessReviewCoordinator.registerReadinessAudit(schema: any)
	return register(schema, State.registerAudit, "ReadinessAudit")
end

function AssetReadinessReviewCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetReadinessReviewCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetReadinessReviewCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetReadinessReviewCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Readiness Review Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetReadinessReviewCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetReadinessReviewCoordinator
