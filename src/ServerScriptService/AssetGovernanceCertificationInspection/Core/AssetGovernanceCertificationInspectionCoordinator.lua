--!strict

local Diagnostics = require(script.Parent.AssetGovernanceCertificationInspectionDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetGovernanceCertificationInspectionSelfChecks)
local Serialization = require(script.Parent.AssetGovernanceCertificationInspectionSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetGovernanceCertificationInspectionSnapshots)
local State = require(script.Parent.AssetGovernanceCertificationInspectionState)
local Types = require(script.Parent.AssetGovernanceCertificationInspectionTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationInspectionValidation)

local AssetGovernanceCertificationInspectionCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetGovernanceCertificationInspection")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetGovernanceCertificationInspection validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetGovernanceCertificationInspectionCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetGovernanceCertificationInspectionCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetGovernanceCertificationInspectionCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Governance Certification Live Inspection Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetGovernanceCertificationInspectionCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Governance Certification Inspection Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetGovernanceCertificationInspectionCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetGovernanceCertificationInspectionCoordinator.registerGovernanceInspection(schema: any)
	return register(schema, State.registerInspection, "GovernanceInspection")
end

function AssetGovernanceCertificationInspectionCoordinator.registerGovernanceInspectionObservation(
	schema: any
)
	return register(schema, State.registerObservation, "GovernanceInspectionObservation")
end

function AssetGovernanceCertificationInspectionCoordinator.registerGovernanceInspectionFinding(
	schema: any
)
	return register(schema, State.registerFinding, "GovernanceInspectionFinding")
end

function AssetGovernanceCertificationInspectionCoordinator.registerGovernanceInspectionAudit(
	schema: any
)
	return register(schema, State.registerAudit, "GovernanceInspectionAudit")
end

function AssetGovernanceCertificationInspectionCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetGovernanceCertificationInspectionCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetGovernanceCertificationInspectionCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetGovernanceCertificationInspectionCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Governance Certification Inspection self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetGovernanceCertificationInspectionCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetGovernanceCertificationInspectionCoordinator
