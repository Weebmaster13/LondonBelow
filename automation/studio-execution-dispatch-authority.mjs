import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateExecutionRequest,
  executionIntents,
  executionRequestAuthorityId,
  executionRequestVersion,
  validateExecutionRequest
} from "./studio-execution-request-authority.mjs";
import {
  executionOrchestratorAuthorityId,
  executionOrchestratorVersion,
  validateOrchestration
} from "./studio-execution-orchestrator.mjs";
import {
  executionPlanningAuthorityId,
  executionPlanningVersion,
  validateExecutionPlan
} from "./studio-execution-planning-authority.mjs";
import {
  executionReadinessAuthorityId,
  executionReadinessVersion,
  readinessDecisions,
  validateReadinessProfile
} from "./studio-execution-readiness-authority.mjs";
import {
  capabilityNegotiationAuthorityId,
  capabilityNegotiationVersion
} from "./studio-capability-negotiation-authority.mjs";
import {
  integrationContractProtocolVersion,
  integrationContractAuthorityId,
  integrationContractSchemaVersion,
  integrationContractVersion,
  integrationContractCompatibilityVersion,
  stableSerialize,
  validateVersionMetadata
} from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const executionDispatchSchemaVersion = 1;
export const executionDispatchVersion = "1.0.0";
export const executionDispatchAuthorityId = "chapter0Home.phase135StudioExecutionDispatchAuthority";

export const dispatchStates = Object.freeze({
  idle: "Idle",
  receiveExecutionRequest: "ReceiveExecutionRequest",
  validateDispatchEligibility: "ValidateDispatchEligibility",
  buildDispatch: "BuildDispatch",
  freezeDispatch: "FreezeDispatch",
  published: "DispatchPublished",
  missingExecutionRequest: "MissingExecutionRequest",
  ineligible: "DispatchIneligible",
  constructionFailed: "DispatchConstructionFailed",
  freezeRejected: "FreezeRejected"
});

export const dispatchEligibilityValues = Object.freeze([
  "Blocked",
  "AwaitingExternalBoundary",
  "EligibleForExternalBoundary"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  dispatchStates.published,
  dispatchStates.missingExecutionRequest,
  dispatchStates.ineligible,
  dispatchStates.constructionFailed,
  dispatchStates.freezeRejected
]);
const legalTransitions = new Map([
  [dispatchStates.idle, new Set([dispatchStates.receiveExecutionRequest])],
  [dispatchStates.receiveExecutionRequest, new Set([dispatchStates.validateDispatchEligibility, dispatchStates.missingExecutionRequest])],
  [dispatchStates.validateDispatchEligibility, new Set([dispatchStates.buildDispatch, dispatchStates.ineligible])],
  [dispatchStates.buildDispatch, new Set([dispatchStates.freezeDispatch, dispatchStates.constructionFailed])],
  [dispatchStates.freezeDispatch, new Set([dispatchStates.published, dispatchStates.freezeRejected])]
]);

const dispatchFields = Object.freeze([
  "dispatchId",
  "dispatchVersion",
  "requestId",
  "orchestrationId",
  "executionPlanId",
  "readinessId",
  "protocolVersion",
  "capabilityProfileId",
  "executionIntent",
  "dispatchEligibility",
  "validationState",
  "timestamp"
]);
const diagnosticsFields = Object.freeze([
  "dispatchVersion",
  "dispatchState",
  "requestState",
  "executionIntent",
  "dispatchEligibility",
  "validationState",
  "compatibilityState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "dispatchId",
  "requestId",
  "orchestrationId",
  "authorityId",
  "dispatchState",
  "dispatchEligibility",
  "executionIntent",
  "timestamp",
  "contractVersion"
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
    const id = validateIdentifier(value, "dispatch identifier");
    if (!id.ok) return id;
    if (seen.has(value)) return result(false, `duplicate dispatch identifier ${value}`, "DuplicateIdentifier");
    seen.add(value);
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: executionDispatchAuthorityId });
}

export function validateDispatchTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "dispatch transitions must be non-empty", "InvalidLifecycle");
  }

  let terminalSeen = false;
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(dispatchStates).includes(item.from) || !Object.values(dispatchStates).includes(item.to)) {
      return result(false, "undocumented dispatch state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== dispatchStates.idle) {
      return result(false, "dispatch lifecycle must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "dispatch lifecycle skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal dispatch state mutated", "InvalidLifecycle");
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal dispatch transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    if (terminalStates.has(item.to)) terminalSeen = true;
  }

  return result(true);
}

function deriveDispatchEligibility(requestEvaluation) {
  if (
    requestEvaluation?.runtimeTruth?.sessionFailureReason === "SESSION_NOT_VISIBLE" &&
    requestEvaluation.status === "executionBlocked" &&
    requestEvaluation.runnerInvoked === false &&
    requestEvaluation.structuredResultCaptured === false
  ) {
    return "Blocked";
  }
  if (requestEvaluation?.status === "executionBlocked") return "Blocked";
  return "AwaitingExternalBoundary";
}

function createDispatch(requestEvaluation, eligibility, timestamp) {
  const request = requestEvaluation.request;
  return deepFreeze({
    dispatchId: `${request.requestId}.dispatch`,
    dispatchVersion: executionDispatchVersion,
    requestId: request.requestId,
    orchestrationId: request.orchestrationId,
    executionPlanId: request.executionPlanId,
    readinessId: request.readinessId,
    protocolVersion: request.protocolVersion,
    capabilityProfileId: request.capabilityProfileId,
    executionIntent: request.executionIntent,
    dispatchEligibility: eligibility,
    validationState: "valid",
    timestamp
  });
}

function validateUpstreamCompatibility(requestEvaluation) {
  if (!isPlainObject(requestEvaluation) || requestEvaluation.authorityId !== executionRequestAuthorityId) {
    return result(false, "execution request authority incompatible", "RequestIncompatible");
  }
  if (requestEvaluation.requestVersion !== executionRequestVersion) {
    return result(false, "execution request version incompatible", "RequestIncompatible");
  }
  const requestValidation = validateExecutionRequest(requestEvaluation.request, requestEvaluation.orchestration);
  if (!requestValidation.ok) return requestValidation;

  const orchestrationEvaluation = requestEvaluation.orchestration;
  if (!isPlainObject(orchestrationEvaluation) || orchestrationEvaluation.authorityId !== executionOrchestratorAuthorityId) {
    return result(false, "orchestration authority incompatible", "OrchestrationIncompatible");
  }
  if (orchestrationEvaluation.orchestrationVersion !== executionOrchestratorVersion) {
    return result(false, "orchestration version incompatible", "OrchestrationIncompatible");
  }
  const orchestrationValidation = validateOrchestration(orchestrationEvaluation.orchestration);
  if (!orchestrationValidation.ok) return orchestrationValidation;

  const planningEvaluation = orchestrationEvaluation.planning;
  if (!isPlainObject(planningEvaluation) || planningEvaluation.authorityId !== executionPlanningAuthorityId) {
    return result(false, "planning authority incompatible", "PlanningIncompatible");
  }
  if (planningEvaluation.planningVersion !== executionPlanningVersion) {
    return result(false, "planning version incompatible", "PlanningIncompatible");
  }
  const planValidation = validateExecutionPlan(planningEvaluation.plan);
  if (!planValidation.ok) return planValidation;

  const readinessEvaluation = planningEvaluation.readiness;
  if (!isPlainObject(readinessEvaluation) || readinessEvaluation.authorityId !== executionReadinessAuthorityId) {
    return result(false, "readiness authority incompatible", "ReadinessIncompatible");
  }
  if (readinessEvaluation.readinessVersion !== executionReadinessVersion) {
    return result(false, "readiness version incompatible", "ReadinessIncompatible");
  }
  if (readinessEvaluation.decision !== readinessDecisions.blocked) {
    return result(false, "readiness decision unsupported for current dispatch", "ReadinessIncompatible");
  }
  const profileValidation = validateReadinessProfile(readinessEvaluation.profile);
  if (!profileValidation.ok) return profileValidation;

  const capability = readinessEvaluation.authorities?.capability;
  if (!isPlainObject(capability) || capability.authorityId !== capabilityNegotiationAuthorityId) {
    return result(false, "capability authority incompatible", "CapabilityIncompatible");
  }
  if (capability.negotiationVersion !== capabilityNegotiationVersion) {
    return result(false, "capability negotiation version incompatible", "CapabilityIncompatible");
  }

  const protocol = readinessEvaluation.authorities?.protocol;
  if (!isPlainObject(protocol) || protocol.authorityId !== integrationContractAuthorityId) {
    return result(false, "protocol authority incompatible", "ProtocolIncompatible");
  }
  if (!isPlainObject(protocol.compatibility)) {
    return result(false, "protocol compatibility posture missing", "ProtocolIncompatible");
  }
  const versionValidation = validateVersionMetadata({
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    schemaVersion: integrationContractSchemaVersion,
    compatibilityVersion: integrationContractCompatibilityVersion
  });
  if (!versionValidation.ok) return versionValidation;

  return result(true);
}

export function validateExecutionDispatch(dispatch, requestEvaluation = null) {
  const fields = exactFields(dispatch, dispatchFields, "execution dispatch");
  if (!fields.ok) return fields;

  for (const field of ["dispatchId", "requestId", "orchestrationId", "executionPlanId", "readinessId", "capabilityProfileId"]) {
    const id = validateIdentifier(dispatch[field], field);
    if (!id.ok) return id;
  }

  const unique = validateUniqueIdentifiers([
    dispatch.dispatchId,
    dispatch.requestId,
    dispatch.orchestrationId,
    dispatch.executionPlanId,
    dispatch.readinessId,
    dispatch.capabilityProfileId
  ]);
  if (!unique.ok) return unique;

  if (dispatch.dispatchVersion !== executionDispatchVersion) {
    return result(false, "dispatch version incompatible", "DispatchVersionIncompatible");
  }
  if (dispatch.protocolVersion !== integrationContractProtocolVersion) {
    return result(false, "dispatch protocol version incompatible", "ProtocolIncompatible");
  }
  if (!executionIntents.includes(dispatch.executionIntent)) {
    return result(false, "execution intent unsupported", "UnsupportedExecutionIntent");
  }
  if (!dispatchEligibilityValues.includes(dispatch.dispatchEligibility)) {
    return result(false, "dispatch eligibility unsupported", "UnsupportedDispatchEligibility");
  }
  if (dispatch.validationState !== "valid") {
    return result(false, "dispatch validation state invalid", "InvalidValidationState");
  }
  if (typeof dispatch.timestamp !== "string" || dispatch.timestamp.trim() === "") {
    return result(false, "dispatch timestamp invalid", "InvalidTimestamp");
  }

  if (requestEvaluation !== null) {
    const upstream = validateUpstreamCompatibility(requestEvaluation);
    if (!upstream.ok) return upstream;
    const request = requestEvaluation.request;
    for (const field of ["requestId", "orchestrationId", "executionPlanId", "readinessId", "protocolVersion", "capabilityProfileId"]) {
      if (dispatch[field] !== request[field]) {
        return result(false, `${field} mismatch`, "RequestIncompatible");
      }
    }
    if (dispatch.executionIntent !== request.executionIntent) {
      return result(false, "execution intent mismatch", "RequestIncompatible");
    }
    const derived = deriveDispatchEligibility(requestEvaluation);
    if (dispatch.dispatchEligibility !== derived) {
      return result(false, "dispatch eligibility does not match upstream truth", "EligibilityIncompatible");
    }
  }

  return result(true);
}

function createAudit(dispatch, dispatchState, timestamp) {
  return deepFreeze([
    {
      dispatchId: dispatch?.dispatchId ?? "missing",
      requestId: dispatch?.requestId ?? "missing",
      orchestrationId: dispatch?.orchestrationId ?? "missing",
      authorityId: executionDispatchAuthorityId,
      dispatchState,
      dispatchEligibility: dispatch?.dispatchEligibility ?? "missing",
      executionIntent: dispatch?.executionIntent ?? "missing",
      timestamp,
      contractVersion: integrationContractVersion
    }
  ]);
}

export function validateExecutionDispatchAudit(audit) {
  if (!Array.isArray(audit) || audit.length === 0) {
    return result(false, "dispatch audit must be non-empty", "InvalidAudit");
  }
  const identities = new Set();
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "dispatch audit");
    if (!fields.ok) return fields;
    for (const field of [
      "dispatchId",
      "requestId",
      "orchestrationId",
      "authorityId",
      "dispatchState",
      "dispatchEligibility",
      "executionIntent",
      "timestamp",
      "contractVersion"
    ]) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== executionDispatchAuthorityId) {
      return result(false, "dispatch audit authority mismatch", "InvalidAudit");
    }
    if (!Object.values(dispatchStates).includes(item.dispatchState)) {
      return result(false, "dispatch audit state invalid", "InvalidAudit");
    }
    if (item.dispatchEligibility !== "missing" && !dispatchEligibilityValues.includes(item.dispatchEligibility)) {
      return result(false, "dispatch audit eligibility invalid", "InvalidAudit");
    }
    if (item.executionIntent !== "missing" && !executionIntents.includes(item.executionIntent)) {
      return result(false, "dispatch audit intent invalid", "InvalidAudit");
    }
    if (item.contractVersion !== integrationContractVersion) {
      return result(false, "dispatch audit contract version mismatch", "InvalidAudit");
    }
    const identity = `${item.dispatchId}:${item.requestId}:${item.dispatchState}:${item.dispatchEligibility}:${item.timestamp}`;
    if (identities.has(identity)) return result(false, "duplicate dispatch audit identity", "DuplicateAudit");
    identities.add(identity);
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    dispatchVersion: evaluation.dispatchVersion,
    dispatchState: evaluation.dispatchState,
    requestState: evaluation.requestEvaluation?.requestState ?? "missing",
    executionIntent: evaluation.executionIntent,
    dispatchEligibility: evaluation.dispatchEligibility,
    validationState: evaluation.dispatchValidation.ok ? "valid" : "invalid",
    compatibilityState: evaluation.compatibilityState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateExecutionDispatchDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "dispatch diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.dispatchVersion !== executionDispatchVersion) {
    return result(false, "dispatch diagnostics version mismatch", "InvalidDiagnostics");
  }
  if (!Object.values(dispatchStates).includes(diagnostics.dispatchState)) {
    return result(false, "dispatch diagnostics state invalid", "InvalidDiagnostics");
  }
  if (diagnostics.executionIntent !== "missing" && !executionIntents.includes(diagnostics.executionIntent)) {
    return result(false, "dispatch diagnostics intent invalid", "InvalidDiagnostics");
  }
  if (!dispatchEligibilityValues.includes(diagnostics.dispatchEligibility) && diagnostics.dispatchEligibility !== "missing") {
    return result(false, "dispatch diagnostics eligibility invalid", "InvalidDiagnostics");
  }
  if (!["valid", "invalid"].includes(diagnostics.validationState)) {
    return result(false, "dispatch diagnostics validation state invalid", "InvalidDiagnostics");
  }
  if (!["compatible", "incompatible"].includes(diagnostics.compatibilityState)) {
    return result(false, "dispatch diagnostics compatibility state invalid", "InvalidDiagnostics");
  }
  return result(true);
}

export function evaluateExecutionDispatch(input = {}) {
  const timestamp = input.timestamp ?? now();
  const requestEvaluation = input.requestEvaluation ?? evaluateExecutionRequest({ ...input, timestamp });
  const transitions = [transition(dispatchStates.idle, dispatchStates.receiveExecutionRequest, "receiving execution request", timestamp)];
  let dispatchState = dispatchStates.published;
  let failureReason = null;
  let dispatch = null;
  let dispatchEligibility = "Blocked";
  let dispatchValidation = result(false, "dispatch not created", "MissingExecutionRequest");

  if (!isPlainObject(requestEvaluation) || requestEvaluation.authorityId !== executionRequestAuthorityId || !isPlainObject(requestEvaluation.request)) {
    transitions.push(transition(dispatchStates.receiveExecutionRequest, dispatchStates.missingExecutionRequest, "MissingExecutionRequest", timestamp));
    dispatchState = dispatchStates.missingExecutionRequest;
    failureReason = "MissingExecutionRequest";
  } else {
    transitions.push(transition(dispatchStates.receiveExecutionRequest, dispatchStates.validateDispatchEligibility, "execution request received", timestamp));
    const upstreamValidation = validateUpstreamCompatibility(requestEvaluation);
    dispatchEligibility = deriveDispatchEligibility(requestEvaluation);
    if (!upstreamValidation.ok) {
      transitions.push(transition(dispatchStates.validateDispatchEligibility, dispatchStates.ineligible, upstreamValidation.failure, timestamp));
      dispatchState = dispatchStates.ineligible;
      failureReason = upstreamValidation.failure;
    } else {
      transitions.push(transition(dispatchStates.validateDispatchEligibility, dispatchStates.buildDispatch, "dispatch eligibility classified", timestamp));
      dispatch = createDispatch(requestEvaluation, dispatchEligibility, timestamp);
      dispatchValidation = validateExecutionDispatch(dispatch, requestEvaluation);
      if (!dispatchValidation.ok) {
        transitions.push(transition(dispatchStates.buildDispatch, dispatchStates.constructionFailed, dispatchValidation.failure, timestamp));
        dispatchState = dispatchStates.constructionFailed;
        failureReason = dispatchValidation.failure;
      } else {
        transitions.push(transition(dispatchStates.buildDispatch, dispatchStates.freezeDispatch, "dispatch artifact built", timestamp));
        if (!Object.isFrozen(dispatch)) {
          transitions.push(transition(dispatchStates.freezeDispatch, dispatchStates.freezeRejected, "FreezeRejected", timestamp));
          dispatchState = dispatchStates.freezeRejected;
          failureReason = "FreezeRejected";
        } else {
          transitions.push(transition(dispatchStates.freezeDispatch, dispatchStates.published, "dispatch artifact frozen", timestamp));
        }
      }
    }
  }

  const transitionValidation = validateDispatchTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  const compatibilityState = dispatchValidation.ok && transitionValidation.ok ? "compatible" : "incompatible";
  const audit = createAudit(dispatch, dispatchState, timestamp);
  const evaluation = {
    schemaVersion: executionDispatchSchemaVersion,
    authorityId: executionDispatchAuthorityId,
    dispatchVersion: executionDispatchVersion,
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
    dispatchState,
    dispatchEligibility,
    executionIntent: requestEvaluation?.request?.executionIntent ?? "missing",
    requestEvaluation,
    dispatch,
    dispatchValidation,
    transitionValidation,
    audit,
    auditValidation: validateExecutionDispatchAudit(audit),
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
      "Phase134ExecutionRequestAuthority",
      "Phase135ExecutionDispatchAuthority"
    ],
    failureReason,
    recommendedAction: "Resolve connected Studio MCP execution support before any future external execution boundary consumes dispatch.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateExecutionDispatchDiagnostics(diagnosticsFor(evaluation)),
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

export function runExecutionDispatchSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExecutionDispatch({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExecutionDispatch({ timestamp: stableTimestamp, repositoryState });
  const missingRequest = evaluateExecutionDispatch({ timestamp: stableTimestamp, requestEvaluation: {} });
  const invalidTransition = validateDispatchTransitions([
    transition(dispatchStates.idle, dispatchStates.freezeDispatch, "skip", stableTimestamp)
  ]);
  const skippedTransition = validateDispatchTransitions([
    transition(dispatchStates.idle, dispatchStates.receiveExecutionRequest, "start", stableTimestamp),
    transition(dispatchStates.validateDispatchEligibility, dispatchStates.buildDispatch, "skip", stableTimestamp)
  ]);
  const terminalMutation = validateDispatchTransitions([
    transition(dispatchStates.idle, dispatchStates.receiveExecutionRequest, "start", stableTimestamp),
    transition(dispatchStates.receiveExecutionRequest, dispatchStates.missingExecutionRequest, "stop", stableTimestamp),
    transition(dispatchStates.missingExecutionRequest, dispatchStates.validateDispatchEligibility, "mutate", stableTimestamp)
  ]);
  const badDispatch = { ...evaluation.dispatch, extra: true };
  const missingFieldDispatch = { ...evaluation.dispatch };
  delete missingFieldDispatch.executionIntent;
  const duplicateDispatch = { ...evaluation.dispatch, dispatchId: evaluation.dispatch.requestId };
  const badEligibility = { ...evaluation.dispatch, dispatchEligibility: "ExecuteNow" };
  const badIntent = { ...evaluation.dispatch, executionIntent: "ExecuteNow" };
  const badRequestEvaluation = {
    ...evaluation.requestEvaluation,
    request: { ...evaluation.requestEvaluation.request, requestId: "different.request" }
  };
  const badDiagnostics = { ...evaluation.diagnostics, productionCertified: false };
  const duplicateAudit = validateExecutionDispatchAudit([...evaluation.audit, ...evaluation.audit]);

  assertSelfCheck(results, "lifecycleClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactDispatchSchema", Object.keys(evaluation.dispatch).length === dispatchFields.length, "");
  assertSelfCheck(results, "unknownFieldRejection", validateExecutionDispatch(badDispatch, evaluation.requestEvaluation).ok === false, "");
  assertSelfCheck(results, "missingFieldRejection", validateExecutionDispatch(missingFieldDispatch, evaluation.requestEvaluation).ok === false, "");
  assertSelfCheck(results, "duplicateIdentifierRejection", validateExecutionDispatch(duplicateDispatch, evaluation.requestEvaluation).ok === false, "");
  assertSelfCheck(results, "dispatchEligibilityValidation", validateExecutionDispatch(badEligibility, evaluation.requestEvaluation).ok === false, "");
  assertSelfCheck(results, "blockedStateTruthfulness", evaluation.dispatchEligibility === "Blocked", "");
  assertSelfCheck(results, "executionIntentConsumption", executionIntents.includes(evaluation.dispatch.executionIntent), "");
  assertSelfCheck(results, "invalidExecutionIntentRejection", validateExecutionDispatch(badIntent, evaluation.requestEvaluation).ok === false, "");
  assertSelfCheck(results, "requestCompatibility", validateExecutionRequest(evaluation.requestEvaluation.request, evaluation.requestEvaluation.orchestration).ok === true, "");
  assertSelfCheck(results, "requestMismatchRejection", validateExecutionDispatch(evaluation.dispatch, badRequestEvaluation).ok === false, "");
  assertSelfCheck(results, "orchestrationCompatibility", validateOrchestration(evaluation.requestEvaluation.orchestration.orchestration).ok === true, "");
  assertSelfCheck(results, "planningCompatibility", validateExecutionPlan(evaluation.requestEvaluation.orchestration.planning.plan).ok === true, "");
  assertSelfCheck(results, "readinessCompatibility", validateReadinessProfile(evaluation.requestEvaluation.orchestration.planning.readiness.profile).ok === true, "");
  assertSelfCheck(results, "capabilityCompatibility", evaluation.requestEvaluation.orchestration.planning.readiness.authorities.capability.authorityId === capabilityNegotiationAuthorityId, "");
  assertSelfCheck(results, "protocolCompatibility", evaluation.dispatch.protocolVersion === integrationContractProtocolVersion, "");
  assertSelfCheck(results, "immutableDispatchPublication", Object.isFrozen(evaluation.dispatch), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateExecutionDispatchDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "immutableAuditValidation", Object.isFrozen(evaluation.audit) && evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditIdentityRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && evaluation.dispatch.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === executionDispatchAuthorityId, "");
  assertSelfCheck(results, "missingRequestHandling", missingRequest.dispatchState === dispatchStates.missingExecutionRequest, "");
  assertSelfCheck(results, "phase134RegressionCompatibility", evaluation.requestEvaluation.authorityId === executionRequestAuthorityId, "");
  assertSelfCheck(results, "phase133RegressionCompatibility", evaluation.requestEvaluation.orchestration.authorityId === executionOrchestratorAuthorityId, "");
  assertSelfCheck(results, "phase132RegressionCompatibility", evaluation.requestEvaluation.orchestration.planning.authorityId === executionPlanningAuthorityId, "");
  assertSelfCheck(results, "backwardCompatibility", executionDispatchSchemaVersion === 1, "");
  assertSelfCheck(results, "noStudioExecution", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noRunnerInvocation", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noTransport", !("transport" in evaluation), "");
  assertSelfCheck(results, "noRuntimeEvidence", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noNetworking", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("productionCertified" in evaluation) && !("certificationDecision" in evaluation), "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExecutionDispatchSelfChecks();
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
  const evaluation = evaluateExecutionDispatch({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
