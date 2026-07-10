--!strict

local Diagnostics = require(script.Parent.AssetGovernanceIntegrationDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetGovernanceIntegrationSelfChecks)
local Serialization = require(script.Parent.AssetGovernanceIntegrationSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetGovernanceIntegrationSnapshots)
local State = require(script.Parent.AssetGovernanceIntegrationState)
local Types = require(script.Parent.AssetGovernanceIntegrationTypes)
local Validation = require(script.Parent.AssetGovernanceIntegrationValidation)

local AssetGovernanceIntegrationCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetGovernanceIntegration")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetGovernanceIntegration validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetGovernanceIntegrationCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetGovernanceIntegrationCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetGovernanceIntegrationCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Governance Integration Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetGovernanceIntegrationCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Governance Integration Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetGovernanceIntegrationCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetGovernanceIntegrationCoordinator.registerGovernanceChain(schema: any)
	return register(schema, State.registerChain, "GovernanceChain")
end

function AssetGovernanceIntegrationCoordinator.registerGovernanceRuntimeNode(schema: any)
	return register(schema, State.registerRuntimeNode, "GovernanceRuntimeNode")
end

function AssetGovernanceIntegrationCoordinator.registerGovernanceReferenceReview(schema: any)
	return register(schema, State.registerReferenceReview, "GovernanceReferenceReview")
end

function AssetGovernanceIntegrationCoordinator.registerGovernanceIntegrationAudit(schema: any)
	return register(schema, State.registerAudit, "GovernanceIntegrationAudit")
end

function AssetGovernanceIntegrationCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetGovernanceIntegrationCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetGovernanceIntegrationCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetGovernanceIntegrationCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Governance Integration self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetGovernanceIntegrationCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetGovernanceIntegrationCoordinator
