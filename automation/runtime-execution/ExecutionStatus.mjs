export const executionStatusValues = Object.freeze({
  executionRequested: "ExecutionRequested",
  environmentValidated: "EnvironmentValidated",
  capabilitiesResolved: "CapabilitiesResolved",
  sessionCreated: "SessionCreated",
  backendSelected: "BackendSelected",
  placePrepared: "PlacePrepared",
  executionStarted: "ExecutionStarted",
  executionRunning: "ExecutionRunning",
  waitingForManualAction: "WaitingForManualAction",
  evidenceCollecting: "EvidenceCollecting",
  executionCompleted: "ExecutionCompleted",
  executionBlocked: "ExecutionBlocked",
  executionFailed: "ExecutionFailed",
  timedOut: "TimedOut",
  cancelled: "Cancelled",
  cleanupRunning: "CleanupRunning",
  cleanupComplete: "CleanupComplete",
  cleanupFailed: "CleanupFailed",
  summaryGenerated: "SummaryGenerated",
  sessionArchived: "SessionArchived"
});

export const terminalExecutionStatuses = Object.freeze([
  executionStatusValues.executionCompleted,
  executionStatusValues.summaryGenerated,
  executionStatusValues.sessionArchived
]);

export const capabilityStatuses = Object.freeze(["Supported", "Unsupported", "Blocked", "Unknown"]);

export const assertionStatuses = Object.freeze(["PASS", "FAIL", "BLOCKED", "NOT_EXECUTED"]);

export const evidenceCategories = Object.freeze(["Static", "Build", "Runtime", "ManualQA", "Certification"]);

export const executionBackends = Object.freeze([
  "StudioManual",
  "StudioMCP",
  "FutureRobloxCLI",
  "FutureHeadless",
  "FutureQARunner",
  "FutureCertificationRunner",
  "FutureMultiplayerRunner"
]);

export const backendAvailabilityStatuses = Object.freeze(["available", "unsupported", "blocked", "unknown"]);

export const backendResultStatuses = Object.freeze([
  "prepared",
  "waitingForManualAction",
  "running",
  "completed",
  "completedWithLimitations",
  "failed",
  "blocked",
  "timedOut",
  "cancelled",
  "cleanupFailed"
]);

export const evidenceTrustLevels = Object.freeze([
  "STATIC_ONLY",
  "BUILD_ONLY",
  "INSTALLATION_DISCOVERY",
  "MANUAL_UNVERIFIED",
  "MANUAL_SOURCE_BOUND",
  "AUTOMATED_STUDIO_HOST",
  "AUTHORITATIVE_SERVER_CLIENT",
  "CERTIFICATION_REVIEW_ELIGIBLE"
]);

export const executionExitCodes = Object.freeze({
  success: 0,
  executionBlocked: 2,
  validationFailed: 5,
  unsupportedBackend: 20,
  timeout: 21,
  cleanupFailed: 22
});
