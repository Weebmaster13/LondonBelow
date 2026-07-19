import { resolveCapabilities } from "./ExecutionCapabilities.mjs";
import { createExecutionConfiguration } from "./ExecutionConfiguration.mjs";
import { createBlockedLifecycle, createLifecycle, createManualLifecycle } from "./ExecutionLifecycle.mjs";
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
import { createBackendRegistry as createModuleBackendRegistry } from "./backends/BackendRegistry.mjs";
import { selectBackend as selectModuleBackend } from "./backends/BackendSelection.mjs";
import { validateBackendModuleContract } from "./backends/BackendContract.mjs";
import { StudioManualBackend } from "./backends/StudioManualBackend.mjs";
import { StudioMcpBackend } from "./backends/StudioMcpBackend.mjs";
import { StudioBridgeBackend } from "./backends/StudioBridgeBackend.mjs";
import { discoverStudioInstallations, discoverStudioMcp } from "./backends/StudioDiscovery.mjs";
import { createRunnerInvocation } from "./RunnerInvocation.mjs";
import { validateRunnerResult } from "./RunnerResultSchema.mjs";
import { importExecutionEvidence } from "./ExecutionEvidenceImporter.mjs";
import { classifyTimeout, createTimeoutPolicy } from "./ExecutionTimeoutManager.mjs";
import { classifySessionRecovery } from "./ExecutionRecovery.mjs";

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
  const manualLifecycle = createManualLifecycle(stableFrameworkTimestamp);
  const blockedLifecycle = createBlockedLifecycle(stableFrameworkTimestamp);
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
  const lifecycleStatuses = [...lifecycle, ...manualLifecycle, ...blockedLifecycle].flatMap((entry) => [entry.from, entry.to]);
  assertSelfCheck(results, "lifecycleStatusesCovered", Object.values(executionStatusValues).every((status) => lifecycleStatuses.includes(status) || ["ExecutionFailed", "TimedOut", "Cancelled", "CleanupFailed"].includes(status)), "");
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

  const moduleRegistry = createModuleBackendRegistry();
  const moduleSelection = selectModuleBackend(moduleRegistry, "StudioManual");
  const manualContract = StudioManualBackend.contract;
  const mcpDiscovery = discoverStudioMcp();
  const studioInstallations = discoverStudioInstallations();
  const invocationContext = {
    sessionId,
    configuration,
    environment: stableEnvironment,
    backend: manualContract,
    timestamp: stableFrameworkTimestamp
  };
  const invocation = createRunnerInvocation(invocationContext, "automation/local-state/runtime-execution/selfcheck/runtime-result.json");
  const validRunnerResult = {
    schemaVersion: 1,
    runnerId: invocation.runnerId,
    sessionId,
    phase: 151,
    repositoryCommit: stableEnvironment.localHead,
    runtime: "RobloxStudio",
    status: "blocked",
    studioVersion: "unavailable",
    serverStarted: false,
    clientStarted: false,
    clientCount: 0,
    assertions: [{ name: "runnerStarted", status: "BLOCKED" }],
    diagnostics: {},
    snapshots: {},
    audit: [],
    errors: [],
    warnings: ["manual evidence not imported"],
    cleanup: { completed: true },
    productionCertified: false,
    capturedAt: stableFrameworkTimestamp
  };

  assertSelfCheck(results, "phase152BackendRegistryCreated", moduleRegistry.registryId === "runtimeExecution.backendRegistry.v2", "");
  assertSelfCheck(results, "phase152BackendRegistryDeterministic", typeof moduleRegistry.stableCatalog === "string" && moduleRegistry.stableCatalog.length > 0, "");
  assertSelfCheck(results, "phase152BackendRegistryValidation", moduleRegistry.validation.every((entry) => entry.ok), "");
  assertSelfCheck(results, "phase152DuplicateIdGuardPresent", new Set(moduleRegistry.backends.map((item) => item.backendId)).size === moduleRegistry.backends.length, "");
  assertSelfCheck(results, "phase152ManualBackendRegistered", moduleRegistry.backends.some((item) => item.backendId === "runtimeExecution.studioManual"), "");
  assertSelfCheck(results, "phase152BridgeBackendRegistered", moduleRegistry.backends.some((item) => item.backendId === "runtimeExecution.studioBridge"), "");
  assertSelfCheck(results, "phase152McpBackendRegistered", moduleRegistry.backends.some((item) => item.backendId === "runtimeExecution.studioMcp"), "");
  assertSelfCheck(results, "phase152ManualSelection", moduleSelection.contract.backendId === "runtimeExecution.studioManual", "");
  assertSelfCheck(results, "phase152NoSilentFallback", moduleSelection.fallbackUsed === false, "");
  assertSelfCheck(results, "phase152SelectionReason", moduleSelection.reason.includes("Selected requested backend"), "");
  assertSelfCheck(results, "phase152ManualContractValid", validateBackendModuleContract(manualContract).ok === true, "");
  assertSelfCheck(results, "phase152ManualBeyondPlaceholder", manualContract.supportsStructuredCapture === true && manualContract.trustLevel === "MANUAL_SOURCE_BOUND", "");
  assertSelfCheck(results, "phase152ManualRequiresHuman", manualContract.requiresHumanAction === true, "");
  assertSelfCheck(results, "phase152ManualNoAutoLaunch", manualContract.supportsLaunch === false, "");
  assertSelfCheck(results, "phase152McpTruthfulBlocked", StudioMcpBackend.contract.availability === "blocked", "");
  assertSelfCheck(results, "phase152McpDiscoveryShape", typeof mcpDiscovery.detected === "boolean", "");
  assertSelfCheck(results, "phase152BridgeTruthfulBlocked", StudioBridgeBackend.contract.availability === "blocked", "");
  assertSelfCheck(results, "phase152StudioDiscoveryShape", Array.isArray(studioInstallations), "");
  assertSelfCheck(results, "phase152StudioDiscoveryNormalized", studioInstallations.every((item) => !String(item.executable).includes(process.env.USERPROFILE ?? "never-match")), "");
  assertSelfCheck(results, "phase152RunnerInvocationSchema", invocation.schemaVersion === 1 && invocation.certificationRequested === false, "");
  assertSelfCheck(results, "phase152RunnerInvocationSourceBound", invocation.repositoryCommit === stableEnvironment.localHead, "");
  assertSelfCheck(results, "phase152RunnerInvocationSessionBound", invocation.sessionId === sessionId, "");
  assertSelfCheck(results, "phase152RunnerResultValidation", validateRunnerResult(validRunnerResult, invocationContext).ok === true, "");
  assertSelfCheck(results, "phase152RejectMismatchedSession", validateRunnerResult({ ...validRunnerResult, sessionId: "wrong" }, invocationContext).ok === false, "");
  assertSelfCheck(results, "phase152RejectMismatchedCommit", validateRunnerResult({ ...validRunnerResult, repositoryCommit: "bbbb" }, invocationContext).ok === false, "");
  assertSelfCheck(results, "phase152RejectCertificationMutation", validateRunnerResult({ ...validRunnerResult, productionCertified: true }, invocationContext).ok === false, "");
  assertSelfCheck(results, "phase152RejectUnsupportedSchema", validateRunnerResult({ ...validRunnerResult, schemaVersion: 999 }, invocationContext).ok === false, "");
  assertSelfCheck(results, "phase152EvidenceImportPathGuard", importExecutionEvidence("../outside.json", invocationContext).ok === false, "");
  assertSelfCheck(results, "phase152TimeoutPolicyFinite", createTimeoutPolicy(1000).finite === true, "");
  assertSelfCheck(results, "phase152TimeoutClassification", classifyTimeout(0, 100, 101) === "timedOut", "");
  assertSelfCheck(results, "phase152NonTimeoutClassification", classifyTimeout(0, 100, 99) === "withinTimeout", "");
  assertSelfCheck(results, "phase152RecoveryMissingSession", classifySessionRecovery(null, stableFrameworkTimestamp).resumable === false, "");
  assertSelfCheck(results, "phase152RecoveryBlockedSession", classifySessionRecovery(session, stableFrameworkTimestamp).resumable === true, "");
  assertSelfCheck(results, "phase152ManualSelfChecks", StudioManualBackend.selfCheck().every((check) => check.ok), "");
  assertSelfCheck(results, "phase152McpSelfChecks", StudioMcpBackend.selfCheck().every((check) => check.ok), "");
  assertSelfCheck(results, "phase152BridgeSelfChecks", StudioBridgeBackend.selfCheck().every((check) => check.ok), "");
  assertSelfCheck(results, "phase152TrustLevels", manualContract.trustLevel === "MANUAL_SOURCE_BOUND" && StudioMcpBackend.contract.trustLevel === "INSTALLATION_DISCOVERY", "");
  assertSelfCheck(results, "phase152EvidenceOutputRoot", invocation.evidenceOutput.startsWith("automation/local-state/runtime-execution"), "");
  assertSelfCheck(results, "phase152ManualCleanupPolicy", StudioManualBackend.cleanup().ok === true, "");
  assertSelfCheck(results, "phase152McpNoLaunch", StudioMcpBackend.contract.supportsLaunch === false, "");
  assertSelfCheck(results, "phase152BridgeNoRunnerInvocationInSelfCheck", StudioBridgeBackend.selfCheck().some((check) => check.name === "bridgeRunnerInvokedPreserved"), "");

  return results;
}
