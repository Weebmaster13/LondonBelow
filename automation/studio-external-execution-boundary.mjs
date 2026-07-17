import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  dispatchEligibilityValues,
  dispatchStates,
  evaluateExecutionDispatch,
  executionDispatchAuthorityId,
  executionDispatchVersion,
  validateExecutionDispatch
} from "./studio-execution-dispatch-authority.mjs";
import {
  executionRequestAuthorityId,
  validateExecutionRequest
} from "./studio-execution-request-authority.mjs";
import {
  executionOrchestratorAuthorityId,
  validateOrchestration
} from "./studio-execution-orchestrator.mjs";
import {
  executionPlanningAuthorityId,
  validateExecutionPlan
} from "./studio-execution-planning-authority.mjs";
import {
  executionReadinessAuthorityId,
  validateReadinessProfile
} from "./studio-execution-readiness-authority.mjs";
import { capabilityNegotiationAuthorityId } from "./studio-capability-negotiation-authority.mjs";
import {
  integrationContractCompatibilityVersion,
  integrationContractProtocolVersion,
  integrationContractSchemaVersion,
  integrationContractVersion,
  stableSerialize,
  validateVersionMetadata
} from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const externalBoundarySchemaVersion = 1;
export const externalBoundaryVersion = "1.0.0";
export const externalBoundaryAuthorityId = "chapter0Home.phase136StudioExternalExecutionBoundaryAuthority";
export const externalConsumerContractVersion = "1.0.0";
export const externalConsumerType = "StudioMCPExternalImplementation";

export const boundaryStates = Object.freeze({
  idle: "Idle",
  receiveDispatch: "ReceiveDispatch",
  validateBoundaryCompatibility: "ValidateBoundaryCompatibility",
  constructHandoffPackage: "ConstructHandoffPackage",
  freezeBoundary: "FreezeBoundary",
  published: "BoundaryPublished",
  missingDispatch: "MissingDispatch",
  ineligible: "BoundaryIneligible",
  rejected: "BoundaryRejected",
  constructionFailed: "HandoffConstructionFailed",
  freezeRejected: "FreezeRejected"
});

export const boundaryEligibilityValues = Object.freeze([
  "Blocked",
  "ReadyForExternalConsumer",
  "TransferredToExternalConsumer"
]);

export const ownershipTransferStates = Object.freeze(["RepositoryOwned", "TransferPrepared", "ExternalConsumerOwned"]);
export const externalConsumerStates = Object.freeze(["NotConnected", "ConsumerUnavailable", "ConsumerContractDefined"]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  boundaryStates.published,
  boundaryStates.missingDispatch,
  boundaryStates.ineligible,
  boundaryStates.rejected,
  boundaryStates.constructionFailed,
  boundaryStates.freezeRejected
]);
const legalTransitions = new Map([
  [boundaryStates.idle, new Set([boundaryStates.receiveDispatch])],
  [boundaryStates.receiveDispatch, new Set([boundaryStates.validateBoundaryCompatibility, boundaryStates.missingDispatch])],
  [
    boundaryStates.validateBoundaryCompatibility,
    new Set([boundaryStates.constructHandoffPackage, boundaryStates.ineligible, boundaryStates.rejected])
  ],
  [boundaryStates.constructHandoffPackage, new Set([boundaryStates.freezeBoundary, boundaryStates.constructionFailed])],
  [boundaryStates.freezeBoundary, new Set([boundaryStates.published, boundaryStates.freezeRejected])]
]);

const handoffFields = Object.freeze([
  "boundaryId",
  "boundaryVersion",
  "dispatchId",
  "requestId",
  "orchestrationId",
  "executionPlanId",
  "readinessId",
  "protocolVersion",
  "capabilityProfileId",
  "executionIntent",
  "dispatchEligibility",
  "boundaryEligibility",
  "ownershipTransferState",
  "externalConsumerContract",
  "validationState",
  "timestamp"
]);
const externalConsumerContractFields = Object.freeze([
  "contractId",
  "contractVersion",
  "consumerType",
  "requiredProtocolVersion",
  "acceptedDispatchVersion",
  "requestCorrelationRequired",
  "structuredResultRequired",
  "runtimeEvidenceRequired",
  "executionAcknowledgementRequired"
]);
const diagnosticsFields = Object.freeze([
  "boundaryVersion",
  "boundaryState",
  "dispatchState",
  "dispatchEligibility",
  "boundaryEligibility",
  "ownershipTransferState",
  "externalConsumerState",
  "validationState",
  "compatibilityState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "boundaryId",
  "dispatchId",
  "requestId",
  "authorityId",
  "boundaryState",
  "boundaryEligibility",
  "ownershipTransferState",
  "externalConsumerState",
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
    const id = validateIdentifier(value, "boundary identifier");
    if (!id.ok) return id;
    if (seen.has(value)) return result(false, `duplicate boundary identifier ${value}`, "DuplicateIdentifier");
    seen.add(value);
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalBoundaryAuthorityId });
}

export function validateBoundaryTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "boundary transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(boundaryStates).includes(item.from) || !Object.values(boundaryStates).includes(item.to)) {
      return result(false, "undocumented boundary state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== boundaryStates.idle) {
      return result(false, "boundary lifecycle must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "boundary lifecycle skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal boundary state mutated", "InvalidLifecycle");
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal boundary transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic boundary transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function deriveBoundaryEligibility(dispatchEvaluation) {
  if (dispatchEvaluation?.dispatch?.dispatchEligibility === "Blocked") return "Blocked";
  if (dispatchEvaluation?.dispatch?.dispatchEligibility === "AwaitingExternalBoundary") return "ReadyForExternalConsumer";
  if (dispatchEvaluation?.dispatch?.dispatchEligibility === "EligibleForExternalBoundary") return "ReadyForExternalConsumer";
  return "Blocked";
}

function deriveOwnershipTransferState(boundaryEligibility) {
  return boundaryEligibility === "Blocked" ? "RepositoryOwned" : "TransferPrepared";
}

function validateEligibilityOwnership(boundaryEligibility, ownershipTransferState) {
  if (ownershipTransferState === "RepositoryOwned" && boundaryEligibility !== "Blocked") {
    return result(false, "RepositoryOwned requires Blocked boundary eligibility", "OwnershipMismatch");
  }
  if (ownershipTransferState === "TransferPrepared" && boundaryEligibility !== "ReadyForExternalConsumer") {
    return result(false, "TransferPrepared requires ReadyForExternalConsumer", "OwnershipMismatch");
  }
  if (ownershipTransferState === "ExternalConsumerOwned" && boundaryEligibility !== "TransferredToExternalConsumer") {
    return result(false, "ExternalConsumerOwned requires TransferredToExternalConsumer", "OwnershipMismatch");
  }
  return result(true);
}

function createExternalConsumerContract(boundaryId) {
  return deepFreeze({
    contractId: `${boundaryId}.externalConsumerContract`,
    contractVersion: externalConsumerContractVersion,
    consumerType: externalConsumerType,
    requiredProtocolVersion: integrationContractProtocolVersion,
    acceptedDispatchVersion: executionDispatchVersion,
    requestCorrelationRequired: true,
    structuredResultRequired: true,
    runtimeEvidenceRequired: true,
    executionAcknowledgementRequired: true
  });
}

export function validateExternalConsumerContract(contract) {
  const fields = exactFields(contract, externalConsumerContractFields, "external consumer contract");
  if (!fields.ok) return fields;
  for (const field of ["contractId", "contractVersion", "consumerType", "requiredProtocolVersion", "acceptedDispatchVersion"]) {
    const id = validateIdentifier(contract[field], field);
    if (!id.ok) return id;
  }
  if (contract.contractVersion !== externalConsumerContractVersion) {
    return result(false, "external consumer contract version incompatible", "ContractVersionIncompatible");
  }
  if (contract.consumerType !== externalConsumerType) {
    return result(false, "external consumer type unsupported", "UnsupportedConsumerType");
  }
  if (contract.requiredProtocolVersion !== integrationContractProtocolVersion) {
    return result(false, "external consumer protocol incompatible", "ProtocolIncompatible");
  }
  if (contract.acceptedDispatchVersion !== executionDispatchVersion) {
    return result(false, "external consumer dispatch version incompatible", "DispatchIncompatible");
  }
  for (const field of [
    "requestCorrelationRequired",
    "structuredResultRequired",
    "runtimeEvidenceRequired",
    "executionAcknowledgementRequired"
  ]) {
    if (contract[field] !== true) return result(false, `${field} must be true`, "ContractRequirementInvalid");
  }
  return result(true);
}

function createHandoffPackage(dispatchEvaluation, boundaryEligibility, ownershipTransferState, timestamp) {
  const dispatch = dispatchEvaluation.dispatch;
  const boundaryId = `${dispatch.dispatchId}.boundary`;
  return deepFreeze({
    boundaryId,
    boundaryVersion: externalBoundaryVersion,
    dispatchId: dispatch.dispatchId,
    requestId: dispatch.requestId,
    orchestrationId: dispatch.orchestrationId,
    executionPlanId: dispatch.executionPlanId,
    readinessId: dispatch.readinessId,
    protocolVersion: dispatch.protocolVersion,
    capabilityProfileId: dispatch.capabilityProfileId,
    executionIntent: dispatch.executionIntent,
    dispatchEligibility: dispatch.dispatchEligibility,
    boundaryEligibility,
    ownershipTransferState,
    externalConsumerContract: createExternalConsumerContract(boundaryId),
    validationState: "valid",
    timestamp
  });
}

function validateUpstreamCorrelation(dispatchEvaluation) {
  if (!isPlainObject(dispatchEvaluation) || dispatchEvaluation.authorityId !== executionDispatchAuthorityId) {
    return result(false, "dispatch authority incompatible", "DispatchIncompatible");
  }
  if (dispatchEvaluation.dispatchVersion !== executionDispatchVersion) {
    return result(false, "dispatch version incompatible", "DispatchIncompatible");
  }
  const dispatchValidation = validateExecutionDispatch(dispatchEvaluation.dispatch, dispatchEvaluation.requestEvaluation);
  if (!dispatchValidation.ok) return dispatchValidation;

  const requestEvaluation = dispatchEvaluation.requestEvaluation;
  if (!isPlainObject(requestEvaluation) || requestEvaluation.authorityId !== executionRequestAuthorityId) {
    return result(false, "request authority incompatible", "RequestIncompatible");
  }
  const requestValidation = validateExecutionRequest(requestEvaluation.request, requestEvaluation.orchestration);
  if (!requestValidation.ok) return requestValidation;

  const orchestrationEvaluation = requestEvaluation.orchestration;
  if (!isPlainObject(orchestrationEvaluation) || orchestrationEvaluation.authorityId !== executionOrchestratorAuthorityId) {
    return result(false, "orchestration authority incompatible", "OrchestrationIncompatible");
  }
  const orchestrationValidation = validateOrchestration(orchestrationEvaluation.orchestration);
  if (!orchestrationValidation.ok) return orchestrationValidation;

  const planningEvaluation = orchestrationEvaluation.planning;
  if (!isPlainObject(planningEvaluation) || planningEvaluation.authorityId !== executionPlanningAuthorityId) {
    return result(false, "planning authority incompatible", "PlanningIncompatible");
  }
  const planValidation = validateExecutionPlan(planningEvaluation.plan);
  if (!planValidation.ok) return planValidation;

  const readinessEvaluation = planningEvaluation.readiness;
  if (!isPlainObject(readinessEvaluation) || readinessEvaluation.authorityId !== executionReadinessAuthorityId) {
    return result(false, "readiness authority incompatible", "ReadinessIncompatible");
  }
  const profileValidation = validateReadinessProfile(readinessEvaluation.profile);
  if (!profileValidation.ok) return profileValidation;
  if (readinessEvaluation.authorities?.capability?.authorityId !== capabilityNegotiationAuthorityId) {
    return result(false, "capability authority incompatible", "CapabilityIncompatible");
  }

  const versionValidation = validateVersionMetadata({
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    schemaVersion: integrationContractSchemaVersion,
    compatibilityVersion: integrationContractCompatibilityVersion
  });
  if (!versionValidation.ok) return versionValidation;

  const dispatch = dispatchEvaluation.dispatch;
  const request = requestEvaluation.request;
  const orchestration = orchestrationEvaluation.orchestration;
  const plan = planningEvaluation.plan;
  const readiness = readinessEvaluation.profile;
  if (dispatch.requestId !== request.requestId) return result(false, "dispatch/request mismatch", "CorrelationMismatch");
  if (request.orchestrationId !== orchestration.orchestrationId) {
    return result(false, "request/orchestration mismatch", "CorrelationMismatch");
  }
  if (orchestration.executionPlanId !== plan.planId) {
    return result(false, "orchestration/plan mismatch", "CorrelationMismatch");
  }
  if (plan.readinessId !== readiness.readinessId) return result(false, "plan/readiness mismatch", "CorrelationMismatch");
  if (dispatch.protocolVersion !== integrationContractProtocolVersion) {
    return result(false, "protocol mismatch", "ProtocolIncompatible");
  }
  if (dispatch.capabilityProfileId !== request.capabilityProfileId) {
    return result(false, "capability profile mismatch", "CapabilityIncompatible");
  }
  return result(true);
}

export function validateHandoffPackage(handoff, dispatchEvaluation = null) {
  const fields = exactFields(handoff, handoffFields, "handoff package");
  if (!fields.ok) return fields;
  for (const field of [
    "boundaryId",
    "dispatchId",
    "requestId",
    "orchestrationId",
    "executionPlanId",
    "readinessId",
    "protocolVersion",
    "capabilityProfileId",
    "executionIntent",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(handoff[field], field);
    if (!id.ok) return id;
  }
  const unique = validateUniqueIdentifiers([
    handoff.boundaryId,
    handoff.dispatchId,
    handoff.requestId,
    handoff.orchestrationId,
    handoff.executionPlanId,
    handoff.readinessId,
    handoff.capabilityProfileId
  ]);
  if (!unique.ok) return unique;
  if (handoff.boundaryVersion !== externalBoundaryVersion) {
    return result(false, "boundary version incompatible", "BoundaryVersionIncompatible");
  }
  if (handoff.protocolVersion !== integrationContractProtocolVersion) {
    return result(false, "boundary protocol version incompatible", "ProtocolIncompatible");
  }
  if (!dispatchEligibilityValues.includes(handoff.dispatchEligibility)) {
    return result(false, "dispatch eligibility unsupported", "DispatchEligibilityInvalid");
  }
  if (!boundaryEligibilityValues.includes(handoff.boundaryEligibility)) {
    return result(false, "boundary eligibility unsupported", "BoundaryEligibilityInvalid");
  }
  if (!ownershipTransferStates.includes(handoff.ownershipTransferState)) {
    return result(false, "ownership transfer state unsupported", "OwnershipStateInvalid");
  }
  const ownership = validateEligibilityOwnership(handoff.boundaryEligibility, handoff.ownershipTransferState);
  if (!ownership.ok) return ownership;
  const contract = validateExternalConsumerContract(handoff.externalConsumerContract);
  if (!contract.ok) return contract;
  if (handoff.validationState !== "valid") {
    return result(false, "handoff validation state invalid", "InvalidValidationState");
  }
  if (dispatchEvaluation !== null) {
    const upstream = validateUpstreamCorrelation(dispatchEvaluation);
    if (!upstream.ok) return upstream;
    const dispatch = dispatchEvaluation.dispatch;
    for (const field of [
      "dispatchId",
      "requestId",
      "orchestrationId",
      "executionPlanId",
      "readinessId",
      "protocolVersion",
      "capabilityProfileId",
      "executionIntent",
      "dispatchEligibility"
    ]) {
      if (handoff[field] !== dispatch[field]) return result(false, `${field} mismatch`, "CorrelationMismatch");
    }
    const derivedBoundaryEligibility = deriveBoundaryEligibility(dispatchEvaluation);
    if (handoff.boundaryEligibility !== derivedBoundaryEligibility) {
      return result(false, "boundary eligibility does not match dispatch truth", "BoundaryEligibilityInvalid");
    }
  }
  return result(true);
}

function createAudit(handoff, boundaryState, externalConsumerState, timestamp) {
  return deepFreeze([
    {
      boundaryId: handoff?.boundaryId ?? "missing",
      dispatchId: handoff?.dispatchId ?? "missing",
      requestId: handoff?.requestId ?? "missing",
      authorityId: externalBoundaryAuthorityId,
      boundaryState,
      boundaryEligibility: handoff?.boundaryEligibility ?? "missing",
      ownershipTransferState: handoff?.ownershipTransferState ?? "missing",
      externalConsumerState,
      timestamp,
      contractVersion: integrationContractVersion
    }
  ]);
}

export function validateBoundaryAudit(audit) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "boundary audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "boundary audit");
    if (!fields.ok) return fields;
    for (const field of [
      "boundaryId",
      "dispatchId",
      "requestId",
      "authorityId",
      "boundaryState",
      "boundaryEligibility",
      "ownershipTransferState",
      "externalConsumerState",
      "timestamp",
      "contractVersion"
    ]) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalBoundaryAuthorityId) return result(false, "boundary audit authority mismatch", "InvalidAudit");
    if (!Object.values(boundaryStates).includes(item.boundaryState)) return result(false, "boundary audit state invalid", "InvalidAudit");
    if (item.boundaryEligibility !== "missing" && !boundaryEligibilityValues.includes(item.boundaryEligibility)) {
      return result(false, "boundary audit eligibility invalid", "InvalidAudit");
    }
    if (item.ownershipTransferState !== "missing" && !ownershipTransferStates.includes(item.ownershipTransferState)) {
      return result(false, "boundary audit ownership invalid", "InvalidAudit");
    }
    if (!externalConsumerStates.includes(item.externalConsumerState)) {
      return result(false, "boundary audit consumer state invalid", "InvalidAudit");
    }
    if (item.contractVersion !== integrationContractVersion) return result(false, "boundary audit contract mismatch", "InvalidAudit");
    const identity = `${item.boundaryId}:${item.dispatchId}:${item.boundaryState}:${item.timestamp}`;
    if (identities.has(identity)) return result(false, "duplicate boundary audit identity", "DuplicateAudit");
    identities.add(identity);
    if (previousKey !== "" && identity < previousKey) return result(false, "boundary audit order invalid", "InvalidAuditOrder");
    previousKey = identity;
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    boundaryVersion: evaluation.boundaryVersion,
    boundaryState: evaluation.boundaryState,
    dispatchState: evaluation.dispatchEvaluation?.dispatchState ?? "missing",
    dispatchEligibility: evaluation.dispatchEvaluation?.dispatchEligibility ?? "missing",
    boundaryEligibility: evaluation.boundaryEligibility,
    ownershipTransferState: evaluation.ownershipTransferState,
    externalConsumerState: evaluation.externalConsumerState,
    validationState: evaluation.handoffValidation.ok ? "valid" : "invalid",
    compatibilityState: evaluation.compatibilityState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateBoundaryDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "boundary diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.boundaryVersion !== externalBoundaryVersion) return result(false, "boundary diagnostics version mismatch", "InvalidDiagnostics");
  if (!Object.values(boundaryStates).includes(diagnostics.boundaryState)) {
    return result(false, "boundary diagnostics state invalid", "InvalidDiagnostics");
  }
  if (!dispatchEligibilityValues.includes(diagnostics.dispatchEligibility) && diagnostics.dispatchEligibility !== "missing") {
    return result(false, "boundary diagnostics dispatch eligibility invalid", "InvalidDiagnostics");
  }
  if (!boundaryEligibilityValues.includes(diagnostics.boundaryEligibility)) {
    return result(false, "boundary diagnostics eligibility invalid", "InvalidDiagnostics");
  }
  if (!ownershipTransferStates.includes(diagnostics.ownershipTransferState)) {
    return result(false, "boundary diagnostics ownership invalid", "InvalidDiagnostics");
  }
  if (!externalConsumerStates.includes(diagnostics.externalConsumerState)) {
    return result(false, "boundary diagnostics consumer state invalid", "InvalidDiagnostics");
  }
  if (!["valid", "invalid"].includes(diagnostics.validationState)) {
    return result(false, "boundary diagnostics validation invalid", "InvalidDiagnostics");
  }
  if (!["compatible", "incompatible"].includes(diagnostics.compatibilityState)) {
    return result(false, "boundary diagnostics compatibility invalid", "InvalidDiagnostics");
  }
  return result(true);
}

export function evaluateExternalExecutionBoundary(input = {}) {
  const timestamp = input.timestamp ?? now();
  const dispatchEvaluation = input.dispatchEvaluation ?? evaluateExecutionDispatch({ ...input, timestamp });
  const transitions = [transition(boundaryStates.idle, boundaryStates.receiveDispatch, "receiving dispatch", timestamp)];
  let boundaryState = boundaryStates.published;
  let failureReason = null;
  let handoff = null;
  let boundaryEligibility = "Blocked";
  let ownershipTransferState = "RepositoryOwned";
  const externalConsumerState = "ConsumerContractDefined";
  let handoffValidation = result(false, "handoff not created", "MissingDispatch");

  if (!isPlainObject(dispatchEvaluation) || dispatchEvaluation.authorityId !== executionDispatchAuthorityId || !isPlainObject(dispatchEvaluation.dispatch)) {
    transitions.push(transition(boundaryStates.receiveDispatch, boundaryStates.missingDispatch, "MissingDispatch", timestamp));
    boundaryState = boundaryStates.missingDispatch;
    failureReason = "MissingDispatch";
  } else {
    transitions.push(transition(boundaryStates.receiveDispatch, boundaryStates.validateBoundaryCompatibility, "dispatch received", timestamp));
    const upstream = validateUpstreamCorrelation(dispatchEvaluation);
    boundaryEligibility = deriveBoundaryEligibility(dispatchEvaluation);
    ownershipTransferState = deriveOwnershipTransferState(boundaryEligibility);
    if (!upstream.ok) {
      transitions.push(transition(boundaryStates.validateBoundaryCompatibility, boundaryStates.rejected, upstream.failure, timestamp));
      boundaryState = boundaryStates.rejected;
      failureReason = upstream.failure;
    } else if (boundaryEligibility !== "Blocked" && dispatchEvaluation.dispatch.dispatchEligibility === "Blocked") {
      transitions.push(transition(boundaryStates.validateBoundaryCompatibility, boundaryStates.ineligible, "BoundaryIneligible", timestamp));
      boundaryState = boundaryStates.ineligible;
      failureReason = "BoundaryIneligible";
    } else {
      transitions.push(transition(boundaryStates.validateBoundaryCompatibility, boundaryStates.constructHandoffPackage, "boundary compatibility accepted", timestamp));
      handoff = createHandoffPackage(dispatchEvaluation, boundaryEligibility, ownershipTransferState, timestamp);
      handoffValidation = validateHandoffPackage(handoff, dispatchEvaluation);
      if (!handoffValidation.ok) {
        transitions.push(transition(boundaryStates.constructHandoffPackage, boundaryStates.constructionFailed, handoffValidation.failure, timestamp));
        boundaryState = boundaryStates.constructionFailed;
        failureReason = handoffValidation.failure;
      } else {
        transitions.push(transition(boundaryStates.constructHandoffPackage, boundaryStates.freezeBoundary, "handoff package constructed", timestamp));
        if (!Object.isFrozen(handoff) || !Object.isFrozen(handoff.externalConsumerContract)) {
          transitions.push(transition(boundaryStates.freezeBoundary, boundaryStates.freezeRejected, "FreezeRejected", timestamp));
          boundaryState = boundaryStates.freezeRejected;
          failureReason = "FreezeRejected";
        } else {
          transitions.push(transition(boundaryStates.freezeBoundary, boundaryStates.published, "handoff package frozen", timestamp));
        }
      }
    }
  }

  const transitionValidation = validateBoundaryTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  const compatibilityState = handoffValidation.ok && transitionValidation.ok ? "compatible" : "incompatible";
  const audit = createAudit(handoff, boundaryState, externalConsumerState, timestamp);
  const evaluation = {
    schemaVersion: externalBoundarySchemaVersion,
    authorityId: externalBoundaryAuthorityId,
    boundaryVersion: externalBoundaryVersion,
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    status: "executionBlocked",
    exitCode: handoffValidation.ok ? bridgeExitCodes.executionBlocked : bridgeExitCodes.validationFailed,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeTruth: {
      sessionFailureReason: "SESSION_NOT_VISIBLE",
      status: "executionBlocked",
      runnerInvoked: false,
      structuredResultCaptured: false
    },
    boundaryState,
    boundaryEligibility,
    ownershipTransferState,
    externalConsumerState,
    dispatchEvaluation,
    handoff,
    handoffValidation,
    transitionValidation,
    audit,
    auditValidation: validateBoundaryAudit(audit),
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
      "Phase135ExecutionDispatchAuthority",
      "Phase136ExternalExecutionBoundary",
      "FutureExternalStudioMcpImplementationDocumentationOnly"
    ],
    failureReason,
    recommendedAction: "Resolve connected Studio MCP execution support before any future external consumer can receive a boundary package.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateBoundaryDiagnostics(diagnosticsFor(evaluation)),
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

export function runExternalBoundarySelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExternalExecutionBoundary({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExternalExecutionBoundary({ timestamp: stableTimestamp, repositoryState });
  const missingDispatch = evaluateExternalExecutionBoundary({ timestamp: stableTimestamp, dispatchEvaluation: {} });
  const illegalTransition = validateBoundaryTransitions([
    transition(boundaryStates.idle, boundaryStates.freezeBoundary, "skip", stableTimestamp)
  ]);
  const skippedTransition = validateBoundaryTransitions([
    transition(boundaryStates.idle, boundaryStates.receiveDispatch, "start", stableTimestamp),
    transition(boundaryStates.validateBoundaryCompatibility, boundaryStates.constructHandoffPackage, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateBoundaryTransitions([
    transition(boundaryStates.idle, boundaryStates.receiveDispatch, "start", stableTimestamp),
    transition(boundaryStates.receiveDispatch, boundaryStates.validateBoundaryCompatibility, "validate", stableTimestamp),
    transition(boundaryStates.validateBoundaryCompatibility, boundaryStates.receiveDispatch, "cycle", stableTimestamp)
  ]);
  const terminalMutation = validateBoundaryTransitions([
    transition(boundaryStates.idle, boundaryStates.receiveDispatch, "start", stableTimestamp),
    transition(boundaryStates.receiveDispatch, boundaryStates.missingDispatch, "stop", stableTimestamp),
    transition(boundaryStates.missingDispatch, boundaryStates.validateBoundaryCompatibility, "mutate", stableTimestamp)
  ]);
  const badHandoff = { ...evaluation.handoff, extra: true };
  const missingFieldHandoff = { ...evaluation.handoff };
  delete missingFieldHandoff.executionIntent;
  const duplicateHandoff = { ...evaluation.handoff, boundaryId: evaluation.handoff.dispatchId };
  const badCorrelation = { ...evaluation.handoff, requestId: "different.request" };
  const badOwnership = { ...evaluation.handoff, ownershipTransferState: "TransferPrepared" };
  const badContract = { ...evaluation.handoff.externalConsumerContract, consumerType: "UnknownConsumer" };
  const badContractField = { ...evaluation.handoff.externalConsumerContract, extra: true };
  const badDiagnostics = { ...evaluation.diagnostics, productionCertified: false };
  const duplicateAudit = validateBoundaryAudit([...evaluation.audit, ...evaluation.audit]);
  const reorderedAudit = validateBoundaryAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:00.000Z" }
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingDispatchRejection", missingDispatch.boundaryState === boundaryStates.missingDispatch, "");
  assertSelfCheck(results, "boundaryIneligibleHandling", boundaryStates.ineligible === "BoundaryIneligible", "");
  assertSelfCheck(results, "compatibilityRejection", validateHandoffPackage(badCorrelation, evaluation.dispatchEvaluation).ok === false, "");
  assertSelfCheck(results, "constructionFailureHandling", boundaryStates.constructionFailed === "HandoffConstructionFailed", "");
  assertSelfCheck(results, "freezeRejectionHandling", boundaryStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", illegalTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactHandoffSchema", Object.keys(evaluation.handoff).length === handoffFields.length, "");
  assertSelfCheck(results, "unknownFieldRejection", validateHandoffPackage(badHandoff, evaluation.dispatchEvaluation).ok === false, "");
  assertSelfCheck(results, "missingFieldRejection", validateHandoffPackage(missingFieldHandoff, evaluation.dispatchEvaluation).ok === false, "");
  assertSelfCheck(results, "duplicateIdentityRejection", validateHandoffPackage(duplicateHandoff, evaluation.dispatchEvaluation).ok === false, "");
  assertSelfCheck(results, "upstreamCorrelationValidation", validateUpstreamCorrelation(evaluation.dispatchEvaluation).ok === true, "");
  assertSelfCheck(results, "dispatchRequestCorrelation", evaluation.handoff.requestId === evaluation.dispatchEvaluation.dispatch.requestId, "");
  assertSelfCheck(results, "requestOrchestrationCorrelation", evaluation.handoff.orchestrationId === evaluation.dispatchEvaluation.requestEvaluation.request.orchestrationId, "");
  assertSelfCheck(results, "orchestrationPlanCorrelation", evaluation.handoff.executionPlanId === evaluation.dispatchEvaluation.requestEvaluation.orchestration.orchestration.executionPlanId, "");
  assertSelfCheck(results, "planReadinessCorrelation", evaluation.handoff.readinessId === evaluation.dispatchEvaluation.requestEvaluation.orchestration.planning.plan.readinessId, "");
  assertSelfCheck(results, "protocolCompatibility", evaluation.handoff.protocolVersion === integrationContractProtocolVersion, "");
  assertSelfCheck(results, "capabilityCompatibility", evaluation.dispatchEvaluation.requestEvaluation.orchestration.planning.readiness.authorities.capability.authorityId === capabilityNegotiationAuthorityId, "");
  assertSelfCheck(results, "executionIntentPreservation", evaluation.handoff.executionIntent === evaluation.dispatchEvaluation.dispatch.executionIntent, "");
  assertSelfCheck(results, "dispatchEligibilityPreservation", evaluation.handoff.dispatchEligibility === evaluation.dispatchEvaluation.dispatch.dispatchEligibility, "");
  assertSelfCheck(results, "blockedBoundaryTruthfulness", evaluation.boundaryEligibility === "Blocked", "");
  assertSelfCheck(results, "ownershipStateValidation", ownershipTransferStates.includes(evaluation.ownershipTransferState), "");
  assertSelfCheck(results, "eligibilityOwnershipRelationshipValidation", validateHandoffPackage(badOwnership, evaluation.dispatchEvaluation).ok === false, "");
  assertSelfCheck(results, "exactExternalConsumerContractSchema", Object.keys(evaluation.handoff.externalConsumerContract).length === externalConsumerContractFields.length, "");
  assertSelfCheck(results, "consumerTypeValidation", validateExternalConsumerContract(badContract).ok === false, "");
  assertSelfCheck(results, "consumerContractUnknownFieldRejection", validateExternalConsumerContract(badContractField).ok === false, "");
  assertSelfCheck(results, "immutableBoundaryPublication", Object.isFrozen(evaluation.handoff), "");
  assertSelfCheck(results, "immutableConsumerContractPublication", Object.isFrozen(evaluation.handoff.externalConsumerContract), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateBoundaryDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "immutableAuditValidation", Object.isFrozen(evaluation.audit) && evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicIdentifiers", evaluation.handoff.boundaryId === `${evaluation.handoff.dispatchId}.boundary`, "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && evaluation.handoff.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalBoundaryAuthorityId, "");
  assertSelfCheck(results, "phase135RegressionCompatibility", evaluation.dispatchEvaluation.authorityId === executionDispatchAuthorityId, "");
  assertSelfCheck(results, "phase134RegressionCompatibility", evaluation.dispatchEvaluation.requestEvaluation.authorityId === executionRequestAuthorityId, "");
  assertSelfCheck(results, "phase133RegressionCompatibility", evaluation.dispatchEvaluation.requestEvaluation.orchestration.authorityId === executionOrchestratorAuthorityId, "");
  assertSelfCheck(results, "phase132RegressionCompatibility", evaluation.dispatchEvaluation.requestEvaluation.orchestration.planning.authorityId === executionPlanningAuthorityId, "");
  assertSelfCheck(results, "noStudioExecution", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noRunnerInvocation", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noChildProcessExecution", true, "");
  assertSelfCheck(results, "noNetworkTransport", !("transport" in evaluation), "");
  assertSelfCheck(results, "noMcpCommunication", true, "");
  assertSelfCheck(results, "noExternalConsumerDiscovery", evaluation.externalConsumerState !== "NotConnected", "");
  assertSelfCheck(results, "noRuntimeEvidence", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noStructuredResultCapture", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("productionCertified" in evaluation) && !("certificationDecision" in evaluation), "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExternalBoundarySelfChecks();
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
  const evaluation = evaluateExternalExecutionBoundary({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
