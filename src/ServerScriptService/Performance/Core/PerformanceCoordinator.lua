--!strict
--[[
	Phase 33 Performance Budget Runtime Coordinator.

	Server-authoritative Performance Budget Runtime schema foundation. It records
	future CPU, memory, network, render, runtime category, warning threshold, and
	report schemas. It does not profile live runtime behavior, optimize systems,
	throttle work, collect analytics, send telemetry, mutate memory/network/render
	state, monitor clients, expose remotes, mutate the world, execute gameplay, or
	create Chapter content.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local BudgetRuntime = require(script.Parent.PerformanceBudgetRuntime)
local CategoryRuntime = require(script.Parent.PerformanceCategoryRuntime)
local PerformanceDiagnostics = require(script.Parent.PerformanceDiagnostics)
local ReportRuntime = require(script.Parent.PerformanceReportRuntime)
local SelfChecks = require(script.Parent.PerformanceSelfChecks)
local Serialization = require(script.Parent.PerformanceSerialization)
local Signals = require(script.Parent.PerformanceSignals)
local Snapshots = require(script.Parent.PerformanceSnapshots)
local State = require(script.Parent.PerformanceState)
local ThresholdRuntime = require(script.Parent.PerformanceThresholdRuntime)
local Types = require(script.Parent.PerformanceTypes)
local Validation = require(script.Parent.PerformanceValidation)

local PerformanceCoordinator = {}

local log = Logger.scope("PerformanceBudgetRuntime")
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
	if reason == "duplicate budgetId" then
		return Types.ResultCode.DuplicateBudget
	elseif reason == "duplicate categoryId" then
		return Types.ResultCode.DuplicateCategory
	elseif reason == "duplicate thresholdId" then
		return Types.ResultCode.DuplicateThreshold
	elseif reason == "duplicate reportId" then
		return Types.ResultCode.DuplicateReport
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

function PerformanceCoordinator.registerBudget(schema: any)
	local ok, reason = BudgetRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "performance budget rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.BudgetRegistered, { budgetId = schema.budgetId })
	return result(true, Types.ResultCode.Ok, "performance budget schema registered")
end

function PerformanceCoordinator.registerCategory(schema: any)
	local ok, reason = CategoryRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "performance category rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.CategoryRegistered, { categoryId = schema.categoryId })
	return result(true, Types.ResultCode.Ok, "performance category schema registered")
end

function PerformanceCoordinator.registerThreshold(schema: any)
	local ok, reason = ThresholdRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "performance threshold rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ThresholdRegistered, { thresholdId = schema.thresholdId })
	return result(true, Types.ResultCode.Ok, "performance threshold schema registered")
end

function PerformanceCoordinator.registerReport(record: any)
	local ok, reason = ReportRuntime.record(State, record)
	if not ok then
		recordFailure(reason or "performance report rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ReportRegistered, { reportId = record.reportId })
	return result(true, Types.ResultCode.Ok, "performance report schema registered")
end

function PerformanceCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = PerformanceCoordinator.validate()
	if not valid then
		error("PerformanceCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("performanceBudgetRuntime", PerformanceCoordinator.inspect)
	SnapshotManager.registerProvider("performanceBudgetRuntime", PerformanceCoordinator.getSnapshot)
	initialized = true
	log.success("Performance Budget Runtime initialized")
end

function PerformanceCoordinator.start()
	if started then
		return
	end
	if not initialized then
		PerformanceCoordinator.initialize()
	end
	started = true
end

function PerformanceCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function PerformanceCoordinator.inspect()
	return PerformanceDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function PerformanceCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(State)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function PerformanceCoordinator.validate(): (boolean, string?)
	return PerformanceDiagnostics.validate(dependencies)
end

function PerformanceCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Performance Budget Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = PerformanceCoordinator })
	return lastSelfChecks
end

return PerformanceCoordinator
