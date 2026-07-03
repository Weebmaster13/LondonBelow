--!strict
-- Main orchestrator for Phase 45 Asset Manifest schema infrastructure.

local Diagnostics = require(script.Parent.AssetManifestDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetManifestSelfChecks)
local Serialization = require(script.Parent.AssetManifestSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetManifestSnapshots)
local State = require(script.Parent.AssetManifestState)
local Validation = require(script.Parent.AssetManifestValidation)

local AssetManifestCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetManifest")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(reason or "unknown AssetManifest validation failure", schema)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetManifestCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("assetManifestRuntime", function()
		return AssetManifestCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("assetManifestRuntime", function()
		return AssetManifestCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Manifest Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetManifestCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Manifest Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetManifestCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetManifestCoordinator.registerAssetDefinition(schema: any)
	return register(schema, State.registerDefinition, "AssetDefinition")
end
function AssetManifestCoordinator.registerAssetCategory(schema: any)
	return register(schema, State.registerCategory, "AssetCategory")
end
function AssetManifestCoordinator.registerAssetPackage(schema: any)
	return register(schema, State.registerPackage, "AssetPackage")
end
function AssetManifestCoordinator.registerAssetReference(schema: any)
	return register(schema, State.registerReference, "AssetReference")
end
function AssetManifestCoordinator.registerAssetVariant(schema: any)
	return register(schema, State.registerVariant, "AssetVariant")
end
function AssetManifestCoordinator.registerAssetDependency(schema: any)
	return register(schema, State.registerDependency, "AssetDependency")
end
function AssetManifestCoordinator.registerAssetOwnership(schema: any)
	return register(schema, State.registerOwnership, "AssetOwnership")
end
function AssetManifestCoordinator.registerAssetBudget(schema: any)
	return register(schema, State.registerBudget, "AssetBudget")
end
function AssetManifestCoordinator.registerAssetCompatibility(schema: any)
	return register(schema, State.registerCompatibility, "AssetCompatibility")
end
function AssetManifestCoordinator.registerAssetAudit(schema: any)
	return register(schema, State.registerAudit, "AssetAudit")
end

function AssetManifestCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetManifestCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetManifestCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetManifestCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Manifest Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetManifestCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetManifestCoordinator
