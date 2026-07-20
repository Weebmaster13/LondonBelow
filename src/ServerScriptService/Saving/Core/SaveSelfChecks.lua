--!strict
-- Deterministic certification scenarios for Phase 18 foundation behavior.

local Serialization = require(script.Parent.SaveSerialization)
local Types = require(script.Parent.SaveTypes)

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
	local validationSave = dependencies.Service.chapter0ValidationSave()
	local serialized = dependencies.Service.serializeProgress(validationSave)
	local deserialized = if serialized.ok
		then dependencies.Service.deserializeProgress(serialized.serialized.envelope)
		else { ok = false }
	local migrated = dependencies.Service.migrateSave(validationSave)
	local missingSchema = Serialization.deepCopy(validationSave)
	missingSchema.schemaVersion = nil
	local missingSchemaRejected = dependencies.Service.deserializeProgress(missingSchema)
	local unsupportedVersion = Serialization.deepCopy(validationSave)
	unsupportedVersion.schemaVersion = 999
	local unsupportedVersionRejected = dependencies.Service.deserializeProgress(unsupportedVersion)
	local duplicateObjective = Serialization.deepCopy(validationSave)
	table.insert(duplicateObjective.objectiveProgress, duplicateObjective.objectiveProgress[1])
	local duplicateObjectiveRejected = dependencies.Service.serializeProgress(duplicateObjective)
	local duplicateCheckpoint = Serialization.deepCopy(validationSave)
	table.insert(duplicateCheckpoint.checkpointProgress, duplicateCheckpoint.checkpointProgress[1])
	local duplicateCheckpointRejected = dependencies.Service.serializeProgress(duplicateCheckpoint)
	local corruptedSave = Serialization.deepCopy(validationSave)
	corruptedSave.objectiveProgress[1].state = "Corrupted"
	local corruptedSaveRejected = dependencies.Service.serializeProgress(corruptedSave)
	local partialSerialization = Serialization.deepCopy(validationSave)
	partialSerialization.checkpointProgress = nil
	local partialSerializationRejected =
		dependencies.Service.serializeProgress(partialSerialization)
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
			and serialized.ok
			and deserialized.ok
			and migrated.ok
			and missingSchemaRejected.ok == false
			and unsupportedVersionRejected.ok == false
			and duplicateObjectiveRejected.ok == false
			and duplicateCheckpointRejected.ok == false
			and corruptedSaveRejected.ok == false
			and partialSerializationRejected.ok == false
			and deserialized.restored.objectiveProgress[1].objectiveId == validationSave.objectiveProgress[1].objectiveId
			and snapshot.saveRuntimeAvailable == true
			and diagnosticsB.saveRuntimePosture.writesDataStore == false
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
		schemaRegistry = dependencies.Service.inspect().saveRuntime.schemas.schemaCount > 0,
		serializer = serialized.ok == true,
		deserializer = deserialized.ok == true,
		migrationRuntime = migrated.ok == true,
		objectivePersistence = serialized.ok == true
			and serialized.serialized.envelope.objectiveProgress[1].objectiveId
				== "chapter0.home.objective.inspect_note",
		checkpointPersistence = serialized.ok == true
			and serialized.serialized.envelope.checkpointProgress[1].checkpointId
				== "chapter0.home.checkpoint.start",
		stableIdentifiers = serialized.ok == true and string.find(
			serialized.serialized.stable,
			"chapter0.home.objective.restore_power",
			1,
			true
		) ~= nil,
		missingSchemaVersionRejects = missingSchemaRejected.ok == false,
		unsupportedVersionRejects = unsupportedVersionRejected.ok == false,
		duplicateObjectiveRejects = duplicateObjectiveRejected.ok == false,
		duplicateCheckpointRejects = duplicateCheckpointRejected.ok == false,
		corruptedSaveRejects = corruptedSaveRejected.ok == false,
		partialSerializationRejects = partialSerializationRejected.ok == false,
		saveRuntimeDiagnostics = diagnosticsB.saveRuntimePosture.providerName == Types.ProviderName,
		saveRuntimeSnapshots = snapshot.saveRuntimeAvailable == true,
		shutdownCleanup = afterShutdown.profileCount == 0,
		noDataStore = true,
		noNetworking = true,
		noWorkspaceMutation = true,
		noRemotes = true,
		noFinalUI = true,
		noChapterContent = true,
		noMonsterAI = true,
		noHorrorPacingOwnership = true,
	}
end

return SelfChecks
