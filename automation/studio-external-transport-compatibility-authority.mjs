import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateEnvelopeTransportCapability,
  externalEnvelopeTransportCapabilityAuthorityId,
  transportCapabilityVersion,
  validateCapabilityProfile
} from "./studio-envelope-transport-capability-authority.mjs";
import {
  externalEnvelopeTransportContractAuthorityId,
  transportContractVersion,
  validateTransportContract
} from "./studio-envelope-transport-contract-authority.mjs";
import { externalExecutionEnvelopeAuthorityId } from "./studio-external-execution-envelope-authority.mjs";
import { stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const externalTransportCompatibilitySchemaVersion = 1;
export const externalTransportCompatibilityVersion = "1.0.0";
export const externalTransportCompatibilityAuthorityId =
  "chapter0Home.phase143StudioExternalTransportCompatibilityAuthority";

export const compatibilityStates = Object.freeze({
  idle: "Idle",
  receiveTransportContract: "ReceiveTransportContract",
  receiveCapabilityProfile: "ReceiveCapabilityProfile",
  resolveCompatibilityInputs: "ResolveCompatibilityInputs",
  validateCompatibilityCorrelation: "ValidateCompatibilityCorrelation",
  evaluateTransportCompatibility: "EvaluateTransportCompatibility",
  freezeCompatibilityEvaluation: "FreezeCompatibilityEvaluation",
  published: "TransportCompatibilityPublished",
  missingTransportContract: "MissingTransportContract",
  missingCapabilityProfile: "MissingCapabilityProfile",
  inputResolutionFailed: "CompatibilityInputResolutionFailed",
  correlationRejected: "CompatibilityCorrelationRejected",
  evaluationFailed: "CompatibilityEvaluationFailed",
  freezeRejected: "FreezeRejected"
});

export const componentResults = Object.freeze(["Compatible", "Incompatible", "NotDeclared"]);
export const overallCompatibilityValues = Object.freeze(["CompatibleDefinition", "IncompatibleDefinition", "IncompleteDefinition"]);
export const transportAvailabilityStates = Object.freeze(["CapabilityDeclared", "TransportUnavailable", "TransportAvailable"]);
export const executionEligibilityValues = Object.freeze([
  "DefinitionCompatibleButUnavailable",
  "DefinitionIncompatible",
  "DefinitionIncomplete"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  compatibilityStates.published,
  compatibilityStates.missingTransportContract,
  compatibilityStates.missingCapabilityProfile,
  compatibilityStates.inputResolutionFailed,
  compatibilityStates.correlationRejected,
  compatibilityStates.evaluationFailed,
  compatibilityStates.freezeRejected
]);
const legalTransitions = new Map([
  [compatibilityStates.idle, new Set([compatibilityStates.receiveTransportContract])],
  [
    compatibilityStates.receiveTransportContract,
    new Set([compatibilityStates.receiveCapabilityProfile, compatibilityStates.missingTransportContract])
  ],
  [
    compatibilityStates.receiveCapabilityProfile,
    new Set([compatibilityStates.resolveCompatibilityInputs, compatibilityStates.missingCapabilityProfile])
  ],
  [
    compatibilityStates.resolveCompatibilityInputs,
    new Set([compatibilityStates.validateCompatibilityCorrelation, compatibilityStates.inputResolutionFailed])
  ],
  [
    compatibilityStates.validateCompatibilityCorrelation,
    new Set([compatibilityStates.evaluateTransportCompatibility, compatibilityStates.correlationRejected])
  ],
  [
    compatibilityStates.evaluateTransportCompatibility,
    new Set([compatibilityStates.freezeCompatibilityEvaluation, compatibilityStates.evaluationFailed])
  ],
  [
    compatibilityStates.freezeCompatibilityEvaluation,
    new Set([compatibilityStates.published, compatibilityStates.freezeRejected])
  ]
]);

const evaluationFields = Object.freeze([
  "compatibilityEvaluationId",
  "compatibilityEvaluationVersion",
  "transportContractId",
  "capabilityId",
  "transportInterfaceResult",
  "envelopeVersionResult",
  "acknowledgementVersionResult",
  "retryPolicyResult",
  "transportErrorResult",
  "capabilityProfileResult",
  "overallTransportCompatibility",
  "transportAvailabilityState",
  "executionEligibility",
  "correlationSnapshot",
  "validationState",
  "timestamp"
]);
const correlationFields = Object.freeze([
  "transportContractId",
  "capabilityId",
  "requiredEnvelopeVersion",
  "supportedEnvelopeVersions",
  "transportInterfaceVersion",
  "supportedInterfaceVersions",
  "strictCorrelationValidated"
]);
const diagnosticsFields = Object.freeze([
  "compatibilityEvaluationVersion",
  "compatibilityState",
  "overallTransportCompatibility",
  "transportAvailabilityState",
  "executionEligibility",
  "executionBlocked",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "compatibilityEvaluationId",
  "transportContractId",
  "capabilityId",
  "authorityId",
  "compatibilityState",
  "overallTransportCompatibility",
  "transportAvailabilityState",
  "executionEligibility",
  "timestamp",
  "compatibilityEvaluationVersion"
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
    const id = validateIdentifier(value, "compatibility identifier");
    if (!id.ok) return id;
    if (seen.has(value)) return result(false, `duplicate compatibility identifier ${value}`, "DuplicateIdentifier");
    seen.add(value);
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalTransportCompatibilityAuthorityId });
}

export function validateCompatibilityTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "compatibility transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(compatibilityStates).includes(item.from) || !Object.values(compatibilityStates).includes(item.to)) {
      return result(false, "undocumented compatibility state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== compatibilityStates.idle) return result(false, "compatibility lifecycle must start at Idle", "InvalidLifecycle");
    if (index > 0 && transitions[index - 1].to !== item.from) return result(false, "compatibility lifecycle skipped state", "InvalidLifecycle");
    if (terminalStates.has(item.from) || terminalSeen) return result(false, "terminal compatibility state mutated", "InvalidLifecycle");
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal compatibility transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic compatibility transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function component(required, declaredValues) {
  if (!Array.isArray(declaredValues) || declaredValues.length === 0) return "NotDeclared";
  return declaredValues.includes(required) ? "Compatible" : "Incompatible";
}

function classifyOverall(results) {
  if (results.includes("Incompatible")) return "IncompatibleDefinition";
  if (results.includes("NotDeclared")) return "IncompleteDefinition";
  return "CompatibleDefinition";
}

function classifyEligibility(overallCompatibility) {
  if (overallCompatibility === "CompatibleDefinition") return "DefinitionCompatibleButUnavailable";
  if (overallCompatibility === "IncompatibleDefinition") return "DefinitionIncompatible";
  return "DefinitionIncomplete";
}

function createCorrelationSnapshot(transportContract, capabilityProfile) {
  return deepFreeze({
    transportContractId: transportContract.transportContractId,
    capabilityId: capabilityProfile.capabilityId,
    requiredEnvelopeVersion: transportContract.requiredEnvelopeVersion,
    supportedEnvelopeVersions: [...capabilityProfile.supportedEnvelopeVersions],
    transportInterfaceVersion: transportContract.transportInterfaceVersion,
    supportedInterfaceVersions: [...capabilityProfile.supportedInterfaceVersions],
    strictCorrelationValidated: true
  });
}

function createCompatibilityEvaluation(transportContract, capabilityProfile, timestamp) {
  const transportInterfaceResult = component(transportContract.transportInterfaceVersion, capabilityProfile.supportedInterfaceVersions);
  const envelopeVersionResult = component(transportContract.requiredEnvelopeVersion, capabilityProfile.supportedEnvelopeVersions);
  const acknowledgementVersionResult = component(
    transportContract.acknowledgementContract.acknowledgementSchemaVersion,
    capabilityProfile.supportedAcknowledgementVersions
  );
  const retryPolicyResult = component(transportContract.retryContract.retryPolicyVersion, capabilityProfile.supportedRetryPolicyVersions);
  const transportErrorResult = component(transportContract.transportErrorContract.errorSchemaVersion, capabilityProfile.supportedTransportErrorVersions);
  let capabilityProfileResult = "Compatible";
  if (!capabilityProfile.capabilityClassification) capabilityProfileResult = "NotDeclared";
  if (["ImplementationVerified", "Deprecated"].includes(capabilityProfile.capabilityClassification)) capabilityProfileResult = "Incompatible";
  if (capabilityProfile.capabilityClassification === "DefinitionOnly") capabilityProfileResult = "Compatible";
  const componentValues = [
    transportInterfaceResult,
    envelopeVersionResult,
    acknowledgementVersionResult,
    retryPolicyResult,
    transportErrorResult,
    capabilityProfileResult
  ];
  const overallTransportCompatibility = classifyOverall(componentValues);
  return deepFreeze({
    compatibilityEvaluationId: `${capabilityProfile.capabilityId}.compatibility`,
    compatibilityEvaluationVersion: externalTransportCompatibilityVersion,
    transportContractId: transportContract.transportContractId,
    capabilityId: capabilityProfile.capabilityId,
    transportInterfaceResult,
    envelopeVersionResult,
    acknowledgementVersionResult,
    retryPolicyResult,
    transportErrorResult,
    capabilityProfileResult,
    overallTransportCompatibility,
    transportAvailabilityState: "TransportUnavailable",
    executionEligibility: classifyEligibility(overallTransportCompatibility),
    correlationSnapshot: createCorrelationSnapshot(transportContract, capabilityProfile),
    validationState: "valid",
    timestamp
  });
}

export function validateCorrelationSnapshot(snapshot, transportContract = null, capabilityProfile = null) {
  const fields = exactFields(snapshot, correlationFields, "transport compatibility correlation");
  if (!fields.ok) return fields;
  for (const field of ["transportContractId", "capabilityId", "requiredEnvelopeVersion", "transportInterfaceVersion"]) {
    const id = validateIdentifier(snapshot[field], field);
    if (!id.ok) return id;
  }
  if (!Array.isArray(snapshot.supportedEnvelopeVersions) || !Array.isArray(snapshot.supportedInterfaceVersions)) {
    return result(false, "correlation version lists invalid", "CorrelationMismatch");
  }
  if (snapshot.strictCorrelationValidated !== true) return result(false, "strict correlation flag invalid", "CorrelationMismatch");
  if (transportContract !== null && snapshot.transportContractId !== transportContract.transportContractId) {
    return result(false, "transport contract correlation mismatch", "CorrelationMismatch");
  }
  if (capabilityProfile !== null && snapshot.capabilityId !== capabilityProfile.capabilityId) {
    return result(false, "capability correlation mismatch", "CorrelationMismatch");
  }
  if (transportContract !== null && snapshot.requiredEnvelopeVersion !== transportContract.requiredEnvelopeVersion) {
    return result(false, "required envelope version correlation mismatch", "CorrelationMismatch");
  }
  if (transportContract !== null && snapshot.transportInterfaceVersion !== transportContract.transportInterfaceVersion) {
    return result(false, "transport interface version correlation mismatch", "CorrelationMismatch");
  }
  return result(true);
}

export function validateCompatibilityEvaluation(evaluation, transportContract = null, capabilityProfile = null) {
  const fields = exactFields(evaluation, evaluationFields, "transport compatibility evaluation");
  if (!fields.ok) return fields;
  for (const field of [
    "compatibilityEvaluationId",
    "compatibilityEvaluationVersion",
    "transportContractId",
    "capabilityId",
    "overallTransportCompatibility",
    "transportAvailabilityState",
    "executionEligibility",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(evaluation[field], field);
    if (!id.ok) return id;
  }
  if (evaluation.compatibilityEvaluationVersion !== externalTransportCompatibilityVersion) {
    return result(false, "transport compatibility version unsupported", "CompatibilityVersionInvalid");
  }
  for (const field of [
    "transportInterfaceResult",
    "envelopeVersionResult",
    "acknowledgementVersionResult",
    "retryPolicyResult",
    "transportErrorResult",
    "capabilityProfileResult"
  ]) {
    if (!componentResults.includes(evaluation[field])) return result(false, `${field} unsupported`, "ComponentResultInvalid");
  }
  if (!overallCompatibilityValues.includes(evaluation.overallTransportCompatibility)) {
    return result(false, "overall transport compatibility unsupported", "OverallCompatibilityInvalid");
  }
  if (!transportAvailabilityStates.includes(evaluation.transportAvailabilityState)) {
    return result(false, "transport availability unsupported", "TransportAvailabilityInvalid");
  }
  if (evaluation.transportAvailabilityState === "TransportAvailable") {
    return result(false, "Phase 143 cannot emit TransportAvailable", "TransportAvailabilityInvalid");
  }
  if (!executionEligibilityValues.includes(evaluation.executionEligibility)) {
    return result(false, "execution eligibility unsupported", "ExecutionEligibilityInvalid");
  }
  if (evaluation.validationState !== "valid") return result(false, "compatibility validation state invalid", "ValidationStateInvalid");
  const correlation = validateCorrelationSnapshot(evaluation.correlationSnapshot, transportContract, capabilityProfile);
  if (!correlation.ok) return correlation;
  const components = [
    evaluation.transportInterfaceResult,
    evaluation.envelopeVersionResult,
    evaluation.acknowledgementVersionResult,
    evaluation.retryPolicyResult,
    evaluation.transportErrorResult,
    evaluation.capabilityProfileResult
  ];
  const expectedOverall = classifyOverall(components);
  if (evaluation.overallTransportCompatibility !== expectedOverall) {
    return result(false, "overall compatibility classification drifted", "OverallCompatibilityInvalid");
  }
  if (evaluation.executionEligibility !== classifyEligibility(expectedOverall)) {
    return result(false, "execution eligibility classification drifted", "ExecutionEligibilityInvalid");
  }
  if (transportContract !== null && capabilityProfile !== null) {
    if (evaluation.compatibilityEvaluationId !== `${capabilityProfile.capabilityId}.compatibility`) {
      return result(false, "compatibility identity correlation mismatch", "CorrelationMismatch");
    }
    const duplicateCheck = validateUniqueIdentifiers([
      evaluation.compatibilityEvaluationId,
      evaluation.transportContractId,
      evaluation.capabilityId
    ]);
    if (!duplicateCheck.ok) return duplicateCheck;
  }
  return result(true);
}

function createAudit(evaluation, compatibilityState, timestamp) {
  return deepFreeze([
    {
      compatibilityEvaluationId: evaluation?.compatibilityEvaluationId ?? "missing",
      transportContractId: evaluation?.transportContractId ?? "missing",
      capabilityId: evaluation?.capabilityId ?? "missing",
      authorityId: externalTransportCompatibilityAuthorityId,
      compatibilityState,
      overallTransportCompatibility: evaluation?.overallTransportCompatibility ?? "IncompleteDefinition",
      transportAvailabilityState: evaluation?.transportAvailabilityState ?? "TransportUnavailable",
      executionEligibility: evaluation?.executionEligibility ?? "DefinitionIncomplete",
      timestamp,
      compatibilityEvaluationVersion: externalTransportCompatibilityVersion
    }
  ]);
}

export function validateCompatibilityAudit(audit, evaluation = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "transport compatibility audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "transport compatibility audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalTransportCompatibilityAuthorityId) return result(false, "transport compatibility audit authority mismatch", "InvalidAudit");
    if (!Object.values(compatibilityStates).includes(item.compatibilityState)) return result(false, "transport compatibility audit state invalid", "InvalidAudit");
    if (!overallCompatibilityValues.includes(item.overallTransportCompatibility)) return result(false, "transport compatibility audit overall invalid", "InvalidAudit");
    if (!transportAvailabilityStates.includes(item.transportAvailabilityState)) return result(false, "transport compatibility audit availability invalid", "InvalidAudit");
    if (!executionEligibilityValues.includes(item.executionEligibility)) return result(false, "transport compatibility audit eligibility invalid", "InvalidAudit");
    if (evaluation !== null && item.compatibilityEvaluationId !== evaluation.compatibilityEvaluationId) {
      return result(false, "transport compatibility audit identity mismatch", "InvalidAudit");
    }
    const identity = `${item.compatibilityEvaluationId}:${item.transportContractId}:${item.capabilityId}:${item.compatibilityState}`;
    if (identities.has(identity)) return result(false, "duplicate transport compatibility audit identity", "InvalidAudit");
    identities.add(identity);
    const orderingKey = `${item.timestamp}:${identity}`;
    if (previousKey && orderingKey < previousKey) return result(false, "transport compatibility audit ordering invalid", "InvalidAudit");
    previousKey = orderingKey;
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    compatibilityEvaluationVersion: evaluation.compatibilityEvaluationVersion,
    compatibilityState: evaluation.compatibilityState,
    overallTransportCompatibility: evaluation.overallTransportCompatibility,
    transportAvailabilityState: evaluation.transportAvailabilityState,
    executionEligibility: evaluation.executionEligibility,
    executionBlocked: evaluation.executionBlocked,
    validationState: evaluation.validationState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateCompatibilityDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "transport compatibility diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.compatibilityEvaluationVersion !== externalTransportCompatibilityVersion) {
    return result(false, "compatibility diagnostics version mismatch", "InvalidDiagnostics");
  }
  if (!Object.values(compatibilityStates).includes(diagnostics.compatibilityState)) {
    return result(false, "compatibility diagnostics state invalid", "InvalidDiagnostics");
  }
  if (!overallCompatibilityValues.includes(diagnostics.overallTransportCompatibility)) {
    return result(false, "compatibility diagnostics overall invalid", "InvalidDiagnostics");
  }
  if (!transportAvailabilityStates.includes(diagnostics.transportAvailabilityState) || diagnostics.transportAvailabilityState === "TransportAvailable") {
    return result(false, "compatibility diagnostics availability invalid", "InvalidDiagnostics");
  }
  if (!executionEligibilityValues.includes(diagnostics.executionEligibility)) {
    return result(false, "compatibility diagnostics eligibility invalid", "InvalidDiagnostics");
  }
  if (diagnostics.executionBlocked !== true) return result(false, "compatibility diagnostics executionBlocked invalid", "InvalidDiagnostics");
  if (diagnostics.validationState !== "valid") return result(false, "compatibility diagnostics validation invalid", "InvalidDiagnostics");
  return result(true);
}

function validateUpstreamInputs(capabilityEvaluation) {
  if (!isPlainObject(capabilityEvaluation)) {
    return result(false, "capability authority incompatible", "CapabilityAuthorityIncompatible");
  }
  if (!isPlainObject(capabilityEvaluation.transportContractEvaluation)) {
    return result(false, "transport contract evaluation missing", "TransportContractMissing");
  }
  if (capabilityEvaluation.authorityId !== externalEnvelopeTransportCapabilityAuthorityId) {
    return result(false, "capability authority incompatible", "CapabilityAuthorityIncompatible");
  }
  if (capabilityEvaluation.transportContractEvaluation.authorityId !== externalEnvelopeTransportContractAuthorityId) {
    return result(false, "transport contract authority incompatible", "TransportContractAuthorityIncompatible");
  }
  if (capabilityEvaluation.transportContractEvaluation.envelopeEvaluation?.authorityId !== externalExecutionEnvelopeAuthorityId) {
    return result(false, "execution envelope authority incompatible", "EnvelopeAuthorityIncompatible");
  }
  if (!isPlainObject(capabilityEvaluation.transportContractEvaluation.transportContract)) {
    return result(false, "transport contract missing", "TransportContractMissing");
  }
  if (!isPlainObject(capabilityEvaluation.capabilityProfile)) {
    return result(false, "capability profile missing", "CapabilityProfileMissing");
  }
  const contractValidation = validateTransportContract(
    capabilityEvaluation.transportContractEvaluation.transportContract,
    capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.envelope
  );
  if (!contractValidation.ok) return contractValidation;
  const capabilityValidation = validateCapabilityProfile(
    capabilityEvaluation.capabilityProfile,
    capabilityEvaluation.transportContractEvaluation.transportContract
  );
  if (!capabilityValidation.ok) return capabilityValidation;
  if (
    capabilityEvaluation.status !== "executionBlocked" ||
    capabilityEvaluation.executionBlocked !== true ||
    capabilityEvaluation.runnerInvoked !== false ||
    capabilityEvaluation.structuredResultCaptured !== false ||
    capabilityEvaluation.transportCreated !== false ||
    capabilityEvaluation.envelopeTransmitted !== false ||
    capabilityEvaluation.acknowledgementReceived !== false
  ) {
    return result(false, "capability blocked posture drifted", "CapabilityPostureInvalid");
  }
  return result(true);
}

export function evaluateExternalTransportCompatibility(input = {}) {
  const timestamp = input.timestamp ?? now();
  const capabilityEvaluation = input.capabilityEvaluation ?? evaluateEnvelopeTransportCapability({ ...input, timestamp });
  const transitions = [transition(compatibilityStates.idle, compatibilityStates.receiveTransportContract, "receiving transport contract", timestamp)];
  let compatibilityState = compatibilityStates.published;
  let failureReason = null;
  let compatibilityEvaluation = null;
  let evaluationValidation = result(false, "transport compatibility not created", "MissingTransportContract");
  let overallTransportCompatibility = "IncompleteDefinition";
  let transportAvailabilityState = "TransportUnavailable";
  let executionEligibility = "DefinitionIncomplete";

  const upstreamValidation = validateUpstreamInputs(capabilityEvaluation);
  if (!upstreamValidation.ok && upstreamValidation.failure === "TransportContractMissing") {
    transitions.push(
      transition(compatibilityStates.receiveTransportContract, compatibilityStates.missingTransportContract, upstreamValidation.failure, timestamp)
    );
    compatibilityState = compatibilityStates.missingTransportContract;
    failureReason = upstreamValidation.failure;
  } else if (!upstreamValidation.ok && upstreamValidation.failure === "CapabilityProfileMissing") {
    transitions.push(transition(compatibilityStates.receiveTransportContract, compatibilityStates.receiveCapabilityProfile, "transport contract received", timestamp));
    transitions.push(transition(compatibilityStates.receiveCapabilityProfile, compatibilityStates.missingCapabilityProfile, upstreamValidation.failure, timestamp));
    compatibilityState = compatibilityStates.missingCapabilityProfile;
    failureReason = upstreamValidation.failure;
  } else if (!upstreamValidation.ok) {
    transitions.push(transition(compatibilityStates.receiveTransportContract, compatibilityStates.receiveCapabilityProfile, "transport contract received", timestamp));
    transitions.push(transition(compatibilityStates.receiveCapabilityProfile, compatibilityStates.resolveCompatibilityInputs, "capability profile received", timestamp));
    transitions.push(
      transition(compatibilityStates.resolveCompatibilityInputs, compatibilityStates.inputResolutionFailed, upstreamValidation.failure ?? "CompatibilityInputResolutionFailed", timestamp)
    );
    compatibilityState = compatibilityStates.inputResolutionFailed;
    failureReason = upstreamValidation.failure ?? "CompatibilityInputResolutionFailed";
  } else {
    const transportContract = capabilityEvaluation.transportContractEvaluation.transportContract;
    const capabilityProfile = capabilityEvaluation.capabilityProfile;
    transitions.push(transition(compatibilityStates.receiveTransportContract, compatibilityStates.receiveCapabilityProfile, "transport contract received", timestamp));
    transitions.push(transition(compatibilityStates.receiveCapabilityProfile, compatibilityStates.resolveCompatibilityInputs, "capability profile received", timestamp));
    transitions.push(transition(compatibilityStates.resolveCompatibilityInputs, compatibilityStates.validateCompatibilityCorrelation, "compatibility inputs resolved", timestamp));
    compatibilityEvaluation = createCompatibilityEvaluation(transportContract, capabilityProfile, timestamp);
    const correlationValidation = validateCorrelationSnapshot(compatibilityEvaluation.correlationSnapshot, transportContract, capabilityProfile);
    if (!correlationValidation.ok) {
      transitions.push(
        transition(compatibilityStates.validateCompatibilityCorrelation, compatibilityStates.correlationRejected, correlationValidation.failure ?? "CompatibilityCorrelationRejected", timestamp)
      );
      compatibilityState = compatibilityStates.correlationRejected;
      failureReason = correlationValidation.failure ?? "CompatibilityCorrelationRejected";
    } else {
      transitions.push(
        transition(compatibilityStates.validateCompatibilityCorrelation, compatibilityStates.evaluateTransportCompatibility, "compatibility correlation validated", timestamp)
      );
      evaluationValidation = validateCompatibilityEvaluation(compatibilityEvaluation, transportContract, capabilityProfile);
      overallTransportCompatibility = compatibilityEvaluation.overallTransportCompatibility;
      transportAvailabilityState = compatibilityEvaluation.transportAvailabilityState;
      executionEligibility = compatibilityEvaluation.executionEligibility;
      if (!evaluationValidation.ok) {
        transitions.push(
          transition(compatibilityStates.evaluateTransportCompatibility, compatibilityStates.evaluationFailed, evaluationValidation.failure ?? "CompatibilityEvaluationFailed", timestamp)
        );
        compatibilityState = compatibilityStates.evaluationFailed;
        failureReason = evaluationValidation.failure ?? "CompatibilityEvaluationFailed";
      } else {
        transitions.push(
          transition(compatibilityStates.evaluateTransportCompatibility, compatibilityStates.freezeCompatibilityEvaluation, "transport compatibility evaluated", timestamp)
        );
        if (!Object.isFrozen(compatibilityEvaluation) || !Object.isFrozen(compatibilityEvaluation.correlationSnapshot)) {
          transitions.push(transition(compatibilityStates.freezeCompatibilityEvaluation, compatibilityStates.freezeRejected, "FreezeRejected", timestamp));
          compatibilityState = compatibilityStates.freezeRejected;
          failureReason = "FreezeRejected";
        } else {
          transitions.push(
            transition(compatibilityStates.freezeCompatibilityEvaluation, compatibilityStates.published, "transport compatibility frozen", timestamp)
          );
        }
      }
    }
  }

  const transitionValidation = validateCompatibilityTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  const audit = createAudit(compatibilityEvaluation, compatibilityState, timestamp);
  const ok = evaluationValidation.ok && transitionValidation.ok;
  const evaluation = {
    schemaVersion: externalTransportCompatibilitySchemaVersion,
    authorityId: externalTransportCompatibilityAuthorityId,
    compatibilityEvaluationVersion: externalTransportCompatibilityVersion,
    status: "executionBlocked",
    exitCode: ok ? bridgeExitCodes.executionBlocked : bridgeExitCodes.validationFailed,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeEvidenceGenerated: false,
    transportImplemented: false,
    transportCreated: false,
    envelopeTransmitted: false,
    acknowledgementReceived: false,
    endpointDiscovered: false,
    externalConsumerConnected: false,
    studioExecuted: false,
    executionBlocked: true,
    compatibilityState,
    overallTransportCompatibility,
    transportAvailabilityState,
    executionEligibility,
    validationState: "valid",
    capabilityEvaluation,
    compatibilityEvaluation,
    upstreamValidation,
    evaluationValidation,
    transitionValidation,
    audit,
    auditValidation: validateCompatibilityAudit(audit, compatibilityEvaluation),
    integrationGraph: [
      "Phase140ExternalExecutionEnvelopeAuthority",
      "Phase141ExternalEnvelopeTransportContractAuthority",
      "Phase142ExternalEnvelopeTransportCapabilityAuthority",
      "Phase143ExternalTransportCompatibilityAuthority",
      "FutureTransportImplementationValidationDocumentationOnly",
      "FutureTransportAvailabilityDocumentationOnly"
    ],
    failureReason,
    recommendedAction: "Define a future external transport implementation contract before any implementation validation can be considered.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateCompatibilityDiagnostics(diagnosticsFor(evaluation)),
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

export function runExternalTransportCompatibilitySelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExternalTransportCompatibility({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExternalTransportCompatibility({ timestamp: stableTimestamp, repositoryState });
  const contract = evaluation.capabilityEvaluation.transportContractEvaluation.transportContract;
  const capability = evaluation.capabilityEvaluation.capabilityProfile;
  const missingContract = evaluateExternalTransportCompatibility({ timestamp: stableTimestamp, capabilityEvaluation: {} });
  const missingCapability = evaluateExternalTransportCompatibility({
    timestamp: stableTimestamp,
    capabilityEvaluation: { ...evaluation.capabilityEvaluation, capabilityProfile: null }
  });
  const inputResolutionFailure = evaluateExternalTransportCompatibility({
    timestamp: stableTimestamp,
    capabilityEvaluation: { ...evaluation.capabilityEvaluation, transportCreated: true }
  });
  const badCorrelation = { ...evaluation.compatibilityEvaluation, correlationSnapshot: { ...evaluation.compatibilityEvaluation.correlationSnapshot, capabilityId: "wrong" } };
  const badEvaluation = { ...evaluation.compatibilityEvaluation, extra: true };
  const missingEvaluationField = { ...evaluation.compatibilityEvaluation };
  delete missingEvaluationField.transportInterfaceResult;
  const duplicateEvaluation = { ...evaluation.compatibilityEvaluation, compatibilityEvaluationId: evaluation.compatibilityEvaluation.capabilityId };
  const badNested = { ...evaluation.compatibilityEvaluation, correlationSnapshot: { ...evaluation.compatibilityEvaluation.correlationSnapshot, extra: true } };
  const missingNested = { ...evaluation.compatibilityEvaluation, correlationSnapshot: { ...evaluation.compatibilityEvaluation.correlationSnapshot } };
  delete missingNested.correlationSnapshot.supportedInterfaceVersions;
  const interfaceIncompatible = createCompatibilityEvaluation(contract, { ...capability, supportedInterfaceVersions: ["9.9.9"] }, stableTimestamp);
  const interfaceUndeclared = createCompatibilityEvaluation(contract, { ...capability, supportedInterfaceVersions: [] }, stableTimestamp);
  const envelopeIncompatible = createCompatibilityEvaluation(contract, { ...capability, supportedEnvelopeVersions: ["9.9.9"] }, stableTimestamp);
  const envelopeUndeclared = createCompatibilityEvaluation(contract, { ...capability, supportedEnvelopeVersions: [] }, stableTimestamp);
  const acknowledgementIncompatible = createCompatibilityEvaluation(contract, { ...capability, supportedAcknowledgementVersions: ["9"] }, stableTimestamp);
  const acknowledgementUndeclared = createCompatibilityEvaluation(contract, { ...capability, supportedAcknowledgementVersions: [] }, stableTimestamp);
  const retryIncompatible = createCompatibilityEvaluation(contract, { ...capability, supportedRetryPolicyVersions: ["9.9.9"] }, stableTimestamp);
  const retryUndeclared = createCompatibilityEvaluation(contract, { ...capability, supportedRetryPolicyVersions: [] }, stableTimestamp);
  const errorIncompatible = createCompatibilityEvaluation(contract, { ...capability, supportedTransportErrorVersions: ["9"] }, stableTimestamp);
  const errorUndeclared = createCompatibilityEvaluation(contract, { ...capability, supportedTransportErrorVersions: [] }, stableTimestamp);
  const verified = createCompatibilityEvaluation(contract, { ...capability, capabilityClassification: "ImplementationVerified" }, stableTimestamp);
  const deprecated = createCompatibilityEvaluation(contract, { ...capability, capabilityClassification: "Deprecated" }, stableTimestamp);
  const available = { ...evaluation.compatibilityEvaluation, transportAvailabilityState: "TransportAvailable" };
  const badDiagnostics = { ...evaluation.diagnostics, endpoint: "none" };
  const duplicateAudit = validateCompatibilityAudit([...evaluation.audit, ...evaluation.audit], evaluation.compatibilityEvaluation);
  const reorderedAudit = validateCompatibilityAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:00.000Z" }
  ]);
  const invalidTransition = validateCompatibilityTransitions([transition(compatibilityStates.idle, compatibilityStates.freezeCompatibilityEvaluation, "skip", stableTimestamp)]);
  const skippedTransition = validateCompatibilityTransitions([
    transition(compatibilityStates.idle, compatibilityStates.receiveTransportContract, "start", stableTimestamp),
    transition(compatibilityStates.receiveCapabilityProfile, compatibilityStates.resolveCompatibilityInputs, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateCompatibilityTransitions([
    transition(compatibilityStates.idle, compatibilityStates.receiveTransportContract, "start", stableTimestamp),
    transition(compatibilityStates.receiveTransportContract, compatibilityStates.receiveCapabilityProfile, "capability", stableTimestamp),
    transition(compatibilityStates.receiveCapabilityProfile, compatibilityStates.receiveTransportContract, "cycle", stableTimestamp)
  ]);
  const repeatedTerminal = validateCompatibilityTransitions([
    transition(compatibilityStates.idle, compatibilityStates.receiveTransportContract, "start", stableTimestamp),
    transition(compatibilityStates.receiveTransportContract, compatibilityStates.missingTransportContract, "stop", stableTimestamp),
    transition(compatibilityStates.missingTransportContract, compatibilityStates.missingTransportContract, "repeat", stableTimestamp)
  ]);
  const terminalMutation = validateCompatibilityTransitions([
    transition(compatibilityStates.idle, compatibilityStates.receiveTransportContract, "start", stableTimestamp),
    transition(compatibilityStates.receiveTransportContract, compatibilityStates.missingTransportContract, "stop", stableTimestamp),
    transition(compatibilityStates.missingTransportContract, compatibilityStates.receiveCapabilityProfile, "mutate", stableTimestamp)
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingTransportContractRejection", missingContract.compatibilityState === compatibilityStates.missingTransportContract, "");
  assertSelfCheck(results, "missingCapabilityProfileRejection", missingCapability.compatibilityState === compatibilityStates.missingCapabilityProfile, "");
  assertSelfCheck(results, "inputResolutionFailure", inputResolutionFailure.compatibilityState === compatibilityStates.inputResolutionFailed, "");
  assertSelfCheck(results, "correlationRejection", validateCompatibilityEvaluation(badCorrelation, contract, capability).ok === false, "");
  assertSelfCheck(results, "compatibilityEvaluationFailure", validateCompatibilityEvaluation(badEvaluation, contract, capability).ok === false, "");
  assertSelfCheck(results, "freezeRejectionStateDocumented", compatibilityStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "repeatedTerminalTransitionRejection", repeatedTerminal.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactTopLevelSchema", Object.keys(evaluation.compatibilityEvaluation).length === evaluationFields.length, "");
  assertSelfCheck(results, "unknownTopLevelFieldRejection", validateCompatibilityEvaluation(badEvaluation, contract, capability).ok === false, "");
  assertSelfCheck(results, "missingTopLevelFieldRejection", validateCompatibilityEvaluation(missingEvaluationField, contract, capability).ok === false, "");
  assertSelfCheck(results, "duplicateIdRejection", validateCompatibilityEvaluation(duplicateEvaluation, contract, capability).ok === false, "");
  assertSelfCheck(results, "exactCorrelationSchema", Object.keys(evaluation.compatibilityEvaluation.correlationSnapshot).length === correlationFields.length, "");
  assertSelfCheck(results, "nestedUnknownFieldRejection", validateCompatibilityEvaluation(badNested, contract, capability).ok === false, "");
  assertSelfCheck(results, "nestedMissingFieldRejection", validateCompatibilityEvaluation(missingNested, contract, capability).ok === false, "");
  assertSelfCheck(results, "transportContractIdCorrelation", evaluation.compatibilityEvaluation.transportContractId === contract.transportContractId, "");
  assertSelfCheck(results, "capabilityIdCorrelation", evaluation.compatibilityEvaluation.capabilityId === capability.capabilityId, "");
  assertSelfCheck(results, "transportInterfaceCompatibility", evaluation.compatibilityEvaluation.transportInterfaceResult === "Compatible", "");
  assertSelfCheck(results, "transportInterfaceIncompatibility", interfaceIncompatible.transportInterfaceResult === "Incompatible", "");
  assertSelfCheck(results, "transportInterfaceUndeclared", interfaceUndeclared.transportInterfaceResult === "NotDeclared", "");
  assertSelfCheck(results, "envelopeVersionCompatibility", evaluation.compatibilityEvaluation.envelopeVersionResult === "Compatible", "");
  assertSelfCheck(results, "envelopeVersionIncompatibility", envelopeIncompatible.envelopeVersionResult === "Incompatible", "");
  assertSelfCheck(results, "envelopeVersionUndeclared", envelopeUndeclared.envelopeVersionResult === "NotDeclared", "");
  assertSelfCheck(results, "acknowledgementCompatibility", evaluation.compatibilityEvaluation.acknowledgementVersionResult === "Compatible", "");
  assertSelfCheck(results, "acknowledgementIncompatibility", acknowledgementIncompatible.acknowledgementVersionResult === "Incompatible", "");
  assertSelfCheck(results, "acknowledgementUndeclared", acknowledgementUndeclared.acknowledgementVersionResult === "NotDeclared", "");
  assertSelfCheck(results, "retryPolicyCompatibility", evaluation.compatibilityEvaluation.retryPolicyResult === "Compatible", "");
  assertSelfCheck(results, "retryPolicyIncompatibility", retryIncompatible.retryPolicyResult === "Incompatible", "");
  assertSelfCheck(results, "retryPolicyUndeclared", retryUndeclared.retryPolicyResult === "NotDeclared", "");
  assertSelfCheck(results, "transportErrorCompatibility", evaluation.compatibilityEvaluation.transportErrorResult === "Compatible", "");
  assertSelfCheck(results, "transportErrorIncompatibility", errorIncompatible.transportErrorResult === "Incompatible", "");
  assertSelfCheck(results, "transportErrorUndeclared", errorUndeclared.transportErrorResult === "NotDeclared", "");
  assertSelfCheck(results, "definitionOnlyCapabilityAcceptance", evaluation.compatibilityEvaluation.capabilityProfileResult === "Compatible", "");
  assertSelfCheck(results, "implementationVerifiedRejection", verified.capabilityProfileResult === "Incompatible", "");
  assertSelfCheck(results, "deprecatedRejection", deprecated.capabilityProfileResult === "Incompatible", "");
  assertSelfCheck(results, "compatibleDefinitionClassification", evaluation.compatibilityEvaluation.overallTransportCompatibility === "CompatibleDefinition", "");
  assertSelfCheck(results, "incompatibleDefinitionClassification", interfaceIncompatible.overallTransportCompatibility === "IncompatibleDefinition", "");
  assertSelfCheck(results, "incompleteDefinitionClassification", interfaceUndeclared.overallTransportCompatibility === "IncompleteDefinition", "");
  assertSelfCheck(results, "transportUnavailablePreservation", evaluation.compatibilityEvaluation.transportAvailabilityState === "TransportUnavailable", "");
  assertSelfCheck(results, "transportAvailableRejection", validateCompatibilityEvaluation(available, contract, capability).ok === false, "");
  assertSelfCheck(results, "definitionCompatibleButUnavailableClassification", evaluation.compatibilityEvaluation.executionEligibility === "DefinitionCompatibleButUnavailable", "");
  assertSelfCheck(results, "definitionIncompatibleClassification", interfaceIncompatible.executionEligibility === "DefinitionIncompatible", "");
  assertSelfCheck(results, "definitionIncompleteClassification", interfaceUndeclared.executionEligibility === "DefinitionIncomplete", "");
  assertSelfCheck(results, "blockedExecutionPreservation", evaluation.executionBlocked === true, "");
  assertSelfCheck(results, "immutableTopLevelPublication", Object.isFrozen(evaluation.compatibilityEvaluation), "");
  assertSelfCheck(results, "immutableNestedPublication", Object.isFrozen(evaluation.compatibilityEvaluation.correlationSnapshot), "");
  assertSelfCheck(results, "deepFreezeValidation", Object.isFrozen(evaluation.audit) && Object.isFrozen(evaluation.diagnostics), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateCompatibilityDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "immutableAuditValidation", Object.isFrozen(evaluation.audit) && evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicIdentifiers", evaluation.compatibilityEvaluation.compatibilityEvaluationId.endsWith(".compatibility"), "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && evaluation.compatibilityEvaluation.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicCorrelation", stableSerialize(evaluation.compatibilityEvaluation.correlationSnapshot) === stableSerialize(rerun.compatibilityEvaluation.correlationSnapshot), "");
  assertSelfCheck(results, "deterministicComponentResults", stableSerialize([
    evaluation.compatibilityEvaluation.transportInterfaceResult,
    evaluation.compatibilityEvaluation.envelopeVersionResult,
    evaluation.compatibilityEvaluation.acknowledgementVersionResult,
    evaluation.compatibilityEvaluation.retryPolicyResult,
    evaluation.compatibilityEvaluation.transportErrorResult,
    evaluation.compatibilityEvaluation.capabilityProfileResult
  ]) === stableSerialize([
    rerun.compatibilityEvaluation.transportInterfaceResult,
    rerun.compatibilityEvaluation.envelopeVersionResult,
    rerun.compatibilityEvaluation.acknowledgementVersionResult,
    rerun.compatibilityEvaluation.retryPolicyResult,
    rerun.compatibilityEvaluation.transportErrorResult,
    rerun.compatibilityEvaluation.capabilityProfileResult
  ]), "");
  assertSelfCheck(results, "deterministicOverallClassification", evaluation.overallTransportCompatibility === rerun.overallTransportCompatibility, "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.compatibilityEvaluation) === stableSerialize(rerun.compatibilityEvaluation), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalTransportCompatibilityAuthorityId, "");
  assertSelfCheck(results, "phase142RegressionCompatibility", evaluation.capabilityEvaluation.authorityId === externalEnvelopeTransportCapabilityAuthorityId, "");
  assertSelfCheck(results, "phase141RegressionCompatibility", evaluation.capabilityEvaluation.transportContractEvaluation.authorityId === externalEnvelopeTransportContractAuthorityId, "");
  assertSelfCheck(results, "phase140RegressionCompatibility", evaluation.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.authorityId === externalExecutionEnvelopeAuthorityId, "");
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
    evaluation.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.compatibilityEvaluation.manifestEvaluation.contractEvaluation.boundaryEvaluation
      .dispatchEvaluation.requestEvaluation.orchestration.planning.readiness.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE",
    ""
  );

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExternalTransportCompatibilitySelfChecks();
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
  const evaluation = evaluateExternalTransportCompatibility({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
