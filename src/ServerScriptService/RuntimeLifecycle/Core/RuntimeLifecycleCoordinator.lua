--!strict
--[[
	Phase 38 Runtime Lifecycle Coordinator.

	Server-authoritative lifecycle schema foundation. It records lifecycle state,
	transition, policy, guard, event, failure, recovery, checkpoint, audit, and
	compatibility schemas. It never starts, stops, initializes, restarts,
	recovers, pauses, resumes, unloads, reloads, orchestrates, manages, injects,
	resolves, loads, requires, or calls any live runtime.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local AuditRuntime = require(script.Parent.LifecycleAuditRuntime)
local CheckpointRuntime = require(script.Parent.LifecycleCheckpointRuntime)
local CompatibilityRuntime = require(script.Parent.LifecycleCompatibilityRuntime)
local EventRuntime = require(script.Parent.LifecycleEventRuntime)
local FailureRuntime = require(script.Parent.LifecycleFailureRuntime)
local GuardRuntime = require(script.Parent.LifecycleGuardRuntime)
local LifecycleDiagnostics = require(script.Parent.RuntimeLifecycleDiagnostics)
local PolicyRuntime = require(script.Parent.LifecyclePolicyRuntime)
local RecoveryRuntime = require(script.Parent.LifecycleRecoveryRuntime)
local SelfChecks = require(script.Parent.RuntimeLifecycleSelfChecks)
local Serialization = require(script.Parent.RuntimeLifecycleSerialization)
local Signals = require(script.Parent.RuntimeLifecycleSignals)
local Snapshots = require(script.Parent.RuntimeLifecycleSnapshots)
local State = require(script.Parent.RuntimeLifecycleState)
local StateRuntime = require(script.Parent.LifecycleStateRuntime)
local TransitionRuntime = require(script.Parent.LifecycleTransitionRuntime)
local Types = require(script.Parent.RuntimeLifecycleTypes)
local Validation = require(script.Parent.RuntimeLifecycleValidation)

local RuntimeLifecycleCoordinator = {}

local log = Logger.scope("RuntimeLifecycle")
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
	if reason == "duplicate lifecycleStateId" then
		return Types.ResultCode.DuplicateState
	elseif reason == "duplicate transitionId" then
		return Types.ResultCode.DuplicateTransition
	elseif reason == "duplicate policyId" then
		return Types.ResultCode.DuplicatePolicy
	elseif reason == "duplicate guardId" then
		return Types.ResultCode.DuplicateGuard
	elseif reason == "duplicate eventId" then
		return Types.ResultCode.DuplicateEvent
	elseif reason == "duplicate failureId" then
		return Types.ResultCode.DuplicateFailure
	elseif reason == "duplicate recoveryId" then
		return Types.ResultCode.DuplicateRecovery
	elseif reason == "duplicate checkpointId" then
		return Types.ResultCode.DuplicateCheckpoint
	elseif reason == "duplicate auditId" then
		return Types.ResultCode.DuplicateAudit
	elseif reason == "duplicate compatibilityId" then
		return Types.ResultCode.DuplicateCompatibility
	elseif
		reason ~= nil
		and (
			string.find(reason, "payload", 1, true)
			or string.find(reason, "forbidden", 1, true)
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

local function register(schema: any, runtime: any, signal: string, payload: any, success: string)
	local ok, reason = runtime.register(State, schema)
	if not ok then
		recordFailure(reason or "runtime lifecycle schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(signal, payload)
	return result(true, Types.ResultCode.Ok, success)
end

function RuntimeLifecycleCoordinator.registerLifecycleState(schema: any)
	return register(
		schema,
		StateRuntime,
		Signals.StateRegistered,
		{ lifecycleStateId = schema.lifecycleStateId },
		"lifecycle state registered"
	)
end

function RuntimeLifecycleCoordinator.registerTransition(schema: any)
	return register(
		schema,
		TransitionRuntime,
		Signals.TransitionRegistered,
		{ transitionId = schema.transitionId },
		"transition registered"
	)
end

function RuntimeLifecycleCoordinator.registerPolicy(schema: any)
	return register(
		schema,
		PolicyRuntime,
		Signals.PolicyRegistered,
		{ policyId = schema.policyId },
		"policy registered"
	)
end

function RuntimeLifecycleCoordinator.registerGuard(schema: any)
	return register(
		schema,
		GuardRuntime,
		Signals.GuardRegistered,
		{ guardId = schema.guardId },
		"guard registered"
	)
end

function RuntimeLifecycleCoordinator.registerEvent(schema: any)
	return register(
		schema,
		EventRuntime,
		Signals.EventRegistered,
		{ eventId = schema.eventId },
		"event registered"
	)
end

function RuntimeLifecycleCoordinator.registerFailure(schema: any)
	return register(
		schema,
		FailureRuntime,
		Signals.FailureRegistered,
		{ failureId = schema.failureId },
		"failure registered"
	)
end

function RuntimeLifecycleCoordinator.registerRecovery(schema: any)
	return register(
		schema,
		RecoveryRuntime,
		Signals.RecoveryRegistered,
		{ recoveryId = schema.recoveryId },
		"recovery registered"
	)
end

function RuntimeLifecycleCoordinator.registerCheckpoint(schema: any)
	return register(
		schema,
		CheckpointRuntime,
		Signals.CheckpointRegistered,
		{ checkpointId = schema.checkpointId },
		"checkpoint registered"
	)
end

function RuntimeLifecycleCoordinator.registerAudit(schema: any)
	return register(
		schema,
		AuditRuntime,
		Signals.AuditRegistered,
		{ auditId = schema.auditId },
		"audit registered"
	)
end

function RuntimeLifecycleCoordinator.registerCompatibility(schema: any)
	return register(
		schema,
		CompatibilityRuntime,
		Signals.CompatibilityRegistered,
		{ compatibilityId = schema.compatibilityId },
		"compatibility registered"
	)
end

function RuntimeLifecycleCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = RuntimeLifecycleCoordinator.validate()
	if not valid then
		error("RuntimeLifecycleCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("runtimeLifecycle", RuntimeLifecycleCoordinator.inspect)
	SnapshotManager.registerProvider("runtimeLifecycle", RuntimeLifecycleCoordinator.getSnapshot)
	initialized = true
	log.success("Runtime Lifecycle initialized")
end

function RuntimeLifecycleCoordinator.start()
	if started then
		return
	end
	if not initialized then
		RuntimeLifecycleCoordinator.initialize()
	end
	started = true
end

function RuntimeLifecycleCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function RuntimeLifecycleCoordinator.inspect()
	return LifecycleDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function RuntimeLifecycleCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(State)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function RuntimeLifecycleCoordinator.validate(): (boolean, string?)
	return LifecycleDiagnostics.validate(dependencies)
end

function RuntimeLifecycleCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Runtime Lifecycle self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = RuntimeLifecycleCoordinator })
	return lastSelfChecks
end

return RuntimeLifecycleCoordinator
