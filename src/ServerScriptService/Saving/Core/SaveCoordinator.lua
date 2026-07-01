--!strict
--[[
	Phase 18 Save / Journal / Identity coordinator.

	Owns server-authoritative foundation state for profiles, checkpoints,
	journal entries, memory fragments, identity percentage, and replay meaning.
	It does not write DataStores yet, create remotes, own UI, write final story,
	own horror pacing, own Monster AI, or mutate Workspace.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Diagnostics = require(Core.Diagnostics)
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)
local SnapshotManager = require(Core.SnapshotManager)

local Checkpoints = require(script.Parent.CheckpointRuntime)
local Identity = require(script.Parent.IdentityRuntime)
local Journal = require(script.Parent.JournalRuntime)
local MemoryFragments = require(script.Parent.MemoryFragmentRuntime)
local Profiles = require(script.Parent.SaveProfileRuntime)
local Replay = require(script.Parent.ReplayStateRuntime)
local SaveDiagnostics = require(script.Parent.SaveDiagnostics)
local SaveSelfChecks = require(script.Parent.SaveSelfChecks)
local SaveSnapshots = require(script.Parent.SaveSnapshots)
local Serialization = require(script.Parent.SaveSerialization)
local Signals = require(script.Parent.SaveSignals)
local Types = require(script.Parent.SaveTypes)
local Validation = require(script.Parent.SaveValidation)

local SaveCoordinator = {}

local log = Logger.scope("SaveCoordinator")
local initialized = false
local started = false
local lastSelfChecks: any = nil
local validationFailures: { any } = {}

local function trimFailures()
	while #validationFailures > Types.Limits.MaxValidationFailures do
		table.remove(validationFailures, 1)
	end
end

local function recordFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
		createdAt = os.clock(),
	})
	trimFailures()
	EventBus.publishDeferred(Signals.ValidationFailed, { reason = reason })
end

local function result(ok: boolean, code: string, message: string?, extra: any?)
	local payload = extra or {}
	payload.ok = ok
	payload.code = code
	payload.message = message
	return payload
end

local function requireProfile(profileId: string): (boolean, string?)
	if not Profiles.exists(profileId) then
		return false, "unknown profile"
	end
	return true, nil
end

function SaveCoordinator.createProfile(definition: any)
	local ok, reason = Profiles.create(definition)
	if not ok then
		recordFailure(reason or "profile rejected", definition)
		return result(
			false,
			if reason == "duplicate profileId"
				then Types.ResultCode.DuplicateProfile
				else Types.ResultCode.InvalidRequest,
			reason
		)
	end
	EventBus.publishDeferred(Signals.ProfileCreated, { profileId = definition.profileId })
	return result(true, Types.ResultCode.Ok, "profile created")
end

function SaveCoordinator.createCheckpoint(profileId: string, checkpoint: any)
	local profileOk, profileReason = requireProfile(profileId)
	if not profileOk then
		recordFailure(profileReason or "unknown profile", { profileId = profileId })
		return result(false, Types.ResultCode.UnknownProfile, profileReason)
	end
	local ok, reason = Checkpoints.create(profileId, checkpoint)
	if not ok then
		recordFailure(reason or "checkpoint rejected", checkpoint)
		return result(false, Types.ResultCode.InvalidCheckpoint, reason)
	end
	Profiles.touch(profileId)
	EventBus.publishDeferred(
		Signals.CheckpointCreated,
		{ profileId = profileId, checkpointId = checkpoint.checkpointId }
	)
	return result(true, Types.ResultCode.Ok, "checkpoint created")
end

function SaveCoordinator.unlockJournalEntry(profileId: string, entry: any)
	local profileOk, profileReason = requireProfile(profileId)
	if not profileOk then
		recordFailure(profileReason or "unknown profile", { profileId = profileId })
		return result(false, Types.ResultCode.UnknownProfile, profileReason)
	end
	local ok, reason = Journal.unlock(profileId, entry)
	if not ok then
		recordFailure(reason or "journal entry rejected", entry)
		return result(
			false,
			if reason == "duplicate journal entry"
				then Types.ResultCode.DuplicateEntry
				else Types.ResultCode.InvalidRequest,
			reason
		)
	end
	Profiles.touch(profileId)
	EventBus.publishDeferred(
		Signals.JournalEntryUnlocked,
		{ profileId = profileId, entryId = entry.entryId }
	)
	return result(true, Types.ResultCode.Ok, "journal entry unlocked")
end

function SaveCoordinator.unlockMemoryFragment(profileId: string, fragment: any)
	local profileOk, profileReason = requireProfile(profileId)
	if not profileOk then
		recordFailure(profileReason or "unknown profile", { profileId = profileId })
		return result(false, Types.ResultCode.UnknownProfile, profileReason)
	end
	local ok, reason = MemoryFragments.unlock(profileId, fragment)
	if not ok then
		recordFailure(reason or "memory fragment rejected", fragment)
		return result(
			false,
			if reason == "duplicate memory fragment"
				then Types.ResultCode.DuplicateFragment
				else Types.ResultCode.InvalidRequest,
			reason
		)
	end
	Profiles.touch(profileId)
	EventBus.publishDeferred(
		Signals.MemoryFragmentUnlocked,
		{ profileId = profileId, fragmentId = fragment.fragmentId }
	)
	return result(true, Types.ResultCode.Ok, "memory fragment unlocked")
end

function SaveCoordinator.adjustIdentity(profileId: string, amount: number)
	local profileOk, profileReason = requireProfile(profileId)
	if not profileOk then
		recordFailure(profileReason or "unknown profile", { profileId = profileId })
		return result(false, Types.ResultCode.UnknownProfile, profileReason)
	end
	local ok, reason, value = Identity.adjust(profileId, amount)
	if not ok then
		recordFailure(
			reason or "identity adjustment rejected",
			{ profileId = profileId, amount = amount }
		)
		return result(false, Types.ResultCode.InvalidRequest, reason)
	end
	Profiles.touch(profileId)
	EventBus.publishDeferred(
		Signals.IdentityChanged,
		{ profileId = profileId, identityPercent = value }
	)
	return result(true, Types.ResultCode.Ok, "identity adjusted", { identityPercent = value })
end

function SaveCoordinator.recordReplayState(profileId: string, replay: any)
	local profileOk, profileReason = requireProfile(profileId)
	if not profileOk then
		recordFailure(profileReason or "unknown profile", { profileId = profileId })
		return result(false, Types.ResultCode.UnknownProfile, profileReason)
	end
	local ok, reason = Replay.record(profileId, replay)
	if not ok then
		recordFailure(reason or "replay state rejected", replay)
		return result(false, Types.ResultCode.InvalidRequest, reason)
	end
	Profiles.touch(profileId)
	EventBus.publishDeferred(
		Signals.ReplayRecorded,
		{ profileId = profileId, replayId = replay.replayId }
	)
	return result(true, Types.ResultCode.Ok, "replay state recorded")
end

function SaveCoordinator.initialize()
	if initialized then
		return
	end
	local valid, reason = SaveCoordinator.validate()
	if not valid then
		error("SaveCoordinator validation failed: " .. tostring(reason), 0)
	end
	Diagnostics.registerSampler("SaveJournalIdentity", SaveCoordinator.inspect)
	SnapshotManager.registerProvider("saveJournalIdentity", SaveCoordinator.getSnapshot)
	initialized = true
	log.success("Save / Journal / Identity runtime initialized")
end

function SaveCoordinator.start()
	if started then
		return
	end
	if not initialized then
		SaveCoordinator.initialize()
	end
	started = true
end

function SaveCoordinator.shutdown()
	Profiles.clear()
	Checkpoints.clear()
	Journal.clear()
	MemoryFragments.clear()
	Identity.clear()
	Replay.clear()
	table.clear(validationFailures)
	started = false
	initialized = false
end

function SaveCoordinator.inspect()
	return SaveDiagnostics.capture({
		initialized = initialized,
		started = started,
		mode = Types.Mode,
		validationFailures = Serialization.deepCopy(validationFailures),
		lastSelfChecks = lastSelfChecks,
	}, {
		Profiles = Profiles,
		Checkpoints = Checkpoints,
		Journal = Journal,
		MemoryFragments = MemoryFragments,
		Identity = Identity,
		Replay = Replay,
	})
end

function SaveCoordinator.getSnapshot()
	local snapshot = SaveSnapshots.capture({
		Profiles = Profiles,
		Checkpoints = Checkpoints,
		Journal = Journal,
		MemoryFragments = MemoryFragments,
		Identity = Identity,
		Replay = Replay,
	})
	EventBus.publishDeferred(Signals.SnapshotCaptured, { snapshot = snapshot })
	return snapshot
end

function SaveCoordinator.validate(): (boolean, string?)
	return SaveDiagnostics.validate({ Validation = Validation })
end

function SaveCoordinator.runSelfChecks()
	if started then
		lastSelfChecks = {
			ok = false,
			reason = "Save self-checks are destructive and may only run before start.",
		}
		return lastSelfChecks
	end
	lastSelfChecks = SaveSelfChecks.run({ Service = SaveCoordinator })
	return lastSelfChecks
end

return SaveCoordinator
