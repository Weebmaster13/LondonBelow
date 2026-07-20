--!strict
-- Shared constants and result codes for Save / Journal / Identity runtime foundation.

local Types = {}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateProfile = "DuplicateProfile",
	UnknownProfile = "UnknownProfile",
	DuplicateEntry = "DuplicateEntry",
	DuplicateFragment = "DuplicateFragment",
	InvalidCheckpoint = "InvalidCheckpoint",
	InvalidSave = "InvalidSave",
	UnsupportedVersion = "UnsupportedVersion",
	DuplicateObjective = "DuplicateObjective",
	DuplicateCheckpoint = "DuplicateCheckpoint",
	UnsafePayload = "UnsafePayload",
}

Types.ProviderName = "saveRuntime"
Types.SchemaVersion = 1
Types.MigrationVersion = 1
Types.Chapter0SchemaId = "chapter0.home.progress.v1"

Types.PersistentObjectiveState = {
	Locked = "Locked",
	Available = "Available",
	Active = "Active",
	Completed = "Completed",
	Failed = "Failed",
	Skipped = "Skipped",
}

Types.Limits = {
	MaxProfiles = 64,
	MaxCheckpointsPerProfile = 24,
	MaxSaveSchemas = 16,
	MaxObjectivesPerSave = 32,
	MaxCheckpointsPerSave = 16,
	MaxJournalEntriesPerProfile = 160,
	MaxMemoryFragmentsPerProfile = 160,
	MaxReplayStatesPerProfile = 120,
	MaxEvidence = 160,
	MaxMigrationRuns = 80,
	MaxSerializationHistory = 80,
	MaxValidationFailures = 160,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 240,
	MaxPayloadStringLength = 512,
}

Types.Mode = "ServerAuthoritativeFoundation"

return Types
