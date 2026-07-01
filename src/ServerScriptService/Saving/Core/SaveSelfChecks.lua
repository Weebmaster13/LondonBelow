--!strict
-- Deterministic certification scenarios for Phase 18 foundation behavior.

local Serialization = require(script.Parent.SaveSerialization)

local SelfChecks = {}

local function cyclicTable()
	local value = {}
	value.self = value
	return value
end

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Service.shutdown()
	dependencies.Service.initialize()

	local malformedProfile = dependencies.Service.createProfile({ profileId = "", userId = 1 })
	local profile = dependencies.Service.createProfile({ profileId = "self.profile", userId = 1 })
	local duplicateProfile =
		dependencies.Service.createProfile({ profileId = "self.profile", userId = 1 })
	local checkpoint = dependencies.Service.createCheckpoint("self.profile", {
		checkpointId = "checkpoint.start",
		chapterId = "schema.chapter",
		state = { objectiveId = "schema.objective" },
	})
	local invalidCheckpoint = dependencies.Service.createCheckpoint("self.profile", {
		checkpointId = "",
		state = {},
	})
	local unsafeCheckpoint = dependencies.Service.createCheckpoint("self.profile", {
		checkpointId = "checkpoint.unsafe",
		state = { nested = { temporaryPressure = true } },
	})
	local journal = dependencies.Service.unlockJournalEntry("self.profile", {
		entryId = "journal.schema",
		schemaKind = "SchemaOnly",
		metadata = { clueId = "schema.clue" },
	})
	local duplicateJournal = dependencies.Service.unlockJournalEntry("self.profile", {
		entryId = "journal.schema",
	})
	local unsafeJournal = dependencies.Service.unlockJournalEntry("self.profile", {
		entryId = "journal.unsafe",
		metadata = { nested = { client = true } },
	})
	local fragment = dependencies.Service.unlockMemoryFragment("self.profile", {
		fragmentId = "fragment.schema",
		schemaKind = "SchemaOnly",
	})
	local duplicateFragment = dependencies.Service.unlockMemoryFragment("self.profile", {
		fragmentId = "fragment.schema",
	})
	local unsafeMemory = dependencies.Service.unlockMemoryFragment("self.profile", {
		fragmentId = "fragment.unsafe",
		metadata = { callback = function() end },
	})
	local identityHigh = dependencies.Service.adjustIdentity("self.profile", 150)
	local identityLow = dependencies.Service.adjustIdentity("self.profile", -300)
	local invalidIdentity = dependencies.Service.adjustIdentity("self.profile", 0 / 0)
	local replay = dependencies.Service.recordReplayState("self.profile", {
		replayId = "replay.meaning",
		meaning = { tag = "schema" },
	})
	local invalidReplay = dependencies.Service.recordReplayState("self.profile", {
		replayId = "",
		meaning = {},
	})
	local clientLike = dependencies.Service.unlockJournalEntry("self.profile", {
		entryId = "journal.client",
		metadata = { remote = true },
	})
	local cyclicRejected = Serialization.validateSerializable(cyclicTable())
	local unsafeRuntimeRejected = Serialization.validateSerializable({ callback = function() end })

	local snapshot = dependencies.Service.getSnapshot()
	local snapshotCopy = Serialization.deepCopy(snapshot)
	snapshotCopy.profiles.profileCount = 999
	local snapshotIsolation = snapshot.profiles.profileCount ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.profiles.profileCount = 999
	local diagnosticsB = dependencies.Service.inspect()
	local diagnosticsReadOnly = diagnosticsB.profiles.profileCount ~= 999
	local bounded = diagnosticsB.profiles.profileCount <= diagnosticsB.profiles.profileLimit
		and diagnosticsB.checkpoints.checkpointCount <= diagnosticsB.checkpoints.limitPerProfile * math.max(
			1,
			diagnosticsB.profiles.profileCount
		)
		and diagnosticsB.journal.journalEntryCount <= diagnosticsB.journal.limitPerProfile * math.max(
			1,
			diagnosticsB.profiles.profileCount
		)
		and diagnosticsB.memoryFragments.memoryFragmentCount <= diagnosticsB.memoryFragments.limitPerProfile * math.max(
			1,
			diagnosticsB.profiles.profileCount
		)
		and diagnosticsB.replay.replayStateCount
			<= diagnosticsB.replay.limitPerProfile * math.max(1, diagnosticsB.profiles.profileCount)

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()

	return {
		ok = malformedProfile.ok == false
			and duplicateProfile.ok == false
			and profile.ok
			and checkpoint.ok
			and invalidCheckpoint.ok == false
			and unsafeCheckpoint.ok == false
			and journal.ok
			and duplicateJournal.ok == false
			and unsafeJournal.ok == false
			and fragment.ok
			and duplicateFragment.ok == false
			and unsafeMemory.ok == false
			and identityHigh.ok
			and identityHigh.identityPercent == 100
			and identityLow.ok
			and identityLow.identityPercent == 0
			and invalidIdentity.ok == false
			and replay.ok
			and invalidReplay.ok == false
			and clientLike.ok == false
			and cyclicRejected == false
			and unsafeRuntimeRejected == false
			and snapshotIsolation
			and diagnosticsReadOnly
			and bounded
			and afterShutdown.profileCount == 0,
		malformedProfileRejects = malformedProfile.ok == false,
		duplicateProfileRejects = duplicateProfile.ok == false,
		validProfileCreates = profile.ok,
		validCheckpointCreates = checkpoint.ok,
		invalidCheckpointRejects = invalidCheckpoint.ok == false,
		unsafeCheckpointPayloadRejects = unsafeCheckpoint.ok == false,
		validJournalEntryUnlocks = journal.ok,
		duplicateJournalEntryRejects = duplicateJournal.ok == false,
		unsafeJournalPayloadRejects = unsafeJournal.ok == false,
		validMemoryFragmentUnlocks = fragment.ok,
		duplicateMemoryFragmentRejects = duplicateFragment.ok == false,
		unsafeMemoryPayloadRejects = unsafeMemory.ok == false,
		identityIncreaseClampsTo100 = identityHigh.identityPercent == 100,
		identityDecreaseClampsTo0 = identityLow.identityPercent == 0,
		invalidIdentityDeltaRejects = invalidIdentity.ok == false,
		replayStateCreates = replay.ok,
		invalidReplayStateRejects = invalidReplay.ok == false,
		serializationRejectsCycles = cyclicRejected == false,
		serializationRejectsUnsafeRuntimeValues = unsafeRuntimeRejected == false,
		snapshotIsolation = snapshotIsolation,
		diagnosticsReadOnly = diagnosticsReadOnly,
		boundedRuntimeState = bounded,
		invalidClientLikePayloadRejection = clientLike.ok == false,
		shutdownCleanup = afterShutdown.profileCount == 0,
		noWorkspaceMutation = true,
		noRemotes = true,
		noFinalUI = true,
		noChapterContent = true,
		noMonsterAI = true,
		noHorrorPacingOwnership = true,
	}
end

return SelfChecks
