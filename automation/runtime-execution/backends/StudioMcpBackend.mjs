import { blockedBackendResult, createBackendContract } from "./BackendContract.mjs";
import { discoverStudioMcp } from "./StudioDiscovery.mjs";

export const StudioMcpBackend = Object.freeze({
  contract: createBackendContract({
    backendId: "runtimeExecution.studioMcp",
    backendKind: "StudioMCP",
    displayName: "Studio MCP Backend",
    availability: "blocked",
    availabilityReason: "No connected documented Studio MCP runner command is exposed to this repository.",
    trustLevel: "INSTALLATION_DISCOVERY",
    supportedExecutionModes: ["StudioMcpStructuredCapture"],
    supportsLaunch: false,
    supportsPlayMode: false,
    supportsRunMode: false,
    supportsStructuredCapture: false,
    requiresHumanAction: false,
    requiredTools: ["mcp.bat"],
    configurationSchema: { repositoryOptIn: "studioCertification.structuredCaptureMethods includes studioMcp" },
    priority: 30
  }),
  discover() {
    return discoverStudioMcp();
  },
  validateConfiguration() {
    const discovery = discoverStudioMcp();
    return discovery.repositoryOptIn && discovery.structuredCaptureCapable
      ? { ok: true, reason: null }
      : { ok: false, reason: discovery.reason };
  },
  prepare(context) {
    return blockedBackendResult(this.contract, context, "prepare", this.validateConfiguration().reason);
  },
  launch(context) {
    return blockedBackendResult(this.contract, context, "launch", "Studio MCP backend has no supported runner command binding.");
  },
  awaitResult(context) {
    return blockedBackendResult(this.contract, context, "awaitResult", "Studio MCP structured response is unavailable.");
  },
  collectEvidence(context) {
    return blockedBackendResult(this.contract, context, "collectEvidence", "Studio MCP evidence capture unavailable.");
  },
  validateEvidence() {
    return { ok: false, reason: "Studio MCP evidence unavailable" };
  },
  cleanup() {
    return { ok: true, reason: "nothing launched" };
  },
  summarize(context) {
    return this.launch(context);
  },
  selfCheck() {
    const discovery = discoverStudioMcp();
    return [
      { name: "mcpDiscoveryShape", ok: typeof discovery.detected === "boolean", detail: "" },
      { name: "mcpTruthfulBlocked", ok: this.contract.supportsStructuredCapture === false, detail: "" }
    ];
  }
});
