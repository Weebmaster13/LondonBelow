export const executionStatusValues = Object.freeze({
  executionRequested: "ExecutionRequested",
  environmentValidated: "EnvironmentValidated",
  capabilitiesResolved: "CapabilitiesResolved",
  sessionCreated: "SessionCreated",
  backendSelected: "BackendSelected",
  executionStarted: "ExecutionStarted",
  executionRunning: "ExecutionRunning",
  evidenceCollecting: "EvidenceCollecting",
  executionCompleted: "ExecutionCompleted",
  cleanupRunning: "CleanupRunning",
  cleanupComplete: "CleanupComplete",
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

export const executionExitCodes = Object.freeze({
  success: 0,
  executionBlocked: 2,
  validationFailed: 5,
  unsupportedBackend: 20,
  timeout: 21,
  cleanupFailed: 22
});
