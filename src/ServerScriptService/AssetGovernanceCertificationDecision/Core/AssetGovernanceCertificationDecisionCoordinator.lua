--!strict

local Diagnostics = require(script.Parent.AssetGovernanceCertificationDecisionDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetGovernanceCertificationDecisionSelfChecks)
local Serialization = require(script.Parent.AssetGovernanceCertificationDecisionSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetGovernanceCertificationDecisionSnapshots)
local State = require(script.Parent.AssetGovernanceCertificationDecisionState)
local Types = require(script.Parent.AssetGovernanceCertificationDecisionTypes)
local Validation = require(script.Parent.AssetGovernanceCertificationDecisionValidation)

local AssetGovernanceCertificationDecisionCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetGovernanceCertificationDecision")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetGovernanceCertificationDecision validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetGovernanceCertificationDecisionCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler(Types.RuntimeProviderName, function()
		return AssetGovernanceCertificationDecisionCoordinator.inspect()
	end)
	SnapshotManager.registerProvider(Types.RuntimeProviderName, function()
		return AssetGovernanceCertificationDecisionCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Governance Certification Decision Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetGovernanceCertificationDecisionCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Governance Certification Decision Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetGovernanceCertificationDecisionCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetGovernanceCertificationDecisionCoordinator.registerGovernanceDecision(schema: any)
	return register(schema, State.registerDecision, "GovernanceDecision")
end

function AssetGovernanceCertificationDecisionCoordinator.registerGovernanceDecisionRequirement(
	schema: any
)
	return register(schema, State.registerRequirement, "GovernanceDecisionRequirement")
end

function AssetGovernanceCertificationDecisionCoordinator.registerGovernanceDecisionEvaluation(
	schema: any
)
	return register(schema, State.registerEvaluation, "GovernanceDecisionEvaluation")
end

function AssetGovernanceCertificationDecisionCoordinator.registerGovernanceDecisionAudit(
	schema: any
)
	return register(schema, State.registerAudit, "GovernanceDecisionAudit")
end

function AssetGovernanceCertificationDecisionCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetGovernanceCertificationDecisionCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetGovernanceCertificationDecisionCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetGovernanceCertificationDecisionCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Governance Certification Decision self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetGovernanceCertificationDecisionCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetGovernanceCertificationDecisionCoordinator
