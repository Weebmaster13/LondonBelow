import { evidenceCategories } from "./ExecutionStatus.mjs";
import {
  runtimeExecutionFrameworkId,
  runtimeExecutionFrameworkVersion,
  runtimeExecutionSchemaVersion
} from "./ExecutionVersion.mjs";
import { createArtifactPlan } from "./ExecutionArtifacts.mjs";
import { deepFreeze } from "./ExecutionUtilities.mjs";

export function createExecutionManifest(configuration, environment, backend, capabilities, sessionId, timestamp) {
  return deepFreeze({
    schemaVersion: runtimeExecutionSchemaVersion,
    frameworkId: runtimeExecutionFrameworkId,
    frameworkVersion: runtimeExecutionFrameworkVersion,
    manifestId: `${sessionId}.manifest`,
    sessionId,
    phase: configuration.phase,
    phaseName: configuration.phaseName,
    backend: backend.backendKind,
    targets: [...configuration.targets],
    policies: { ...configuration.policies },
    environment,
    capabilities,
    evidenceCategories: [...evidenceCategories],
    artifactPlan: createArtifactPlan(sessionId),
    createdAt: timestamp
  });
}
