--!strict
--[[
	Phase 36 Content Registry Runtime Coordinator.

	Server-authoritative content schema foundation. It records content
	definitions, categories, references, dependencies, packages, versions, and
	tags as catalog structure only. It never loads assets, streams content,
	spawns objects, completes objectives, runs gameplay, persists saves, creates
	remotes, mutates the world, or writes Chapter/story/dialogue content.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local CategoryRuntime = require(script.Parent.ContentCategoryRuntime)
local ContentDiagnostics = require(script.Parent.ContentDiagnostics)
local DefinitionRuntime = require(script.Parent.ContentDefinitionRuntime)
local DependencyRuntime = require(script.Parent.ContentDependencyRuntime)
local PackageRuntime = require(script.Parent.ContentPackageRuntime)
local ReferenceRuntime = require(script.Parent.ContentReferenceRuntime)
local SelfChecks = require(script.Parent.ContentSelfChecks)
local Serialization = require(script.Parent.ContentSerialization)
local Signals = require(script.Parent.ContentSignals)
local Snapshots = require(script.Parent.ContentSnapshots)
local State = require(script.Parent.ContentState)
local TagRuntime = require(script.Parent.ContentTagRuntime)
local Types = require(script.Parent.ContentTypes)
local Validation = require(script.Parent.ContentValidation)
local VersionRuntime = require(script.Parent.ContentVersionRuntime)

local ContentRegistryCoordinator = {}

local log = Logger.scope("ContentRegistryRuntime")
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
	if reason == "duplicate contentId" then
		return Types.ResultCode.DuplicateContent
	elseif reason == "duplicate categoryId" then
		return Types.ResultCode.DuplicateCategory
	elseif reason == "duplicate referenceId" then
		return Types.ResultCode.DuplicateReference
	elseif reason == "duplicate dependencyId" then
		return Types.ResultCode.DuplicateDependency
	elseif reason == "duplicate packageId" then
		return Types.ResultCode.DuplicatePackage
	elseif reason == "duplicate versionId" then
		return Types.ResultCode.DuplicateVersion
	elseif reason == "duplicate tagId" then
		return Types.ResultCode.DuplicateTag
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

function ContentRegistryCoordinator.registerContentDefinition(schema: any)
	local ok, reason = DefinitionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "content definition rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ContentDefinitionRegistered, { contentId = schema.contentId })
	return result(true, Types.ResultCode.Ok, "content definition registered")
end

function ContentRegistryCoordinator.registerCategory(schema: any)
	local ok, reason = CategoryRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "category schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.CategoryRegistered, { categoryId = schema.categoryId })
	return result(true, Types.ResultCode.Ok, "category schema registered")
end

function ContentRegistryCoordinator.registerReference(schema: any)
	local ok, reason = ReferenceRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "reference schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.ReferenceRegistered, { referenceId = schema.referenceId })
	return result(true, Types.ResultCode.Ok, "reference schema registered")
end

function ContentRegistryCoordinator.registerDependency(schema: any)
	local ok, reason = DependencyRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "dependency schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.DependencyRegistered, { dependencyId = schema.dependencyId })
	return result(true, Types.ResultCode.Ok, "dependency schema registered")
end

function ContentRegistryCoordinator.registerPackage(schema: any)
	local ok, reason = PackageRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "package schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.PackageRegistered, { packageId = schema.packageId })
	return result(true, Types.ResultCode.Ok, "package schema registered")
end

function ContentRegistryCoordinator.registerVersion(schema: any)
	local ok, reason = VersionRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "version schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.VersionRegistered, { versionId = schema.versionId })
	return result(true, Types.ResultCode.Ok, "version schema registered")
end

function ContentRegistryCoordinator.registerTag(schema: any)
	local ok, reason = TagRuntime.register(State, schema)
	if not ok then
		recordFailure(reason or "tag schema rejected", schema)
		return result(false, codeFor(reason), reason)
	end
	EventBus.publishDeferred(Signals.TagRegistered, { tagId = schema.tagId })
	return result(true, Types.ResultCode.Ok, "tag schema registered")
end

function ContentRegistryCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = ContentRegistryCoordinator.validate()
	if not valid then
		error("ContentRegistryCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("contentRegistryRuntime", ContentRegistryCoordinator.inspect)
	SnapshotManager.registerProvider(
		"contentRegistryRuntime",
		ContentRegistryCoordinator.getSnapshot
	)
	initialized = true
	log.success("Content Registry Runtime initialized")
end

function ContentRegistryCoordinator.start()
	if started then
		return
	end
	if not initialized then
		ContentRegistryCoordinator.initialize()
	end
	started = true
end

function ContentRegistryCoordinator.shutdown()
	State.clear()
	started = false
	initialized = false
end

function ContentRegistryCoordinator.inspect()
	return ContentDiagnostics.capture({
		initialized = initialized,
		started = started,
		lastSelfChecks = lastSelfChecks,
	}, dependencies)
end

function ContentRegistryCoordinator.getSnapshot()
	local snapshot = Snapshots.capture(State)
	EventBus.publishDeferred(
		Signals.SnapshotCaptured,
		{ snapshot = Serialization.deepCopy(snapshot) }
	)
	return snapshot
end

function ContentRegistryCoordinator.validate(): (boolean, string?)
	return ContentDiagnostics.validate(dependencies)
end

function ContentRegistryCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Content Registry self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SelfChecks.run({ Service = ContentRegistryCoordinator })
	return lastSelfChecks
end

return ContentRegistryCoordinator
