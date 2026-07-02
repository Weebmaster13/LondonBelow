--!strict
--[[
	Phase 32 Accessibility Runtime Coordinator.

	Server-authoritative Accessibility Runtime schema foundation. It records future
	accessibility setting schemas, visual safety rules, audio safety rules, input
	assist schemas, motion comfort schemas, readability schemas, and content
	warning schemas. It does not execute settings, remap input, run audio, mutate
	lighting, move cameras, play VFX, expose remotes, trust clients, mutate the
	world, execute gameplay, or create final accessibility UI.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local AggregationRuntime = require(script.Parent.AccessibilityAudioRuntime)
local ContentWarningRuntime = require(script.Parent.AccessibilityContentWarningRuntime)
local DefinitionRuntime = require(script.Parent.AccessibilitySettingsRuntime)
local ConsentRuntime = require(script.Parent.AccessibilityInputRuntime)
local MetricRuntime = require(script.Parent.AccessibilityVisualRuntime)
local ReportRuntime = require(script.Parent.AccessibilityReadabilityRuntime)
local RetentionRuntime = require(script.Parent.AccessibilityMotionRuntime)
local SelfChecks = require(script.Parent.AccessibilitySelfChecks)
local Serialization = require(script.Parent.AccessibilitySerialization)
local Signals = require(script.Parent.AccessibilitySignals)
local Snapshots = require(script.Parent.AccessibilitySnapshots)
local State = require(script.Parent.AccessibilityState)
local AccessibilityDiagnostics = require(script.Parent.AccessibilityDiagnostics)
local Types = require(script.Parent.AccessibilityTypes)
local Validation = require(script.Parent.AccessibilityValidation)

local AccessibilityCoordinator = {}

local log = Logger.scope("accessibilityRuntime")
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
	if reason == "duplicate settingId" then
		return Types.ResultCode.DuplicateSetting
	elseif reason == "duplicate visualId" then
		return Types.ResultCode.DuplicateVisual
	elseif reason == "duplicate audioId" then
		return Types.ResultCode.DuplicateAudio
	elseif reason == "duplicate inputId" then
		return Types.ResultCode.DuplicateInput
	elseif reason == "duplicate motionId" then
		return Types.ResultCode.DuplicateMotion
	elseif reason == "duplicate readabilityId" then
		return Types.ResultCode.DuplicateReadability
	elseif reason == "duplicate contentWarningId" then
		return Types.ResultCode.DuplicateContentWarning
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

function AccessibilityCoordinator.registerSetting(schema: any)
	local ok, reason = DefinitionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "accessibility setting rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.SettingRegistered, { settingId = schema.settingId })
	return result(true, Types.ResultCode.Ok, "accessibility setting schema registered")
end

function AccessibilityCoordinator.registerVisual(schema: any)
	local ok, reason = MetricRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "visual safety rule rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.VisualRegistered, { visualId = schema.visualId })
	return result(true, Types.ResultCode.Ok, "visual safety rule schema registered")
end

function AccessibilityCoordinator.registerAudio(schema: any)
	local ok, reason = AggregationRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "audio safety rule rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.AudioRegistered, { audioId = schema.audioId })
	return result(true, Types.ResultCode.Ok, "audio safety rule registered")
end

function AccessibilityCoordinator.registerInput(schema: any)
	local ok, reason = ConsentRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "input assist schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.InputRegistered, { inputId = schema.inputId })
	return result(true, Types.ResultCode.Ok, "input assist schema registered")
end

function AccessibilityCoordinator.registerMotion(schema: any)
	local ok, reason = RetentionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "motion comfort schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.MotionRegistered, { motionId = schema.motionId })
	return result(true, Types.ResultCode.Ok, "motion comfort schema registered")
end

function AccessibilityCoordinator.registerReadability(record: any)
	local ok, reason = ReportRuntime.record(State, record)
	if not ok then
		recordFailure(reason or "readability schema rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.ReadabilityRegistered,
		{ readabilityId = record.readabilityId }
	)
	return result(true, Types.ResultCode.Ok, "readability schema stored")
end

function AccessibilityCoordinator.registerContentWarning(record: any)
	local ok, reason = ContentWarningRuntime.register(State, record)
	if not ok then
		recordFailure(reason or "content warning schema rejected", record)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(
		Signals.ContentWarningRegistered,
		{ contentWarningId = record.contentWarningId }
	)
	return result(true, Types.ResultCode.Ok, "content warning schema registered")
end

function AccessibilityCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = AccessibilityCoordinator.validate()
	if not valid then
		error("AccessibilityCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("accessibilityRuntime", AccessibilityCoordinator.inspect)
	SnapshotManager.registerProvider("accessibilityRuntime", AccessibilityCoordinator.getSnapshot)
	initialized = true
	log.success("Accessibility Runtime initialized")
end

function AccessibilityCoordinator.start()
	if started then
		return
	end
	if not initialized then
		AccessibilityCoordinator.initialize()
	end
	started = true
end

function AccessibilityCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function AccessibilityCoordinator.inspect()
	return AccessibilityDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function AccessibilityCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(State)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function AccessibilityCoordinator.validate(): (boolean, string?)
	return AccessibilityDiagnostics.validate(dependencies)
end

function AccessibilityCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Accessibility Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = AccessibilityCoordinator })
	return lastSelfChecks
end

return AccessibilityCoordinator
