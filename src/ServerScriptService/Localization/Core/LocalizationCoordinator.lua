--!strict
--[[
	Phase 35 Localization Runtime Coordinator.

	Server-authoritative localization schema foundation. It records language
	definitions, text keys, package schemas, fallback policies, subtitle schemas,
	caption schemas, and text safety schemas. It does not create final translated
	text, author dialogue or story, render UI/subtitles/captions, play voiceover,
	call external services, create remotes, mutate the world, or add Chapter
	content.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local CaptionRuntime = require(script.Parent.LocalizationCaptionRuntime)
local FallbackRuntime = require(script.Parent.LocalizationFallbackRuntime)
local LanguageRuntime = require(script.Parent.LocalizationLanguageRuntime)
local LocalizationDiagnostics = require(script.Parent.LocalizationDiagnostics)
local PackageRuntime = require(script.Parent.LocalizationPackageRuntime)
local SelfChecks = require(script.Parent.LocalizationSelfChecks)
local Serialization = require(script.Parent.LocalizationSerialization)
local Signals = require(script.Parent.LocalizationSignals)
local Snapshots = require(script.Parent.LocalizationSnapshots)
local State = require(script.Parent.LocalizationState)
local SubtitleRuntime = require(script.Parent.LocalizationSubtitleRuntime)
local TextKeyRuntime = require(script.Parent.LocalizationTextKeyRuntime)
local TextSafetyRuntime = require(script.Parent.LocalizationTextSafetyRuntime)
local Types = require(script.Parent.LocalizationTypes)
local Validation = require(script.Parent.LocalizationValidation)

local LocalizationCoordinator = {}

local log = Logger.scope("LocalizationRuntime")
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
	if reason == "duplicate languageId" then
		return Types.ResultCode.DuplicateLanguage
	elseif reason == "duplicate textKeyId" then
		return Types.ResultCode.DuplicateTextKey
	elseif reason == "duplicate packageId" then
		return Types.ResultCode.DuplicatePackage
	elseif reason == "duplicate fallbackId" then
		return Types.ResultCode.DuplicateFallback
	elseif reason == "duplicate subtitleId" then
		return Types.ResultCode.DuplicateSubtitle
	elseif reason == "duplicate captionId" then
		return Types.ResultCode.DuplicateCaption
	elseif reason == "duplicate textSafetyId" then
		return Types.ResultCode.DuplicateTextSafety
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

function LocalizationCoordinator.registerLanguage(schema: any)
	local ok, reason = LanguageRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "language schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.LanguageRegistered, { languageId = schema.languageId })
	return result(true, Types.ResultCode.Ok, "language schema registered")
end

function LocalizationCoordinator.registerTextKey(schema: any)
	local ok, reason = TextKeyRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "text key schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.TextKeyRegistered, { textKeyId = schema.textKeyId })
	return result(true, Types.ResultCode.Ok, "text key schema registered")
end

function LocalizationCoordinator.registerPackage(schema: any)
	local ok, reason = PackageRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "package schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.PackageRegistered, { packageId = schema.packageId })
	return result(true, Types.ResultCode.Ok, "package schema registered")
end

function LocalizationCoordinator.registerFallback(schema: any)
	local ok, reason = FallbackRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "fallback schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.FallbackRegistered, { fallbackId = schema.fallbackId })
	return result(true, Types.ResultCode.Ok, "fallback schema registered")
end

function LocalizationCoordinator.registerSubtitle(schema: any)
	local ok, reason = SubtitleRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "subtitle schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.SubtitleRegistered, { subtitleId = schema.subtitleId })
	return result(true, Types.ResultCode.Ok, "subtitle schema registered")
end

function LocalizationCoordinator.registerCaption(schema: any)
	local ok, reason = CaptionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "caption schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.CaptionRegistered, { captionId = schema.captionId })
	return result(true, Types.ResultCode.Ok, "caption schema registered")
end

function LocalizationCoordinator.registerTextSafety(schema: any)
	local ok, reason = TextSafetyRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "text safety schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.TextSafetyRegistered, { textSafetyId = schema.textSafetyId })
	return result(true, Types.ResultCode.Ok, "text safety schema registered")
end

function LocalizationCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = LocalizationCoordinator.validate()
	if not valid then
		error("LocalizationCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("localizationRuntime", LocalizationCoordinator.inspect)
	SnapshotManager.registerProvider("localizationRuntime", LocalizationCoordinator.getSnapshot)
	initialized = true
	log.success("Localization Runtime initialized")
end

function LocalizationCoordinator.start()
	if started then
		return
	end
	if not initialized then
		LocalizationCoordinator.initialize()
	end
	started = true
end

function LocalizationCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function LocalizationCoordinator.inspect()
	return LocalizationDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function LocalizationCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(State)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function LocalizationCoordinator.validate(): (boolean, string?)
	return LocalizationDiagnostics.validate(dependencies)
end

function LocalizationCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Localization Runtime self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = LocalizationCoordinator })
	return lastSelfChecks
end

return LocalizationCoordinator
