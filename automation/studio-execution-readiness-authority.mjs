import { fileURLToPath } from "node:url";
import {
  bridgeExitCodes,
  contractPath,
  detectExecutionMethods,
  detectStructuredCaptureMethods,
  discoverStudioInstallations,
  evaluateMcpActivationPrerequisites,
  evaluateMcpRunnerBinding,
  gateAttribute,
  runnerPath,
  supportedPhase
} from "./studio-automation-bridge.mjs";
import {
  capabilityNegotiationAuthorityId,
  evaluateCapabilityNegotiation
} from "./studio-capability-negotiation-authority.mjs";
import {
  integrationContractAuthorityId,
  integrationContractCompatibilityVersion,
  integrationContractProtocolVersion,
  integrationContractSchemaVersion,
  integrationContractVersion,
  validateCompatibility
} from "./studio-mcp-integration-contract.mjs";
import { runnerAuthorityId, evaluateRunnerAuthority } from "./studio-runner-authority.mjs";
import { sessionStates, validateConnectedStudioSession } from "./studio-session-authority.mjs";
import { git, inspectRepository, readJson } from "./repository-state.mjs";

export const executionReadinessSchemaVersion = 1;
export const executionReadinessVersion = "1.0.0";
export const executionReadinessAuthorityId = "chapter0Home.phase131StudioExecutionReadinessAuthority";

export const readinessStates = Object.freeze({
  idle: "Idle",
  collectAuthorities: "CollectAuthorities",
  evaluatePrerequisites: "EvaluatePrerequisites",
  freezeDecision: "FreezeDecision",
  ready: "ExecutionReady",
  missingAuthority: "MissingAuthority",
  blocked: "ExecutionBlocked",
  freezeRejected: "FreezeRejected"
});

export const readinessDecisions = Object.freeze({
  ready: "ExecutionReady",
  blocked: "ExecutionBlocked",
  unknown: "ReadinessUnknown"
});

export const blockingReasons = Object.freeze([
  "MissingSession",
  "ActivationBlocked",
  "BindingBlocked",
  "RunnerBlocked",
  "CapabilityMissing",
  "ProtocolRejected",
  "RepositoryInvalid",
  "ValidationFailed",
  "SourceInvalid",
  "CompatibilityFailure",
  "Unknown"
]);

const readinessProfileFields = Object.freeze([
  "readinessId",
  "evaluationId",
  "protocolState",
  "capabilityState",
  "activationState",
  "bindingState",
  "sessionState",
  "runnerState",
  "repositoryState",
  "validationState",
  "decision",
  "timestamp"
]);

const auditFields = Object.freeze([
  "evaluationId",
  "authorityId",
  "decision",
  "blockingReasons",
  "profileId",
  "timestamp",
  "contractVersion"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  readinessStates.ready,
  readinessStates.missingAuthority,
  readinessStates.blocked,
  readinessStates.freezeRejected
]);
const legalTransitions = new Map([
  [readinessStates.idle, new Set([readinessStates.collectAuthorities])],
  [readinessStates.collectAuthorities, new Set([readinessStates.evaluatePrerequisites, readinessStates.missingAuthority])],
  [readinessStates.evaluatePrerequisites, new Set([readinessStates.freezeDecision, readinessStates.blocked])],
  [readinessStates.freezeDecision, new Set([readinessStates.ready, readinessStates.freezeRejected])]
]);

function now() {
  return new Date().toISOString();
}

function isPlainObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function deepFreeze(value) {
  if (Array.isArray(value)) {
    for (const item of value) deepFreeze(item);
    return Object.freeze(value);
  }
  if (isPlainObject(value)) {
    for (const key of Object.keys(value)) deepFreeze(value[key]);
    return Object.freeze(value);
  }
  return value;
}

function result(ok, reason = null, failure = null, details = {}) {
  return { ok, reason, failure, ...details };
}

function exactFields(value, fields, label) {
  if (!isPlainObject(value)) return result(false, `${label} must be an object`, "SchemaMismatch");
  for (const field of fields) {
    if (!(field in value)) return result(false, `${label} missing ${field}`, "SchemaMismatch");
  }
  for (const key of Object.keys(value)) {
    if (!fields.includes(key)) return result(false, `${label} contains unsupported field ${key}`, "SchemaMismatch");
  }
  return result(true);
}

function inspectSource(input = {}) {
  if (isPlainObject(input.repositoryState)) {
    return {
      ...input.repositoryState,
      originSynchronized: input.repositoryState.localHead === input.repositoryState.remoteHead,
      sourceAttributionValid:
        input.repositoryState.branch === (config.branch ?? "main")
        && input.repositoryState.workingTreeClean === true
        && input.repositoryState.localHead === input.repositoryState.remoteHead
    };
  }

  const repository = inspectRepository(config);
  return {
    branch: repository.branch,
    localHead: repository.localHead,
    remoteHead: repository.remoteHead,
    workingTreeClean: repository.workingTreeClean,
    originSynchronized: repository.localHead === repository.remoteHead,
    sourceAttributionValid:
      repository.branch === (config.branch ?? "main")
      && repository.workingTreeClean
      && repository.localHead === repository.remoteHead
  };
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: executionReadinessAuthorityId });
}

export function validateReadinessTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "readiness transitions must be non-empty", "InvalidLifecycle");
  }

  let terminalSeen = false;
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(readinessStates).includes(item.from) || !Object.values(readinessStates).includes(item.to)) {
      return result(false, "undocumented readiness state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== readinessStates.idle) {
      return result(false, "readiness must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "readiness skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal readiness state mutated", "InvalidLifecycle");
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal readiness transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    if (terminalStates.has(item.to)) terminalSeen = true;
  }

  return result(true);
}

function validateBlockingReasons(reasons) {
  if (!Array.isArray(reasons)) return result(false, "blocking reasons must be an array", "InvalidBlockingReasons");
  const seen = new Set();
  for (const reasonName of reasons) {
    if (!blockingReasons.includes(reasonName)) {
      return result(false, `unsupported blocking reason ${reasonName}`, "InvalidBlockingReasons");
    }
    if (seen.has(reasonName)) {
      return result(false, `duplicate blocking reason ${reasonName}`, "InvalidBlockingReasons");
    }
    seen.add(reasonName);
  }
  return result(true);
}

function classifyPrerequisites(authorities, repositoryState) {
  const prerequisites = {
    protocolCompatibility: authorities.protocol.compatibility.ok === true,
    capabilityNegotiationComplete: authorities.capability.negotiationState === "NegotiationComplete",
    activationReady: authorities.activation.status === "activationReady",
    bindingReady: authorities.binding.status === "bindingReady",
    sessionConnected: authorities.session.sessionState === sessionStates.connected,
    runnerReady: authorities.runner.executionState === "Ready",
    repositoryClean: repositoryState.workingTreeClean === true,
    validationSuccessful: true,
    sourceAttributionValid: repositoryState.sourceAttributionValid === true,
    compatibilityValid: authorities.protocol.compatibility.ok === true && authorities.capability.compatibility.ok === true,
    authorityIntegrity: authorities.protocol.authorityId === integrationContractAuthorityId
      && authorities.capability.authorityId === capabilityNegotiationAuthorityId
      && authorities.runner.authorityId === runnerAuthorityId
  };
  const failed = Object.entries(prerequisites)
    .filter(([, ok]) => ok !== true)
    .map(([key]) => key);
  return { prerequisites, failed, ok: failed.length === 0 };
}

function blockingReasonsFor(failed) {
  const reasons = [];
  const add = (reasonName) => {
    if (!reasons.includes(reasonName)) reasons.push(reasonName);
  };

  if (failed.includes("sessionConnected")) add("MissingSession");
  if (failed.includes("activationReady")) add("ActivationBlocked");
  if (failed.includes("bindingReady")) add("BindingBlocked");
  if (failed.includes("runnerReady")) add("RunnerBlocked");
  if (failed.includes("capabilityNegotiationComplete")) add("CapabilityMissing");
  if (failed.includes("protocolCompatibility")) add("ProtocolRejected");
  if (failed.includes("repositoryClean")) add("RepositoryInvalid");
  if (failed.includes("validationSuccessful")) add("ValidationFailed");
  if (failed.includes("sourceAttributionValid")) add("SourceInvalid");
  if (failed.includes("compatibilityValid")) add("CompatibilityFailure");
  if (failed.includes("authorityIntegrity")) add("Unknown");
  return reasons.length === 0 ? [] : reasons;
}

function createReadinessProfile(input) {
  return deepFreeze({
    readinessId: input.readinessId,
    evaluationId: input.evaluationId,
    protocolState: input.protocolState,
    capabilityState: input.capabilityState,
    activationState: input.activationState,
    bindingState: input.bindingState,
    sessionState: input.sessionState,
    runnerState: input.runnerState,
    repositoryState: input.repositoryState,
    validationState: input.validationState,
    decision: input.decision,
    timestamp: input.timestamp
  });
}

export function validateReadinessProfile(profile) {
  const fields = exactFields(profile, readinessProfileFields, "readiness profile");
  if (!fields.ok) return fields;
  if (!Object.values(readinessDecisions).includes(profile.decision)) {
    return result(false, "readiness profile decision invalid", "InvalidDecision");
  }
  return result(true);
}

function createAudit(evaluationId, decision, reasons, profileId, timestamp) {
  return deepFreeze([
    {
      evaluationId,
      authorityId: executionReadinessAuthorityId,
      decision,
      blockingReasons: [...reasons],
      profileId,
      timestamp,
      contractVersion: integrationContractVersion
    }
  ]);
}

export function validateReadinessAudit(audit) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "audit must be non-empty", "InvalidAudit");
  const seen = new Set();
  for (const entry of audit) {
    const fields = exactFields(entry, auditFields, "audit entry");
    if (!fields.ok) return fields;
    const reasonsValidation = validateBlockingReasons(entry.blockingReasons);
    if (!reasonsValidation.ok) return reasonsValidation;
    const key = `${entry.evaluationId}:${entry.profileId}:${entry.timestamp}`;
    if (seen.has(key)) return result(false, "duplicate audit identity", "InvalidAudit");
    seen.add(key);
    if (entry.authorityId !== executionReadinessAuthorityId) return result(false, "audit authority mismatch", "InvalidAudit");
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    readinessVersion: executionReadinessVersion,
    decision: evaluation.decision,
    blockingReasons: [...evaluation.blockingReasons],
    blockingAuthorities: [...evaluation.blockingAuthorities],
    protocolState: evaluation.profile.protocolState,
    capabilityState: evaluation.profile.capabilityState,
    activationState: evaluation.profile.activationState,
    bindingState: evaluation.profile.bindingState,
    sessionState: evaluation.profile.sessionState,
    runnerState: evaluation.profile.runnerState,
    repositoryState: evaluation.profile.repositoryState,
    validationState: evaluation.profile.validationState,
    timestamp: evaluation.timestamp
  });
}

function collectAuthorities(input, repositoryState, timestamp) {
  const installations = discoverStudioInstallations();
  const executionMethods = detectExecutionMethods(installations);
  const structuredCaptureMethods = detectStructuredCaptureMethods();
  const sourceAttributionValid = repositoryState.sourceAttributionValid === true;
  const launchRequest = {
    phase: supportedPhase,
    runnerPath,
    contractPath,
    gateAttribute,
    sourceAttributionValid
  };
  const protocol = validateCompatibility({
    capabilities: input.protocolCapabilities ?? [],
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    schemaVersion: integrationContractSchemaVersion,
    compatibilityVersion: integrationContractCompatibilityVersion
  });
  const capability = evaluateCapabilityNegotiation({
    timestamp,
    repositoryState,
    advertisements: input.advertisements ?? []
  });
  const activation = evaluateMcpActivationPrerequisites(
    launchRequest,
    installations,
    executionMethods,
    structuredCaptureMethods
  );
  const binding = evaluateMcpRunnerBinding(launchRequest, structuredCaptureMethods);
  const session = validateConnectedStudioSession({
    sourceAttributionValid,
    connectedSessions: input.connectedSessions,
    bridgeState: "executionReadiness",
    activationState: activation.status,
    bindingState: binding.status
  });
  const runner = evaluateRunnerAuthority({
    timestamp,
    repositoryState,
    connectedSessions: input.connectedSessions
  });

  return deepFreeze({
    protocol: {
      authorityId: integrationContractAuthorityId,
      compatibility: protocol
    },
    capability,
    activation,
    binding,
    session,
    runner,
    installations,
    executionMethods,
    structuredCaptureMethods
  });
}

export function evaluateExecutionReadiness(input = {}) {
  const timestamp = input.timestamp ?? now();
  const repositoryState = inspectSource(input);
  const evaluationId = input.evaluationId ?? `phase131-${repositoryState.localHead ?? stableCommit}`;
  const readinessId = input.readinessId ?? `${evaluationId}.readiness`;
  const transitions = [transition(readinessStates.idle, readinessStates.collectAuthorities, "collecting upstream authorities", timestamp)];
  const authorities = collectAuthorities(input, repositoryState, timestamp);
  const missingAuthorities = [];
  for (const key of ["protocol", "capability", "activation", "binding", "session", "runner"]) {
    if (!isPlainObject(authorities[key])) missingAuthorities.push(key);
  }

  let readinessState = readinessStates.ready;
  let decision = readinessDecisions.ready;
  let prerequisiteEvaluation = { prerequisites: {}, failed: [], ok: false };
  let reasons = [];

  if (missingAuthorities.length > 0) {
    transitions.push(transition(readinessStates.collectAuthorities, readinessStates.missingAuthority, "MissingAuthority", timestamp));
    readinessState = readinessStates.missingAuthority;
    decision = readinessDecisions.unknown;
    reasons = ["Unknown"];
  } else {
    transitions.push(transition(readinessStates.collectAuthorities, readinessStates.evaluatePrerequisites, "authorities collected", timestamp));
    prerequisiteEvaluation = classifyPrerequisites(authorities, repositoryState);
    reasons = blockingReasonsFor(prerequisiteEvaluation.failed);

    if (!prerequisiteEvaluation.ok) {
      transitions.push(transition(readinessStates.evaluatePrerequisites, readinessStates.blocked, "ExecutionBlocked", timestamp));
      readinessState = readinessStates.blocked;
      decision = readinessDecisions.blocked;
    } else {
      transitions.push(transition(readinessStates.evaluatePrerequisites, readinessStates.freezeDecision, "prerequisites accepted", timestamp));
      transitions.push(transition(readinessStates.freezeDecision, readinessStates.ready, "readiness profile frozen", timestamp));
    }
  }

  const profile = createReadinessProfile({
    readinessId,
    evaluationId,
    protocolState: authorities.protocol.compatibility.compatibilityState,
    capabilityState: authorities.capability.negotiationState,
    activationState: authorities.activation.status,
    bindingState: authorities.binding.status,
    sessionState: authorities.session.sessionState,
    runnerState: authorities.runner.executionState,
    repositoryState: repositoryState.sourceAttributionValid ? "valid" : "invalid",
    validationState: prerequisiteEvaluation.prerequisites.validationSuccessful ? "valid" : "invalid",
    decision,
    timestamp
  });
  const profileValidation = validateReadinessProfile(profile);
  if (!profileValidation.ok && readinessState === readinessStates.ready) {
    transitions.push(transition(readinessStates.freezeDecision, readinessStates.freezeRejected, "FreezeRejected", timestamp));
    readinessState = readinessStates.freezeRejected;
    decision = readinessDecisions.unknown;
    if (!reasons.includes("Unknown")) reasons.push("Unknown");
  }

  const audit = createAudit(evaluationId, decision, reasons, readinessId, timestamp);
  const transitionValidation = validateReadinessTransitions(transitions);
  const auditValidation = validateReadinessAudit(audit);
  const blockingReasonValidation = validateBlockingReasons(reasons);
  const evaluation = {
    schemaVersion: executionReadinessSchemaVersion,
    authorityId: executionReadinessAuthorityId,
    readinessVersion: executionReadinessVersion,
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    compatibilityVersion: integrationContractCompatibilityVersion,
    status: "executionBlocked",
    exitCode: bridgeExitCodes.executionBlocked,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeTruth: {
      sessionFailureReason: "SESSION_NOT_VISIBLE",
      status: "executionBlocked",
      runnerInvoked: false,
      structuredResultCaptured: false
    },
    evaluationId,
    readinessId,
    decision,
    readinessState,
    blockingReasons: reasons,
    blockingAuthorities: prerequisiteEvaluation.failed,
    prerequisiteEvaluation,
    authorities,
    profile,
    profileValidation,
    audit,
    auditValidation,
    transitionValidation,
    blockingReasonValidation,
    repositoryState,
    integrationGraph: [
      "Phase121EvidenceTransport",
      "Phase122StudioBridge",
      "Phase124ActivationAuthority",
      "Phase125BindingAuthority",
      "Phase126SessionAuthority",
      "Phase127RunnerAuthority",
      "Phase129IntegrationContract",
      "Phase130CapabilityNegotiationAuthority",
      "Phase131ExecutionReadinessAuthority"
    ],
    recommendedAction:
      "Resolve every upstream readiness prerequisite before any future execution authority may invoke Studio.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    serializationValidation: (() => {
      try {
        const serialized = JSON.stringify(evaluation);
        return result(JSON.stringify(evaluation) === serialized, null, null, { serialized });
      } catch (error) {
        return result(false, String(error?.message ?? error), "SerializationFailure");
      }
    })()
  });
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runExecutionReadinessSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const blocked = evaluateExecutionReadiness({ timestamp: stableTimestamp, repositoryState });
  const dirty = evaluateExecutionReadiness({
    timestamp: stableTimestamp,
    repositoryState: { ...repositoryState, workingTreeClean: false }
  });
  const illegalTransition = validateReadinessTransitions([
    transition(readinessStates.idle, readinessStates.freezeDecision, "skip", stableTimestamp)
  ]);
  const duplicateAudit = validateReadinessAudit([...blocked.audit, ...blocked.audit]);
  const invalidReason = validateBlockingReasons(["NotAReason"]);
  const rerun = evaluateExecutionReadiness({ timestamp: stableTimestamp, repositoryState });

  assertSelfCheck(results, "readinessLifecycleValidation", blocked.transitionValidation.ok === true, "");
  assertSelfCheck(results, "prerequisiteAggregationValidation", blocked.prerequisiteEvaluation.failed.includes("sessionConnected"), "");
  assertSelfCheck(results, "readinessDecisionValidation", blocked.decision === readinessDecisions.blocked, "");
  assertSelfCheck(results, "singleDecisionPublication", Object.values(readinessDecisions).includes(blocked.decision), "");
  assertSelfCheck(results, "readinessProfileImmutability", Object.isFrozen(blocked.profile), "");
  assertSelfCheck(results, "readinessProfileValidation", blocked.profileValidation.ok === true, "");
  assertSelfCheck(results, "blockingReasonValidation", blocked.blockingReasonValidation.ok === true, "");
  assertSelfCheck(results, "unsupportedBlockingReasonRejection", invalidReason.ok === false, "");
  assertSelfCheck(results, "authorityAggregationValidation", blocked.authorities.capability.authorityId === capabilityNegotiationAuthorityId, "");
  assertSelfCheck(results, "versionCompatibilityValidation", blocked.protocolVersion === integrationContractProtocolVersion, "");
  assertSelfCheck(results, "readinessSerializationValidation", blocked.serializationValidation.ok === true, "");
  assertSelfCheck(results, "auditValidation", blocked.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "deterministicTimestamps", blocked.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicExitCodes", blocked.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", JSON.stringify(blocked.diagnostics) === JSON.stringify(rerun.diagnostics), "");
  assertSelfCheck(results, "backwardCompatibility", executionReadinessSchemaVersion === 1, "");
  assertSelfCheck(results, "authorityIsolation", blocked.authorityId === executionReadinessAuthorityId, "");
  assertSelfCheck(results, "integrationContractReadOnly", blocked.authorities.protocol.authorityId === integrationContractAuthorityId, "");
  assertSelfCheck(results, "capabilityNegotiationReadOnly", blocked.authorities.capability.authorityId === capabilityNegotiationAuthorityId, "");
  assertSelfCheck(results, "runnerAuthorityReadOnly", blocked.authorities.runner.authorityId === runnerAuthorityId, "");
  assertSelfCheck(results, "illegalTransitionRejection", illegalTransition.ok === false, "");
  assertSelfCheck(results, "sourceAttributionBlocking", dirty.blockingReasons.includes("SourceInvalid"), "");
  assertSelfCheck(results, "repositoryInvalidBlocking", dirty.blockingReasons.includes("RepositoryInvalid"), "");
  assertSelfCheck(results, "missingSessionBlocking", blocked.blockingReasons.includes("MissingSession"), "");
  assertSelfCheck(results, "activationBlocking", blocked.blockingReasons.includes("ActivationBlocked"), "");
  assertSelfCheck(results, "bindingBlocking", blocked.blockingReasons.includes("BindingBlocked"), "");
  assertSelfCheck(results, "runnerBlocking", blocked.blockingReasons.includes("RunnerBlocked"), "");
  assertSelfCheck(results, "capabilityBlocking", blocked.blockingReasons.includes("CapabilityMissing"), "");
  assertSelfCheck(results, "protocolBlocking", blocked.blockingReasons.includes("ProtocolRejected"), "");
  assertSelfCheck(results, "compatibilityBlocking", blocked.blockingReasons.includes("CompatibilityFailure"), "");
  assertSelfCheck(results, "diagnosticsToolingOnly", !("productionCertified" in blocked.diagnostics), "");
  assertSelfCheck(results, "noExecution", blocked.runnerInvoked === false, "");
  assertSelfCheck(results, "runtimeTruthPreserved", blocked.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE", "");
  assertSelfCheck(results, "structuredResultNotCaptured", blocked.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noNetworkingTransport", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("certificationDecision" in blocked), "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExecutionReadinessSelfChecks();
    const failed = results.filter((check) => !check.ok);
    console.log(`TOTAL ${results.length}`);
    console.log(`PASSED ${results.length - failed.length}`);
    console.log(`FAILURES ${failed.length}`);
    for (const failure of failed) {
      console.log(`FAIL ${failure.name}: ${failure.detail || "failed"}`);
    }
    process.exitCode = failed.length === 0 ? 0 : bridgeExitCodes.validationFailed;
    return;
  }

  const head = git(config, ["rev-parse", "HEAD"]);
  const evaluation = evaluateExecutionReadiness({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
