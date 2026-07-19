import { createCapability } from "../ExecutionCapabilities.mjs";

export function capabilitiesFromBackend(contract) {
  return [
    createCapability("backendLaunch", contract.supportsLaunch ? "Supported" : "Blocked", contract.backendId, contract.availabilityReason),
    createCapability("playMode", contract.supportsPlayMode ? "Supported" : "Blocked", contract.backendId, contract.availabilityReason),
    createCapability("runMode", contract.supportsRunMode ? "Supported" : "Blocked", contract.backendId, contract.availabilityReason),
    createCapability("serverExecution", contract.supportsServer ? "Supported" : "Blocked", contract.backendId, contract.availabilityReason),
    createCapability("clientExecution", contract.supportsClient ? "Supported" : "Blocked", contract.backendId, contract.availabilityReason),
    createCapability("multiClientExecution", contract.supportsMultiClient ? "Supported" : "Blocked", contract.backendId, contract.availabilityReason),
    createCapability(
      "structuredCapture",
      contract.supportsStructuredCapture ? "Supported" : "Blocked",
      contract.backendId,
      contract.availabilityReason
    ),
    createCapability("manualAction", contract.requiresHumanAction ? "Supported" : "Unsupported", contract.backendId, "Manual action requirement declared.")
  ];
}
