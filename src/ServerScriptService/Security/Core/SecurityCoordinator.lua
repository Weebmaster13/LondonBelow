--!strict
--[[
	Phase 34 Security / Anti-Exploit Boundary Coordinator.

	Server-authoritative security policy schema foundation. It records future
	trust policies, authority rules, exploit signal definitions, client rejection
	categories, remote safety contracts, rate-limit policies, and audit records.
	It does not detect exploits, punish players, monitor clients, create remotes,
	write DataStores, collect analytics, send telemetry, mutate the world, execute
	gameplay, or create Chapter content.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local AuditRuntime = require(script.Parent.SecurityAuditRuntime)
local AuthorityRuntime = require(script.Parent.SecurityAuthorityRuntime)
local ClientRejectionRuntime = require(script.Parent.SecurityClientRejectionRuntime)
local ExploitSignalRuntime = require(script.Parent.SecurityExploitSignalRuntime)
local RateLimitRuntime = require(script.Parent.SecurityRateLimitRuntime)
local RemoteSafetyRuntime = require(script.Parent.SecurityRemoteSafetyRuntime)
local SecurityDiagnostics = require(script.Parent.SecurityDiagnostics)
local SelfChecks = require(script.Parent.SecuritySelfChecks)
local Serialization = require(script.Parent.SecuritySerialization)
local Signals = require(script.Parent.SecuritySignals)
local Snapshots = require(script.Parent.SecuritySnapshots)
local State = require(script.Parent.SecurityState)
local TrustPolicyRuntime = require(script.Parent.SecurityTrustPolicyRuntime)
local Types = require(script.Parent.SecurityTypes)
local Validation = require(script.Parent.SecurityValidation)

local SecurityCoordinator = {}

local log = Logger.scope("SecurityBoundary")
local initialized = false
local started = false
local lastSelfChecks: any = nil

local dependencies = {
	State = State,
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
	if reason == "duplicate trustPolicyId" then
		return Types.ResultCode.DuplicateTrustPolicy
	elseif reason == "duplicate authorityRuleId" then
		return Types.ResultCode.DuplicateAuthorityRule
	elseif reason == "duplicate exploitSignalId" then
		return Types.ResultCode.DuplicateExploitSignal
	elseif reason == "duplicate clientRejectionId" then
		return Types.ResultCode.DuplicateClientRejection
	elseif reason == "duplicate remoteSafetyId" then
		return Types.ResultCode.DuplicateRemoteSafety
	elseif reason == "duplicate rateLimitId" then
		return Types.ResultCode.DuplicateRateLimit
	elseif reason == "duplicate auditId" then
		return Types.ResultCode.DuplicateAudit
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
	State.recordValidationFailure(reason, payload)
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

function SecurityCoordinator.registerTrustPolicy(schema: any)
	local ok, reason = TrustPolicyRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "trust policy rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.TrustPolicyRegistered,
		{ trustPolicyId = schema.trustPolicyId }
	)
	return result(true, Types.ResultCode.Ok, "trust policy schema registered")
end

function SecurityCoordinator.registerAuthorityRule(schema: any)
	local ok, reason = AuthorityRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "authority rule rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.AuthorityRuleRegistered,
		{ authorityRuleId = schema.authorityRuleId }
	)
	return result(true, Types.ResultCode.Ok, "authority rule schema registered")
end

function SecurityCoordinator.registerExploitSignal(schema: any)
	local ok, reason = ExploitSignalRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "exploit signal rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.ExploitSignalRegistered,
		{ exploitSignalId = schema.exploitSignalId }
	)
	return result(true, Types.ResultCode.Ok, "exploit signal schema registered")
end

function SecurityCoordinator.registerClientRejection(schema: any)
	local ok, reason = ClientRejectionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "client rejection rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.ClientRejectionRegistered,
		{ clientRejectionId = schema.clientRejectionId }
	)
	return result(true, Types.ResultCode.Ok, "client rejection schema registered")
end

function SecurityCoordinator.registerRemoteSafety(schema: any)
	local ok, reason = RemoteSafetyRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "remote safety rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.RemoteSafetyRegistered,
		{ remoteSafetyId = schema.remoteSafetyId }
	)
	return result(true, Types.ResultCode.Ok, "remote safety schema registered")
end

function SecurityCoordinator.registerRateLimit(schema: any)
	local ok, reason = RateLimitRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "rate-limit policy rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.RateLimitRegistered, { rateLimitId = schema.rateLimitId })
	return result(true, Types.ResultCode.Ok, "rate-limit policy schema registered")
end

function SecurityCoordinator.registerAudit(record: any)
	local ok, reason = AuditRuntime.record(State, record)
	if not ok then
		recordFailure(reason or "audit record rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.AuditRegistered, { auditId = record.auditId })
	return result(true, Types.ResultCode.Ok, "audit record schema registered")
end

function SecurityCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = SecurityCoordinator.validate()
	if not valid then
		error("SecurityCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("securityBoundary", SecurityCoordinator.inspect)
	SnapshotManager.registerProvider("securityBoundary", SecurityCoordinator.getSnapshot)
	initialized = true
	log.success("Security Boundary initialized")
end

function SecurityCoordinator.start()
	if started then
		return
	end
	if not initialized then
		SecurityCoordinator.initialize()
	end
	started = true
end

function SecurityCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function SecurityCoordinator.inspect()
	return SecurityDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function SecurityCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(State)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function SecurityCoordinator.validate(): (boolean, string?)
	return SecurityDiagnostics.validate(dependencies)
end

function SecurityCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Security Boundary self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = SecurityCoordinator })
	return lastSelfChecks
end

return SecurityCoordinator
