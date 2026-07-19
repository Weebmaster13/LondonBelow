import { resolveCapabilities } from "./ExecutionCapabilities.mjs";
import { createExecutionConfiguration } from "./ExecutionConfiguration.mjs";
import { createLifecycle } from "./ExecutionLifecycle.mjs";
import { createExecutionManifest } from "./ExecutionManifest.mjs";
import { createExecutionRegistry, selectBackend } from "./ExecutionRegistry.mjs";
import { validateDeterministicSerialization } from "./ExecutionResultSerializer.mjs";
import {
  validateAssertion,
  validateBackendContract,
  validateCapability,
  validateEvidenceRecord,
  validateExecutionManifest,
  validateExecutionSession,
  validateLifecycle,
  validateSummary
} from "./ExecutionSchema.mjs";
import { assertionStatuses, capabilityStatuses, evidenceCategories, executionBackends, executionStatusValues } from "./ExecutionStatus.mjs";
import { createExecutionSession, createSessionId } from "./ExecutionSession.mjs";
import { evaluateRuntimeExecution } from "./ExecutionPipeline.mjs";
import { stableFrameworkTimestamp } from "./ExecutionVersion.mjs";

const stableEnvironment = Object.freeze({
  repository: "LondonBelow",
  branch: "main",
  localHead: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  remoteHead: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  workingTreeClean: true,
  originSynchronized: true,
  tools: []
});

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runRuntimeExecutionSelfChecks() {
  const results = [];
  const configuration = createExecutionConfiguration({
    phase: 151,
    phaseName: "Runtime Execution Framework Foundation"
  });
  const registry = createExecutionRegistry();
  const backend = selectBackend(registry, "StudioManual");
  const capabilities = resolveCapabilities(stableEnvironment, backend);
  const lifecycle = createLifecycle(stableFrameworkTimestamp);
  const sessionId = createSessionId(configuration, stableEnvironment);
  const manifest = createExecutionManifest(configuration, stableEnvironment, backend, capabilities, sessionId, stableFrameworkTimestamp);
  const session = createExecutionSession(configuration, stableEnvironment, backend, capabilities, lifecycle, stableFrameworkTimestamp);
  const evaluation = evaluateRuntimeExecution({
    ...configuration,
    environment: stableEnvironment,
    timestamp: stableFrameworkTimestamp
  });
  const rerun = evaluateRuntimeExecution({
    ...configuration,
    environment: stableEnvironment,
    timestamp: stableFrameworkTimestamp
  });
  const badSession = { ...session, runtimeEvidenceClaimed: true };
  const badSummary = { ...session.summary, runtimeEvidenceClaimed: true };
  const badCapability = { ...capabilities[0], status: "Maybe" };
  const badAssertion = { ...session.assertions[0], status: "MAYBE" };
  const badEvidence = { ...session.evidence[0], category: "Mixed" };
  const brokenLifecycle = [{ from: executionStatusValues.backendSelected, to: executionStatusValues.sessionArchived, reason: "skip", timestamp: stableFrameworkTimestamp }];

  assertSelfCheck(results, "schemaVersionStable", session.schemaVersion === 1 && manifest.schemaVersion === 1, "");
  assertSelfCheck(results, "frameworkIdentityStable", session.frameworkId === "london.runtimeExecutionFramework", "");
  assertSelfCheck(results, "phaseIdentity", session.phase === 151 && manifest.phase === 151, "");
  assertSelfCheck(results, "sessionValidation", validateExecutionSession(session).ok === true, "");
  assertSelfCheck(results, "manifestValidation", validateExecutionManifest(manifest).ok === true, "");
  assertSelfCheck(results, "rejectUnknownSessionField", validateExecutionSession(badSession).ok === false, "");
  assertSelfCheck(results, "summaryValidation", validateSummary(session.summary).ok === true, "");
  assertSelfCheck(results, "rejectRuntimeEvidenceClaim", validateSummary(badSummary).ok === false, "");
  assertSelfCheck(results, "lifecycleValidation", validateLifecycle(lifecycle).ok === true, "");
  assertSelfCheck(results, "rejectLifecycleSkip", validateLifecycle(brokenLifecycle).ok === false, "");
  assertSelfCheck(results, "backendRegistryComplete", registry.backends.length === executionBackends.length, "");
  assertSelfCheck(results, "backendContractsValid", registry.validation.every((entry) => entry.ok), "");
  assertSelfCheck(results, "manualBackendSelected", backend.backendKind === "StudioManual", "");
  assertSelfCheck(results, "backendContractValidation", validateBackendContract(backend).ok === true, "");
  assertSelfCheck(results, "capabilityVocabulary", capabilityStatuses.includes("Blocked") && capabilityStatuses.includes("Unknown"), "");
  assertSelfCheck(results, "capabilityCompleteness", capabilities.length >= 9, "");
  assertSelfCheck(results, "capabilityValidation", capabilities.every((capability) => validateCapability(capability).ok), "");
  assertSelfCheck(results, "rejectBadCapabilityStatus", validateCapability(badCapability).ok === false, "");
  assertSelfCheck(results, "assertionVocabulary", assertionStatuses.includes("NOT_EXECUTED"), "");
  assertSelfCheck(results, "assertionValidation", session.assertions.every((assertion) => validateAssertion(assertion).ok), "");
  assertSelfCheck(results, "rejectBadAssertionStatus", validateAssertion(badAssertion).ok === false, "");
  assertSelfCheck(results, "evidenceCategoriesSeparated", evidenceCategories.includes("Runtime") && evidenceCategories.includes("Certification"), "");
  assertSelfCheck(results, "evidenceValidation", session.evidence.every((record) => validateEvidenceRecord(record).ok), "");
  assertSelfCheck(results, "rejectMixedEvidenceCategory", validateEvidenceRecord(badEvidence).ok === false, "");
  assertSelfCheck(results, "artifactPlanStable", session.artifacts.manifest.endsWith("execution-manifest.json"), "");
  assertSelfCheck(results, "cleanupRegistered", session.cleanup.registered === true && session.cleanup.completed === true, "");
  assertSelfCheck(results, "historyGenerated", session.history.historyId.endsWith(".history"), "");
  assertSelfCheck(results, "replayMetadataOnly", session.history.replayEligible === false, "");
  assertSelfCheck(results, "deterministicSerialization", validateDeterministicSerialization(evaluation.session, rerun.session), "");
  assertSelfCheck(results, "deterministicManifest", validateDeterministicSerialization(evaluation.manifest, rerun.manifest), "");
  assertSelfCheck(results, "blockedExecutionStatus", evaluation.status === "executionBlocked", "");
  assertSelfCheck(results, "stableExitCode", evaluation.exitCode === 2, "");
  assertSelfCheck(results, "noRuntimeInvocation", evaluation.runtimeInvoked === false, "");
  assertSelfCheck(results, "noStudioLaunch", evaluation.studioLaunched === false, "");
  assertSelfCheck(results, "noCertificationAuthorityInvocation", evaluation.certificationAuthorityInvoked === false, "");
  assertSelfCheck(results, "certificationDecisionNotMade", session.summary.certificationDecisionMade === false, "");
  assertSelfCheck(results, "runtimeEvidenceNotClaimed", session.summary.runtimeEvidenceClaimed === false, "");
  assertSelfCheck(results, "environmentSnapshotIsolated", evaluation.environment !== stableEnvironment || Object.isFrozen(evaluation), "");
  assertSelfCheck(results, "sessionImmutable", Object.isFrozen(session) && Object.isFrozen(session.summary), "");
  assertSelfCheck(results, "registryImmutable", Object.isFrozen(registry) && Object.isFrozen(registry.backends), "");
  assertSelfCheck(results, "lifecycleStatusesCovered", Object.values(executionStatusValues).every((status) => lifecycle.some((entry) => entry.from === status || entry.to === status)), "");
  assertSelfCheck(results, "futureBackendContracts", executionBackends.includes("FutureCertificationRunner") && executionBackends.includes("FutureMultiplayerRunner"), "");
  assertSelfCheck(results, "manualQaEvidenceSeparated", session.evidence.some((record) => record.category === "ManualQA"), "");
  assertSelfCheck(results, "buildEvidenceSeparated", session.evidence.some((record) => record.category === "Build"), "");
  assertSelfCheck(results, "staticEvidenceRecorded", session.evidence.find((record) => record.category === "Static").status === "Recorded", "");
  assertSelfCheck(results, "runtimeEvidenceBlocked", session.evidence.find((record) => record.category === "Runtime").status === "Blocked", "");
  assertSelfCheck(results, "certificationEvidenceBlocked", session.evidence.find((record) => record.category === "Certification").status === "Blocked", "");
  assertSelfCheck(results, "noGameplayOwnership", !("gameplay" in evaluation), "");
  assertSelfCheck(results, "noObservationOwnership", !("observation" in evaluation), "");
  assertSelfCheck(results, "noInteractionOwnership", !("interaction" in evaluation), "");
  assertSelfCheck(results, "noNetworking", !("remote" in evaluation) && !("network" in evaluation), "");
  assertSelfCheck(results, "noPersistence", !("dataStore" in evaluation), "");
  assertSelfCheck(results, "noAnalytics", !("analytics" in evaluation), "");
  assertSelfCheck(results, "noTelemetry", !("telemetry" in evaluation), "");

  return results;
}
