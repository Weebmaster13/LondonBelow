--!strict
-- Shared constants and result codes for Phase 17 Monster AI execution foundation.

local Types = {}

Types.ResultCode = {
	Ok = "Ok",
	InvalidRequest = "InvalidRequest",
	DuplicateMonster = "DuplicateMonster",
	UnknownMonster = "UnknownMonster",
	DuplicateIntent = "DuplicateIntent",
	ExpiredIntent = "ExpiredIntent",
	MissingApproval = "MissingApproval",
	UnsafePayload = "UnsafePayload",
	UnsupportedIntent = "UnsupportedIntent",
	ExecutionDisabled = "ExecutionDisabled",
}

Types.IntentStatus = {
	Accepted = "Accepted",
	Rejected = "Rejected",
	Planned = "Planned",
	DryRunApplied = "DryRunApplied",
	Deferred = "Deferred",
	Expired = "Expired",
}

Types.SupportedIntentKinds = {
	Chase = true,
	Stalk = true,
	Watch = true,
	Retreat = true,
	Navigate = true,
	Perceive = true,
}

Types.IntentBridgeKinds = {
	Chase = "ChaseIntentFoundation",
	Stalk = "StalkIntentFoundation",
	Watch = "WatchIntentFoundation",
	Retreat = "RetreatIntentFoundation",
	Navigate = "NavigationIntentBridge",
	Perceive = "PerceptionBridge",
}

Types.Limits = {
	MaxMonsters = 64,
	MaxIntentHistory = 240,
	MaxSeenIntentIds = 480,
	MaxExecutionRecords = 240,
	MaxValidationFailures = 160,
	MaxSnapshotHistory = 80,
	MaxContextDepth = 8,
	MaxContextNodes = 240,
	MaxContextStringLength = 512,
	DefaultExpirationSeconds = 15,
}

Types.ExecutionMode = "DryRunOnly"

return Types
