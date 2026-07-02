--!strict
--[[
	Phase 29 Data Persistence Boundary Coordinator.

	Server-authoritative persistence boundary schema foundation. It records
	future persistence requests, save/load packages, migrations, policies, and
	failures. It does not perform DataStore reads/writes, live persistence,
	profile loading, cloud saves, migration execution, save mutation, remotes,
	client authority, Workspace mutation, or Chapter content.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local FailureRuntime = require(script.Parent.PersistenceFailureRuntime)
local MigrationRuntime = require(script.Parent.PersistenceMigrationRuntime)
local PackageRuntime = require(script.Parent.PersistencePackageRuntime)
local PolicyRuntime = require(script.Parent.PersistencePolicyRuntime)
local RequestRuntime = require(script.Parent.PersistenceRequestRuntime)
local PersistenceDiagnostics = require(script.Parent.PersistenceDiagnostics)
local SelfChecks = require(script.Parent.PersistenceSelfChecks)
local Serialization = require(script.Parent.PersistenceSerialization)
local Signals = require(script.Parent.PersistenceSignals)
local Snapshots = require(script.Parent.PersistenceSnapshots)
local Types = require(script.Parent.PersistenceTypes)
local Validation = require(script.Parent.PersistenceValidation)

local PersistenceCoordinator = {}

local log = Logger.scope("PersistenceBoundary")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	State = RequestRuntime,
	Validation = Validation,
}

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

local function codeFor(reason: string?): string
	if reason == "duplicate requestId" then
		return Types.ResultCode.DuplicateRequest
	elseif reason == "duplicate packageId" then
		return Types.ResultCode.DuplicatePackage
	elseif reason == "duplicate policyId" then
		return Types.ResultCode.DuplicatePolicy
	elseif
		reason ~= nil
		and (
			string.find(reason, "payload", 1, true)
			or string.find(reason, "forbidden field", 1, true)
			or string.find(reason, "unsafe runtime", 1, true)
			or string.find(reason, "cyclic", 1, true)
		)
	then
		return Types.ResultCode.UnsafePayload
	end
	return Types.ResultCode.InvalidRequest
end

local function recordFailure(reason: string, payload: any?)
	RequestRuntime.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

function PersistenceCoordinator.registerRequest(schema: any)
	local ok, reason = RequestRuntime.registerRequest(schema)
	if not ok then
		recordFailure(reason or "persistence request rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.RequestRegistered, { requestId = schema.requestId })
	return result(true, Types.ResultCode.Ok, "persistence request schema registered")
end

function PersistenceCoordinator.registerPackage(schema: any)
	local ok, reason = PackageRuntime.register(RequestRuntime, schema)
	if not ok then
		recordFailure(reason or "persistence package rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.PackageRegistered, { packageId = schema.packageId })
	return result(true, Types.ResultCode.Ok, "persistence package schema registered")
end

function PersistenceCoordinator.registerMigration(schema: any)
	local ok, reason = MigrationRuntime.register(RequestRuntime, schema)
	if not ok then
		recordFailure(reason or "migration schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.MigrationRegistered, { migrationId = schema.migrationId })
	return result(true, Types.ResultCode.Ok, "migration schema registered")
end

function PersistenceCoordinator.registerWritePolicy(schema: any)
	local ok, reason = PolicyRuntime.registerWritePolicy(RequestRuntime, schema)
	if not ok then
		recordFailure(reason or "write policy rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.PolicyRegistered, { policyId = schema.policyId })
	return result(true, Types.ResultCode.Ok, "write policy schema registered")
end

function PersistenceCoordinator.registerRetryPolicy(schema: any)
	local ok, reason = PolicyRuntime.registerRetryPolicy(RequestRuntime, schema)
	if not ok then
		recordFailure(reason or "retry policy rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.PolicyRegistered, { policyId = schema.policyId })
	return result(true, Types.ResultCode.Ok, "retry policy schema registered")
end

function PersistenceCoordinator.recordFailure(record: any)
	local ok, reason = FailureRuntime.record(RequestRuntime, record)
	if not ok then
		recordFailure(reason or "failure record rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.FailureRecorded, { failureId = record.failureId })
	return result(true, Types.ResultCode.Ok, "failure record stored")
end

function PersistenceCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = PersistenceCoordinator.validate()
	if not valid then
		error("PersistenceCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("PersistenceBoundary", PersistenceCoordinator.inspect)
	SnapshotManager.registerProvider("persistenceBoundary", PersistenceCoordinator.getSnapshot)
	initialized = true
	log.success("Persistence Boundary initialized")
end

function PersistenceCoordinator.start()
	if started then
		return
	end
	if not initialized then
		PersistenceCoordinator.initialize()
	end
	started = true
end

function PersistenceCoordinator.shutdown()
	RequestRuntime.clear()
	started = false
	initialized = false
end

function PersistenceCoordinator.inspect()
	return PersistenceDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function PersistenceCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(RequestRuntime)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function PersistenceCoordinator.validate(): (boolean, string?)
	return PersistenceDiagnostics.validate(dependencies)
end

function PersistenceCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Persistence Boundary self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = PersistenceCoordinator })
	return lastSelfChecks
end

return PersistenceCoordinator
