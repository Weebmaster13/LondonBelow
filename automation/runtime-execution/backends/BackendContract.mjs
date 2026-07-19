import { runtimeExecutionFrameworkVersion } from "../ExecutionVersion.mjs";
import { backendAvailabilityStatuses, evidenceTrustLevels, executionBackends } from "../ExecutionStatus.mjs";
import { deepFreeze, exactFields, result, validateIdentifier } from "../ExecutionUtilities.mjs";

export const backendContractFields = Object.freeze([
  "backendId",
  "backendKind",
  "displayName",
  "frameworkVersion",
  "backendVersion",
  "availability",
  "availabilityReason",
  "trustLevel",
  "supportedExecutionModes",
  "supportsLaunch",
  "supportsPlayMode",
  "supportsRunMode",
  "supportsServer",
  "supportsClient",
  "supportsMultiClient",
  "supportsStructuredCapture",
  "requiresHumanAction",
  "supportsTimeout",
  "supportsCleanup",
  "supportedPlatforms",
  "requiredTools",
  "configurationSchema",
  "evidenceSchemaVersion",
  "priority"
]);

export function createBackendContract(fields) {
  return deepFreeze({
    frameworkVersion: runtimeExecutionFrameworkVersion,
    backendVersion: "1.0.0",
    supportedExecutionModes: [],
    supportsLaunch: false,
    supportsPlayMode: false,
    supportsRunMode: false,
    supportsServer: false,
    supportsClient: false,
    supportsMultiClient: false,
    supportsStructuredCapture: false,
    requiresHumanAction: true,
    supportsTimeout: true,
    supportsCleanup: true,
    supportedPlatforms: [process.platform],
    requiredTools: [],
    configurationSchema: {},
    evidenceSchemaVersion: 1,
    priority: 100,
    ...fields
  });
}

export function validateBackendModuleContract(contract) {
  const fields = exactFields(contract, backendContractFields, "backend module contract");
  if (!fields.ok) return fields;
  const id = validateIdentifier(contract.backendId, "backendId");
  if (!id.ok) return id;
  if (!executionBackends.includes(contract.backendKind)) {
    return result(false, "backendKind unsupported", "UnsupportedBackendKind");
  }
  if (contract.frameworkVersion !== runtimeExecutionFrameworkVersion) {
    return result(false, "frameworkVersion unsupported", "UnsupportedFrameworkVersion");
  }
  if (!backendAvailabilityStatuses.includes(contract.availability)) {
    return result(false, "availability unsupported", "UnsupportedAvailability");
  }
  if (!evidenceTrustLevels.includes(contract.trustLevel)) {
    return result(false, "trustLevel unsupported", "UnsupportedTrustLevel");
  }
  for (const field of [
    "supportsLaunch",
    "supportsPlayMode",
    "supportsRunMode",
    "supportsServer",
    "supportsClient",
    "supportsMultiClient",
    "supportsStructuredCapture",
    "requiresHumanAction",
    "supportsTimeout",
    "supportsCleanup"
  ]) {
    if (typeof contract[field] !== "boolean") return result(false, `${field} must be boolean`, "SchemaMismatch");
  }
  if (!Array.isArray(contract.supportedExecutionModes) || !Array.isArray(contract.supportedPlatforms) || !Array.isArray(contract.requiredTools)) {
    return result(false, "backend arrays invalid", "SchemaMismatch");
  }
  if (!Number.isInteger(contract.priority) || contract.priority < 0) {
    return result(false, "backend priority invalid", "InvalidPriority");
  }
  return result(true);
}

export function blockedBackendResult(contract, context, stage, reason) {
  const timestamp = context?.timestamp ?? new Date().toISOString();
  return {
    backendId: contract.backendId,
    backendVersion: contract.backendVersion,
    sessionId: context?.sessionId ?? "unassigned",
    status: "blocked",
    stage,
    executionMode: context?.configuration?.requestedBackend ?? contract.backendKind,
    launched: false,
    playModeEntered: false,
    runModeEntered: false,
    serverStarted: false,
    clientStarted: false,
    clientCount: 0,
    runnerInvoked: false,
    structuredResultCaptured: false,
    startTimestamp: timestamp,
    endTimestamp: timestamp,
    durationMilliseconds: 0,
    process: { started: false, pid: null, exitCode: null },
    artifacts: [],
    evidence: [],
    assertions: [],
    errors: [],
    warnings: [reason],
    cleanup: { attempted: true, completed: true, warnings: [] },
    limitations: [reason],
    nextAction: reason
  };
}
