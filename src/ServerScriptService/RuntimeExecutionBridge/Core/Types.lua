--!strict

local Types = {}

Types.RuntimeName = "RuntimeExecutionBridge"
Types.CoordinatorName = "RuntimeExecutionBridgeCoordinator"
Types.RuntimeProviderName = "runtimeExecutionBridge"
Types.SnapshotKind = "runtimeExecutionBridgeSnapshot"
Types.SchemaVersion = 1
Types.BridgeVersion = "1.0.0"
Types.StableTimestamp = "2026-07-19T00:00:00.000Z"

Types.Status = {
	Passed = "passed",
	Failed = "failed",
	Blocked = "blocked",
	NotExecuted = "notExecuted",
}

Types.AssertionStatus = {
	Pass = "PASS",
	Fail = "FAIL",
	Blocked = "BLOCKED",
	NotExecuted = "NOT_EXECUTED",
}

Types.LifecycleState = {
	Idle = "IDLE",
	SessionImported = "SESSION_IMPORTED",
	BridgeStarted = "BRIDGE_STARTED",
	Capturing = "CAPTURING",
	EvidencePrepared = "EVIDENCE_PREPARED",
	WriterBlocked = "WRITER_BLOCKED",
	CleanupComplete = "CLEANUP_COMPLETE",
	Failed = "FAILED",
}

Types.FailureClassification = {
	Framework = "Framework",
	Backend = "Backend",
	Bridge = "Bridge",
	Studio = "Studio",
	Runner = "Runner",
	Bootstrap = "Bootstrap",
	Coordinator = "Coordinator",
	Evidence = "Evidence",
	Writer = "Writer",
	Import = "Import",
	Cleanup = "Cleanup",
	Unknown = "Unknown",
}

Types.RequiredSessionFields = {
	"sessionId",
	"manifestId",
	"phase",
	"runnerId",
	"frameworkVersion",
	"repositoryCommit",
	"expectedOutputPath",
	"executionMode",
	"timeout",
	"policies",
}

Types.RunnerResultFields = {
	"schemaVersion",
	"runnerId",
	"sessionId",
	"phase",
	"repositoryCommit",
	"runtime",
	"status",
	"studioVersion",
	"serverStarted",
	"clientStarted",
	"clientCount",
	"assertions",
	"diagnostics",
	"snapshots",
	"audit",
	"errors",
	"warnings",
	"cleanup",
	"productionCertified",
	"capturedAt",
}

Types.Limits = {
	MaxAssertions = 64,
	MaxDiagnostics = 64,
	MaxSnapshots = 16,
	MaxCoordinators = 128,
	MaxStringLength = 256,
	MaxOutputPathLength = 260,
	MaxTimeoutMilliseconds = 900000,
}

Types.DefaultSession = {
	sessionId = "phase-155-studio-runtime-bridge-session",
	manifestId = "phase-155-studio-runtime-bridge-session.manifest",
	phase = 155,
	runnerId = "runtimeExecution.phase155.studioRuntimeExecutionBridge",
	frameworkVersion = "1.0.0",
	repositoryCommit = "unknown",
	expectedOutputPath = "automation/local-state/runtime-execution/phase-155-studio-runtime-bridge-session/runtime-result.json",
	executionMode = "StudioManual",
	timeout = 300000,
	policies = {
		certificationDecisionAllowed = false,
		allowFilesystemWrite = false,
	},
}

return Types
