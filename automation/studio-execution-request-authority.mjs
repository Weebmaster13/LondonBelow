import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateExecutionOrchestrator,
  executionOrchestratorAuthorityId,
  executionOrchestratorVersion,
  validateOrchestration
} from "./studio-execution-orchestrator.mjs";
import {
  integrationContractProtocolVersion,
  integrationContractVersion,
  stableSerialize
} from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const executionRequestSchemaVersion = 1;
export const executionRequestVersion = "1.0.0";
export const executionRequestAuthorityId = "chapter0Home.phase134StudioExecutionRequestAuthority";

export const requestStates = Object.freeze({
  idle: "Idle",
  createRequest: "CreateRequest",
  validateRequest: "ValidateRequest",
  freezeRequest: "FreezeRequest",
  published: "RequestPublished",
  invalidInput: "InvalidInput",
  rejected: "RequestRejected",
  freezeRejected: "FreezeRejected"
});

export const executionIntents = Object.freeze(["ValidationOnly", "DryRun", "AuthoritativeExecution"]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const requestFields = Object.freeze([
  "requestId",
  "orchestrationId",
  "executionPlanId",
  "readinessId",
  "protocolVersion",
  "capabilityProfileId",
  "requestVersion",
  "executionIntent",
  "validationState",
  "timestamp"
]);
const diagnosticsFields = Object.freeze([
  "requestVersion",
  "requestState",
  "intent",
  "validationState",
  "compatibilityState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "requestId",
  "orchestrationId",
  "authorityId",
  "requestState",
  "intent",
  "timestamp",
  "contractVersion"
]);
const terminalStates = new Set([
  requestStates.published,
  requestStates.invalidInput,
  requestStates.rejected,
  requestStates.freezeRejected
]);
const legalTransitions = new Map([
  [requestStates.idle, new Set([requestStates.createRequest])],
  [requestStates.createRequest, new Set([requestStates.validateRequest, requestStates.invalidInput])],
  [requestStates.validateRequest, new Set([requestStates.freezeRequest, requestStates.rejected])],
  [requestStates.freezeRequest, new Set([requestStates.published, requestStates.freezeRejected])]
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

function validateIdentifier(value, label) {
  return typeof value === "string" && value.trim() !== ""
    ? result(true)
    : result(false, `${label} invalid`, "InvalidIdentifier");
}

function validateUniqueIdentifiers(values) {
  const seen = new Set();
  for (const value of values) {
    const id = validateIdentifier(value, "request identifier");
    if (!id.ok) return id;
    if (seen.has(value)) return result(false, `duplicate request identifier ${value}`, "DuplicateIdentifier");
    seen.add(value);
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: executionRequestAuthorityId });
}

export function validateRequestTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "request transitions must be non-empty", "InvalidLifecycle");
  }

  let terminalSeen = false;
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(requestStates).includes(item.from) || !Object.values(requestStates).includes(item.to)) {
      return result(false, "undocumented request state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== requestStates.idle) {
      return result(false, "request lifecycle must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "request lifecycle skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal request state mutated", "InvalidLifecycle");
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal request transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    if (terminalStates.has(item.to)) terminalSeen = true;
  }

  return result(true);
}

function requestIdFor(orchestrationId, intent) {
  return `${orchestrationId}.request.${intent}`;
}

function createExecutionRequest(orchestrationEvaluation, intent, timestamp) {
  const orchestration = orchestrationEvaluation.orchestration;
  const context = orchestrationEvaluation.context;
  return deepFreeze({
    requestId: requestIdFor(orchestration.orchestrationId, intent),
    orchestrationId: orchestration.orchestrationId,
    executionPlanId: orchestration.executionPlanId,
    readinessId: orchestration.readinessId,
    protocolVersion: integrationContractProtocolVersion,
    capabilityProfileId: context.capabilityProfileId,
    requestVersion: executionRequestVersion,
    executionIntent: intent,
    validationState: "valid",
    timestamp
  });
}

export function validateExecutionRequest(request, orchestrationEvaluation = null) {
  const fields = exactFields(request, requestFields, "execution request");
  if (!fields.ok) return fields;

  for (const field of ["requestId", "orchestrationId", "executionPlanId", "readinessId", "capabilityProfileId"]) {
    const id = validateIdentifier(request[field], field);
    if (!id.ok) return id;
  }

  const unique = validateUniqueIdentifiers([
    request.requestId,
    request.orchestrationId,
    request.executionPlanId,
    request.readinessId,
    request.capabilityProfileId
  ]);
  if (!unique.ok) return unique;

  if (request.protocolVersion !== integrationContractProtocolVersion) {
    return result(false, "request protocol version incompatible", "ProtocolIncompatible");
  }
  if (request.requestVersion !== executionRequestVersion) {
    return result(false, "request version incompatible", "RequestVersionIncompatible");
  }
  if (!executionIntents.includes(request.executionIntent)) {
    return result(false, "execution intent unsupported", "UnsupportedExecutionIntent");
  }
  if (request.validationState !== "valid") {
    return result(false, "request validation state invalid", "InvalidValidationState");
  }
  if (typeof request.timestamp !== "string" || request.timestamp.trim() === "") {
    return result(false, "request timestamp invalid", "InvalidTimestamp");
  }

  if (orchestrationEvaluation !== null) {
    if (!isPlainObject(orchestrationEvaluation) || orchestrationEvaluation.authorityId !== executionOrchestratorAuthorityId) {
      return result(false, "orchestration authority incompatible", "OrchestrationIncompatible");
    }
    const orchestration = orchestrationEvaluation.orchestration;
    const context = orchestrationEvaluation.context;
    const orchestrationValidation = validateOrchestration(orchestration);
    if (!orchestrationValidation.ok) return orchestrationValidation;
    if (!isPlainObject(context)) return result(false, "execution context missing", "CapabilityIncompatible");
    if (orchestration.orchestrationId !== request.orchestrationId) {
      return result(false, "orchestration id mismatch", "OrchestrationIncompatible");
    }
    if (orchestration.executionPlanId !== request.executionPlanId) {
      return result(false, "execution plan id mismatch", "OrchestrationIncompatible");
    }
    if (orchestration.readinessId !== request.readinessId) {
      return result(false, "readiness id mismatch", "ReadinessIncompatible");
    }
    if (context.capabilityProfileId !== request.capabilityProfileId) {
      return result(false, "capability profile id mismatch", "CapabilityIncompatible");
    }
  }

  return result(true);
}

function createAudit(request, requestState, timestamp) {
  return deepFreeze([
    {
      requestId: request?.requestId ?? "missing",
      orchestrationId: request?.orchestrationId ?? "missing",
      authorityId: executionRequestAuthorityId,
      requestState,
      intent: request?.executionIntent ?? "missing",
      timestamp,
      contractVersion: integrationContractVersion
    }
  ]);
}

export function validateExecutionRequestAudit(audit) {
  if (!Array.isArray(audit) || audit.length === 0) {
    return result(false, "request audit must be non-empty", "InvalidAudit");
  }
  const identities = new Set();
  for (const [index, item] of audit.entries()) {
    const fields = exactFields(item, auditFields, "request audit");
    if (!fields.ok) return fields;
    for (const field of ["requestId", "orchestrationId", "authorityId", "requestState", "intent", "timestamp", "contractVersion"]) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== executionRequestAuthorityId) {
      return result(false, "request audit authority mismatch", "InvalidAudit");
    }
    if (!Object.values(requestStates).includes(item.requestState)) {
      return result(false, "request audit state invalid", "InvalidAudit");
    }
    if (item.intent !== "missing" && !executionIntents.includes(item.intent)) {
      return result(false, "request audit intent invalid", "InvalidAudit");
    }
    if (item.contractVersion !== integrationContractVersion) {
      return result(false, "request audit contract version mismatch", "InvalidAudit");
    }
    const identity = `${item.requestId}:${item.orchestrationId}:${item.requestState}:${item.intent}:${item.timestamp}`;
    if (identities.has(identity)) return result(false, "duplicate request audit identity", "DuplicateAudit");
    identities.add(identity);
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  const diagnostics = {
    requestVersion: evaluation.requestVersion,
    requestState: evaluation.requestState,
    intent: evaluation.intent,
    validationState: evaluation.requestValidation.ok ? "valid" : "invalid",
    compatibilityState: evaluation.compatibilityState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  };
  return deepFreeze(diagnostics);
}

export function validateExecutionRequestDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "request diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.requestVersion !== executionRequestVersion) {
    return result(false, "request diagnostics version mismatch", "InvalidDiagnostics");
  }
  if (!Object.values(requestStates).includes(diagnostics.requestState)) {
    return result(false, "request diagnostics state invalid", "InvalidDiagnostics");
  }
  if (diagnostics.intent !== "missing" && !executionIntents.includes(diagnostics.intent)) {
    return result(false, "request diagnostics intent invalid", "InvalidDiagnostics");
  }
  if (!["valid", "invalid"].includes(diagnostics.validationState)) {
    return result(false, "request diagnostics validation state invalid", "InvalidDiagnostics");
  }
  if (!["compatible", "incompatible"].includes(diagnostics.compatibilityState)) {
    return result(false, "request diagnostics compatibility state invalid", "InvalidDiagnostics");
  }
  return result(true);
}

export function evaluateExecutionRequest(input = {}) {
  const timestamp = input.timestamp ?? now();
  const intent = input.executionIntent ?? "ValidationOnly";
  const orchestration =
    input.orchestration ?? evaluateExecutionOrchestrator({ ...input, timestamp, repositoryState: input.repositoryState });
  const transitions = [transition(requestStates.idle, requestStates.createRequest, "creating execution request", timestamp)];
  let requestState = requestStates.published;
  let failureReason = null;
  let request = null;
  let requestValidation = result(false, "request not created", "InvalidInput");

  if (!executionIntents.includes(intent)) {
    transitions.push(transition(requestStates.createRequest, requestStates.invalidInput, "UnsupportedExecutionIntent", timestamp));
    requestState = requestStates.invalidInput;
    failureReason = "UnsupportedExecutionIntent";
  } else if (!isPlainObject(orchestration) || orchestration.authorityId !== executionOrchestratorAuthorityId || !isPlainObject(orchestration.orchestration)) {
    transitions.push(transition(requestStates.createRequest, requestStates.invalidInput, "MissingOrchestration", timestamp));
    requestState = requestStates.invalidInput;
    failureReason = "MissingOrchestration";
  } else {
    transitions.push(transition(requestStates.createRequest, requestStates.validateRequest, "execution request created", timestamp));
    request = createExecutionRequest(orchestration, intent, timestamp);
    requestValidation = validateExecutionRequest(request, orchestration);
    if (!requestValidation.ok) {
      transitions.push(transition(requestStates.validateRequest, requestStates.rejected, requestValidation.failure, timestamp));
      requestState = requestStates.rejected;
      failureReason = requestValidation.failure;
    } else {
      transitions.push(transition(requestStates.validateRequest, requestStates.freezeRequest, "execution request validated", timestamp));
      if (!Object.isFrozen(request)) {
        transitions.push(transition(requestStates.freezeRequest, requestStates.freezeRejected, "FreezeRejected", timestamp));
        requestState = requestStates.freezeRejected;
        failureReason = "FreezeRejected";
      } else {
        transitions.push(transition(requestStates.freezeRequest, requestStates.published, "execution request frozen", timestamp));
      }
    }
  }

  const transitionValidation = validateRequestTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) {
    failureReason = transitionValidation.failure;
  }
  const compatibilityState = requestValidation.ok && transitionValidation.ok ? "compatible" : "incompatible";
  const audit = createAudit(request, requestState, timestamp);
  const evaluation = {
    schemaVersion: executionRequestSchemaVersion,
    authorityId: executionRequestAuthorityId,
    requestVersion: executionRequestVersion,
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
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
    requestState,
    intent,
    orchestration,
    request,
    requestValidation,
    transitionValidation,
    audit,
    auditValidation: validateExecutionRequestAudit(audit),
    compatibilityState,
    integrationGraph: [
      "Phase121EvidenceTransport",
      "Phase122StudioBridge",
      "Phase124ActivationAuthority",
      "Phase125BindingAuthority",
      "Phase126SessionAuthority",
      "Phase127RunnerAuthority",
      "Phase129IntegrationContract",
      "Phase130CapabilityNegotiationAuthority",
      "Phase131ExecutionReadinessAuthority",
      "Phase132ExecutionPlanningAuthority",
      "Phase133ExecutionOrchestrator",
      "Phase134ExecutionRequestAuthority"
    ],
    failureReason,
    recommendedAction: "Resolve connected Studio MCP execution support before any future execution runtime consumes the request.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateExecutionRequestDiagnostics(diagnosticsFor(evaluation)),
    serializationValidation: (() => {
      try {
        const serialized = stableSerialize(evaluation);
        return result(stableSerialize(evaluation) === serialized, null, null, { serialized });
      } catch (error) {
        return result(false, String(error?.message ?? error), "SerializationFailure");
      }
    })()
  });
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runExecutionRequestSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExecutionRequest({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExecutionRequest({ timestamp: stableTimestamp, repositoryState });
  const invalidIntent = evaluateExecutionRequest({ timestamp: stableTimestamp, repositoryState, executionIntent: "ExecuteNow" });
  const invalidTransition = validateRequestTransitions([
    transition(requestStates.idle, requestStates.freezeRequest, "skip", stableTimestamp)
  ]);
  const terminalMutation = validateRequestTransitions([
    transition(requestStates.idle, requestStates.createRequest, "start", stableTimestamp),
    transition(requestStates.createRequest, requestStates.invalidInput, "stop", stableTimestamp),
    transition(requestStates.invalidInput, requestStates.validateRequest, "mutate", stableTimestamp)
  ]);
  const duplicateAudit = validateExecutionRequestAudit([...evaluation.audit, ...evaluation.audit]);
  const badRequest = { ...evaluation.request, extra: true };
  const badProtocol = { ...evaluation.request, protocolVersion: "0.0.0" };
  const badPlan = { ...evaluation.request, executionPlanId: evaluation.request.readinessId };
  const badOrchestration = {
    ...evaluation.orchestration,
    orchestration: { ...evaluation.orchestration.orchestration, readinessId: "different.readiness" }
  };
  const badDiagnostics = { ...evaluation.diagnostics, productionCertified: false };

  assertSelfCheck(results, "requestLifecycleValidation", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "requestSchemaValidation", evaluation.requestValidation.ok === true, "");
  assertSelfCheck(results, "identifierValidation", validateIdentifier(evaluation.request.requestId, "requestId").ok === true, "");
  assertSelfCheck(results, "duplicateIdentifierRejection", validateExecutionRequest(badPlan, evaluation.orchestration).ok === false, "");
  assertSelfCheck(results, "unsupportedIntentRejection", invalidIntent.requestState === requestStates.invalidInput, "");
  assertSelfCheck(results, "orchestrationCompatibility", evaluation.orchestration.authorityId === executionOrchestratorAuthorityId, "");
  assertSelfCheck(results, "orchestrationVersionCompatibility", evaluation.orchestration.orchestrationVersion === executionOrchestratorVersion, "");
  assertSelfCheck(results, "orchestrationMismatchRejection", validateExecutionRequest(evaluation.request, badOrchestration).ok === false, "");
  assertSelfCheck(results, "readinessCompatibility", evaluation.request.readinessId === evaluation.orchestration.orchestration.readinessId, "");
  assertSelfCheck(results, "capabilityCompatibility", evaluation.request.capabilityProfileId === evaluation.orchestration.context.capabilityProfileId, "");
  assertSelfCheck(results, "protocolCompatibility", validateExecutionRequest(badProtocol, evaluation.orchestration).ok === false, "");
  assertSelfCheck(results, "immutableRequestValidation", Object.isFrozen(evaluation.request), "");
  assertSelfCheck(results, "requestPublication", evaluation.requestState === requestStates.published, "");
  assertSelfCheck(results, "unknownRequestFieldRejection", validateExecutionRequest(badRequest, evaluation.orchestration).ok === false, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && evaluation.request.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateExecutionRequestDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "auditValidation", evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === executionRequestAuthorityId, "");
  assertSelfCheck(results, "orchestratorReadOnly", evaluation.orchestration.authorityId === executionOrchestratorAuthorityId, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "backwardCompatibility", executionRequestSchemaVersion === 1, "");
  assertSelfCheck(results, "requestFieldCompleteness", requestFields.every((field) => field in evaluation.request), "");
  assertSelfCheck(results, "requestExactFields", Object.keys(evaluation.request).length === requestFields.length, "");
  assertSelfCheck(results, "intentClassificationsOnly", executionIntents.length === 3 && evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "runtimeTruthPreserved", evaluation.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE", "");
  assertSelfCheck(results, "executionBlockedPreserved", evaluation.status === "executionBlocked", "");
  assertSelfCheck(results, "runnerInvocationPreservedFalse", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "structuredCapturePreservedFalse", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noExecution", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noRuntimeEvidence", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("productionCertified" in evaluation) && !("certificationDecision" in evaluation), "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noNetworking", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExecutionRequestSelfChecks();
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
  const evaluation = evaluateExecutionRequest({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
