import { createFrameworkAssertions } from "./ExecutionAssertions.mjs";
import { createArtifactPlan } from "./ExecutionArtifacts.mjs";
import { evidenceCategories, executionStatusValues } from "./ExecutionStatus.mjs";
import {
  runtimeExecutionFrameworkId,
  runtimeExecutionFrameworkVersion,
  runtimeExecutionProtocolVersion,
  runtimeExecutionSchemaVersion
} from "./ExecutionVersion.mjs";
import { deepFreeze } from "./ExecutionUtilities.mjs";

export function createSessionId(configuration, environment) {
  return `phase-${configuration.phase}-runtime-execution-${environment.localHead.slice(0, 12)}`;
}

function createEvidenceRecords() {
  return evidenceCategories.map((category) => ({
    category,
    status: category === "Static" || category === "Build" ? "Recorded" : "Blocked",
    source: category === "Runtime" ? "ExecutionLauncher" : "RuntimeExecutionFramework",
    artifactIds: [],
    notes:
      category === "Runtime"
        ? ["No supported backend invoked runtime execution."]
        : ["Framework metadata evidence only."]
  }));
}

function createSummary(sessionId, configuration, backend, assertions) {
  const failedAssertions = assertions.filter((assertion) => assertion.status === "FAIL").length;
  const blockedAssertions = assertions.filter((assertion) => assertion.status === "BLOCKED").length;
  const notExecutedAssertions = assertions.filter((assertion) => assertion.status === "NOT_EXECUTED").length;
  return {
    status: "executionBlocked",
    sessionId,
    phase: configuration.phase,
    backend: backend.backendKind,
    runtimeEvidenceClaimed: false,
    certificationDecisionMade: false,
    totalAssertions: assertions.length,
    failedAssertions,
    blockedAssertions,
    notExecutedAssertions,
    nextAction:
      configuration.phase >= 152
        ? "Manual backend is ready for source-bound evidence import; future phases can request runtime validation through this framework."
        : "A future phase must bind a supported execution backend to this framework."
  };
}

export function createExecutionSession(configuration, environment, backend, capabilities, lifecycle, timestamp) {
  const sessionId = createSessionId(configuration, environment);
  const assertions = createFrameworkAssertions(sessionId);
  const artifacts = createArtifactPlan(sessionId);

  return deepFreeze({
    schemaVersion: runtimeExecutionSchemaVersion,
    frameworkId: runtimeExecutionFrameworkId,
    frameworkVersion: runtimeExecutionFrameworkVersion,
    protocolVersion: runtimeExecutionProtocolVersion,
    sessionId,
    phase: configuration.phase,
    phaseName: configuration.phaseName,
    repositoryCommit: environment.localHead,
    branch: environment.branch,
    backend: backend.backendKind,
    environment,
    participants: [...configuration.participants],
    capabilities,
    status: executionStatusValues.sessionArchived,
    lifecycle,
    timestamps: {
      requestedAt: timestamp,
      completedAt: timestamp,
      archivedAt: timestamp
    },
    artifacts,
    evidence: createEvidenceRecords(),
    assertions,
    errors: [],
    warnings: [
      configuration.phase >= 152
        ? "Runtime execution requires manual action or a supported automated backend; no runtime evidence is claimed by session creation."
        : "Runtime execution is blocked by design in Phase 151; framework architecture only."
    ],
    cleanup: {
      registered: true,
      started: true,
      completed: true,
      artifactIds: [],
      warnings: []
    },
    summary: createSummary(sessionId, configuration, backend, assertions),
    history: {
      historyId: `${sessionId}.history`,
      replayEligible: false,
      replayReason: "Replay metadata exists; no runtime event stream was captured."
    }
  });
}
