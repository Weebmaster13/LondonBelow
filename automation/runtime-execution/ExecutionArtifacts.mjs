import { deepFreeze } from "./ExecutionUtilities.mjs";

export function createArtifactPlan(sessionId) {
  return deepFreeze({
    root: `automation/runtime-execution/history/${sessionId}`,
    manifest: `automation/runtime-execution/history/${sessionId}/execution-manifest.json`,
    summary: `automation/runtime-execution/history/${sessionId}/execution-summary.json`,
    report: `automation/runtime-execution/history/${sessionId}/execution-report.md`,
    evidenceManifest: `automation/runtime-execution/history/${sessionId}/evidence-manifest.json`,
    cleanupReport: `automation/runtime-execution/history/${sessionId}/cleanup-report.json`
  });
}
