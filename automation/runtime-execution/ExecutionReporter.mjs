import { serializeExecutionResult } from "./ExecutionResultSerializer.mjs";

export function createExecutionReport(evaluation) {
  const { session, manifest, validation } = evaluation;
  const failed = session.assertions.filter((assertion) => assertion.status === "FAIL");
  const blocked = session.assertions.filter((assertion) => assertion.status === "BLOCKED");

  return `# Phase ${session.phase} Runtime Execution Report

Status: ${session.summary.status}

Framework: ${session.frameworkId} ${session.frameworkVersion}

Session: ${session.sessionId}

Backend: ${session.backend}

Runtime evidence claimed: ${session.summary.runtimeEvidenceClaimed}

Certification decision made: ${session.summary.certificationDecisionMade}

Validation:

- session: ${validation.session.ok ? "PASS" : "FAIL"}
- manifest: ${validation.manifest.ok ? "PASS" : "FAIL"}

Assertions:

- total: ${session.summary.totalAssertions}
- failed: ${failed.length}
- blocked: ${blocked.length}
- not executed: ${session.summary.notExecutedAssertions}

Next action:

${session.summary.nextAction}
`;
}

export function createReportBundle(evaluation) {
  return {
    manifestJson: serializeExecutionResult(evaluation.manifest),
    sessionJson: serializeExecutionResult(evaluation.session),
    summaryJson: serializeExecutionResult(evaluation.session.summary),
    evidenceManifestJson: serializeExecutionResult({
      sessionId: evaluation.session.sessionId,
      evidence: evaluation.session.evidence
    }),
    assertionReportJson: serializeExecutionResult({
      sessionId: evaluation.session.sessionId,
      assertions: evaluation.session.assertions
    }),
    capabilityReportJson: serializeExecutionResult({
      sessionId: evaluation.session.sessionId,
      capabilities: evaluation.session.capabilities
    }),
    cleanupReportJson: serializeExecutionResult(evaluation.session.cleanup),
    environmentReportJson: serializeExecutionResult(evaluation.session.environment),
    historyRecordJson: serializeExecutionResult(evaluation.session.history),
    reportMarkdown: createExecutionReport(evaluation)
  };
}
