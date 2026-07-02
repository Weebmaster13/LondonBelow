--!strict
-- Shared constants for Phase 28 Session Runtime Foundation.

local Types = {}

Types.Mode = "ServerAuthoritativeSessionSchemaRuntime"

Types.SchemaType = {
	SessionSchema = "SessionSchema",
	PlayerSessionSchema = "PlayerSessionSchema",
	PartySessionSchema = "PartySessionSchema",
	ReadinessSchema = "ReadinessSchema",
	SessionLifecycleSchema = "SessionLifecycleSchema",
	JoinLeaveSchema = "JoinLeaveSchema",
	SystemSessionSchema = "SystemSessionSchema",
}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateSession = "DuplicateSession",
	DuplicatePlayerSession = "DuplicatePlayerSession",
	DuplicateParty = "DuplicateParty",
	UnsafePayload = "UnsafePayload",
}

Types.Limits = {
	MaxSessions = 500,
	MaxPlayerSessions = 3000,
	MaxParties = 900,
	MaxReadinessRecords = 3000,
	MaxLifecycleRecords = 1200,
	MaxJoinLeaveRecords = 4000,
	MaxValidationFailures = 220,
	MaxSnapshotHistory = 80,
	MaxPayloadDepth = 9,
	MaxPayloadNodes = 360,
	MaxPayloadStringLength = 640,
	MaxTags = 32,
}

return Types
