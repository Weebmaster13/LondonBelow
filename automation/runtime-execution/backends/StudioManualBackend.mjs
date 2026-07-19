import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { blockedBackendResult, createBackendContract } from "./BackendContract.mjs";
import { buildTemporaryPlace } from "./StudioPlaceBuilder.mjs";
import { createRunnerInvocation } from "../RunnerInvocation.mjs";
import { importExecutionEvidence } from "../ExecutionEvidenceImporter.mjs";

export const StudioManualBackend = Object.freeze({
  contract: createBackendContract({
    backendId: "runtimeExecution.studioManual",
    backendKind: "StudioManual",
    displayName: "Studio Manual Backend",
    availability: "available",
    availabilityReason: "Manual backend can prepare source-bound Studio instructions and import structured results.",
    trustLevel: "MANUAL_SOURCE_BOUND",
    supportedExecutionModes: ["ManualStudioRun", "ManualStudioPlay", "EvidenceImport"],
    supportsLaunch: false,
    supportsPlayMode: true,
    supportsRunMode: true,
    supportsServer: true,
    supportsClient: false,
    supportsMultiClient: false,
    supportsStructuredCapture: true,
    requiresHumanAction: true,
    supportedPlatforms: ["win32", "darwin"],
    requiredTools: ["rojo"],
    configurationSchema: {
      timeoutMs: "positive integer",
      projectPath: "default.project.json",
      evidenceOutputRoot: "automation/local-state/runtime-execution"
    },
    priority: 10
  }),
  discover() {
    return { available: true, reason: "Manual backend is repository-owned and requires human Studio action." };
  },
  validateConfiguration(configuration) {
    return configuration.policies?.certificationDecisionAllowed === false
      ? { ok: true, reason: null }
      : { ok: false, reason: "manual backend cannot enable certification decisions" };
  },
  prepare(context) {
    const place = buildTemporaryPlace(context.sessionId, "default.project.json", { retain: true });
    const evidenceOutput = join("automation", "local-state", "runtime-execution", context.sessionId, "runtime-result.json");
    const invocation = createRunnerInvocation(context, evidenceOutput);
    const instructionPath = join("automation", "local-state", "runtime-execution", context.sessionId, "manual-studio-instructions.md");
    mkdirSync(dirname(instructionPath), { recursive: true });
    writeFileSync(
      instructionPath,
      `# Manual Studio Runtime Execution\n\nSession: ${context.sessionId}\n\nPlace: ${place.path}\n\nExpected result: ${evidenceOutput.replaceAll("\\", "/")}\n\n1. Open the generated place in Roblox Studio.\n2. Enter Run or Play mode.\n3. Invoke the repository-owned runtime runner matching runnerId ${invocation.runnerId}.\n4. Export the structured result to the expected result path.\n5. Resume with npm run london:studio-backend:manual:resume -- --session ${context.sessionId}.\n`,
      "utf8"
    );
    return {
      ...blockedBackendResult(this.contract, context, "prepare", "Manual action required before runtime evidence can be imported."),
      status: place.ok ? "waitingForManualAction" : "failed",
      stage: "prepare",
      artifacts: [place, { artifactId: `${context.sessionId}.instructions`, path: instructionPath.replaceAll("\\", "/") }],
      evidence: [{ category: "Build", status: place.ok ? "Recorded" : "Blocked", artifactIds: [place.artifactId] }],
      assertions: [{ name: "placePrepared", status: place.ok ? "PASS" : "FAIL" }],
      limitations: ["Studio was not launched by automation.", "Manual action is required."],
      nextAction: place.ok
        ? `Open ${place.path}, run the repository runner, and write ${evidenceOutput.replaceAll("\\", "/")}.`
        : "Fix Rojo place generation before manual execution."
    };
  },
  launch(context) {
    return {
      ...blockedBackendResult(this.contract, context, "waitingForManualAction", "Manual Studio backend does not launch Studio automatically."),
      status: "waitingForManualAction",
      nextAction: "Use the generated instruction file, then resume/import structured evidence."
    };
  },
  awaitResult(context) {
    return blockedBackendResult(this.contract, context, "awaitResult", "Manual backend awaits a repository-owned evidence file on resume.");
  },
  collectEvidence(context) {
    const evidencePath = join("automation", "local-state", "runtime-execution", context.sessionId, "runtime-result.json");
    return importExecutionEvidence(evidencePath, context);
  },
  validateEvidence(evidence, context) {
    return evidence?.sessionId === context.sessionId ? { ok: true, reason: null } : { ok: false, reason: "session mismatch" };
  },
  cleanup() {
    return { ok: true, reason: "manual backend preserves local-state artifacts for review; no binary artifact is committed" };
  },
  summarize(context) {
    return this.launch(context);
  },
  selfCheck() {
    return [
      { name: "manualBackendAvailable", ok: true, detail: "" },
      { name: "manualBackendRequiresHuman", ok: this.contract.requiresHumanAction === true, detail: "" },
      { name: "manualBackendSourceBoundTrust", ok: this.contract.trustLevel === "MANUAL_SOURCE_BOUND", detail: "" }
    ];
  }
});
