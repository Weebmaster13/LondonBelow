--!strict

local Diagnostics = require(script.Parent.AssetGovernanceCertificationDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetGovernanceCertificationSelfChecks)
local Serialization = require(script.Parent.AssetGovernanceCertificationSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetGovernanceCertificationSnapshots)
local State = require(script.Parent.AssetGovernanceCertificationState)
local Types = require(script.Parent.AssetGovernanceCertificationTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationValidation)

local AssetGovernanceCertificationCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetGovernanceCertification")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetGovernanceCertification validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetGovernanceCertificationCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetGovernanceCertificationCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetGovernanceCertificationCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Governance Certification Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetGovernanceCertificationCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Governance Certification Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetGovernanceCertificationCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetGovernanceCertificationCoordinator.registerGovernanceCertification(schema: any)
	return register(schema, State.registerCertification, "GovernanceCertification")
end

function AssetGovernanceCertificationCoordinator.registerGovernanceCertificationRequirement(
	schema: any
)
	return register(schema, State.registerRequirement, "GovernanceCertificationRequirement")
end

function AssetGovernanceCertificationCoordinator.registerGovernanceCertificationResult(schema: any)
	return register(schema, State.registerResult, "GovernanceCertificationResult")
end

function AssetGovernanceCertificationCoordinator.registerGovernanceCertificationAudit(schema: any)
	return register(schema, State.registerAudit, "GovernanceCertificationAudit")
end

function AssetGovernanceCertificationCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetGovernanceCertificationCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetGovernanceCertificationCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetGovernanceCertificationCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Governance Certification self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetGovernanceCertificationCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetGovernanceCertificationCoordinator
