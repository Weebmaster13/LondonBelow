--!strict
-- Main orchestrator for Phase 39 Runtime Scheduler schema infrastructure.

local Diagnostics = require(script.Parent.RuntimeSchedulerDiagnostics)
local SchedulerDiagnostics = require(script.Parent.Parent.Parent.Core.Diagnostics)
local EventBus = require(script.Parent.Parent.Parent.Core.EventBus)
local Logger = require(script.Parent.Parent.Parent.Core.Logger)
local SelfChecks = require(script.Parent.RuntimeSchedulerSelfChecks)
local Signals = require(script.Parent.RuntimeSchedulerSignals)
local SnapshotManager = require(script.Parent.Parent.Parent.Core.SnapshotManager)
local Snapshots = require(script.Parent.RuntimeSchedulerSnapshots)
local State = require(script.Parent.RuntimeSchedulerState)
local Validation = require(script.Parent.RuntimeSchedulerValidation)

local RuntimeSchedulerCoordinator = {}

local lifecycle = {
	initialized = false,
	started = false,
	lastSelfChecks = nil :: any,
}

local log = Logger.scope("RuntimeScheduler")

local dependencies = {
	State = State,
	Validation = Validation,
}

local function result(ok: boolean, code: string, message: string?)
	return {
		ok = ok,
		code = code,
		message = message,
	}
end

local function register(schema: any, callback: (any) -> (boolean, string?), code: string)
	local ok, reason = callback(schema)
	if not ok then
		State.recordValidationFailure(
			reason or "unknown Runtime Scheduler validation failure",
			schema
		)
		EventBus.emit(Signals.Rejected, { code = code, reason = reason })
		return result(false, code, reason)
	end
	EventBus.emit(Signals.Registered, { code = code })
	return result(true, code, nil)
end

function RuntimeSchedulerCoordinator.initialize()
	if lifecycle.initialized then
		return result(true, "AlreadyInitialized", nil)
	end
	local ok, reason = Validation.validate()
	if not ok then
		return result(false, "ValidationFailed", reason)
	end
	SchedulerDiagnostics.registerSampler("runtimeScheduler", function()
		return RuntimeSchedulerCoordinator.inspect()
	end)
	SnapshotManager.registerProvider("runtimeScheduler", function()
		return RuntimeSchedulerCoordinator.getSnapshot()
	end)
	lifecycle.initialized = true
	log.info("Runtime Scheduler Foundation initialized")
	return result(true, "Initialized", nil)
end

function RuntimeSchedulerCoordinator.start()
	if not lifecycle.initialized then
		return result(false, "NotInitialized", "Runtime Scheduler must initialize before start")
	end
	lifecycle.started = true
	return result(true, "Started", nil)
end

function RuntimeSchedulerCoordinator.shutdown()
	State.clear()
	lifecycle.initialized = false
	lifecycle.started = false
	lifecycle.lastSelfChecks = nil
	EventBus.emit(Signals.Shutdown, {})
	return result(true, "Shutdown", nil)
end

function RuntimeSchedulerCoordinator.registerSchedulePlan(schema: any)
	return register(schema, State.registerPlan, "SchedulePlan")
end

function RuntimeSchedulerCoordinator.registerScheduleSlot(schema: any)
	return register(schema, State.registerSlot, "ScheduleSlot")
end

function RuntimeSchedulerCoordinator.registerScheduleQueue(schema: any)
	return register(schema, State.registerQueue, "ScheduleQueue")
end

function RuntimeSchedulerCoordinator.registerSchedulePriority(schema: any)
	return register(schema, State.registerPriority, "SchedulePriority")
end

function RuntimeSchedulerCoordinator.registerScheduleBudget(schema: any)
	return register(schema, State.registerBudget, "ScheduleBudget")
end

function RuntimeSchedulerCoordinator.registerScheduleDeadline(schema: any)
	return register(schema, State.registerDeadline, "ScheduleDeadline")
end

function RuntimeSchedulerCoordinator.registerScheduleRetry(schema: any)
	return register(schema, State.registerRetry, "ScheduleRetry")
end

function RuntimeSchedulerCoordinator.registerScheduleInterval(schema: any)
	return register(schema, State.registerInterval, "ScheduleInterval")
end

function RuntimeSchedulerCoordinator.registerScheduleWindow(schema: any)
	return register(schema, State.registerWindow, "ScheduleWindow")
end

function RuntimeSchedulerCoordinator.registerScheduleDependency(schema: any)
	return register(schema, State.registerDependency, "ScheduleDependency")
end

function RuntimeSchedulerCoordinator.registerScheduleAudit(schema: any)
	return register(schema, State.registerAudit, "ScheduleAudit")
end

function RuntimeSchedulerCoordinator.inspect()
	return Diagnostics.capture(lifecycle, dependencies)
end

function RuntimeSchedulerCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(lifecycle, dependencies)
	EventBus.emit(Signals.SnapshotCaptured, { counts = snapshot.counts })
	return snapshot
end

function RuntimeSchedulerCoordinator.validate()
	return Diagnostics.validate(dependencies)
end

function RuntimeSchedulerCoordinator.runSelfChecks()
	if lifecycle.started then
		return result(
			false,
			"AlreadyStarted",
			"Runtime Scheduler self-checks must run before start"
		)
	end
	local checks = SelfChecks.run({ Service = RuntimeSchedulerCoordinator })
	lifecycle.lastSelfChecks = checks
	EventBus.emit(Signals.SelfChecksCompleted, { ok = checks.ok })
	return checks
end

return RuntimeSchedulerCoordinator
