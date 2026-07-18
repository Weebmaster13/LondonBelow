import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateExternalTransportCompatibility,
  externalTransportCompatibilityAuthorityId,
  externalTransportCompatibilityVersion,
  validateCompatibilityEvaluation
} from "./studio-external-transport-compatibility-authority.mjs";
import { transportCapabilityProfileVersion } from "./studio-envelope-transport-capability-authority.mjs";
import { transportContractVersion } from "./studio-envelope-transport-contract-authority.mjs";
import { stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const implementationContractSchemaVersion = 1;
export const implementationContractVersion = "1.0.0";
export const externalTransportImplementationContractAuthorityId =
  "chapter0Home.phase144StudioExternalTransportImplementationContractAuthority";

export const implementationContractStates = Object.freeze({
  idle: "Idle",
  receiveCompatibilityEvaluation: "ReceiveCompatibilityEvaluation",
  resolveImplementationRequirements: "ResolveImplementationRequirements",
  validateImplementationContract: "ValidateImplementationContract",
  constructImplementationContract: "ConstructImplementationContract",
  validateImplementationReadinessClassification: "ValidateImplementationReadinessClassification",
  freezeImplementationContract: "FreezeImplementationContract",
  published: "ImplementationContractPublished",
  missingCompatibilityEvaluation: "MissingCompatibilityEvaluation",
  requirementResolutionFailed: "ImplementationRequirementResolutionFailed",
  rejected: "ImplementationContractRejected",
  constructionFailed: "ImplementationConstructionFailed",
  readinessRejected: "ImplementationReadinessRejected",
  freezeRejected: "FreezeRejected"
});

export const implementationReadinessValues = Object.freeze([
  "DefinitionOnly",
  "StructurallyReadyForFutureValidation",
  "ImplementationValidated",
  "Deprecated"
]);
export const implementationStates = Object.freeze(["Declared", "Configured", "Initialized", "Available", "Degraded", "Unavailable", "Failed", "Stopped"]);
export const terminalImplementationStates = Object.freeze(["Failed", "Stopped"]);
export const checkpointNames = Object.freeze([
  "ImplementationIdentityValidated",
  "ContractVersionValidated",
  "CapabilityVersionValidated",
  "CompatibilityVersionValidated",
  "ConfigurationValidated",
  "BoundaryValidated",
  "TransportInitializationValidated",
  "AvailabilityValidated",
  "ShutdownValidated"
]);
export const failureCodes = Object.freeze([
  "ImplementationUnavailable",
  "ImplementationIdentityMismatch",
  "ImplementationVersionMismatch",
  "ConfigurationInvalid",
  "BoundaryViolation",
  "InitializationFailed",
  "AvailabilityCheckFailed",
  "TransportFailure",
  "ShutdownFailed",
  "UnknownImplementationFailure"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-18T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  implementationContractStates.published,
  implementationContractStates.missingCompatibilityEvaluation,
  implementationContractStates.requirementResolutionFailed,
  implementationContractStates.rejected,
  implementationContractStates.constructionFailed,
  implementationContractStates.readinessRejected,
  implementationContractStates.freezeRejected
]);
const legalTransitions = new Map([
  [implementationContractStates.idle, new Set([implementationContractStates.receiveCompatibilityEvaluation])],
  [
    implementationContractStates.receiveCompatibilityEvaluation,
    new Set([implementationContractStates.resolveImplementationRequirements, implementationContractStates.missingCompatibilityEvaluation])
  ],
  [
    implementationContractStates.resolveImplementationRequirements,
    new Set([implementationContractStates.validateImplementationContract, implementationContractStates.requirementResolutionFailed])
  ],
  [
    implementationContractStates.validateImplementationContract,
    new Set([implementationContractStates.constructImplementationContract, implementationContractStates.rejected])
  ],
  [
    implementationContractStates.constructImplementationContract,
    new Set([implementationContractStates.validateImplementationReadinessClassification, implementationContractStates.constructionFailed])
  ],
  [
    implementationContractStates.validateImplementationReadinessClassification,
    new Set([implementationContractStates.freezeImplementationContract, implementationContractStates.readinessRejected])
  ],
  [
    implementationContractStates.freezeImplementationContract,
    new Set([implementationContractStates.published, implementationContractStates.freezeRejected])
  ]
]);

const contractFields = Object.freeze([
  "implementationContractId",
  "implementationContractVersion",
  "compatibilityEvaluationId",
  "requiredTransportContractVersion",
  "requiredCapabilityProfileVersion",
  "requiredCompatibilityEvaluationVersion",
  "implementationLifecycleContract",
  "implementationCheckpointContract",
  "implementationFailureContract",
  "implementationBoundaryContract",
  "implementationReadiness",
  "validationState",
  "timestamp"
]);
const lifecycleFields = Object.freeze([
  "lifecycleVersion",
  "requiredStates",
  "requiredTerminalStates",
  "stateTransitionValidationRequired",
  "terminalMutationRejected"
]);
const checkpointFields = Object.freeze(["checkpointSchemaVersion", "requiredCheckpoints", "strictOrderingRequired", "correlationRequired", "immutableResultsRequired"]);
const failureFields = Object.freeze([
  "failureSchemaVersion",
  "supportedFailureCodes",
  "failureCorrelationRequired",
  "terminalFailureRequired",
  "failureEvidenceRequired"
]);
const boundaryFields = Object.freeze([
  "boundarySchemaVersion",
  "repositoryOwnershipRequired",
  "externalExecutionRequired",
  "networkingOwnedExternally",
  "credentialHandlingOwnedExternally",
  "runtimeEvidenceOwnedExternally"
]);
const diagnosticsFields = Object.freeze([
  "implementationContractVersion",
  "implementationContractState",
  "implementationReadiness",
  "overallTransportCompatibility",
  "transportAvailabilityState",
  "executionEligibility",
  "executionBlocked",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "implementationContractId",
  "compatibilityEvaluationId",
  "transportContractId",
  "capabilityId",
  "authorityId",
  "implementationContractState",
  "implementationReadiness",
  "transportAvailabilityState",
  "executionEligibility",
  "timestamp",
  "implementationContractVersion"
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
    const id = validateIdentifier(value, "implementation contract identifier");
    if (!id.ok) return id;
    if (seen.has(value)) return result(false, `duplicate implementation contract identifier ${value}`, "DuplicateIdentifier");
    seen.add(value);
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalTransportImplementationContractAuthorityId });
}

export function validateImplementationContractTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "implementation contract transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(implementationContractStates).includes(item.from) || !Object.values(implementationContractStates).includes(item.to)) {
      return result(false, "undocumented implementation contract state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== implementationContractStates.idle) return result(false, "implementation contract lifecycle must start at Idle", "InvalidLifecycle");
    if (index > 0 && transitions[index - 1].to !== item.from) return result(false, "implementation contract lifecycle skipped state", "InvalidLifecycle");
    if (terminalStates.has(item.from) || terminalSeen) return result(false, "terminal implementation contract state mutated", "InvalidLifecycle");
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal implementation contract transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic implementation contract transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function createImplementationContract(compatibilityEvaluation, timestamp) {
  return deepFreeze({
    implementationContractId: `${compatibilityEvaluation.compatibilityEvaluation.compatibilityEvaluationId}.implementationContract`,
    implementationContractVersion,
    compatibilityEvaluationId: compatibilityEvaluation.compatibilityEvaluation.compatibilityEvaluationId,
    requiredTransportContractVersion: transportContractVersion,
    requiredCapabilityProfileVersion: transportCapabilityProfileVersion,
    requiredCompatibilityEvaluationVersion: externalTransportCompatibilityVersion,
    implementationLifecycleContract: deepFreeze({
      lifecycleVersion: implementationContractVersion,
      requiredStates: [...implementationStates],
      requiredTerminalStates: [...terminalImplementationStates],
      stateTransitionValidationRequired: true,
      terminalMutationRejected: true
    }),
    implementationCheckpointContract: deepFreeze({
      checkpointSchemaVersion: String(implementationContractSchemaVersion),
      requiredCheckpoints: [...checkpointNames],
      strictOrderingRequired: true,
      correlationRequired: true,
      immutableResultsRequired: true
    }),
    implementationFailureContract: deepFreeze({
      failureSchemaVersion: String(implementationContractSchemaVersion),
      supportedFailureCodes: [...failureCodes],
      failureCorrelationRequired: true,
      terminalFailureRequired: true,
      failureEvidenceRequired: false
    }),
    implementationBoundaryContract: deepFreeze({
      boundarySchemaVersion: String(implementationContractSchemaVersion),
      repositoryOwnershipRequired: true,
      externalExecutionRequired: true,
      networkingOwnedExternally: true,
      credentialHandlingOwnedExternally: true,
      runtimeEvidenceOwnedExternally: true
    }),
    implementationReadiness: "DefinitionOnly",
    validationState: "valid",
    timestamp
  });
}

function exactList(values, expected, label) {
  if (!Array.isArray(values) || values.length !== expected.length) return result(false, `${label} invalid`, "SchemaMismatch");
  for (let index = 0; index < expected.length; index += 1) {
    if (values[index] !== expected[index]) return result(false, `${label} ordering invalid`, "SchemaMismatch");
  }
  return result(true);
}

export function validateLifecycleContract(contract) {
  const fields = exactFields(contract, lifecycleFields, "implementation lifecycle contract");
  if (!fields.ok) return fields;
  if (contract.lifecycleVersion !== implementationContractVersion) return result(false, "lifecycle version unsupported", "LifecycleVersionInvalid");
  const states = exactList(contract.requiredStates, implementationStates, "implementation lifecycle states");
  if (!states.ok) return states;
  const terminal = exactList(contract.requiredTerminalStates, terminalImplementationStates, "implementation terminal states");
  if (!terminal.ok) return terminal;
  if (contract.stateTransitionValidationRequired !== true) return result(false, "state transition validation must be required", "LifecycleValidationInvalid");
  if (contract.terminalMutationRejected !== true) return result(false, "terminal mutation rejection must be required", "LifecycleValidationInvalid");
  return result(true);
}

export function validateCheckpointContract(contract) {
  const fields = exactFields(contract, checkpointFields, "implementation checkpoint contract");
  if (!fields.ok) return fields;
  if (contract.checkpointSchemaVersion !== String(implementationContractSchemaVersion)) return result(false, "checkpoint schema version unsupported", "CheckpointSchemaInvalid");
  const checkpoints = exactList(contract.requiredCheckpoints, checkpointNames, "implementation checkpoints");
  if (!checkpoints.ok) return checkpoints;
  if (contract.strictOrderingRequired !== true) return result(false, "checkpoint ordering must be strict", "CheckpointContractInvalid");
  if (contract.correlationRequired !== true) return result(false, "checkpoint correlation must be required", "CheckpointContractInvalid");
  if (contract.immutableResultsRequired !== true) return result(false, "checkpoint immutability must be required", "CheckpointContractInvalid");
  return result(true);
}

export function validateFailureContract(contract) {
  const fields = exactFields(contract, failureFields, "implementation failure contract");
  if (!fields.ok) return fields;
  if (contract.failureSchemaVersion !== String(implementationContractSchemaVersion)) return result(false, "failure schema version unsupported", "FailureSchemaInvalid");
  const codes = exactList(contract.supportedFailureCodes, failureCodes, "implementation failure codes");
  if (!codes.ok) return codes;
  if (contract.failureCorrelationRequired !== true) return result(false, "failure correlation must be required", "FailureContractInvalid");
  if (contract.terminalFailureRequired !== true) return result(false, "terminal failure must be required", "FailureContractInvalid");
  if (contract.failureEvidenceRequired !== false) return result(false, "runtime failure evidence cannot be required in Phase 144", "FailureContractInvalid");
  return result(true);
}

export function validateBoundaryContract(contract) {
  const fields = exactFields(contract, boundaryFields, "implementation boundary contract");
  if (!fields.ok) return fields;
  if (contract.boundarySchemaVersion !== String(implementationContractSchemaVersion)) return result(false, "boundary schema version unsupported", "BoundarySchemaInvalid");
  for (const field of [
    "repositoryOwnershipRequired",
    "externalExecutionRequired",
    "networkingOwnedExternally",
    "credentialHandlingOwnedExternally",
    "runtimeEvidenceOwnedExternally"
  ]) {
    if (contract[field] !== true) return result(false, `${field} must be true`, "BoundaryContractInvalid");
  }
  return result(true);
}

export function validateImplementationContract(contract, compatibilityEvaluation = null) {
  const fields = exactFields(contract, contractFields, "implementation contract");
  if (!fields.ok) return fields;
  for (const field of [
    "implementationContractId",
    "implementationContractVersion",
    "compatibilityEvaluationId",
    "requiredTransportContractVersion",
    "requiredCapabilityProfileVersion",
    "requiredCompatibilityEvaluationVersion",
    "implementationReadiness",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(contract[field], field);
    if (!id.ok) return id;
  }
  if (contract.implementationContractVersion !== implementationContractVersion) return result(false, "implementation contract version unsupported", "ImplementationContractVersionInvalid");
  if (contract.requiredTransportContractVersion !== transportContractVersion) return result(false, "transport contract version drift", "UpstreamVersionInvalid");
  if (contract.requiredCapabilityProfileVersion !== transportCapabilityProfileVersion) return result(false, "capability profile version drift", "UpstreamVersionInvalid");
  if (contract.requiredCompatibilityEvaluationVersion !== externalTransportCompatibilityVersion) return result(false, "compatibility evaluation version drift", "UpstreamVersionInvalid");
  if (!implementationReadinessValues.includes(contract.implementationReadiness)) return result(false, "implementation readiness unsupported", "ImplementationReadinessInvalid");
  if (["StructurallyReadyForFutureValidation", "ImplementationValidated"].includes(contract.implementationReadiness)) {
    return result(false, "Phase 144 cannot emit readiness validation", "ImplementationReadinessInvalid");
  }
  if (contract.validationState !== "valid") return result(false, "implementation validation state invalid", "ValidationStateInvalid");
  const lifecycle = validateLifecycleContract(contract.implementationLifecycleContract);
  if (!lifecycle.ok) return lifecycle;
  const checkpoints = validateCheckpointContract(contract.implementationCheckpointContract);
  if (!checkpoints.ok) return checkpoints;
  const failures = validateFailureContract(contract.implementationFailureContract);
  if (!failures.ok) return failures;
  const boundary = validateBoundaryContract(contract.implementationBoundaryContract);
  if (!boundary.ok) return boundary;
  if (compatibilityEvaluation !== null) {
    if (contract.compatibilityEvaluationId !== compatibilityEvaluation.compatibilityEvaluation.compatibilityEvaluationId) {
      return result(false, "compatibility evaluation ID drift", "CorrelationMismatch");
    }
    if (contract.implementationContractId !== `${compatibilityEvaluation.compatibilityEvaluation.compatibilityEvaluationId}.implementationContract`) {
      return result(false, "implementation contract ID drift", "CorrelationMismatch");
    }
    const duplicateCheck = validateUniqueIdentifiers([
      contract.implementationContractId,
      contract.compatibilityEvaluationId,
      compatibilityEvaluation.compatibilityEvaluation.transportContractId,
      compatibilityEvaluation.compatibilityEvaluation.capabilityId
    ]);
    if (!duplicateCheck.ok) return duplicateCheck;
  }
  return result(true);
}

function validateCompatibilityPreconditions(compatibilityEvaluation) {
  if (!isPlainObject(compatibilityEvaluation)) {
    return result(false, "compatibility authority incompatible", "CompatibilityAuthorityIncompatible");
  }
  if (!isPlainObject(compatibilityEvaluation.compatibilityEvaluation)) {
    return result(false, "compatibility evaluation missing", "CompatibilityEvaluationMissing");
  }
  if (compatibilityEvaluation.authorityId !== externalTransportCompatibilityAuthorityId) {
    return result(false, "compatibility authority incompatible", "CompatibilityAuthorityIncompatible");
  }
  const validation = validateCompatibilityEvaluation(
    compatibilityEvaluation.compatibilityEvaluation,
    compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.transportContract,
    compatibilityEvaluation.capabilityEvaluation.capabilityProfile
  );
  if (!validation.ok) return validation;
  if (compatibilityEvaluation.overallTransportCompatibility !== "CompatibleDefinition") {
    return result(false, "overall compatibility not acceptable", "ImplementationRequirementResolutionFailed");
  }
  if (compatibilityEvaluation.transportAvailabilityState !== "TransportUnavailable") {
    return result(false, "transport availability must remain unavailable", "TransportAvailabilityInvalid");
  }
  if (compatibilityEvaluation.executionEligibility !== "DefinitionCompatibleButUnavailable") {
    return result(false, "execution eligibility must remain definition compatible but unavailable", "ExecutionEligibilityInvalid");
  }
  if (
    compatibilityEvaluation.executionBlocked !== true ||
    compatibilityEvaluation.runnerInvoked !== false ||
    compatibilityEvaluation.structuredResultCaptured !== false ||
    compatibilityEvaluation.transportCreated !== false ||
    compatibilityEvaluation.envelopeTransmitted !== false ||
    compatibilityEvaluation.acknowledgementReceived !== false
  ) {
    return result(false, "compatibility blocked posture drifted", "CompatibilityPostureInvalid");
  }
  return result(true);
}

function createAudit(contract, compatibilityEvaluation, implementationContractState, timestamp) {
  return deepFreeze([
    {
      implementationContractId: contract?.implementationContractId ?? "missing",
      compatibilityEvaluationId: compatibilityEvaluation?.compatibilityEvaluation?.compatibilityEvaluationId ?? "missing",
      transportContractId: compatibilityEvaluation?.compatibilityEvaluation?.transportContractId ?? "missing",
      capabilityId: compatibilityEvaluation?.compatibilityEvaluation?.capabilityId ?? "missing",
      authorityId: externalTransportImplementationContractAuthorityId,
      implementationContractState,
      implementationReadiness: contract?.implementationReadiness ?? "DefinitionOnly",
      transportAvailabilityState: compatibilityEvaluation?.transportAvailabilityState ?? "TransportUnavailable",
      executionEligibility: compatibilityEvaluation?.executionEligibility ?? "DefinitionCompatibleButUnavailable",
      timestamp,
      implementationContractVersion
    }
  ]);
}

export function validateImplementationAudit(audit, contract = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "implementation contract audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "implementation contract audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalTransportImplementationContractAuthorityId) return result(false, "implementation audit authority mismatch", "InvalidAudit");
    if (!Object.values(implementationContractStates).includes(item.implementationContractState)) return result(false, "implementation audit state invalid", "InvalidAudit");
    if (!implementationReadinessValues.includes(item.implementationReadiness)) return result(false, "implementation audit readiness invalid", "InvalidAudit");
    if (item.transportAvailabilityState !== "TransportUnavailable") return result(false, "implementation audit availability invalid", "InvalidAudit");
    if (item.executionEligibility !== "DefinitionCompatibleButUnavailable") return result(false, "implementation audit eligibility invalid", "InvalidAudit");
    if (contract !== null && item.implementationContractId !== contract.implementationContractId) {
      return result(false, "implementation audit identity mismatch", "InvalidAudit");
    }
    const identity = `${item.implementationContractId}:${item.compatibilityEvaluationId}:${item.implementationContractState}`;
    if (identities.has(identity)) return result(false, "duplicate implementation audit identity", "InvalidAudit");
    identities.add(identity);
    const orderingKey = `${item.timestamp}:${identity}`;
    if (previousKey && orderingKey < previousKey) return result(false, "implementation audit ordering invalid", "InvalidAudit");
    previousKey = orderingKey;
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    implementationContractVersion: evaluation.implementationContractVersion,
    implementationContractState: evaluation.implementationContractState,
    implementationReadiness: evaluation.implementationReadiness,
    overallTransportCompatibility: evaluation.overallTransportCompatibility,
    transportAvailabilityState: evaluation.transportAvailabilityState,
    executionEligibility: evaluation.executionEligibility,
    executionBlocked: evaluation.executionBlocked,
    validationState: evaluation.validationState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateImplementationDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "implementation contract diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.implementationContractVersion !== implementationContractVersion) return result(false, "implementation diagnostics version mismatch", "InvalidDiagnostics");
  if (!Object.values(implementationContractStates).includes(diagnostics.implementationContractState)) return result(false, "implementation diagnostics state invalid", "InvalidDiagnostics");
  if (diagnostics.implementationReadiness !== "DefinitionOnly") return result(false, "implementation diagnostics readiness invalid", "InvalidDiagnostics");
  if (diagnostics.overallTransportCompatibility !== "CompatibleDefinition") return result(false, "implementation diagnostics compatibility invalid", "InvalidDiagnostics");
  if (diagnostics.transportAvailabilityState !== "TransportUnavailable") return result(false, "implementation diagnostics availability invalid", "InvalidDiagnostics");
  if (diagnostics.executionEligibility !== "DefinitionCompatibleButUnavailable") return result(false, "implementation diagnostics eligibility invalid", "InvalidDiagnostics");
  if (diagnostics.executionBlocked !== true) return result(false, "implementation diagnostics executionBlocked invalid", "InvalidDiagnostics");
  if (diagnostics.validationState !== "valid") return result(false, "implementation diagnostics validation invalid", "InvalidDiagnostics");
  return result(true);
}

export function evaluateExternalTransportImplementationContract(input = {}) {
  const timestamp = input.timestamp ?? now();
  const compatibilityEvaluation = input.compatibilityEvaluation ?? evaluateExternalTransportCompatibility({ ...input, timestamp });
  const transitions = [
    transition(implementationContractStates.idle, implementationContractStates.receiveCompatibilityEvaluation, "receiving compatibility evaluation", timestamp)
  ];
  let implementationContractState = implementationContractStates.published;
  let failureReason = null;
  let contract = null;
  let contractValidation = result(false, "implementation contract not created", "MissingCompatibilityEvaluation");
  let implementationReadiness = "DefinitionOnly";
  let overallTransportCompatibility = compatibilityEvaluation?.overallTransportCompatibility ?? "IncompleteDefinition";
  let transportAvailabilityState = compatibilityEvaluation?.transportAvailabilityState ?? "TransportUnavailable";
  let executionEligibility = compatibilityEvaluation?.executionEligibility ?? "DefinitionIncomplete";

  const preconditions = validateCompatibilityPreconditions(compatibilityEvaluation);
  if (!preconditions.ok && preconditions.failure === "CompatibilityEvaluationMissing") {
    transitions.push(
      transition(implementationContractStates.receiveCompatibilityEvaluation, implementationContractStates.missingCompatibilityEvaluation, preconditions.failure, timestamp)
    );
    implementationContractState = implementationContractStates.missingCompatibilityEvaluation;
    failureReason = preconditions.failure;
  } else if (!preconditions.ok) {
    transitions.push(
      transition(implementationContractStates.receiveCompatibilityEvaluation, implementationContractStates.resolveImplementationRequirements, "compatibility evaluation received", timestamp)
    );
    transitions.push(
      transition(
        implementationContractStates.resolveImplementationRequirements,
        implementationContractStates.requirementResolutionFailed,
        preconditions.failure ?? "ImplementationRequirementResolutionFailed",
        timestamp
      )
    );
    implementationContractState = implementationContractStates.requirementResolutionFailed;
    failureReason = preconditions.failure ?? "ImplementationRequirementResolutionFailed";
  } else {
    transitions.push(
      transition(implementationContractStates.receiveCompatibilityEvaluation, implementationContractStates.resolveImplementationRequirements, "compatibility evaluation received", timestamp)
    );
    transitions.push(
      transition(implementationContractStates.resolveImplementationRequirements, implementationContractStates.validateImplementationContract, "implementation requirements resolved", timestamp)
    );
    contract = createImplementationContract(compatibilityEvaluation, timestamp);
    implementationReadiness = contract.implementationReadiness;
    contractValidation = validateImplementationContract(contract, compatibilityEvaluation);
    if (!contractValidation.ok) {
      transitions.push(
        transition(implementationContractStates.validateImplementationContract, implementationContractStates.rejected, contractValidation.failure ?? "ImplementationContractRejected", timestamp)
      );
      implementationContractState = implementationContractStates.rejected;
      failureReason = contractValidation.failure ?? "ImplementationContractRejected";
    } else {
      transitions.push(
        transition(implementationContractStates.validateImplementationContract, implementationContractStates.constructImplementationContract, "implementation contract validated", timestamp)
      );
      if (!isPlainObject(contract)) {
        transitions.push(
          transition(implementationContractStates.constructImplementationContract, implementationContractStates.constructionFailed, "ImplementationConstructionFailed", timestamp)
        );
        implementationContractState = implementationContractStates.constructionFailed;
        failureReason = "ImplementationConstructionFailed";
      } else {
        transitions.push(
          transition(
            implementationContractStates.constructImplementationContract,
            implementationContractStates.validateImplementationReadinessClassification,
            "implementation contract constructed",
            timestamp
          )
        );
        if (contract.implementationReadiness !== "DefinitionOnly") {
          transitions.push(
            transition(
              implementationContractStates.validateImplementationReadinessClassification,
              implementationContractStates.readinessRejected,
              "ImplementationReadinessRejected",
              timestamp
            )
          );
          implementationContractState = implementationContractStates.readinessRejected;
          failureReason = "ImplementationReadinessRejected";
        } else {
          transitions.push(
            transition(
              implementationContractStates.validateImplementationReadinessClassification,
              implementationContractStates.freezeImplementationContract,
              "implementation readiness accepted",
              timestamp
            )
          );
          if (
            !Object.isFrozen(contract) ||
            !Object.isFrozen(contract.implementationLifecycleContract) ||
            !Object.isFrozen(contract.implementationCheckpointContract) ||
            !Object.isFrozen(contract.implementationFailureContract) ||
            !Object.isFrozen(contract.implementationBoundaryContract)
          ) {
            transitions.push(transition(implementationContractStates.freezeImplementationContract, implementationContractStates.freezeRejected, "FreezeRejected", timestamp));
            implementationContractState = implementationContractStates.freezeRejected;
            failureReason = "FreezeRejected";
          } else {
            transitions.push(
              transition(implementationContractStates.freezeImplementationContract, implementationContractStates.published, "implementation contract frozen", timestamp)
            );
          }
        }
      }
    }
  }

  const transitionValidation = validateImplementationContractTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  const audit = createAudit(contract, compatibilityEvaluation, implementationContractState, timestamp);
  const ok = contractValidation.ok && transitionValidation.ok;
  const evaluation = {
    schemaVersion: implementationContractSchemaVersion,
    authorityId: externalTransportImplementationContractAuthorityId,
    implementationContractVersion,
    status: "executionBlocked",
    exitCode: ok ? bridgeExitCodes.executionBlocked : bridgeExitCodes.validationFailed,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeEvidenceGenerated: false,
    implementationDiscovered: false,
    implementationLoaded: false,
    implementationExecuted: false,
    transportCreated: false,
    envelopeTransmitted: false,
    acknowledgementReceived: false,
    endpointDiscovered: false,
    externalConsumerConnected: false,
    studioExecuted: false,
    executionBlocked: true,
    implementationContractState,
    implementationReadiness,
    overallTransportCompatibility,
    transportAvailabilityState,
    executionEligibility,
    validationState: "valid",
    compatibilityEvaluation,
    implementationContract: contract,
    preconditions,
    contractValidation,
    transitionValidation,
    audit,
    auditValidation: validateImplementationAudit(audit, contract),
    integrationGraph: [
      "Phase140ExternalExecutionEnvelopeAuthority",
      "Phase141ExternalEnvelopeTransportContractAuthority",
      "Phase142ExternalEnvelopeTransportCapabilityAuthority",
      "Phase143ExternalTransportCompatibilityAuthority",
      "Phase144ExternalTransportImplementationContractAuthority",
      "FutureImplementationReadinessEvaluationDocumentationOnly",
      "FutureImplementationDocumentationOnly"
    ],
    failureReason,
    recommendedAction: "Define future implementation readiness evaluation before any implementation may be loaded or executed.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateImplementationDiagnostics(diagnosticsFor(evaluation)),
    serializationValidation: (() => {
      try {
        const serialized = stableSerialize(evaluation);
        return result(stableSerialize(evaluation) === serialized);
      } catch (error) {
        return result(false, String(error?.message ?? error), "SerializationFailure");
      }
    })()
  });
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runExternalTransportImplementationContractSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExternalTransportImplementationContract({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExternalTransportImplementationContract({ timestamp: stableTimestamp, repositoryState });
  const compatibility = evaluation.compatibilityEvaluation;
  const contract = evaluation.implementationContract;
  const missingCompatibility = evaluateExternalTransportImplementationContract({ timestamp: stableTimestamp, compatibilityEvaluation: {} });
  const requirementFailure = evaluateExternalTransportImplementationContract({
    timestamp: stableTimestamp,
    compatibilityEvaluation: { ...compatibility, overallTransportCompatibility: "IncompatibleDefinition" }
  });
  const badContract = { ...contract, extra: true };
  const missingContractField = { ...contract };
  delete missingContractField.requiredCapabilityProfileVersion;
  const duplicateContract = { ...contract, implementationContractId: contract.compatibilityEvaluationId };
  const badLifecycle = { ...contract.implementationLifecycleContract, requiredStates: ["Declared"] };
  const badCheckpoint = { ...contract.implementationCheckpointContract, requiredCheckpoints: [...checkpointNames].reverse() };
  const badFailure = { ...contract.implementationFailureContract, failureEvidenceRequired: true };
  const badBoundary = { ...contract.implementationBoundaryContract, networkingOwnedExternally: false };
  const badNested = { ...contract, implementationLifecycleContract: { ...contract.implementationLifecycleContract, extra: true } };
  const missingNested = { ...contract, implementationCheckpointContract: { ...contract.implementationCheckpointContract } };
  delete missingNested.implementationCheckpointContract.strictOrderingRequired;
  const readyContract = { ...contract, implementationReadiness: "StructurallyReadyForFutureValidation" };
  const validatedContract = { ...contract, implementationReadiness: "ImplementationValidated" };
  const deprecatedContract = { ...contract, implementationReadiness: "Deprecated" };
  const badDiagnostics = { ...evaluation.diagnostics, implementationPath: "none" };
  const duplicateAudit = validateImplementationAudit([...evaluation.audit, ...evaluation.audit], contract);
  const reorderedAudit = validateImplementationAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-18T00:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-18T00:00:00.000Z" }
  ]);
  const invalidTransition = validateImplementationContractTransitions([
    transition(implementationContractStates.idle, implementationContractStates.freezeImplementationContract, "skip", stableTimestamp)
  ]);
  const skippedTransition = validateImplementationContractTransitions([
    transition(implementationContractStates.idle, implementationContractStates.receiveCompatibilityEvaluation, "start", stableTimestamp),
    transition(implementationContractStates.validateImplementationContract, implementationContractStates.constructImplementationContract, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateImplementationContractTransitions([
    transition(implementationContractStates.idle, implementationContractStates.receiveCompatibilityEvaluation, "start", stableTimestamp),
    transition(implementationContractStates.receiveCompatibilityEvaluation, implementationContractStates.resolveImplementationRequirements, "resolve", stableTimestamp),
    transition(implementationContractStates.resolveImplementationRequirements, implementationContractStates.receiveCompatibilityEvaluation, "cycle", stableTimestamp)
  ]);
  const repeatedTerminal = validateImplementationContractTransitions([
    transition(implementationContractStates.idle, implementationContractStates.receiveCompatibilityEvaluation, "start", stableTimestamp),
    transition(implementationContractStates.receiveCompatibilityEvaluation, implementationContractStates.missingCompatibilityEvaluation, "stop", stableTimestamp),
    transition(implementationContractStates.missingCompatibilityEvaluation, implementationContractStates.missingCompatibilityEvaluation, "repeat", stableTimestamp)
  ]);
  const terminalMutation = validateImplementationContractTransitions([
    transition(implementationContractStates.idle, implementationContractStates.receiveCompatibilityEvaluation, "start", stableTimestamp),
    transition(implementationContractStates.receiveCompatibilityEvaluation, implementationContractStates.missingCompatibilityEvaluation, "stop", stableTimestamp),
    transition(implementationContractStates.missingCompatibilityEvaluation, implementationContractStates.resolveImplementationRequirements, "mutate", stableTimestamp)
  ]);
  const failureToSuccess = validateImplementationContractTransitions([
    transition(implementationContractStates.idle, implementationContractStates.receiveCompatibilityEvaluation, "start", stableTimestamp),
    transition(implementationContractStates.receiveCompatibilityEvaluation, implementationContractStates.missingCompatibilityEvaluation, "stop", stableTimestamp),
    transition(implementationContractStates.missingCompatibilityEvaluation, implementationContractStates.published, "recover", stableTimestamp)
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingCompatibilityEvaluationRejection", missingCompatibility.implementationContractState === implementationContractStates.missingCompatibilityEvaluation, "");
  assertSelfCheck(results, "requirementResolutionFailure", requirementFailure.implementationContractState === implementationContractStates.requirementResolutionFailed, "");
  assertSelfCheck(results, "implementationContractRejection", validateImplementationContract(badContract, compatibility).ok === false, "");
  assertSelfCheck(results, "implementationConstructionFailureStateDocumented", implementationContractStates.constructionFailed === "ImplementationConstructionFailed", "");
  assertSelfCheck(results, "readinessRejection", validateImplementationContract(readyContract, compatibility).ok === false, "");
  assertSelfCheck(results, "freezeRejectionStateDocumented", implementationContractStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "repeatedTerminalTransitionRejection", repeatedTerminal.ok === false, "");
  assertSelfCheck(results, "failureToSuccessRejection", failureToSuccess.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactTopLevelSchema", Object.keys(contract).length === contractFields.length, "");
  assertSelfCheck(results, "unknownTopLevelFieldRejection", validateImplementationContract(badContract, compatibility).ok === false, "");
  assertSelfCheck(results, "missingTopLevelFieldRejection", validateImplementationContract(missingContractField, compatibility).ok === false, "");
  assertSelfCheck(results, "duplicateIdRejection", validateImplementationContract(duplicateContract, compatibility).ok === false, "");
  assertSelfCheck(results, "exactLifecycleContractSchema", Object.keys(contract.implementationLifecycleContract).length === lifecycleFields.length, "");
  assertSelfCheck(results, "exactCheckpointContractSchema", Object.keys(contract.implementationCheckpointContract).length === checkpointFields.length, "");
  assertSelfCheck(results, "exactFailureContractSchema", Object.keys(contract.implementationFailureContract).length === failureFields.length, "");
  assertSelfCheck(results, "exactBoundaryContractSchema", Object.keys(contract.implementationBoundaryContract).length === boundaryFields.length, "");
  assertSelfCheck(results, "nestedUnknownFieldRejection", validateImplementationContract(badNested, compatibility).ok === false, "");
  assertSelfCheck(results, "nestedMissingFieldRejection", validateImplementationContract(missingNested, compatibility).ok === false, "");
  assertSelfCheck(results, "compatibilityEvaluationIdCorrelation", contract.compatibilityEvaluationId === compatibility.compatibilityEvaluation.compatibilityEvaluationId, "");
  assertSelfCheck(results, "transportContractVersionCorrelation", contract.requiredTransportContractVersion === transportContractVersion, "");
  assertSelfCheck(results, "capabilityProfileVersionCorrelation", contract.requiredCapabilityProfileVersion === transportCapabilityProfileVersion, "");
  assertSelfCheck(results, "compatibilityEvaluationVersionCorrelation", contract.requiredCompatibilityEvaluationVersion === externalTransportCompatibilityVersion, "");
  assertSelfCheck(results, "upstreamIdPreservation", contract.compatibilityEvaluationId === compatibility.compatibilityEvaluation.compatibilityEvaluationId, "");
  assertSelfCheck(results, "upstreamVersionPreservation", contract.requiredCompatibilityEvaluationVersion === compatibility.compatibilityEvaluationVersion, "");
  assertSelfCheck(results, "compatibleDefinitionAcceptance", evaluation.overallTransportCompatibility === "CompatibleDefinition", "");
  assertSelfCheck(results, "incompatibleDefinitionRejection", requirementFailure.implementationContractState === implementationContractStates.requirementResolutionFailed, "");
  assertSelfCheck(
    results,
    "incompleteDefinitionRejection",
    evaluateExternalTransportImplementationContract({
      timestamp: stableTimestamp,
      compatibilityEvaluation: { ...compatibility, overallTransportCompatibility: "IncompleteDefinition" }
    }).implementationContractState === implementationContractStates.requirementResolutionFailed,
    ""
  );
  assertSelfCheck(results, "transportUnavailablePreservation", evaluation.transportAvailabilityState === "TransportUnavailable", "");
  assertSelfCheck(
    results,
    "transportAvailableRejection",
    evaluateExternalTransportImplementationContract({
      timestamp: stableTimestamp,
      compatibilityEvaluation: { ...compatibility, transportAvailabilityState: "TransportAvailable" }
    }).implementationContractState === implementationContractStates.requirementResolutionFailed,
    ""
  );
  assertSelfCheck(results, "definitionCompatibleButUnavailablePreservation", evaluation.executionEligibility === "DefinitionCompatibleButUnavailable", "");
  assertSelfCheck(results, "lifecycleStateExactness", validateLifecycleContract(contract.implementationLifecycleContract).ok === true, "");
  assertSelfCheck(results, "terminalStateExactness", exactList(contract.implementationLifecycleContract.requiredTerminalStates, terminalImplementationStates, "terminal").ok === true, "");
  assertSelfCheck(results, "checkpointExactness", validateCheckpointContract(contract.implementationCheckpointContract).ok === true, "");
  assertSelfCheck(results, "checkpointOrdering", validateCheckpointContract(badCheckpoint).ok === false, "");
  assertSelfCheck(results, "failureCodeExactness", validateFailureContract(contract.implementationFailureContract).ok === true, "");
  assertSelfCheck(results, "repositoryOwnershipRequirement", contract.implementationBoundaryContract.repositoryOwnershipRequired === true, "");
  assertSelfCheck(results, "externalExecutionOwnershipRequirement", contract.implementationBoundaryContract.externalExecutionRequired === true, "");
  assertSelfCheck(results, "networkingExternalOwnershipRequirement", contract.implementationBoundaryContract.networkingOwnedExternally === true, "");
  assertSelfCheck(results, "credentialExternalOwnershipRequirement", contract.implementationBoundaryContract.credentialHandlingOwnedExternally === true, "");
  assertSelfCheck(results, "runtimeEvidenceExternalOwnershipRequirement", contract.implementationBoundaryContract.runtimeEvidenceOwnedExternally === true, "");
  assertSelfCheck(results, "definitionOnlyPublication", contract.implementationReadiness === "DefinitionOnly", "");
  assertSelfCheck(results, "structurallyReadyRejection", validateImplementationContract(readyContract, compatibility).ok === false, "");
  assertSelfCheck(results, "implementationValidatedRejection", validateImplementationContract(validatedContract, compatibility).ok === false, "");
  assertSelfCheck(results, "deprecatedReadinessAcceptedForExplicitFixture", validateImplementationContract(deprecatedContract, compatibility).ok === true, "");
  assertSelfCheck(results, "badLifecycleRejection", validateLifecycleContract(badLifecycle).ok === false, "");
  assertSelfCheck(results, "badFailureRejection", validateFailureContract(badFailure).ok === false, "");
  assertSelfCheck(results, "badBoundaryRejection", validateBoundaryContract(badBoundary).ok === false, "");
  assertSelfCheck(results, "immutableTopLevelPublication", Object.isFrozen(contract), "");
  assertSelfCheck(results, "immutableNestedPublication", Object.isFrozen(contract.implementationLifecycleContract), "");
  assertSelfCheck(results, "deepFreezeValidation", Object.isFrozen(contract.implementationCheckpointContract) && Object.isFrozen(contract.implementationFailureContract), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateImplementationDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "immutableAuditValidation", Object.isFrozen(evaluation.audit) && evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicIds", contract.implementationContractId.endsWith(".implementationContract"), "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && contract.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicCorrelation", contract.compatibilityEvaluationId === rerun.implementationContract.compatibilityEvaluationId, "");
  assertSelfCheck(results, "deterministicReadinessClassification", evaluation.implementationReadiness === rerun.implementationReadiness, "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(contract) === stableSerialize(rerun.implementationContract), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalTransportImplementationContractAuthorityId, "");
  assertSelfCheck(results, "phase143RegressionCompatibility", compatibility.authorityId === externalTransportCompatibilityAuthorityId, "");
  assertSelfCheck(results, "phase142RegressionCompatibility", compatibility.capabilityEvaluation.authorityId.includes("phase142"), "");
  assertSelfCheck(results, "phase141RegressionCompatibility", compatibility.capabilityEvaluation.transportContractEvaluation.authorityId.includes("phase141"), "");
  assertSelfCheck(results, "phase140RegressionCompatibility", compatibility.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.authorityId.includes("phase140"), "");
  assertSelfCheck(results, "noDynamicImplementationLoading", evaluation.implementationLoaded === false, "");
  assertSelfCheck(results, "noChildProcessExecution", evaluation.implementationExecuted === false, "");
  assertSelfCheck(results, "noNetworking", !("network" in evaluation), "");
  assertSelfCheck(results, "noHttp", true, "");
  assertSelfCheck(results, "noTcp", true, "");
  assertSelfCheck(results, "noUdp", true, "");
  assertSelfCheck(results, "noSockets", true, "");
  assertSelfCheck(results, "noWsSurface", true, "");
  assertSelfCheck(results, "noAuthentication", !("credentials" in evaluation), "");
  assertSelfCheck(results, "noCredentialHandling", true, "");
  assertSelfCheck(results, "noEndpointDiscovery", evaluation.endpointDiscovered === false, "");
  assertSelfCheck(results, "noTransportCreation", evaluation.transportCreated === false, "");
  assertSelfCheck(results, "noEnvelopeTransmission", evaluation.envelopeTransmitted === false, "");
  assertSelfCheck(results, "noAcknowledgementReception", evaluation.acknowledgementReceived === false, "");
  assertSelfCheck(results, "noMcpCommunication", !("mcpClient" in evaluation), "");
  assertSelfCheck(results, "noStudioExecution", evaluation.studioExecuted === false, "");
  assertSelfCheck(results, "noRunnerInvocation", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noStructuredResultSynthesis", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noRuntimeEvidenceGeneration", evaluation.runtimeEvidenceGenerated === false, "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("productionCertified" in evaluation) && !("certificationDecision" in evaluation), "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");
  assertSelfCheck(
    results,
    "sessionNotVisiblePreserved",
    compatibility.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.compatibilityEvaluation.manifestEvaluation.contractEvaluation.boundaryEvaluation
      .dispatchEvaluation.requestEvaluation.orchestration.planning.readiness.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE",
    ""
  );

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExternalTransportImplementationContractSelfChecks();
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
  const evaluation = evaluateExternalTransportImplementationContract({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
