import { runtimeExecutionSchemaVersion } from "./ExecutionVersion.mjs";
import { deepFreeze } from "./ExecutionUtilities.mjs";

export const runnerInvocationFields = Object.freeze([
  "schemaVersion",
  "runnerId",
  "sessionId",
  "phase",
  "repositoryCommit",
  "executionMode",
  "requestedCapabilities",
  "assertionSet",
  "evidenceOutput",
  "timeout",
  "participantCount",
  "certificationRequested",
  "metadata"
]);

export function createRunnerInvocation(context, outputPath) {
  return deepFreeze({
    schemaVersion: runtimeExecutionSchemaVersion,
    runnerId: "runtimeExecution.phase152.manualStudioSmoke",
    sessionId: context.sessionId,
    phase: context.configuration.phase,
    repositoryCommit: context.environment.localHead,
    executionMode: context.backend.backendKind,
    requestedCapabilities: ["serverContextConfirmed", "structuredResultWritten", "cleanupCompleted"],
    assertionSet: ["runnerStarted", "repositoryCommitMatched", "sessionIdMatched"],
    evidenceOutput: outputPath.replaceAll("\\", "/"),
    timeout: context.configuration.policies.timeoutMs,
    participantCount: context.configuration.participants.length,
    certificationRequested: false,
    metadata: {
      framework: "runtimeExecution",
      phase: "152"
    }
  });
}
