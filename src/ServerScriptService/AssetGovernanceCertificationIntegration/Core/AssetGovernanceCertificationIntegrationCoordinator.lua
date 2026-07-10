--!strict

local Diagnostics = require(script.Parent.AssetGovernanceCertificationIntegrationDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetGovernanceCertificationIntegrationSelfChecks)
local Serialization = require(script.Parent.AssetGovernanceCertificationIntegrationSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetGovernanceCertificationIntegrationSnapshots)
local State = require(script.Parent.AssetGovernanceCertificationIntegrationState)
local Types = require(script.Parent.AssetGovernanceCertificationIntegrationTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationIntegrationValidation)

local AssetGovernanceCertificationIntegrationCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetGovernanceCertificationIntegration")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetGovernanceCertificationIntegration validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetGovernanceCertificationIntegrationCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetGovernanceCertificationIntegrationCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetGovernanceCertificationIntegrationCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Governance Certification Integration Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetGovernanceCertificationIntegrationCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Governance Certification Integration Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetGovernanceCertificationIntegrationCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetGovernanceCertificationIntegrationCoordinator.registerGovernanceCertificationIntegration(
	schema: any
)
	return register(schema, State.registerIntegration, "GovernanceCertificationIntegration")
end

function AssetGovernanceCertificationIntegrationCoordinator.registerGovernanceCertificationIntegrationChain(
	schema: any
)
	return register(schema, State.registerChain, "GovernanceCertificationIntegrationChain")
end

function AssetGovernanceCertificationIntegrationCoordinator.registerGovernanceCertificationIntegrationReview(
	schema: any
)
	return register(schema, State.registerReview, "GovernanceCertificationIntegrationReview")
end

function AssetGovernanceCertificationIntegrationCoordinator.registerGovernanceCertificationIntegrationAudit(
	schema: any
)
	return register(schema, State.registerAudit, "GovernanceCertificationIntegrationAudit")
end

function AssetGovernanceCertificationIntegrationCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetGovernanceCertificationIntegrationCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetGovernanceCertificationIntegrationCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetGovernanceCertificationIntegrationCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Governance Certification Integration self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetGovernanceCertificationIntegrationCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetGovernanceCertificationIntegrationCoordinator
