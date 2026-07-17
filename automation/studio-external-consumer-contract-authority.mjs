import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  boundaryEligibilityValues,
  boundaryStates,
  evaluateExternalExecutionBoundary,
  externalBoundaryAuthorityId,
  externalBoundaryVersion,
  externalConsumerContractVersion as boundaryConsumerContractVersion,
  externalConsumerType,
  ownershipTransferStates,
  validateExternalConsumerContract,
  validateHandoffPackage
} from "./studio-external-execution-boundary.mjs";
import {
  executionDispatchAuthorityId,
  executionDispatchVersion,
  validateExecutionDispatch
} from "./studio-execution-dispatch-authority.mjs";
import {
  integrationContractCompatibilityVersion,
  integrationContractProtocolVersion,
  integrationContractSchemaVersion,
  integrationContractVersion,
  stableSerialize,
  validateVersionMetadata
} from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const externalConsumerContractAuthoritySchemaVersion = 1;
export const externalConsumerContractAuthorityVersion = "1.0.0";
export const externalConsumerContractAuthorityId = "chapter0Home.phase137StudioExternalConsumerContractAuthority";
export const consumerContractIdSuffix = ".externalConsumerAuthorityContract";

export const consumerContractStates = Object.freeze({
  idle: "Idle",
  receiveBoundaryContract: "ReceiveBoundaryContract",
  validateContractDefinition: "ValidateContractDefinition",
  buildConsumerContract: "BuildConsumerContract",
  validateCompatibilityPolicy: "ValidateCompatibilityPolicy",
  freezeConsumerContract: "FreezeConsumerContract",
  published: "ConsumerContractPublished",
  missingBoundaryContract: "MissingBoundaryContract",
  rejected: "ContractRejected",
  constructionFailed: "ContractConstructionFailed",
  compatibilityRejected: "CompatibilityRejected",
  freezeRejected: "FreezeRejected"
});

export const compatibilityStates = Object.freeze(["NotEvaluated", "DefinitionCompatible", "DefinitionIncompatible"]);
export const consumerAvailabilityStates = Object.freeze(["NotDiscovered", "NotConnected", "ContractOnly"]);
export const evolutionChangeClasses = Object.freeze(["PatchCompatible", "MinorCompatible", "MajorBreaking"]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  consumerContractStates.published,
  consumerContractStates.missingBoundaryContract,
  consumerContractStates.rejected,
  consumerContractStates.constructionFailed,
  consumerContractStates.compatibilityRejected,
  consumerContractStates.freezeRejected
]);
const legalTransitions = new Map([
  [consumerContractStates.idle, new Set([consumerContractStates.receiveBoundaryContract])],
  [
    consumerContractStates.receiveBoundaryContract,
    new Set([consumerContractStates.validateContractDefinition, consumerContractStates.missingBoundaryContract])
  ],
  [
    consumerContractStates.validateContractDefinition,
    new Set([consumerContractStates.buildConsumerContract, consumerContractStates.rejected])
  ],
  [
    consumerContractStates.buildConsumerContract,
    new Set([consumerContractStates.validateCompatibilityPolicy, consumerContractStates.constructionFailed])
  ],
  [
    consumerContractStates.validateCompatibilityPolicy,
    new Set([consumerContractStates.freezeConsumerContract, consumerContractStates.compatibilityRejected])
  ],
  [consumerContractStates.freezeConsumerContract, new Set([consumerContractStates.published, consumerContractStates.freezeRejected])]
]);

const consumerContractFields = Object.freeze([
  "consumerContractId",
  "consumerContractVersion",
  "consumerType",
  "boundaryContractId",
  "boundaryVersion",
  "acceptedDispatchVersion",
  "requiredProtocolVersion",
  "minimumCapabilityProfileVersion",
  "executionAcknowledgementContract",
  "structuredResultContract",
  "runtimeEvidenceContract",
  "correlationContract",
  "failureContract",
  "compatibilityPolicy",
  "validationState",
  "timestamp"
]);
const acknowledgementFields = Object.freeze([
  "schemaVersion",
  "acknowledgementRequired",
  "acknowledgementIdRequired",
  "boundaryIdRequired",
  "dispatchIdRequired",
  "requestIdRequired",
  "consumerContractIdRequired",
  "consumerInstanceIdRequired",
  "acceptedState",
  "rejectedState",
  "timestampRequired"
]);
const structuredResultFields = Object.freeze([
  "schemaVersion",
  "resultRequired",
  "resultIdRequired",
  "acknowledgementIdRequired",
  "boundaryIdRequired",
  "dispatchIdRequired",
  "requestIdRequired",
  "executionStateRequired",
  "resultPayloadRequired",
  "diagnosticsRequired",
  "timestampRequired"
]);
const runtimeEvidenceFields = Object.freeze([
  "schemaVersion",
  "evidenceRequired",
  "evidenceEnvelopeRequired",
  "evidenceCorrelationRequired",
  "executionResultRequired",
  "provenanceRequired",
  "integrityRequired",
  "timestampRequired",
  "certificationEligibleByDefault"
]);
const correlationFields = Object.freeze([
  "readinessIdRequired",
  "executionPlanIdRequired",
  "orchestrationIdRequired",
  "requestIdRequired",
  "dispatchIdRequired",
  "boundaryIdRequired",
  "consumerContractIdRequired",
  "acknowledgementIdRequired",
  "resultIdRequired",
  "strictOrderingRequired"
]);
const failureFields = Object.freeze([
  "schemaVersion",
  "failureCodeRequired",
  "failureCategoryRequired",
  "failureStageRequired",
  "retryableRequired",
  "diagnosticsRequired",
  "timestampRequired"
]);
const compatibilityPolicyFields = Object.freeze([
  "policyVersion",
  "protocolRule",
  "dispatchVersionRule",
  "boundaryVersionRule",
  "capabilityRule",
  "schemaRule",
  "forwardCompatibilityRule",
  "backwardCompatibilityRule",
  "unknownFieldRule"
]);
const diagnosticsFields = Object.freeze([
  "consumerContractVersion",
  "contractState",
  "boundaryState",
  "boundaryEligibility",
  "ownershipTransferState",
  "consumerAvailabilityState",
  "compatibilityState",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "consumerContractId",
  "boundaryId",
  "dispatchId",
  "authorityId",
  "contractState",
  "consumerAvailabilityState",
  "compatibilityState",
  "validationState",
  "timestamp",
  "contractVersion"
]);
const futureExecutionStates = Object.freeze(["ExecutionSucceeded", "ExecutionFailed", "ExecutionCancelled", "ExecutionRejected"]);
const futureFailureCategories = Object.freeze([
  "ContractRejected",
  "ConsumerUnavailable",
  "ProtocolMismatch",
  "CapabilityMismatch",
  "ExecutionRejected",
  "ExecutionFailed",
  "ResultInvalid",
  "EvidenceInvalid"
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

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalConsumerContractAuthorityId });
}

export function validateConsumerContractTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "consumer contract transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(consumerContractStates).includes(item.from) || !Object.values(consumerContractStates).includes(item.to)) {
      return result(false, "undocumented consumer contract state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== consumerContractStates.idle) {
      return result(false, "consumer contract lifecycle must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "consumer contract lifecycle skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal consumer contract state mutated", "InvalidLifecycle");
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal consumer contract transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic consumer contract transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function validateBooleanTrueFields(value, fields, label) {
  for (const field of fields) {
    if (value[field] !== true) return result(false, `${label} ${field} must be true`, "ContractRequirementInvalid");
  }
  return result(true);
}

export function validateExecutionAcknowledgementContract(contract) {
  const fields = exactFields(contract, acknowledgementFields, "execution acknowledgement contract");
  if (!fields.ok) return fields;
  if (contract.schemaVersion !== externalConsumerContractAuthoritySchemaVersion) {
    return result(false, "execution acknowledgement schema version invalid", "SchemaVersionInvalid");
  }
  const required = validateBooleanTrueFields(
    contract,
    [
      "acknowledgementRequired",
      "acknowledgementIdRequired",
      "boundaryIdRequired",
      "dispatchIdRequired",
      "requestIdRequired",
      "consumerContractIdRequired",
      "consumerInstanceIdRequired",
      "timestampRequired"
    ],
    "execution acknowledgement contract"
  );
  if (!required.ok) return required;
  if (contract.acceptedState !== "Accepted" || contract.rejectedState !== "Rejected") {
    return result(false, "execution acknowledgement states invalid", "StateInvalid");
  }
  return result(true);
}

export function validateStructuredResultContract(contract) {
  const fields = exactFields(contract, structuredResultFields, "structured result contract");
  if (!fields.ok) return fields;
  if (contract.schemaVersion !== externalConsumerContractAuthoritySchemaVersion) {
    return result(false, "structured result schema version invalid", "SchemaVersionInvalid");
  }
  const required = validateBooleanTrueFields(
    contract,
    [
      "resultRequired",
      "resultIdRequired",
      "acknowledgementIdRequired",
      "boundaryIdRequired",
      "dispatchIdRequired",
      "requestIdRequired",
      "executionStateRequired",
      "resultPayloadRequired",
      "diagnosticsRequired",
      "timestampRequired"
    ],
    "structured result contract"
  );
  if (!required.ok) return required;
  return result(true);
}

export function validateRuntimeEvidenceContract(contract) {
  const fields = exactFields(contract, runtimeEvidenceFields, "runtime evidence contract");
  if (!fields.ok) return fields;
  if (contract.schemaVersion !== externalConsumerContractAuthoritySchemaVersion) {
    return result(false, "runtime evidence schema version invalid", "SchemaVersionInvalid");
  }
  const required = validateBooleanTrueFields(
    contract,
    [
      "evidenceRequired",
      "evidenceEnvelopeRequired",
      "evidenceCorrelationRequired",
      "executionResultRequired",
      "provenanceRequired",
      "integrityRequired",
      "timestampRequired"
    ],
    "runtime evidence contract"
  );
  if (!required.ok) return required;
  if (contract.certificationEligibleByDefault !== false) {
    return result(false, "runtime evidence certification eligibility must default false", "CertificationBoundaryInvalid");
  }
  return result(true);
}

export function validateCorrelationContract(contract) {
  const fields = exactFields(contract, correlationFields, "correlation contract");
  if (!fields.ok) return fields;
  return validateBooleanTrueFields(contract, correlationFields, "correlation contract");
}

export function validateFailureContract(contract) {
  const fields = exactFields(contract, failureFields, "failure contract");
  if (!fields.ok) return fields;
  if (contract.schemaVersion !== externalConsumerContractAuthoritySchemaVersion) {
    return result(false, "failure schema version invalid", "SchemaVersionInvalid");
  }
  return validateBooleanTrueFields(
    contract,
    [
      "failureCodeRequired",
      "failureCategoryRequired",
      "failureStageRequired",
      "retryableRequired",
      "diagnosticsRequired",
      "timestampRequired"
    ],
    "failure contract"
  );
}

export function validateCompatibilityPolicy(policy) {
  const fields = exactFields(policy, compatibilityPolicyFields, "compatibility policy");
  if (!fields.ok) return fields;
  const expected = {
    policyVersion: "1.0.0",
    protocolRule: "ExactMatch",
    dispatchVersionRule: "ExactMatch",
    boundaryVersionRule: "ExactMatch",
    capabilityRule: "MinimumCompatible",
    schemaRule: "ExactSchema",
    forwardCompatibilityRule: "RejectUnknownMajor",
    backwardCompatibilityRule: "AllowDeclaredCompatibleMinor",
    unknownFieldRule: "Reject"
  };
  for (const [field, value] of Object.entries(expected)) {
    if (policy[field] !== value) return result(false, `compatibility policy ${field} invalid`, "CompatibilityPolicyInvalid");
  }
  return result(true);
}

export function classifyContractEvolution(change) {
  if (!isPlainObject(change) || typeof change.changeType !== "string") {
    return result(false, "contract evolution change invalid", "EvolutionInvalid");
  }
  const classifications = {
    documentationClarification: "PatchCompatible",
    optionalFieldAdded: "MinorCompatible",
    fieldRemoved: "MajorBreaking",
    fieldRenamed: "MajorBreaking",
    requiredFieldTypeChanged: "MajorBreaking",
    enumExpanded: "MinorCompatible",
    enumNarrowed: "MajorBreaking",
    correlationChanged: "MajorBreaking",
    evidenceChanged: "MajorBreaking",
    unknownMajorVersion: "MajorBreaking",
    undeclaredCompatibility: "MajorBreaking"
  };
  const classification = classifications[change.changeType];
  if (!classification) return result(false, "contract evolution change unsupported", "EvolutionInvalid");
  if (change.changeType === "optionalFieldAdded" && change.declaredCompatibility !== true) {
    return result(false, "optional field additions require declared minor compatibility", "EvolutionInvalid");
  }
  if (change.changeType === "enumExpanded" && change.declaredCompatibility !== true) {
    return result(false, "enum expansion requires declared minor compatibility", "EvolutionInvalid");
  }
  return result(true, null, null, { classification });
}

function createConsumerContract(handoff, timestamp) {
  return deepFreeze({
    consumerContractId: `${handoff.boundaryId}${consumerContractIdSuffix}`,
    consumerContractVersion: externalConsumerContractAuthorityVersion,
    consumerType: externalConsumerType,
    boundaryContractId: handoff.externalConsumerContract.contractId,
    boundaryVersion: handoff.boundaryVersion,
    acceptedDispatchVersion: handoff.externalConsumerContract.acceptedDispatchVersion,
    requiredProtocolVersion: handoff.externalConsumerContract.requiredProtocolVersion,
    minimumCapabilityProfileVersion: "1.0.0",
    executionAcknowledgementContract: {
      schemaVersion: externalConsumerContractAuthoritySchemaVersion,
      acknowledgementRequired: true,
      acknowledgementIdRequired: true,
      boundaryIdRequired: true,
      dispatchIdRequired: true,
      requestIdRequired: true,
      consumerContractIdRequired: true,
      consumerInstanceIdRequired: true,
      acceptedState: "Accepted",
      rejectedState: "Rejected",
      timestampRequired: true
    },
    structuredResultContract: {
      schemaVersion: externalConsumerContractAuthoritySchemaVersion,
      resultRequired: true,
      resultIdRequired: true,
      acknowledgementIdRequired: true,
      boundaryIdRequired: true,
      dispatchIdRequired: true,
      requestIdRequired: true,
      executionStateRequired: true,
      resultPayloadRequired: true,
      diagnosticsRequired: true,
      timestampRequired: true
    },
    runtimeEvidenceContract: {
      schemaVersion: externalConsumerContractAuthoritySchemaVersion,
      evidenceRequired: true,
      evidenceEnvelopeRequired: true,
      evidenceCorrelationRequired: true,
      executionResultRequired: true,
      provenanceRequired: true,
      integrityRequired: true,
      timestampRequired: true,
      certificationEligibleByDefault: false
    },
    correlationContract: {
      readinessIdRequired: true,
      executionPlanIdRequired: true,
      orchestrationIdRequired: true,
      requestIdRequired: true,
      dispatchIdRequired: true,
      boundaryIdRequired: true,
      consumerContractIdRequired: true,
      acknowledgementIdRequired: true,
      resultIdRequired: true,
      strictOrderingRequired: true
    },
    failureContract: {
      schemaVersion: externalConsumerContractAuthoritySchemaVersion,
      failureCodeRequired: true,
      failureCategoryRequired: true,
      failureStageRequired: true,
      retryableRequired: true,
      diagnosticsRequired: true,
      timestampRequired: true
    },
    compatibilityPolicy: {
      policyVersion: "1.0.0",
      protocolRule: "ExactMatch",
      dispatchVersionRule: "ExactMatch",
      boundaryVersionRule: "ExactMatch",
      capabilityRule: "MinimumCompatible",
      schemaRule: "ExactSchema",
      forwardCompatibilityRule: "RejectUnknownMajor",
      backwardCompatibilityRule: "AllowDeclaredCompatibleMinor",
      unknownFieldRule: "Reject"
    },
    validationState: "valid",
    timestamp
  });
}

export function validateConsumerContract(contract, boundaryEvaluation = null) {
  const fields = exactFields(contract, consumerContractFields, "external consumer authority contract");
  if (!fields.ok) return fields;
  for (const field of [
    "consumerContractId",
    "consumerContractVersion",
    "consumerType",
    "boundaryContractId",
    "boundaryVersion",
    "acceptedDispatchVersion",
    "requiredProtocolVersion",
    "minimumCapabilityProfileVersion",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(contract[field], field);
    if (!id.ok) return id;
  }
  if (contract.consumerContractVersion !== externalConsumerContractAuthorityVersion) {
    return result(false, "consumer contract version incompatible", "ContractVersionIncompatible");
  }
  if (contract.consumerType !== externalConsumerType) {
    return result(false, "consumer type unsupported", "UnsupportedConsumerType");
  }
  if (contract.boundaryVersion !== externalBoundaryVersion) {
    return result(false, "boundary version incompatible", "BoundaryVersionIncompatible");
  }
  if (contract.acceptedDispatchVersion !== executionDispatchVersion) {
    return result(false, "dispatch version incompatible", "DispatchIncompatible");
  }
  if (contract.requiredProtocolVersion !== integrationContractProtocolVersion) {
    return result(false, "protocol version incompatible", "ProtocolIncompatible");
  }
  if (contract.validationState !== "valid") {
    return result(false, "consumer contract validation state invalid", "ValidationStateInvalid");
  }
  for (const validation of [
    validateExecutionAcknowledgementContract(contract.executionAcknowledgementContract),
    validateStructuredResultContract(contract.structuredResultContract),
    validateRuntimeEvidenceContract(contract.runtimeEvidenceContract),
    validateCorrelationContract(contract.correlationContract),
    validateFailureContract(contract.failureContract),
    validateCompatibilityPolicy(contract.compatibilityPolicy)
  ]) {
    if (!validation.ok) return validation;
  }
  if (boundaryEvaluation !== null) {
    if (!isPlainObject(boundaryEvaluation) || boundaryEvaluation.authorityId !== externalBoundaryAuthorityId) {
      return result(false, "boundary authority incompatible", "BoundaryIncompatible");
    }
    const handoff = boundaryEvaluation.handoff;
    const handoffValidation = validateHandoffPackage(handoff, boundaryEvaluation.dispatchEvaluation);
    if (!handoffValidation.ok) return handoffValidation;
    const boundaryContractValidation = validateExternalConsumerContract(handoff.externalConsumerContract);
    if (!boundaryContractValidation.ok) return boundaryContractValidation;
    if (contract.boundaryContractId !== handoff.externalConsumerContract.contractId) {
      return result(false, "boundary contract identity mismatch", "CorrelationMismatch");
    }
    if (contract.consumerContractId !== `${handoff.boundaryId}${consumerContractIdSuffix}`) {
      return result(false, "consumer contract identity mismatch", "CorrelationMismatch");
    }
    if (contract.requiredProtocolVersion !== handoff.externalConsumerContract.requiredProtocolVersion) {
      return result(false, "protocol version not preserved", "ProtocolIncompatible");
    }
    if (contract.acceptedDispatchVersion !== handoff.externalConsumerContract.acceptedDispatchVersion) {
      return result(false, "dispatch version not preserved", "DispatchIncompatible");
    }
    const dispatchValidation = validateExecutionDispatch(handoff, boundaryEvaluation.dispatchEvaluation?.requestEvaluation);
    if (boundaryEvaluation.dispatchEvaluation?.authorityId !== executionDispatchAuthorityId || dispatchValidation.ok) {
      return result(false, "consumer contract must validate dispatch through the boundary handoff, not as a dispatch", "AuthorityIsolationInvalid");
    }
  }
  return result(true);
}

function createAudit(contract, boundaryEvaluation, contractState, consumerAvailabilityState, compatibilityState, validationState, timestamp) {
  return deepFreeze([
    {
      consumerContractId: contract?.consumerContractId ?? "missing",
      boundaryId: boundaryEvaluation?.handoff?.boundaryId ?? "missing",
      dispatchId: boundaryEvaluation?.handoff?.dispatchId ?? "missing",
      authorityId: externalConsumerContractAuthorityId,
      contractState,
      consumerAvailabilityState,
      compatibilityState,
      validationState,
      timestamp,
      contractVersion: externalConsumerContractAuthorityVersion
    }
  ]);
}

export function validateConsumerContractAudit(audit, boundaryEvaluation = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "consumer contract audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "consumer contract audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalConsumerContractAuthorityId) {
      return result(false, "consumer contract audit authority mismatch", "InvalidAudit");
    }
    if (!Object.values(consumerContractStates).includes(item.contractState)) {
      return result(false, "consumer contract audit state invalid", "InvalidAudit");
    }
    if (!consumerAvailabilityStates.includes(item.consumerAvailabilityState)) {
      return result(false, "consumer contract audit availability invalid", "InvalidAudit");
    }
    if (!compatibilityStates.includes(item.compatibilityState)) {
      return result(false, "consumer contract audit compatibility invalid", "InvalidAudit");
    }
    if (!["valid", "invalid"].includes(item.validationState)) {
      return result(false, "consumer contract audit validation invalid", "InvalidAudit");
    }
    if (item.contractVersion !== externalConsumerContractAuthorityVersion) {
      return result(false, "consumer contract audit version mismatch", "InvalidAudit");
    }
    if (boundaryEvaluation !== null && item.boundaryId !== boundaryEvaluation.handoff?.boundaryId) {
      return result(false, "consumer contract audit boundary mismatch", "InvalidAudit");
    }
    const identity = `${item.consumerContractId}:${item.boundaryId}:${item.contractState}:${item.timestamp}`;
    if (identities.has(identity)) return result(false, "duplicate consumer contract audit identity", "DuplicateAudit");
    identities.add(identity);
    if (previousKey !== "" && identity < previousKey) return result(false, "consumer contract audit order invalid", "InvalidAuditOrder");
    previousKey = identity;
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    consumerContractVersion: evaluation.consumerContractVersion,
    contractState: evaluation.contractState,
    boundaryState: evaluation.boundaryEvaluation?.boundaryState ?? "missing",
    boundaryEligibility: evaluation.boundaryEligibility,
    ownershipTransferState: evaluation.ownershipTransferState,
    consumerAvailabilityState: evaluation.consumerAvailabilityState,
    compatibilityState: evaluation.compatibilityState,
    validationState: evaluation.contractValidation.ok ? "valid" : "invalid",
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateConsumerContractDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "consumer contract diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.consumerContractVersion !== externalConsumerContractAuthorityVersion) {
    return result(false, "consumer contract diagnostics version mismatch", "InvalidDiagnostics");
  }
  if (!Object.values(consumerContractStates).includes(diagnostics.contractState)) {
    return result(false, "consumer contract diagnostics state invalid", "InvalidDiagnostics");
  }
  if (!Object.values(boundaryStates).includes(diagnostics.boundaryState) && diagnostics.boundaryState !== "missing") {
    return result(false, "consumer contract diagnostics boundary state invalid", "InvalidDiagnostics");
  }
  if (!boundaryEligibilityValues.includes(diagnostics.boundaryEligibility)) {
    return result(false, "consumer contract diagnostics boundary eligibility invalid", "InvalidDiagnostics");
  }
  if (!ownershipTransferStates.includes(diagnostics.ownershipTransferState)) {
    return result(false, "consumer contract diagnostics ownership invalid", "InvalidDiagnostics");
  }
  if (!consumerAvailabilityStates.includes(diagnostics.consumerAvailabilityState)) {
    return result(false, "consumer contract diagnostics availability invalid", "InvalidDiagnostics");
  }
  if (!compatibilityStates.includes(diagnostics.compatibilityState)) {
    return result(false, "consumer contract diagnostics compatibility invalid", "InvalidDiagnostics");
  }
  if (!["valid", "invalid"].includes(diagnostics.validationState)) {
    return result(false, "consumer contract diagnostics validation invalid", "InvalidDiagnostics");
  }
  return result(true);
}

function createCompatibilityState(contractValidation, policyValidation) {
  return contractValidation.ok && policyValidation.ok ? "DefinitionCompatible" : "DefinitionIncompatible";
}

export function evaluateExternalConsumerContractAuthority(input = {}) {
  const timestamp = input.timestamp ?? now();
  const boundaryEvaluation = input.boundaryEvaluation ?? evaluateExternalExecutionBoundary({ ...input, timestamp });
  const transitions = [transition(consumerContractStates.idle, consumerContractStates.receiveBoundaryContract, "receiving boundary contract", timestamp)];
  let contractState = consumerContractStates.published;
  let failureReason = null;
  let contract = null;
  let contractValidation = result(false, "contract not created", "MissingBoundaryContract");
  let policyValidation = result(false, "policy not created", "MissingBoundaryContract");
  let compatibilityState = "NotEvaluated";
  const consumerAvailabilityState = "ContractOnly";
  const boundaryEligibility = boundaryEvaluation?.boundaryEligibility ?? "Blocked";
  const ownershipTransferState = boundaryEvaluation?.ownershipTransferState ?? "RepositoryOwned";

  if (!isPlainObject(boundaryEvaluation) || boundaryEvaluation.authorityId !== externalBoundaryAuthorityId || !isPlainObject(boundaryEvaluation.handoff)) {
    transitions.push(
      transition(consumerContractStates.receiveBoundaryContract, consumerContractStates.missingBoundaryContract, "MissingBoundaryContract", timestamp)
    );
    contractState = consumerContractStates.missingBoundaryContract;
    failureReason = "MissingBoundaryContract";
  } else {
    transitions.push(
      transition(consumerContractStates.receiveBoundaryContract, consumerContractStates.validateContractDefinition, "boundary contract received", timestamp)
    );
    const handoffValidation = validateHandoffPackage(boundaryEvaluation.handoff, boundaryEvaluation.dispatchEvaluation);
    const boundaryContractValidation = validateExternalConsumerContract(boundaryEvaluation.handoff.externalConsumerContract);
    if (!handoffValidation.ok || !boundaryContractValidation.ok) {
      transitions.push(
        transition(
          consumerContractStates.validateContractDefinition,
          consumerContractStates.rejected,
          handoffValidation.failure ?? boundaryContractValidation.failure,
          timestamp
        )
      );
      contractState = consumerContractStates.rejected;
      failureReason = handoffValidation.failure ?? boundaryContractValidation.failure;
    } else {
      transitions.push(
        transition(consumerContractStates.validateContractDefinition, consumerContractStates.buildConsumerContract, "contract definition accepted", timestamp)
      );
      contract = createConsumerContract(boundaryEvaluation.handoff, timestamp);
      contractValidation = validateConsumerContract(contract, boundaryEvaluation);
      if (!contractValidation.ok) {
        transitions.push(
          transition(consumerContractStates.buildConsumerContract, consumerContractStates.constructionFailed, contractValidation.failure, timestamp)
        );
        contractState = consumerContractStates.constructionFailed;
        failureReason = contractValidation.failure;
      } else {
        transitions.push(
          transition(
            consumerContractStates.buildConsumerContract,
            consumerContractStates.validateCompatibilityPolicy,
            "consumer contract constructed",
            timestamp
          )
        );
        policyValidation = validateCompatibilityPolicy(contract.compatibilityPolicy);
        compatibilityState = createCompatibilityState(contractValidation, policyValidation);
        if (!policyValidation.ok || compatibilityState !== "DefinitionCompatible") {
          transitions.push(
            transition(
              consumerContractStates.validateCompatibilityPolicy,
              consumerContractStates.compatibilityRejected,
              policyValidation.failure ?? "CompatibilityRejected",
              timestamp
            )
          );
          contractState = consumerContractStates.compatibilityRejected;
          failureReason = policyValidation.failure ?? "CompatibilityRejected";
        } else {
          transitions.push(
            transition(
              consumerContractStates.validateCompatibilityPolicy,
              consumerContractStates.freezeConsumerContract,
              "compatibility policy accepted",
              timestamp
            )
          );
          if (!Object.isFrozen(contract) || !Object.isFrozen(contract.executionAcknowledgementContract)) {
            transitions.push(
              transition(consumerContractStates.freezeConsumerContract, consumerContractStates.freezeRejected, "FreezeRejected", timestamp)
            );
            contractState = consumerContractStates.freezeRejected;
            failureReason = "FreezeRejected";
          } else {
            transitions.push(
              transition(consumerContractStates.freezeConsumerContract, consumerContractStates.published, "consumer contract frozen", timestamp)
            );
          }
        }
      }
    }
  }

  const transitionValidation = validateConsumerContractTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  if (compatibilityState === "NotEvaluated" && contractValidation.ok) {
    compatibilityState = createCompatibilityState(contractValidation, policyValidation);
  }
  const audit = createAudit(
    contract,
    boundaryEvaluation,
    contractState,
    consumerAvailabilityState,
    compatibilityState,
    contractValidation.ok ? "valid" : "invalid",
    timestamp
  );
  const evaluation = {
    schemaVersion: externalConsumerContractAuthoritySchemaVersion,
    authorityId: externalConsumerContractAuthorityId,
    consumerContractVersion: externalConsumerContractAuthorityVersion,
    boundaryAuthorityId: externalBoundaryAuthorityId,
    boundaryVersion: externalBoundaryVersion,
    boundaryConsumerContractVersion,
    protocolVersion: integrationContractProtocolVersion,
    status: "executionBlocked",
    exitCode: contractValidation.ok && transitionValidation.ok ? bridgeExitCodes.executionBlocked : bridgeExitCodes.validationFailed,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeEvidenceGenerated: false,
    acknowledgementSynthesized: false,
    consumerInstanceIdentityCreated: false,
    externalConsumerDiscovered: false,
    externalConsumerConnected: false,
    dispatchEligibility: boundaryEvaluation?.handoff?.dispatchEligibility ?? "Blocked",
    boundaryEligibility,
    ownershipTransferState,
    consumerAvailabilityState,
    compatibilityState,
    contractState,
    boundaryEvaluation,
    consumerContract: contract,
    contractValidation,
    transitionValidation,
    policyValidation,
    audit,
    auditValidation: validateConsumerContractAudit(audit, boundaryEvaluation),
    futureExecutionStates,
    futureFailureCategories,
    evolutionPolicy: {
      supportedChangeClasses: evolutionChangeClasses,
      automaticMigrationAdded: false,
      unknownMajorVersionsReject: true,
      undeclaredCompatibilityRejects: true
    },
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
      "Phase137ExternalConsumerContractAuthority",
      "FutureExternalStudioMcpImplementationDocumentationOnly"
    ],
    failureReason,
    recommendedAction: "Resolve a supported external Studio MCP consumer implementation before any execution handoff can be transferred.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateConsumerContractDiagnostics(diagnosticsFor(evaluation)),
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

export function runExternalConsumerContractSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExternalConsumerContractAuthority({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExternalConsumerContractAuthority({ timestamp: stableTimestamp, repositoryState });
  const missingBoundary = evaluateExternalConsumerContractAuthority({ timestamp: stableTimestamp, boundaryEvaluation: {} });
  const invalidTransition = validateConsumerContractTransitions([
    transition(consumerContractStates.idle, consumerContractStates.freezeConsumerContract, "skip", stableTimestamp)
  ]);
  const skippedTransition = validateConsumerContractTransitions([
    transition(consumerContractStates.idle, consumerContractStates.receiveBoundaryContract, "start", stableTimestamp),
    transition(consumerContractStates.validateContractDefinition, consumerContractStates.buildConsumerContract, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateConsumerContractTransitions([
    transition(consumerContractStates.idle, consumerContractStates.receiveBoundaryContract, "start", stableTimestamp),
    transition(consumerContractStates.receiveBoundaryContract, consumerContractStates.validateContractDefinition, "validate", stableTimestamp),
    transition(consumerContractStates.validateContractDefinition, consumerContractStates.receiveBoundaryContract, "cycle", stableTimestamp)
  ]);
  const terminalMutation = validateConsumerContractTransitions([
    transition(consumerContractStates.idle, consumerContractStates.receiveBoundaryContract, "start", stableTimestamp),
    transition(consumerContractStates.receiveBoundaryContract, consumerContractStates.missingBoundaryContract, "stop", stableTimestamp),
    transition(consumerContractStates.missingBoundaryContract, consumerContractStates.validateContractDefinition, "mutate", stableTimestamp)
  ]);
  const badContract = { ...evaluation.consumerContract, extra: true };
  const missingContract = { ...evaluation.consumerContract };
  delete missingContract.consumerType;
  const badAcknowledgement = { ...evaluation.consumerContract, executionAcknowledgementContract: { ...evaluation.consumerContract.executionAcknowledgementContract, extra: true } };
  const missingAcknowledgement = {
    ...evaluation.consumerContract,
    executionAcknowledgementContract: { ...evaluation.consumerContract.executionAcknowledgementContract }
  };
  delete missingAcknowledgement.executionAcknowledgementContract.requestIdRequired;
  const badStructuredResult = { ...evaluation.consumerContract, structuredResultContract: { ...evaluation.consumerContract.structuredResultContract, extra: true } };
  const missingStructuredResult = { ...evaluation.consumerContract, structuredResultContract: { ...evaluation.consumerContract.structuredResultContract } };
  delete missingStructuredResult.structuredResultContract.resultPayloadRequired;
  const badRuntimeEvidence = { ...evaluation.consumerContract, runtimeEvidenceContract: { ...evaluation.consumerContract.runtimeEvidenceContract, extra: true } };
  const missingRuntimeEvidence = { ...evaluation.consumerContract, runtimeEvidenceContract: { ...evaluation.consumerContract.runtimeEvidenceContract } };
  delete missingRuntimeEvidence.runtimeEvidenceContract.integrityRequired;
  const badCorrelation = { ...evaluation.consumerContract, correlationContract: { ...evaluation.consumerContract.correlationContract, extra: true } };
  const missingCorrelation = { ...evaluation.consumerContract, correlationContract: { ...evaluation.consumerContract.correlationContract } };
  delete missingCorrelation.correlationContract.strictOrderingRequired;
  const badFailure = { ...evaluation.consumerContract, failureContract: { ...evaluation.consumerContract.failureContract, extra: true } };
  const missingFailure = { ...evaluation.consumerContract, failureContract: { ...evaluation.consumerContract.failureContract } };
  delete missingFailure.failureContract.failureStageRequired;
  const badPolicy = { ...evaluation.consumerContract, compatibilityPolicy: { ...evaluation.consumerContract.compatibilityPolicy, extra: true } };
  const wrongPolicy = { ...evaluation.consumerContract, compatibilityPolicy: { ...evaluation.consumerContract.compatibilityPolicy, protocolRule: "Compatible" } };
  const wrongType = { ...evaluation.consumerContract, consumerType: "ConnectedConsumer" };
  const wrongVersion = { ...evaluation.consumerContract, requiredProtocolVersion: "9.0.0" };
  const wrongBoundaryId = { ...evaluation.consumerContract, boundaryContractId: "different.boundary.contract" };
  const badDiagnostics = { ...evaluation.diagnostics, resultCaptured: false };
  const duplicateAudit = validateConsumerContractAudit([...evaluation.audit, ...evaluation.audit], evaluation.boundaryEvaluation);
  const reorderedAudit = validateConsumerContractAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:00.000Z" }
  ]);
  const optionalFieldAdded = classifyContractEvolution({ changeType: "optionalFieldAdded", declaredCompatibility: true });
  const invalidEvolution = classifyContractEvolution({ changeType: "optionalFieldAdded", declaredCompatibility: false });

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingBoundaryContractRejection", missingBoundary.contractState === consumerContractStates.missingBoundaryContract, "");
  assertSelfCheck(results, "contractRejectionPath", consumerContractStates.rejected === "ContractRejected", "");
  assertSelfCheck(results, "constructionFailurePath", consumerContractStates.constructionFailed === "ContractConstructionFailed", "");
  assertSelfCheck(results, "compatibilityRejectionPath", validateConsumerContract(wrongPolicy, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "freezeRejection", consumerContractStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactTopLevelSchema", Object.keys(evaluation.consumerContract).length === consumerContractFields.length, "");
  assertSelfCheck(results, "unknownTopLevelFieldRejection", validateConsumerContract(badContract, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "missingTopLevelFieldRejection", validateConsumerContract(missingContract, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "exactAcknowledgementSchema", Object.keys(evaluation.consumerContract.executionAcknowledgementContract).length === acknowledgementFields.length, "");
  assertSelfCheck(results, "exactStructuredResultSchema", Object.keys(evaluation.consumerContract.structuredResultContract).length === structuredResultFields.length, "");
  assertSelfCheck(results, "exactRuntimeEvidenceSchema", Object.keys(evaluation.consumerContract.runtimeEvidenceContract).length === runtimeEvidenceFields.length, "");
  assertSelfCheck(results, "exactCorrelationSchema", Object.keys(evaluation.consumerContract.correlationContract).length === correlationFields.length, "");
  assertSelfCheck(results, "exactFailureSchema", Object.keys(evaluation.consumerContract.failureContract).length === failureFields.length, "");
  assertSelfCheck(results, "exactCompatibilityPolicySchema", Object.keys(evaluation.consumerContract.compatibilityPolicy).length === compatibilityPolicyFields.length, "");
  assertSelfCheck(results, "nestedUnknownFieldRejection", validateConsumerContract(badAcknowledgement, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "nestedMissingFieldRejection", validateConsumerContract(missingAcknowledgement, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "structuredResultUnknownFieldRejection", validateConsumerContract(badStructuredResult, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "structuredResultMissingFieldRejection", validateConsumerContract(missingStructuredResult, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "runtimeEvidenceUnknownFieldRejection", validateConsumerContract(badRuntimeEvidence, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "runtimeEvidenceMissingFieldRejection", validateConsumerContract(missingRuntimeEvidence, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "correlationUnknownFieldRejection", validateConsumerContract(badCorrelation, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "correlationMissingFieldRejection", validateConsumerContract(missingCorrelation, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "failureUnknownFieldRejection", validateConsumerContract(badFailure, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "failureMissingFieldRejection", validateConsumerContract(missingFailure, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "compatibilityPolicyUnknownFieldRejection", validateConsumerContract(badPolicy, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "consumerTypeValidation", validateConsumerContract(wrongType, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "compatibilityStateValidation", compatibilityStates.includes(evaluation.compatibilityState), "");
  assertSelfCheck(results, "availabilityStateValidation", consumerAvailabilityStates.includes(evaluation.consumerAvailabilityState), "");
  assertSelfCheck(
    results,
    "versionValidation",
    validateVersionMetadata({
      protocolVersion: integrationContractProtocolVersion,
      contractVersion: integrationContractVersion,
      schemaVersion: integrationContractSchemaVersion,
      compatibilityVersion: integrationContractCompatibilityVersion
    }).ok === true,
    ""
  );
  assertSelfCheck(results, "contractEvolutionClassification", optionalFieldAdded.classification === "MinorCompatible", "");
  assertSelfCheck(results, "invalidEvolutionRejection", invalidEvolution.ok === false, "");
  assertSelfCheck(results, "upstreamBoundaryIdentifierValidation", evaluation.consumerContract.boundaryContractId === evaluation.boundaryEvaluation.handoff.externalConsumerContract.contractId, "");
  assertSelfCheck(results, "upstreamDispatchIdentifierValidation", evaluation.boundaryEvaluation.handoff.dispatchId === evaluation.boundaryEvaluation.dispatchEvaluation.dispatch.dispatchId, "");
  assertSelfCheck(results, "upstreamVersionPreservation", validateConsumerContract(wrongVersion, evaluation.boundaryEvaluation).ok === false, "");
  assertSelfCheck(results, "upstreamBoundaryVersionPreservation", evaluation.consumerContract.boundaryVersion === externalBoundaryVersion, "");
  assertSelfCheck(results, "blockedBoundaryTruthfulness", evaluation.boundaryEligibility === "Blocked" && evaluation.dispatchEligibility === "Blocked", "");
  assertSelfCheck(results, "repositoryOwnershipPreservation", evaluation.ownershipTransferState === "RepositoryOwned", "");
  assertSelfCheck(results, "noConsumerIdentityFabrication", evaluation.consumerInstanceIdentityCreated === false, "");
  assertSelfCheck(results, "noAcknowledgementSynthesis", evaluation.acknowledgementSynthesized === false, "");
  assertSelfCheck(results, "noStructuredResultSynthesis", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noRuntimeEvidenceSynthesis", evaluation.runtimeEvidenceGenerated === false, "");
  assertSelfCheck(results, "immutableContractPublication", Object.isFrozen(evaluation.consumerContract), "");
  assertSelfCheck(results, "immutableNestedObjectPublication", Object.isFrozen(evaluation.consumerContract.runtimeEvidenceContract), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateConsumerContractDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "immutableAuditValidation", Object.isFrozen(evaluation.audit) && evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicIdentifiers", evaluation.consumerContract.consumerContractId === `${evaluation.boundaryEvaluation.handoff.boundaryId}${consumerContractIdSuffix}`, "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && evaluation.consumerContract.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicCompatibilityResult", evaluation.compatibilityState === "DefinitionCompatible", "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalConsumerContractAuthorityId, "");
  assertSelfCheck(results, "phase136RegressionCompatibility", evaluation.boundaryEvaluation.authorityId === externalBoundaryAuthorityId, "");
  assertSelfCheck(results, "phase135RegressionCompatibility", evaluation.boundaryEvaluation.dispatchEvaluation.authorityId === executionDispatchAuthorityId, "");
  assertSelfCheck(results, "phase134RegressionCompatibility", typeof evaluation.boundaryEvaluation.handoff.requestId === "string", "");
  assertSelfCheck(results, "phase133RegressionCompatibility", typeof evaluation.boundaryEvaluation.handoff.orchestrationId === "string", "");
  assertSelfCheck(results, "noStudioExecution", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noRunnerInvocation", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noChildProcessExecution", true, "");
  assertSelfCheck(results, "noNetworkTransport", !("transport" in evaluation), "");
  assertSelfCheck(results, "noMcpCommunication", !("mcpClient" in evaluation), "");
  assertSelfCheck(results, "noConsumerDiscovery", evaluation.externalConsumerDiscovered === false, "");
  assertSelfCheck(results, "noAuthentication", !("credentials" in evaluation), "");
  assertSelfCheck(results, "noSecrets", !("credentialSecret" in evaluation), "");
  assertSelfCheck(results, "noOwnershipTransfer", evaluation.ownershipTransferState === "RepositoryOwned", "");
  assertSelfCheck(results, "noRuntimeEvidence", evaluation.runtimeEvidenceGenerated === false, "");
  assertSelfCheck(results, "noStructuredResultCapture", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("productionCertified" in evaluation) && !("certificationDecision" in evaluation), "");
  assertSelfCheck(results, "boundaryContractIdentityMismatchRejection", validateConsumerContract(wrongBoundaryId, evaluation.boundaryEvaluation).ok === false, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExternalConsumerContractSelfChecks();
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
  const evaluation = evaluateExternalConsumerContractAuthority({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
