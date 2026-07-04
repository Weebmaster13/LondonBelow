--!strict

local Diagnostics = require(script.Parent.AssetApprovalLedgerDiagnostics)
local EngineDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.AssetApprovalLedgerSelfChecks)
local Serialization = require(script.Parent.AssetApprovalLedgerSerialization)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.AssetApprovalLedgerSnapshots)
local State = require(script.Parent.AssetApprovalLedgerState)
local Validation = require(script.Parent.AssetApprovalLedgerValidation)

local AssetApprovalLedgerCoordinator = {}

local lifecycle = { initialized = false, started = false, lastSelfChecks = nil :: any }
local log = Logger.scope("AssetApprovalLedger")
local dependencies = { Serialization = Serialization, State = State, Validation = Validation }

local function result(ok: boolean, code: string, message: string?)
	return { ok = ok, code = code, message = message }
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown AssetApprovalLedger validation failure",
			schema
		)
		return result(false, code, reason)
	end
	return result(true, code, nil)
end

function AssetApprovalLedgerCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	EngineDiagnostics.registerSampler("assetApprovalLedgerRuntime", function()
		return AssetApprovalLedgerCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("assetApprovalLedgerRuntime", function()
		return AssetApprovalLedgerCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Asset Approval Ledger Runtime Foundation initialized")
	return result(true, "Initialized", nil)
end

function AssetApprovalLedgerCoordinator.start()
	if not lifecycle.initialized then
		return result(
			false,
			"NotInitialized",
			"Asset Approval Ledger Runtime must initialize before start"
		)
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function AssetApprovalLedgerCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	return result(true, "Shutdown", nil)
end

function AssetApprovalLedgerCoordinator.registerApprovalRecord(schema: any)
	return register(schema, State.registerApproval, "ApprovalRecord")
end

function AssetApprovalLedgerCoordinator.registerApprovalCondition(schema: any)
	return register(schema, State.registerCondition, "ApprovalCondition")
end

function AssetApprovalLedgerCoordinator.registerApprovalRevocation(schema: any)
	return register(schema, State.registerRevocation, "ApprovalRevocation")
end

function AssetApprovalLedgerCoordinator.registerApprovalAudit(schema: any)
	return register(schema, State.registerAudit, "ApprovalAudit")
end

function AssetApprovalLedgerCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function AssetApprovalLedgerCoordinator.getSnapshot()
	return Snapshots.capture(lifecycle, dependencies)
end

function AssetApprovalLedgerCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function AssetApprovalLedgerCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Asset Approval Ledger Runtime self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = AssetApprovalLedgerCoordinator })
	lifecycle.lastSelfChecks = checks
	return checks
end

return AssetApprovalLedgerCoordinator
