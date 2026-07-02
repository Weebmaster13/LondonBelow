--!strict
--[[
	Phase 31 Analytics Boundary Coordinator.

	Server-authoritative Analytics Boundary schema foundation. It records future
	analytics event schemas, metric definitions, aggregation schemas, consent
	and eligibility schemas, retention policy schemas, and report schemas. It
	does not collect analytics, send telemetry, track players, report externally,
	moderate, profile, expose remotes, mutate Workspace, call DataStores, or
	create player-facing UI.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local AggregationRuntime = require(script.Parent.AnalyticsAggregationRuntime)
local DefinitionRuntime = require(script.Parent.AnalyticsEventRuntime)
local ConsentRuntime = require(script.Parent.AnalyticsConsentRuntime)
local MetricRuntime = require(script.Parent.AnalyticsMetricRuntime)
local ReportRuntime = require(script.Parent.AnalyticsReportRuntime)
local RetentionRuntime = require(script.Parent.AnalyticsRetentionRuntime)
local SelfChecks = require(script.Parent.AnalyticsSelfChecks)
local Serialization = require(script.Parent.AnalyticsSerialization)
local Signals = require(script.Parent.AnalyticsSignals)
local Snapshots = require(script.Parent.AnalyticsSnapshots)
local State = require(script.Parent.AnalyticsState)
local AnalyticsDiagnostics = require(script.Parent.AnalyticsDiagnostics)
local Types = require(script.Parent.AnalyticsTypes)
local Validation = require(script.Parent.AnalyticsValidation)

local AnalyticsCoordinator = {}

local log = Logger.scope("AnalyticsBoundary")
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
	if reason == "duplicate eventId" then
		return Types.ResultCode.DuplicateEvent
	elseif reason == "duplicate metricId" then
		return Types.ResultCode.DuplicateMetric
	elseif reason == "duplicate aggregationId" then
		return Types.ResultCode.DuplicateAggregation
	elseif reason == "duplicate consentId" then
		return Types.ResultCode.DuplicateConsent
	elseif reason == "duplicate retentionId" then
		return Types.ResultCode.DuplicateRetention
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

function AnalyticsCoordinator.registerEvent(schema: any)
	local ok, reason = DefinitionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "analytics event rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.EventRegistered, { eventId = schema.eventId })
	return result(true, Types.ResultCode.Ok, "analytics event schema registered")
end

function AnalyticsCoordinator.registerMetric(schema: any)
	local ok, reason = MetricRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "metric definition rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.MetricRegistered, { metricId = schema.metricId })
	return result(true, Types.ResultCode.Ok, "metric definition schema registered")
end

function AnalyticsCoordinator.registerAggregation(schema: any)
	local ok, reason = AggregationRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "aggregation schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.AggregationRegistered,
		{ aggregationId = schema.aggregationId }
	)
	return result(true, Types.ResultCode.Ok, "aggregation schema registered")
end

function AnalyticsCoordinator.registerConsent(schema: any)
	local ok, reason = ConsentRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "consent schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ConsentRegistered, { consentId = schema.consentId })
	return result(true, Types.ResultCode.Ok, "consent schema registered")
end

function AnalyticsCoordinator.registerRetention(schema: any)
	local ok, reason = RetentionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "retention policy schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.RetentionRegistered, { retentionId = schema.retentionId })
	return result(true, Types.ResultCode.Ok, "retention policy schema registered")
end

function AnalyticsCoordinator.registerReport(record: any)
	local ok, reason = ReportRuntime.record(State, record)
	if not ok then
		recordFailure(reason or "report schema rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ReportRegistered, { reportId = record.reportId })
	return result(true, Types.ResultCode.Ok, "report schema stored")
end

function AnalyticsCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = AnalyticsCoordinator.validate()
	if not valid then
		error("AnalyticsCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("AnalyticsBoundary", AnalyticsCoordinator.inspect)
	SnapshotManager.registerProvider("analyticsBoundary", AnalyticsCoordinator.getSnapshot)
	initialized = true
	log.success("Analytics Boundary initialized")
end

function AnalyticsCoordinator.start()
	if started then
		return
	end
	if not initialized then
		AnalyticsCoordinator.initialize()
	end
	started = true
end

function AnalyticsCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function AnalyticsCoordinator.inspect()
	return AnalyticsDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function AnalyticsCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(State)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function AnalyticsCoordinator.validate(): (boolean, string?)
	return AnalyticsDiagnostics.validate(dependencies)
end

function AnalyticsCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Analytics Boundary self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = AnalyticsCoordinator })
	return lastSelfChecks
end

return AnalyticsCoordinator
