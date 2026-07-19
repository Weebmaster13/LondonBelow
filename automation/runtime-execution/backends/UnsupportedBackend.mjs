import { blockedBackendResult, createBackendContract } from "./BackendContract.mjs";

export const UnsupportedBackend = Object.freeze({
  contract: createBackendContract({
    backendId: "runtimeExecution.unsupported",
    backendKind: "FutureHeadless",
    displayName: "Unsupported Backend",
    availability: "blocked",
    availabilityReason: "No supported execution backend is available.",
    trustLevel: "STATIC_ONLY",
    priority: 999
  }),
  discover() {
    return { available: false, reason: "unsupported backend" };
  },
  validateConfiguration() {
    return { ok: false, reason: "unsupported backend" };
  },
  prepare(context) {
    return blockedBackendResult(this.contract, context, "prepare", "Unsupported backend cannot prepare execution.");
  },
  launch(context) {
    return blockedBackendResult(this.contract, context, "launch", "Unsupported backend cannot launch execution.");
  },
  awaitResult(context) {
    return blockedBackendResult(this.contract, context, "awaitResult", "Unsupported backend cannot await results.");
  },
  collectEvidence(context) {
    return blockedBackendResult(this.contract, context, "collectEvidence", "Unsupported backend cannot collect evidence.");
  },
  validateEvidence() {
    return { ok: false, reason: "unsupported backend" };
  },
  cleanup() {
    return { ok: true, reason: "nothing to clean" };
  },
  summarize(context) {
    return blockedBackendResult(this.contract, context, "summarize", "Unsupported backend summary is blocked.");
  },
  selfCheck() {
    return [{ name: "unsupportedBackendBlocked", ok: true, detail: "" }];
  }
});
