import { capabilityStatuses } from "./ExecutionStatus.mjs";

export const capabilityIds = Object.freeze([
  "studioInstalled",
  "studioExecutable",
  "studioMcpAvailable",
  "robloxCliAvailable",
  "runnerAvailable",
  "structuredCaptureAvailable",
  "multiplayerAvailable",
  "replayAvailable",
  "humanQaAvailable"
]);

export function createCapability(capabilityId, status, source, reason) {
  if (!capabilityStatuses.includes(status)) {
    throw new Error(`Unsupported capability status: ${status}`);
  }
  return { capabilityId, status, source, reason };
}

export function resolveCapabilities(environment, backend) {
  const studioBlockedReason =
    "The selected backend preserves blocked execution until a supported Studio runtime result is available.";

  return [
    createCapability("studioInstalled", "Unknown", "ExecutionDiscovery", "Installation discovery is backend-owned."),
    createCapability("studioExecutable", "Unknown", "ExecutionDiscovery", "Executable probing is backend-owned."),
    createCapability("studioMcpAvailable", "Blocked", "ExecutionDiscovery", studioBlockedReason),
    createCapability("robloxCliAvailable", "Unknown", "ExecutionDiscovery", "Future Roblox CLI probing is backend-owned."),
    createCapability("runnerAvailable", "Blocked", "ExecutionLauncher", "No runtime runner is invoked until backend evidence is imported."),
    createCapability(
      "structuredCaptureAvailable",
      "Blocked",
      "ExecutionEvidenceCollector",
      "Structured runtime capture requires a supported backend."
    ),
    createCapability("multiplayerAvailable", "Blocked", "ExecutionTargets", "No multiplayer runtime is launched during Phase 151."),
    createCapability("replayAvailable", "Unsupported", "ExecutionReplay", "Replay metadata is modeled; replay execution is future work."),
    createCapability(
      "humanQaAvailable",
      environment.workingTreeClean ? "Supported" : "Blocked",
      "ExecutionEnvironment",
      environment.workingTreeClean ? "Manual QA can attach evidence to a clean source state." : "Manual QA evidence requires a clean source state."
    ),
    createCapability(
      "backendSelected",
      backend.availability === "available" ? "Supported" : "Blocked",
      "ExecutionRegistry",
      backend.reason
    )
  ];
}
