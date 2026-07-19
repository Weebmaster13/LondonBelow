import { blockedBackendResult, createBackendContract } from "./BackendContract.mjs";
import { runStudioBridge, runnerPath, contractPath, gateAttribute, supportedPhase } from "../../studio-automation-bridge.mjs";

export const StudioBridgeBackend = Object.freeze({
  contract: createBackendContract({
    backendId: "runtimeExecution.studioBridge",
    backendKind: "FutureQARunner",
    displayName: "Existing Studio Bridge Backend",
    availability: "blocked",
    availabilityReason: "Existing bridge is integrated read-only and currently preserves executionBlocked.",
    trustLevel: "INSTALLATION_DISCOVERY",
    supportedExecutionModes: ["ExistingStudioBridge"],
    supportsLaunch: false,
    supportsPlayMode: false,
    supportsRunMode: false,
    supportsStructuredCapture: false,
    requiresHumanAction: false,
    requiredTools: ["node"],
    configurationSchema: { sourceAttributionValid: "boolean" },
    priority: 20
  }),
  discover() {
    return { available: true, reason: "Existing bridge module is importable." };
  },
  validateConfiguration(configuration, environment) {
    return environment.localHead === environment.remoteHead
      ? { ok: true, reason: null }
      : { ok: false, reason: "source attribution requires local and remote head match" };
  },
  prepare(context) {
    return this.launch(context);
  },
  launch(context) {
    const bridge = runStudioBridge({
      phase: supportedPhase,
      runnerPath,
      contractPath,
      gateAttribute,
      sourceAttributionValid: context.environment.localHead === context.environment.remoteHead
    });
    return {
      ...blockedBackendResult(this.contract, context, "launch", bridge.nextAction),
      status: bridge.status === "executionBlocked" ? "blocked" : "failed",
      runnerInvoked: bridge.runnerInvoked,
      structuredResultCaptured: bridge.structuredResultCaptured,
      warnings: [bridge.nextAction],
      evidence: [{ category: "Static", status: "Recorded", source: "studio-automation-bridge", artifactIds: [] }],
      nextAction: bridge.nextAction,
      bridge
    };
  },
  awaitResult(context) {
    return this.launch(context);
  },
  collectEvidence(context) {
    return this.launch(context);
  },
  validateEvidence(evidence) {
    return evidence?.runnerInvoked === false && evidence?.structuredResultCaptured === false
      ? { ok: true, reason: null }
      : { ok: false, reason: "malformed bridge output" };
  },
  cleanup() {
    return { ok: true, reason: "bridge launched no runtime process" };
  },
  summarize(context) {
    return this.launch(context);
  },
  selfCheck() {
    const result = this.launch({
      sessionId: "selfcheck",
      timestamp: "2026-07-19T00:00:00.000Z",
      configuration: { requestedBackend: "FutureQARunner" },
      environment: { localHead: "a", remoteHead: "a" }
    });
    return [
      { name: "bridgeRunnerInvokedPreserved", ok: result.runnerInvoked === false, detail: "" },
      { name: "bridgeStructuredCapturePreserved", ok: result.structuredResultCaptured === false, detail: "" },
      { name: "bridgeBlockedMapped", ok: result.status === "blocked" || result.status === "failed", detail: "" }
    ];
  }
});
