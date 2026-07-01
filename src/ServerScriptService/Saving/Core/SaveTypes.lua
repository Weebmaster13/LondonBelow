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
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxProfiles = 64,
	MaxCheckpointsPerProfile = 24,
	MaxJournalEntriesPerProfile = 160,
	MaxMemoryFragmentsPerProfile = 160,
	MaxReplayStatesPerProfile = 120,
	MaxValidationFailures = 160,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 240,
	MaxPayloadStringLength = 512,
}

Types.Mode = "ServerAuthoritativeFoundation"

return Types
