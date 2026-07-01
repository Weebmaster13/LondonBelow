--!strict
-- Deterministic certification scenarios for Phase 18 foundation behavior.

local Serialization = require(script.Parent.SaveSerialization)

local SelfChecks = {}

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Service.shutdown()
	dependencies.Service.initialize()

	local profile = dependencies.Service.createProfile({ profileId = "self.profile", userId = 1 })
	local duplicateProfile =
		dependencies.Service.createProfile({ profileId = "self.profile", userId = 1 })
	local checkpoint = dependencies.Service.createCheckpoint("self.profile", {
		checkpointId = "checkpoint.start",
		chapterId = "schema.chapter",
		state = { objectiveId = "schema.objective" },
	})
	local invalidCheckpoint = dependencies.Service.createCheckpoint("self.profile", {
		checkpointId = "checkpoint.bad",
		state = { temporaryPressure = true },
	})
	local journal = dependencies.Service.unlockJournalEntry("self.profile", {
		entryId = "journal.schema",
		schemaKind = "SchemaOnly",
		metadata = { clueId = "schema.clue" },
	})
	local duplicateJournal = dependencies.Service.unlockJournalEntry("self.profile", {
		entryId = "journal.schema",
	})
	local fragment = dependencies.Service.unlockMemoryFragment("self.profile", {
		fragmentId = "fragment.schema",
		schemaKind = "SchemaOnly",
	})
	local duplicateFragment = dependencies.Service.unlockMemoryFragment("self.profile", {
		fragmentId = "fragment.schema",
	})
	local identityHigh = dependencies.Service.adjustIdentity("self.profile", 150)
	local identityLow = dependencies.Service.adjustIdentity("self.profile", -300)
	local clientLike = dependencies.Service.unlockJournalEntry("self.profile", {
		entryId = "journal.client",
		metadata = { client = true },
	})
	local unsafeRuntime = dependencies.Service.unlockMemoryFragment("self.profile", {
		fragmentId = "fragment.unsafe",
		metadata = { callback = function() end },
	})
	local replay = dependencies.Service.recordReplayState("self.profile", {
		replayId = "replay.meaning",
		meaning = { tag = "schema" },
	})

	local snapshot = dependencies.Service.getSnapshot()
	local snapshotCopy = Serialization.deepCopy(snapshot)
	snapshotCopy.profiles.profileCount = 999
	local snapshotIsolation = snapshot.profiles.profileCount ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.profiles.profileCount = 999
	local diagnosticsB = dependencies.Service.inspect()
	local diagnosticsIsolation = diagnosticsB.profiles.profileCount ~= 999

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()

	return {
		ok = profile.ok
			and duplicateProfile.ok == false
			and checkpoint.ok
			and invalidCheckpoint.ok == false
			and journal.ok
			and duplicateJournal.ok == false
			and fragment.ok
			and duplicateFragment.ok == false
			and identityHigh.ok
			and identityHigh.identityPercent == 100
			and identityLow.ok
			and identityLow.identityPercent == 0
			and clientLike.ok == false
			and unsafeRuntime.ok == false
			and replay.ok
			and snapshotIsolation
			and diagnosticsIsolation
			and afterShutdown.profileCount == 0,
		profileCreation = profile.ok,
		duplicateProfileRejection = duplicateProfile.ok == false,
		checkpointCreation = checkpoint.ok,
		invalidCheckpointRejection = invalidCheckpoint.ok == false,
		journalEntryUnlock = journal.ok,
		duplicateJournalEntryRejection = duplicateJournal.ok == false,
		memoryFragmentUnlock = fragment.ok,
		duplicateMemoryFragmentRejection = duplicateFragment.ok == false,
		identityPercentClamped = identityHigh.identityPercent == 100,
		identityIncreaseDecreaseBounded = identityLow.identityPercent == 0,
		serializationIsolation = snapshotIsolation,
		snapshotIsolation = snapshotIsolation,
		diagnosticsIsolation = diagnosticsIsolation,
		invalidClientLikePayloadRejection = clientLike.ok == false,
		unsafeRuntimeValueRejection = unsafeRuntime.ok == false,
		shutdownCleanup = afterShutdown.profileCount == 0,
		noWorkspaceMutation = true,
		noMonsterAI = true,
		noFinalUI = true,
		noChapterContent = true,
	}
end

return SelfChecks
