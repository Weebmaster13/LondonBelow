--!strict
-- Shared constants and result codes for Narrative Runtime foundation.

local Types = {}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateBeat = "DuplicateBeat",
	DuplicateGate = "DuplicateGate",
	UnknownBeat = "UnknownBeat",
	UnsafePayload = "UnsafePayload",
	Suppressed = "Suppressed",
}

Types.Limits = {
	MaxBeats = 160,
	MaxStoryGates = 160,
	MaxRevealEligibility = 240,
	MaxEmotionalProtections = 160,
	MaxValidationFailures = 160,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 8,
	MaxPayloadNodes = 240,
	MaxPayloadStringLength = 512,
}

Types.Mode = "ServerAuthoritativeNarrativeFoundation"

return Types
