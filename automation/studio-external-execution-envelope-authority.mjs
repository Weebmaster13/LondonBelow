import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  consumerCompatibilityAuthorityId,
  consumerCompatibilityVersion,
  evaluateConsumerCompatibility,
  validateCompatibilityEvaluation
} from "./studio-consumer-compatibility-authority.mjs";
import { externalConsumerManifestAuthorityId, externalConsumerManifestVersion } from "./studio-external-consumer-manifest-authority.mjs";
import { externalConsumerContractAuthorityId, externalConsumerContractAuthorityVersion } from "./studio-external-consumer-contract-authority.mjs";
import { externalBoundaryAuthorityId, externalBoundaryVersion } from "./studio-external-execution-boundary.mjs";
import { executionDispatchAuthorityId, executionDispatchVersion } from "./studio-execution-dispatch-authority.mjs";
import { executionRequestAuthorityId } from "./studio-execution-request-authority.mjs";
import { executionOrchestratorAuthorityId } from "./studio-execution-orchestrator.mjs";
import { executionPlanningAuthorityId } from "./studio-execution-planning-authority.mjs";
import { executionReadinessAuthorityId } from "./studio-execution-readiness-authority.mjs";
import { stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const externalExecutionEnvelopeSchemaVersion = 1;
export const externalExecutionEnvelopeVersion = "1.0.0";
export const externalExecutionEnvelopeAuthorityId = "chapter0Home.phase140StudioExternalExecutionEnvelopeAuthority";

export const envelopeStates = Object.freeze({
  idle: "Idle",
  receiveCompatibilityEvaluation: "ReceiveCompatibilityEvaluation",
  resolveUpstreamArtifacts: "ResolveUpstreamArtifacts",
  validateEnvelopeCorrelation: "ValidateEnvelopeCorrelation",
  constructExecutionEnvelope: "ConstructExecutionEnvelope",
  validateEnvelopeEligibility: "ValidateEnvelopeEligibility",
  freezeExecutionEnvelope: "FreezeExecutionEnvelope",
  published: "ExecutionEnvelopePublished",
  missingCompatibilityEvaluation: "MissingCompatibilityEvaluation",
  upstreamResolutionFailed: "UpstreamArtifactResolutionFailed",
  correlationRejected: "EnvelopeCorrelationRejected",
  constructionFailed: "EnvelopeConstructionFailed",
  ineligible: "EnvelopeIneligible",
  freezeRejected: "FreezeRejected"
});

export const envelopeEligibilityValues = Object.freeze(["Blocked", "DefinitionCompleteButUnavailable", "ReadyForFutureTransport"]);
export const upstreamResolutionStates = Object.freeze(["Resolved", "Unresolved"]);
export const correlationStates = Object.freeze(["Valid", "Invalid"]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  envelopeStates.published,
  envelopeStates.missingCompatibilityEvaluation,
  envelopeStates.upstreamResolutionFailed,
  envelopeStates.correlationRejected,
  envelopeStates.constructionFailed,
  envelopeStates.ineligible,
  envelopeStates.freezeRejected
]);
const legalTransitions = new Map([
  [envelopeStates.idle, new Set([envelopeStates.receiveCompatibilityEvaluation])],
  [envelopeStates.receiveCompatibilityEvaluation, new Set([envelopeStates.resolveUpstreamArtifacts, envelopeStates.missingCompatibilityEvaluation])],
  [envelopeStates.resolveUpstreamArtifacts, new Set([envelopeStates.validateEnvelopeCorrelation, envelopeStates.upstreamResolutionFailed])],
  [envelopeStates.validateEnvelopeCorrelation, new Set([envelopeStates.constructExecutionEnvelope, envelopeStates.correlationRejected])],
  [envelopeStates.constructExecutionEnvelope, new Set([envelopeStates.validateEnvelopeEligibility, envelopeStates.constructionFailed])],
  [envelopeStates.validateEnvelopeEligibility, new Set([envelopeStates.freezeExecutionEnvelope, envelopeStates.ineligible])],
  [envelopeStates.freezeExecutionEnvelope, new Set([envelopeStates.published, envelopeStates.freezeRejected])]
]);

const envelopeFields = Object.freeze([
  "envelopeId",
  "envelopeVersion",
  "readinessId",
  "executionPlanId",
  "orchestrationId",
  "requestId",
  "dispatchId",
  "boundaryId",
  "consumerContractId",
  "manifestId",
  "compatibilityEvaluationId",
  "candidateProfileId",
  "protocolVersion",
  "capabilityProfileVersion",
  "executionIntentSnapshot",
  "dispatchSnapshot",
  "boundarySnapshot",
  "consumerContractSnapshot",
  "manifestSnapshot",
  "compatibilitySnapshot",
  "correlationSnapshot",
  "envelopeEligibility",
  "ownershipTransferState",
  "consumerAvailabilityState",
  "executionBlocked",
  "validationState",
  "timestamp"
]);
const intentFields = Object.freeze(["intentType", "executionTarget", "requestPurpose", "runtimeScope", "evidenceRequired", "certificationRequested"]);
const dispatchFields = Object.freeze(["dispatchVersion", "dispatchState", "dispatchEligibility", "requestId", "executionIntent", "validationState"]);
const boundaryFields = Object.freeze([
  "boundaryVersion",
  "boundaryState",
  "boundaryEligibility",
  "ownershipTransferState",
  "externalConsumerState",
  "externalConsumerContractId",
  "validationState"
]);
const contractFields = Object.freeze([
  "consumerContractVersion",
  "consumerType",
  "requiredProtocolVersion",
  "acceptedDispatchVersion",
  "minimumCapabilityProfileVersion",
  "acknowledgementSchemaVersion",
  "resultSchemaVersion",
  "evidenceSchemaVersion",
  "failureSchemaVersion",
  "compatibilityState"
]);
const manifestFields = Object.freeze([
  "manifestVersion",
  "consumerType",
  "consumerStatus",
  "supportedContractVersion",
  "supportedProtocolVersion",
  "supportedBoundaryVersion",
  "supportedDispatchVersion",
  "minimumCapabilityVersion",
  "matrixResult"
]);
const compatibilityFields = Object.freeze([
  "evaluationVersion",
  "overallCompatibility",
  "consumerAvailabilityState",
  "executionEligibility",
  "protocolResult",
  "dispatchResult",
  "boundaryResult",
  "capabilityResult",
  "acknowledgementSchemaResult",
  "resultSchemaResult",
  "evidenceSchemaResult",
  "failureSchemaResult",
  "manifestRecognitionResult"
]);
const correlationFields = Object.freeze([
  "readinessId",
  "executionPlanId",
  "orchestrationId",
  "requestId",
  "dispatchId",
  "boundaryId",
  "consumerContractId",
  "manifestId",
  "compatibilityEvaluationId",
  "candidateProfileId",
  "strictCorrelationValidated"
]);
const diagnosticsFields = Object.freeze([
  "envelopeVersion",
  "envelopeState",
  "upstreamResolutionState",
  "correlationState",
  "envelopeEligibility",
  "consumerAvailabilityState",
  "executionEligibility",
  "boundaryEligibility",
  "ownershipTransferState",
  "executionBlocked",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "envelopeId",
  "compatibilityEvaluationId",
  "manifestId",
  "consumerContractId",
  "boundaryId",
  "dispatchId",
  "requestId",
  "authorityId",
  "envelopeState",
  "envelopeEligibility",
  "ownershipTransferState",
  "timestamp",
  "envelopeVersion"
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
    const id = validateIdentifier(value, "envelope identifier");
    if (!id.ok) return id;
    if (seen.has(value)) return result(false, `duplicate envelope identifier ${value}`, "DuplicateIdentifier");
    seen.add(value);
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalExecutionEnvelopeAuthorityId });
}

export function validateEnvelopeTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) return result(false, "envelope transitions must be non-empty", "InvalidLifecycle");
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(envelopeStates).includes(item.from) || !Object.values(envelopeStates).includes(item.to)) {
      return result(false, "undocumented envelope state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== envelopeStates.idle) return result(false, "envelope lifecycle must start at Idle", "InvalidLifecycle");
    if (index > 0 && transitions[index - 1].to !== item.from) return result(false, "envelope lifecycle skipped state", "InvalidLifecycle");
    if (terminalStates.has(item.from) || terminalSeen) return result(false, "terminal envelope state mutated", "InvalidLifecycle");
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal envelope transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic envelope transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function upstream(compatibilityEvaluation) {
  const manifestEvaluation = compatibilityEvaluation.manifestEvaluation;
  const contractEvaluation = manifestEvaluation.contractEvaluation;
  const boundaryEvaluation = contractEvaluation.boundaryEvaluation;
  const dispatchEvaluation = boundaryEvaluation.dispatchEvaluation;
  const requestEvaluation = dispatchEvaluation.requestEvaluation;
  const orchestrationEvaluation = requestEvaluation.orchestration;
  const planningEvaluation = orchestrationEvaluation.planning;
  const readinessEvaluation = planningEvaluation.readiness;
  return {
    manifestEvaluation,
    contractEvaluation,
    boundaryEvaluation,
    dispatchEvaluation,
    requestEvaluation,
    orchestrationEvaluation,
    planningEvaluation,
    readinessEvaluation,
    manifest: manifestEvaluation.manifest,
    contract: contractEvaluation.consumerContract,
    handoff: boundaryEvaluation.handoff,
    dispatch: dispatchEvaluation.dispatch,
    request: requestEvaluation.request,
    orchestration: orchestrationEvaluation.orchestration,
    plan: planningEvaluation.plan,
    readiness: readinessEvaluation.profile,
    compatibility: compatibilityEvaluation.compatibilityEvaluation,
    candidate: compatibilityEvaluation.candidateProfile
  };
}

export function validateUpstreamArtifacts(compatibilityEvaluation) {
  if (!isPlainObject(compatibilityEvaluation) || compatibilityEvaluation.authorityId !== consumerCompatibilityAuthorityId) {
    return result(false, "compatibility authority incompatible", "CompatibilityIncompatible");
  }
  if (!isPlainObject(compatibilityEvaluation.compatibilityEvaluation)) {
    return result(false, "compatibility evaluation missing", "CompatibilityMissing");
  }
  const compatibilityValidation = validateCompatibilityEvaluation(
    compatibilityEvaluation.compatibilityEvaluation,
    compatibilityEvaluation.candidateProfile,
    compatibilityEvaluation.manifestEvaluation
  );
  if (!compatibilityValidation.ok) return compatibilityValidation;
  const refs = upstream(compatibilityEvaluation);
  if (refs.manifestEvaluation.authorityId !== externalConsumerManifestAuthorityId) return result(false, "manifest authority incompatible", "ManifestIncompatible");
  if (refs.contractEvaluation.authorityId !== externalConsumerContractAuthorityId) return result(false, "contract authority incompatible", "ContractIncompatible");
  if (refs.boundaryEvaluation.authorityId !== externalBoundaryAuthorityId) return result(false, "boundary authority incompatible", "BoundaryIncompatible");
  if (refs.dispatchEvaluation.authorityId !== executionDispatchAuthorityId) return result(false, "dispatch authority incompatible", "DispatchIncompatible");
  if (refs.requestEvaluation.authorityId !== executionRequestAuthorityId) return result(false, "request authority incompatible", "RequestIncompatible");
  if (refs.orchestrationEvaluation.authorityId !== executionOrchestratorAuthorityId) return result(false, "orchestration authority incompatible", "OrchestrationIncompatible");
  if (refs.planningEvaluation.authorityId !== executionPlanningAuthorityId) return result(false, "planning authority incompatible", "PlanningIncompatible");
  if (refs.readinessEvaluation.authorityId !== executionReadinessAuthorityId) return result(false, "readiness authority incompatible", "ReadinessIncompatible");
  return result(true, null, null, refs);
}

function createSnapshots(refs) {
  const catalog = refs.manifest.supportedCapabilityProfiles[0];
  const matrix = refs.manifest.compatibilityMatrix[0];
  return {
    executionIntentSnapshot: deepFreeze({
      intentType: refs.dispatch.executionIntent,
      executionTarget: refs.request.runnerId ?? "chapter0Home.phase118ObservationCertification",
      requestPurpose: refs.request.intent ?? refs.dispatch.executionIntent,
      runtimeScope: "ValidationOnly",
      evidenceRequired: refs.contract.runtimeEvidenceContract.evidenceRequired,
      certificationRequested: false
    }),
    dispatchSnapshot: deepFreeze({
      dispatchVersion: refs.dispatch.dispatchVersion,
      dispatchState: refs.dispatchEvaluation.dispatchState,
      dispatchEligibility: refs.dispatch.dispatchEligibility,
      requestId: refs.dispatch.requestId,
      executionIntent: refs.dispatch.executionIntent,
      validationState: refs.dispatch.validationState
    }),
    boundarySnapshot: deepFreeze({
      boundaryVersion: refs.handoff.boundaryVersion,
      boundaryState: refs.boundaryEvaluation.boundaryState,
      boundaryEligibility: refs.handoff.boundaryEligibility,
      ownershipTransferState: refs.handoff.ownershipTransferState,
      externalConsumerState: refs.boundaryEvaluation.externalConsumerState,
      externalConsumerContractId: refs.handoff.externalConsumerContract.contractId,
      validationState: refs.handoff.validationState
    }),
    consumerContractSnapshot: deepFreeze({
      consumerContractVersion: refs.contract.consumerContractVersion,
      consumerType: refs.contract.consumerType,
      requiredProtocolVersion: refs.contract.requiredProtocolVersion,
      acceptedDispatchVersion: refs.contract.acceptedDispatchVersion,
      minimumCapabilityProfileVersion: refs.contract.minimumCapabilityProfileVersion,
      acknowledgementSchemaVersion: String(refs.contract.executionAcknowledgementContract.schemaVersion),
      resultSchemaVersion: String(refs.contract.structuredResultContract.schemaVersion),
      evidenceSchemaVersion: String(refs.contract.runtimeEvidenceContract.schemaVersion),
      failureSchemaVersion: String(refs.contract.failureContract.schemaVersion),
      compatibilityState: refs.contractEvaluation.compatibilityState
    }),
    manifestSnapshot: deepFreeze({
      manifestVersion: refs.manifest.manifestVersion,
      consumerType: refs.manifest.consumerType,
      consumerStatus: catalog.status,
      supportedContractVersion: catalog.supportedContractVersion,
      supportedProtocolVersion: catalog.supportedProtocolVersion,
      supportedBoundaryVersion: matrix.boundaryVersion,
      supportedDispatchVersion: matrix.dispatchVersion,
      minimumCapabilityVersion: catalog.minimumCapabilityVersion,
      matrixResult: matrix.compatibilityResult
    }),
    compatibilitySnapshot: deepFreeze({
      evaluationVersion: refs.compatibility.evaluationVersion,
      overallCompatibility: refs.compatibility.overallCompatibility,
      consumerAvailabilityState: refs.compatibility.consumerAvailabilityState,
      executionEligibility: refs.compatibility.executionEligibility,
      protocolResult: refs.compatibility.protocolEvaluation.evaluationResult,
      dispatchResult: refs.compatibility.dispatchEvaluation.evaluationResult,
      boundaryResult: refs.compatibility.boundaryEvaluation.evaluationResult,
      capabilityResult: refs.compatibility.capabilityEvaluation.evaluationResult,
      acknowledgementSchemaResult: refs.compatibility.acknowledgementSchemaEvaluation.evaluationResult,
      resultSchemaResult: refs.compatibility.resultSchemaEvaluation.evaluationResult,
      evidenceSchemaResult: refs.compatibility.evidenceSchemaEvaluation.evaluationResult,
      failureSchemaResult: refs.compatibility.failureSchemaEvaluation.evaluationResult,
      manifestRecognitionResult: refs.compatibility.manifestRecognitionEvaluation.evaluationResult
    }),
    correlationSnapshot: deepFreeze({
      readinessId: refs.readiness.readinessId,
      executionPlanId: refs.plan.planId,
      orchestrationId: refs.orchestration.orchestrationId,
      requestId: refs.request.requestId,
      dispatchId: refs.dispatch.dispatchId,
      boundaryId: refs.handoff.boundaryId,
      consumerContractId: refs.contract.consumerContractId,
      manifestId: refs.manifest.manifestId,
      compatibilityEvaluationId: refs.compatibility.evaluationId,
      candidateProfileId: refs.candidate.candidateProfileId,
      strictCorrelationValidated: true
    })
  };
}

function validateSnapshot(value, fields, label) {
  return exactFields(value, fields, label);
}

function deriveEnvelopeEligibility(refs) {
  if (
    refs.compatibility.overallCompatibility === "CompatibleDefinition" &&
    refs.compatibility.consumerAvailabilityState === "CandidateDeclared" &&
    refs.compatibility.executionEligibility === "DefinitionCompatibleButUnavailable" &&
    refs.handoff.boundaryEligibility === "Blocked" &&
    refs.handoff.ownershipTransferState === "RepositoryOwned"
  ) {
    return "DefinitionCompleteButUnavailable";
  }
  return "Blocked";
}

function createEnvelope(refs, timestamp) {
  const snapshots = createSnapshots(refs);
  const envelopeEligibility = deriveEnvelopeEligibility(refs);
  return deepFreeze({
    envelopeId: `${refs.compatibility.evaluationId}.envelope`,
    envelopeVersion: externalExecutionEnvelopeVersion,
    readinessId: refs.readiness.readinessId,
    executionPlanId: refs.plan.planId,
    orchestrationId: refs.orchestration.orchestrationId,
    requestId: refs.request.requestId,
    dispatchId: refs.dispatch.dispatchId,
    boundaryId: refs.handoff.boundaryId,
    consumerContractId: refs.contract.consumerContractId,
    manifestId: refs.manifest.manifestId,
    compatibilityEvaluationId: refs.compatibility.evaluationId,
    candidateProfileId: refs.candidate.candidateProfileId,
    protocolVersion: refs.dispatch.protocolVersion,
    capabilityProfileVersion: refs.candidate.capabilityProfileVersion,
    ...snapshots,
    envelopeEligibility,
    ownershipTransferState: refs.handoff.ownershipTransferState,
    consumerAvailabilityState: refs.compatibility.consumerAvailabilityState,
    executionBlocked: true,
    validationState: "valid",
    timestamp
  });
}

export function validateEnvelopeCorrelation(envelope, refs) {
  const pairs = [
    ["readinessId", refs.readiness.readinessId],
    ["executionPlanId", refs.plan.planId],
    ["orchestrationId", refs.orchestration.orchestrationId],
    ["requestId", refs.request.requestId],
    ["dispatchId", refs.dispatch.dispatchId],
    ["boundaryId", refs.handoff.boundaryId],
    ["consumerContractId", refs.contract.consumerContractId],
    ["manifestId", refs.manifest.manifestId],
    ["compatibilityEvaluationId", refs.compatibility.evaluationId],
    ["candidateProfileId", refs.candidate.candidateProfileId]
  ];
  for (const [field, expected] of pairs) {
    if (envelope[field] !== expected || envelope.correlationSnapshot[field] !== expected) {
      return result(false, `${field} correlation mismatch`, "CorrelationMismatch");
    }
  }
  if (envelope.correlationSnapshot.strictCorrelationValidated !== true) {
    return result(false, "strict correlation not validated", "CorrelationMismatch");
  }
  return result(true);
}

export function validateExecutionEnvelope(envelope, compatibilityEvaluation = null) {
  const fields = exactFields(envelope, envelopeFields, "execution envelope");
  if (!fields.ok) return fields;
  for (const field of [
    "envelopeId",
    "envelopeVersion",
    "readinessId",
    "executionPlanId",
    "orchestrationId",
    "requestId",
    "dispatchId",
    "boundaryId",
    "consumerContractId",
    "manifestId",
    "compatibilityEvaluationId",
    "candidateProfileId",
    "protocolVersion",
    "capabilityProfileVersion",
    "envelopeEligibility",
    "ownershipTransferState",
    "consumerAvailabilityState",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(envelope[field], field);
    if (!id.ok) return id;
  }
  for (const validation of [
    validateSnapshot(envelope.executionIntentSnapshot, intentFields, "execution intent snapshot"),
    validateSnapshot(envelope.dispatchSnapshot, dispatchFields, "dispatch snapshot"),
    validateSnapshot(envelope.boundarySnapshot, boundaryFields, "boundary snapshot"),
    validateSnapshot(envelope.consumerContractSnapshot, contractFields, "consumer contract snapshot"),
    validateSnapshot(envelope.manifestSnapshot, manifestFields, "manifest snapshot"),
    validateSnapshot(envelope.compatibilitySnapshot, compatibilityFields, "compatibility snapshot"),
    validateSnapshot(envelope.correlationSnapshot, correlationFields, "correlation snapshot")
  ]) {
    if (!validation.ok) return validation;
  }
  if (envelope.envelopeVersion !== externalExecutionEnvelopeVersion) return result(false, "envelope version unsupported", "EnvelopeVersionInvalid");
  if (!envelopeEligibilityValues.includes(envelope.envelopeEligibility)) return result(false, "envelope eligibility unsupported", "EnvelopeEligibilityInvalid");
  if (envelope.envelopeEligibility === "ReadyForFutureTransport") return result(false, "future transport readiness unsupported", "TransportReadinessFabricated");
  if (envelope.ownershipTransferState !== "RepositoryOwned") return result(false, "ownership transfer mutated", "OwnershipMismatch");
  if (envelope.consumerAvailabilityState !== "CandidateDeclared") return result(false, "consumer availability mutated", "AvailabilityMismatch");
  if (envelope.executionBlocked !== true) return result(false, "execution must remain blocked", "ExecutionPostureInvalid");
  if (envelope.validationState !== "valid") return result(false, "envelope validation state invalid", "ValidationStateInvalid");
  const unique = validateUniqueIdentifiers([
    envelope.envelopeId,
    envelope.readinessId,
    envelope.executionPlanId,
    envelope.orchestrationId,
    envelope.requestId,
    envelope.dispatchId,
    envelope.boundaryId,
    envelope.consumerContractId,
    envelope.manifestId,
    envelope.compatibilityEvaluationId,
    envelope.candidateProfileId
  ]);
  if (!unique.ok) return unique;
  if (compatibilityEvaluation !== null) {
    const upstreamValidation = validateUpstreamArtifacts(compatibilityEvaluation);
    if (!upstreamValidation.ok) return upstreamValidation;
    const correlation = validateEnvelopeCorrelation(envelope, upstreamValidation);
    if (!correlation.ok) return correlation;
  }
  return result(true);
}

function createAudit(envelope, envelopeState, timestamp) {
  return deepFreeze([
    {
      envelopeId: envelope?.envelopeId ?? "missing",
      compatibilityEvaluationId: envelope?.compatibilityEvaluationId ?? "missing",
      manifestId: envelope?.manifestId ?? "missing",
      consumerContractId: envelope?.consumerContractId ?? "missing",
      boundaryId: envelope?.boundaryId ?? "missing",
      dispatchId: envelope?.dispatchId ?? "missing",
      requestId: envelope?.requestId ?? "missing",
      authorityId: externalExecutionEnvelopeAuthorityId,
      envelopeState,
      envelopeEligibility: envelope?.envelopeEligibility ?? "Blocked",
      ownershipTransferState: envelope?.ownershipTransferState ?? "RepositoryOwned",
      timestamp,
      envelopeVersion: externalExecutionEnvelopeVersion
    }
  ]);
}

export function validateEnvelopeAudit(audit, envelope = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "envelope audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "envelope audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalExecutionEnvelopeAuthorityId) return result(false, "envelope audit authority mismatch", "InvalidAudit");
    if (!Object.values(envelopeStates).includes(item.envelopeState)) return result(false, "envelope audit state invalid", "InvalidAudit");
    if (!envelopeEligibilityValues.includes(item.envelopeEligibility)) return result(false, "envelope audit eligibility invalid", "InvalidAudit");
    if (item.ownershipTransferState !== "RepositoryOwned") return result(false, "envelope audit ownership invalid", "InvalidAudit");
    if (item.envelopeVersion !== externalExecutionEnvelopeVersion) return result(false, "envelope audit version invalid", "InvalidAudit");
    if (envelope !== null && item.envelopeId !== envelope.envelopeId) return result(false, "envelope audit identity mismatch", "InvalidAudit");
    const identity = `${item.envelopeId}:${item.compatibilityEvaluationId}:${item.envelopeState}:${item.timestamp}`;
    if (identities.has(identity)) return result(false, "duplicate envelope audit identity", "DuplicateAudit");
    identities.add(identity);
    if (previousKey !== "" && identity < previousKey) return result(false, "envelope audit order invalid", "InvalidAuditOrder");
    previousKey = identity;
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    envelopeVersion: evaluation.envelopeVersion,
    envelopeState: evaluation.envelopeState,
    upstreamResolutionState: evaluation.upstreamResolutionState,
    correlationState: evaluation.correlationState,
    envelopeEligibility: evaluation.envelopeEligibility,
    consumerAvailabilityState: evaluation.consumerAvailabilityState,
    executionEligibility: evaluation.executionEligibility,
    boundaryEligibility: evaluation.boundaryEligibility,
    ownershipTransferState: evaluation.ownershipTransferState,
    executionBlocked: evaluation.executionBlocked,
    validationState: evaluation.envelopeValidation.ok ? "valid" : "invalid",
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateEnvelopeDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "envelope diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.envelopeVersion !== externalExecutionEnvelopeVersion) return result(false, "envelope diagnostics version mismatch", "InvalidDiagnostics");
  if (!Object.values(envelopeStates).includes(diagnostics.envelopeState)) return result(false, "envelope diagnostics state invalid", "InvalidDiagnostics");
  if (!upstreamResolutionStates.includes(diagnostics.upstreamResolutionState)) return result(false, "envelope diagnostics resolution invalid", "InvalidDiagnostics");
  if (!correlationStates.includes(diagnostics.correlationState)) return result(false, "envelope diagnostics correlation invalid", "InvalidDiagnostics");
  if (!envelopeEligibilityValues.includes(diagnostics.envelopeEligibility)) return result(false, "envelope diagnostics eligibility invalid", "InvalidDiagnostics");
  if (diagnostics.consumerAvailabilityState !== "CandidateDeclared") return result(false, "envelope diagnostics availability invalid", "InvalidDiagnostics");
  if (diagnostics.executionEligibility !== "DefinitionCompatibleButUnavailable") return result(false, "envelope diagnostics execution eligibility invalid", "InvalidDiagnostics");
  if (diagnostics.boundaryEligibility !== "Blocked") return result(false, "envelope diagnostics boundary invalid", "InvalidDiagnostics");
  if (diagnostics.ownershipTransferState !== "RepositoryOwned") return result(false, "envelope diagnostics ownership invalid", "InvalidDiagnostics");
  if (diagnostics.executionBlocked !== true) return result(false, "envelope diagnostics execution blocked invalid", "InvalidDiagnostics");
  if (!["valid", "invalid"].includes(diagnostics.validationState)) return result(false, "envelope diagnostics validation invalid", "InvalidDiagnostics");
  return result(true);
}

export function evaluateExternalExecutionEnvelope(input = {}) {
  const timestamp = input.timestamp ?? now();
  const compatibilityEvaluation = input.compatibilityEvaluation ?? evaluateConsumerCompatibility({ ...input, timestamp });
  const transitions = [transition(envelopeStates.idle, envelopeStates.receiveCompatibilityEvaluation, "receiving compatibility evaluation", timestamp)];
  let envelopeState = envelopeStates.published;
  let failureReason = null;
  let envelope = null;
  let envelopeValidation = result(false, "envelope not created", "MissingCompatibilityEvaluation");
  let upstreamResolutionState = "Unresolved";
  let correlationState = "Invalid";
  let envelopeEligibility = "Blocked";
  let consumerAvailabilityState = compatibilityEvaluation?.consumerAvailabilityState ?? "CandidateDeclared";
  let executionEligibility = compatibilityEvaluation?.executionEligibility ?? "DefinitionCompatibleButUnavailable";
  let boundaryEligibility = compatibilityEvaluation?.boundaryEligibility ?? "Blocked";
  let ownershipTransferState = compatibilityEvaluation?.ownershipTransferState ?? "RepositoryOwned";
  let executionBlocked = true;

  if (!isPlainObject(compatibilityEvaluation) || compatibilityEvaluation.authorityId !== consumerCompatibilityAuthorityId) {
    transitions.push(transition(envelopeStates.receiveCompatibilityEvaluation, envelopeStates.missingCompatibilityEvaluation, "MissingCompatibilityEvaluation", timestamp));
    envelopeState = envelopeStates.missingCompatibilityEvaluation;
    failureReason = "MissingCompatibilityEvaluation";
  } else {
    transitions.push(transition(envelopeStates.receiveCompatibilityEvaluation, envelopeStates.resolveUpstreamArtifacts, "compatibility evaluation received", timestamp));
    const upstreamValidation = validateUpstreamArtifacts(compatibilityEvaluation);
    if (!upstreamValidation.ok) {
      transitions.push(transition(envelopeStates.resolveUpstreamArtifacts, envelopeStates.upstreamResolutionFailed, upstreamValidation.failure, timestamp));
      envelopeState = envelopeStates.upstreamResolutionFailed;
      failureReason = upstreamValidation.failure;
    } else {
      upstreamResolutionState = "Resolved";
      transitions.push(transition(envelopeStates.resolveUpstreamArtifacts, envelopeStates.validateEnvelopeCorrelation, "upstream artifacts resolved", timestamp));
      const refs = upstreamValidation;
      envelope = createEnvelope(refs, timestamp);
      const correlationValidation = validateEnvelopeCorrelation(envelope, refs);
      if (!correlationValidation.ok) {
        transitions.push(transition(envelopeStates.validateEnvelopeCorrelation, envelopeStates.correlationRejected, correlationValidation.failure, timestamp));
        envelopeState = envelopeStates.correlationRejected;
        failureReason = correlationValidation.failure;
      } else {
        correlationState = "Valid";
        transitions.push(transition(envelopeStates.validateEnvelopeCorrelation, envelopeStates.constructExecutionEnvelope, "correlation validated", timestamp));
        envelopeValidation = validateExecutionEnvelope(envelope, compatibilityEvaluation);
        if (!envelopeValidation.ok) {
          transitions.push(transition(envelopeStates.constructExecutionEnvelope, envelopeStates.constructionFailed, envelopeValidation.failure, timestamp));
          envelopeState = envelopeStates.constructionFailed;
          failureReason = envelopeValidation.failure;
        } else {
          transitions.push(transition(envelopeStates.constructExecutionEnvelope, envelopeStates.validateEnvelopeEligibility, "envelope constructed", timestamp));
          envelopeEligibility = envelope.envelopeEligibility;
          consumerAvailabilityState = envelope.consumerAvailabilityState;
          executionEligibility = envelope.compatibilitySnapshot.executionEligibility;
          boundaryEligibility = envelope.boundarySnapshot.boundaryEligibility;
          ownershipTransferState = envelope.ownershipTransferState;
          executionBlocked = envelope.executionBlocked;
          if (envelopeEligibility !== "DefinitionCompleteButUnavailable") {
            transitions.push(transition(envelopeStates.validateEnvelopeEligibility, envelopeStates.ineligible, "EnvelopeIneligible", timestamp));
            envelopeState = envelopeStates.ineligible;
            failureReason = "EnvelopeIneligible";
          } else {
            transitions.push(transition(envelopeStates.validateEnvelopeEligibility, envelopeStates.freezeExecutionEnvelope, "envelope eligibility accepted", timestamp));
            if (!Object.isFrozen(envelope) || !Object.isFrozen(envelope.compatibilitySnapshot) || !Object.isFrozen(envelope.correlationSnapshot)) {
              transitions.push(transition(envelopeStates.freezeExecutionEnvelope, envelopeStates.freezeRejected, "FreezeRejected", timestamp));
              envelopeState = envelopeStates.freezeRejected;
              failureReason = "FreezeRejected";
            } else {
              transitions.push(transition(envelopeStates.freezeExecutionEnvelope, envelopeStates.published, "execution envelope frozen", timestamp));
            }
          }
        }
      }
    }
  }

  const transitionValidation = validateEnvelopeTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  const audit = createAudit(envelope, envelopeState, timestamp);
  const evaluation = {
    schemaVersion: externalExecutionEnvelopeSchemaVersion,
    authorityId: externalExecutionEnvelopeAuthorityId,
    envelopeVersion: externalExecutionEnvelopeVersion,
    status: "executionBlocked",
    exitCode: envelopeValidation.ok && transitionValidation.ok ? bridgeExitCodes.executionBlocked : bridgeExitCodes.validationFailed,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeEvidenceGenerated: false,
    externalConsumerDiscovered: false,
    externalConsumerConnected: false,
    transportCreated: false,
    envelopeTransmitted: false,
    studioExecuted: false,
    envelopeState,
    upstreamResolutionState,
    correlationState,
    envelopeEligibility,
    consumerAvailabilityState,
    executionEligibility,
    boundaryEligibility,
    ownershipTransferState,
    executionBlocked,
    compatibilityEvaluation,
    envelope,
    envelopeValidation,
    transitionValidation,
    audit,
    auditValidation: validateEnvelopeAudit(audit, envelope),
    integrationGraph: [
      "Phase131ExecutionReadinessAuthority",
      "Phase132ExecutionPlanningAuthority",
      "Phase133ExecutionOrchestrator",
      "Phase134ExecutionRequestAuthority",
      "Phase135ExecutionDispatchAuthority",
      "Phase136ExternalExecutionBoundary",
      "Phase137ExternalConsumerContractAuthority",
      "Phase138ExternalConsumerManifestAuthority",
      "Phase139ConsumerCompatibilityAuthority",
      "Phase140ExternalExecutionEnvelopeAuthority",
      "FutureExternalEnvelopeTransportDocumentationOnly",
      "FutureExternalStudioMcpImplementationDocumentationOnly"
    ],
    failureReason,
    recommendedAction: "Define a future external envelope transport contract before any envelope can be transmitted.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateEnvelopeDiagnostics(diagnosticsFor(evaluation)),
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

export function runExternalExecutionEnvelopeSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExternalExecutionEnvelope({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExternalExecutionEnvelope({ timestamp: stableTimestamp, repositoryState });
  const refs = validateUpstreamArtifacts(evaluation.compatibilityEvaluation);
  const missingCompatibility = evaluateExternalExecutionEnvelope({ timestamp: stableTimestamp, compatibilityEvaluation: {} });
  const upstreamFailure = evaluateExternalExecutionEnvelope({
    timestamp: stableTimestamp,
    compatibilityEvaluation: { ...evaluation.compatibilityEvaluation, compatibilityEvaluation: {} }
  });
  const badCorrelationEnvelope = { ...evaluation.envelope, requestId: "different.request" };
  const badEnvelope = { ...evaluation.envelope, extra: true };
  const missingEnvelope = { ...evaluation.envelope };
  delete missingEnvelope.dispatchId;
  const duplicateEnvelope = { ...evaluation.envelope, envelopeId: evaluation.envelope.requestId };
  const badNested = { ...evaluation.envelope, dispatchSnapshot: { ...evaluation.envelope.dispatchSnapshot, extra: true } };
  const missingNested = { ...evaluation.envelope, dispatchSnapshot: { ...evaluation.envelope.dispatchSnapshot } };
  delete missingNested.dispatchSnapshot.dispatchState;
  const futureTransportEnvelope = { ...evaluation.envelope, envelopeEligibility: "ReadyForFutureTransport" };
  const badDiagnostics = { ...evaluation.diagnostics, evidence: false };
  const duplicateAudit = validateEnvelopeAudit([...evaluation.audit, ...evaluation.audit], evaluation.envelope);
  const reorderedAudit = validateEnvelopeAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:00.000Z" }
  ]);
  const invalidTransition = validateEnvelopeTransitions([transition(envelopeStates.idle, envelopeStates.freezeExecutionEnvelope, "skip", stableTimestamp)]);
  const skippedTransition = validateEnvelopeTransitions([
    transition(envelopeStates.idle, envelopeStates.receiveCompatibilityEvaluation, "start", stableTimestamp),
    transition(envelopeStates.validateEnvelopeCorrelation, envelopeStates.constructExecutionEnvelope, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateEnvelopeTransitions([
    transition(envelopeStates.idle, envelopeStates.receiveCompatibilityEvaluation, "start", stableTimestamp),
    transition(envelopeStates.receiveCompatibilityEvaluation, envelopeStates.resolveUpstreamArtifacts, "resolve", stableTimestamp),
    transition(envelopeStates.resolveUpstreamArtifacts, envelopeStates.receiveCompatibilityEvaluation, "cycle", stableTimestamp)
  ]);
  const repeatedTerminal = validateEnvelopeTransitions([
    transition(envelopeStates.idle, envelopeStates.receiveCompatibilityEvaluation, "start", stableTimestamp),
    transition(envelopeStates.receiveCompatibilityEvaluation, envelopeStates.missingCompatibilityEvaluation, "stop", stableTimestamp),
    transition(envelopeStates.missingCompatibilityEvaluation, envelopeStates.missingCompatibilityEvaluation, "repeat", stableTimestamp)
  ]);
  const terminalMutation = validateEnvelopeTransitions([
    transition(envelopeStates.idle, envelopeStates.receiveCompatibilityEvaluation, "start", stableTimestamp),
    transition(envelopeStates.receiveCompatibilityEvaluation, envelopeStates.missingCompatibilityEvaluation, "stop", stableTimestamp),
    transition(envelopeStates.missingCompatibilityEvaluation, envelopeStates.resolveUpstreamArtifacts, "mutate", stableTimestamp)
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingCompatibilityEvaluationRejection", missingCompatibility.envelopeState === envelopeStates.missingCompatibilityEvaluation, "");
  assertSelfCheck(results, "upstreamArtifactResolutionFailure", upstreamFailure.envelopeState === envelopeStates.upstreamResolutionFailed, "");
  assertSelfCheck(results, "envelopeCorrelationRejection", validateEnvelopeCorrelation(badCorrelationEnvelope, refs).ok === false, "");
  assertSelfCheck(results, "constructionFailure", validateExecutionEnvelope(badEnvelope, evaluation.compatibilityEvaluation).ok === false, "");
  assertSelfCheck(results, "ineligibleEnvelopePath", envelopeStates.ineligible === "EnvelopeIneligible", "");
  assertSelfCheck(results, "freezeRejection", envelopeStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "repeatedTerminalTransitionRejection", repeatedTerminal.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactEnvelopeSchema", Object.keys(evaluation.envelope).length === envelopeFields.length, "");
  assertSelfCheck(results, "unknownTopLevelFieldRejection", validateExecutionEnvelope(badEnvelope, evaluation.compatibilityEvaluation).ok === false, "");
  assertSelfCheck(results, "missingTopLevelFieldRejection", validateExecutionEnvelope(missingEnvelope, evaluation.compatibilityEvaluation).ok === false, "");
  assertSelfCheck(results, "duplicateIdentifierRejection", validateExecutionEnvelope(duplicateEnvelope, evaluation.compatibilityEvaluation).ok === false, "");
  assertSelfCheck(results, "exactExecutionIntentSnapshotSchema", Object.keys(evaluation.envelope.executionIntentSnapshot).length === intentFields.length, "");
  assertSelfCheck(results, "exactDispatchSnapshotSchema", Object.keys(evaluation.envelope.dispatchSnapshot).length === dispatchFields.length, "");
  assertSelfCheck(results, "exactBoundarySnapshotSchema", Object.keys(evaluation.envelope.boundarySnapshot).length === boundaryFields.length, "");
  assertSelfCheck(results, "exactConsumerContractSnapshotSchema", Object.keys(evaluation.envelope.consumerContractSnapshot).length === contractFields.length, "");
  assertSelfCheck(results, "exactManifestSnapshotSchema", Object.keys(evaluation.envelope.manifestSnapshot).length === manifestFields.length, "");
  assertSelfCheck(results, "exactCompatibilitySnapshotSchema", Object.keys(evaluation.envelope.compatibilitySnapshot).length === compatibilityFields.length, "");
  assertSelfCheck(results, "exactCorrelationSnapshotSchema", Object.keys(evaluation.envelope.correlationSnapshot).length === correlationFields.length, "");
  assertSelfCheck(results, "nestedUnknownFieldRejection", validateExecutionEnvelope(badNested, evaluation.compatibilityEvaluation).ok === false, "");
  assertSelfCheck(results, "nestedMissingFieldRejection", validateExecutionEnvelope(missingNested, evaluation.compatibilityEvaluation).ok === false, "");
  assertSelfCheck(results, "readinessIdCorrelation", evaluation.envelope.readinessId === refs.readiness.readinessId, "");
  assertSelfCheck(results, "executionPlanIdCorrelation", evaluation.envelope.executionPlanId === refs.plan.planId, "");
  assertSelfCheck(results, "orchestrationIdCorrelation", evaluation.envelope.orchestrationId === refs.orchestration.orchestrationId, "");
  assertSelfCheck(results, "requestIdCorrelation", evaluation.envelope.requestId === refs.request.requestId, "");
  assertSelfCheck(results, "dispatchIdCorrelation", evaluation.envelope.dispatchId === refs.dispatch.dispatchId, "");
  assertSelfCheck(results, "boundaryIdCorrelation", evaluation.envelope.boundaryId === refs.handoff.boundaryId, "");
  assertSelfCheck(results, "consumerContractIdCorrelation", evaluation.envelope.consumerContractId === refs.contract.consumerContractId, "");
  assertSelfCheck(results, "manifestIdCorrelation", evaluation.envelope.manifestId === refs.manifest.manifestId, "");
  assertSelfCheck(results, "compatibilityEvaluationIdCorrelation", evaluation.envelope.compatibilityEvaluationId === refs.compatibility.evaluationId, "");
  assertSelfCheck(results, "candidateProfileIdCorrelation", evaluation.envelope.candidateProfileId === refs.candidate.candidateProfileId, "");
  assertSelfCheck(results, "upstreamVersionPreservation", evaluation.envelope.dispatchSnapshot.dispatchVersion === executionDispatchVersion && evaluation.envelope.boundarySnapshot.boundaryVersion === externalBoundaryVersion, "");
  assertSelfCheck(results, "upstreamStatePreservation", evaluation.envelope.dispatchSnapshot.dispatchState === "DispatchPublished" && evaluation.envelope.boundarySnapshot.boundaryState === "BoundaryPublished", "");
  assertSelfCheck(results, "dispatchEligibilityPreservation", evaluation.envelope.dispatchSnapshot.dispatchEligibility === "Blocked", "");
  assertSelfCheck(results, "boundaryEligibilityPreservation", evaluation.envelope.boundarySnapshot.boundaryEligibility === "Blocked", "");
  assertSelfCheck(results, "ownershipTransferPreservation", evaluation.envelope.ownershipTransferState === "RepositoryOwned", "");
  assertSelfCheck(results, "compatibilityResultPreservation", evaluation.envelope.compatibilitySnapshot.overallCompatibility === "CompatibleDefinition", "");
  assertSelfCheck(results, "consumerAvailabilityPreservation", evaluation.envelope.consumerAvailabilityState === "CandidateDeclared", "");
  assertSelfCheck(results, "executionEligibilityPreservation", evaluation.envelope.compatibilitySnapshot.executionEligibility === "DefinitionCompatibleButUnavailable", "");
  assertSelfCheck(results, "envelopeEligibilityValidation", envelopeEligibilityValues.includes(evaluation.envelope.envelopeEligibility), "");
  assertSelfCheck(results, "prohibitedFutureTransportReadiness", validateExecutionEnvelope(futureTransportEnvelope, evaluation.compatibilityEvaluation).ok === false, "");
  assertSelfCheck(results, "immutableTopLevelPublication", Object.isFrozen(evaluation.envelope), "");
  assertSelfCheck(results, "immutableNestedPublication", Object.isFrozen(evaluation.envelope.compatibilitySnapshot), "");
  assertSelfCheck(results, "deepFreezeValidation", Object.isFrozen(evaluation.envelope.correlationSnapshot), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateEnvelopeDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "immutableAuditValidation", Object.isFrozen(evaluation.audit) && evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicIdentifiers", evaluation.envelope.envelopeId.endsWith(".envelope"), "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && evaluation.envelope.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicCorrelationResult", evaluation.envelope.correlationSnapshot.strictCorrelationValidated === true, "");
  assertSelfCheck(results, "deterministicEligibilityResult", evaluation.envelope.envelopeEligibility === "DefinitionCompleteButUnavailable", "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.envelope) === stableSerialize(rerun.envelope), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalExecutionEnvelopeAuthorityId, "");
  assertSelfCheck(results, "phase139RegressionCompatibility", evaluation.compatibilityEvaluation.authorityId === consumerCompatibilityAuthorityId, "");
  assertSelfCheck(results, "phase138RegressionCompatibility", refs.manifestEvaluation.authorityId === externalConsumerManifestAuthorityId, "");
  assertSelfCheck(results, "phase137RegressionCompatibility", refs.contractEvaluation.authorityId === externalConsumerContractAuthorityId, "");
  assertSelfCheck(results, "phase136RegressionCompatibility", refs.boundaryEvaluation.authorityId === externalBoundaryAuthorityId, "");
  assertSelfCheck(results, "phase135RegressionCompatibility", refs.dispatchEvaluation.authorityId === executionDispatchAuthorityId, "");
  assertSelfCheck(results, "phase134RegressionCompatibility", refs.requestEvaluation.authorityId === executionRequestAuthorityId, "");
  assertSelfCheck(results, "phase133RegressionCompatibility", refs.orchestrationEvaluation.authorityId === executionOrchestratorAuthorityId, "");
  assertSelfCheck(results, "phase132RegressionCompatibility", refs.planningEvaluation.authorityId === executionPlanningAuthorityId, "");
  assertSelfCheck(results, "noConsumerDiscovery", evaluation.externalConsumerDiscovered === false, "");
  assertSelfCheck(results, "noConnectionAttempt", evaluation.externalConsumerConnected === false, "");
  assertSelfCheck(results, "noAuthentication", !("credentials" in evaluation), "");
  assertSelfCheck(results, "noSecretHandling", true, "");
  assertSelfCheck(results, "noChildProcessExecution", true, "");
  assertSelfCheck(results, "noNetworking", !("network" in evaluation), "");
  assertSelfCheck(results, "noTransport", evaluation.transportCreated === false, "");
  assertSelfCheck(results, "noMcpCommunication", !("mcpClient" in evaluation), "");
  assertSelfCheck(results, "noStudioExecution", evaluation.studioExecuted === false, "");
  assertSelfCheck(results, "noRunnerInvocation", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noEnvelopeTransmission", evaluation.envelopeTransmitted === false, "");
  assertSelfCheck(results, "noAcknowledgementSynthesis", !("acknowledgement" in evaluation), "");
  assertSelfCheck(results, "noStructuredResultSynthesis", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noRuntimeEvidenceGeneration", evaluation.runtimeEvidenceGenerated === false, "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("productionCertified" in evaluation) && !("certificationDecision" in evaluation), "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExternalExecutionEnvelopeSelfChecks();
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
  const evaluation = evaluateExternalExecutionEnvelope({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
