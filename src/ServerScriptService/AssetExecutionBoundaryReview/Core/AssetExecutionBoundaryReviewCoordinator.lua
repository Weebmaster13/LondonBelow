--!strict

local Diagnostics = require(script.Parent.AssetExecutionBoundaryReviewDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetExecutionBoundaryReviewSelfChecks)
local Serialization = require(script.Parent.AssetExecutionBoundaryReviewSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetExecutionBoundaryReviewSnapshots)
local State = require(script.Parent.AssetExecutionBoundaryReviewState)
local Validation = require(script.Parent.AssetExecutionBoundaryReviewValidation)

local AssetExecutionBoundaryReviewCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetExecutionBoundaryReview")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetExecutionBoundaryReview validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetExecutionBoundaryReviewCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("assetExecutionBoundaryReviewRuntime", function()
		return AssetExecutionBoundaryReviewCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("assetExecutionBoundaryReviewRuntime", function()
		return AssetExecutionBoundaryReviewCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Execution Boundary Review Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetExecutionBoundaryReviewCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Execution Boundary Review Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetExecutionBoundaryReviewCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetExecutionBoundaryReviewCoordinator.registerBoundaryReview(schema: any)
	return register(schema, State.registerReview, "BoundaryReview")
end

function AssetExecutionBoundaryReviewCoordinator.registerBoundaryRisk(schema: any)
	return register(schema, State.registerRisk, "BoundaryRisk")
end

function AssetExecutionBoundaryReviewCoordinator.registerBoundaryRequirement(schema: any)
	return register(schema, State.registerRequirement, "BoundaryRequirement")
end

function AssetExecutionBoundaryReviewCoordinator.registerBoundaryAudit(schema: any)
	return register(schema, State.registerAudit, "BoundaryReviewAudit")
end

function AssetExecutionBoundaryReviewCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetExecutionBoundaryReviewCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetExecutionBoundaryReviewCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetExecutionBoundaryReviewCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Execution Boundary Review Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetExecutionBoundaryReviewCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetExecutionBoundaryReviewCoordinator
