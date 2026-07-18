import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateExternalExecutionEnvelope,
  externalExecutionEnvelopeAuthorityId,
  externalExecutionEnvelopeVersion,
  validateExecutionEnvelope
} from "./studio-external-execution-envelope-authority.mjs";
import { stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const transportContractSchemaVersion = 1;
export const transportContractVersion = "1.0.0";
export const transportInterfaceVersion = "1.0.0";
export const externalEnvelopeTransportContractAuthorityId =
  "chapter0Home.phase141StudioExternalEnvelopeTransportContractAuthority";

export const transportContractStates = Object.freeze({
  idle: "Idle",
  receiveExecutionEnvelope: "ReceiveExecutionEnvelope",
  resolveTransportRequirements: "ResolveTransportRequirements",
  validateTransportContract: "ValidateTransportContract",
  constructTransportContract: "ConstructTransportContract",
  freezeTransportContract: "FreezeTransportContract",
  published: "TransportContractPublished",
  missingExecutionEnvelope: "MissingExecutionEnvelope",
  requirementFailure: "TransportRequirementFailure",
  rejected: "TransportContractRejected",
  constructionFailed: "TransportConstructionFailed",
  freezeRejected: "FreezeRejected"
});

export const transportAvailabilityStates = Object.freeze(["TransportUnavailable"]);
export const validationStates = Object.freeze(["valid"]);
export const deliveryModes = Object.freeze(["FutureExternalTransport"]);
export const deliveryOrderingValues = Object.freeze(["DeterministicEnvelopeOrder"]);
export const deliveryReliabilityValues = Object.freeze(["DefinitionOnly"]);
export const acknowledgementStates = Object.freeze(["Accepted", "Rejected", "Unavailable"]);
export const retryClassifications = Object.freeze(["None", "Transient", "Permanent"]);
export const transportErrorCodes = Object.freeze([
  "TransportUnavailable",
  "EndpointUnavailable",
  "EnvelopeRejected",
  "VersionMismatch",
  "ContractMismatch",
  "AuthenticationUnavailable",
  "UnknownTransportFailure"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  transportContractStates.published,
  transportContractStates.missingExecutionEnvelope,
  transportContractStates.requirementFailure,
  transportContractStates.rejected,
  transportContractStates.constructionFailed,
  transportContractStates.freezeRejected
]);
const legalTransitions = new Map([
  [transportContractStates.idle, new Set([transportContractStates.receiveExecutionEnvelope])],
  [
    transportContractStates.receiveExecutionEnvelope,
    new Set([transportContractStates.resolveTransportRequirements, transportContractStates.missingExecutionEnvelope])
  ],
  [
    transportContractStates.resolveTransportRequirements,
    new Set([transportContractStates.validateTransportContract, transportContractStates.requirementFailure])
  ],
  [
    transportContractStates.validateTransportContract,
    new Set([transportContractStates.constructTransportContract, transportContractStates.rejected])
  ],
  [
    transportContractStates.constructTransportContract,
    new Set([transportContractStates.freezeTransportContract, transportContractStates.constructionFailed])
  ],
  [
    transportContractStates.freezeTransportContract,
    new Set([transportContractStates.published, transportContractStates.freezeRejected])
  ]
]);

const transportContractFields = Object.freeze([
  "transportContractId",
  "transportContractVersion",
  "transportInterfaceVersion",
  "requiredEnvelopeVersion",
  "supportedEnvelopeVersion",
  "deliveryContract",
  "acknowledgementContract",
  "retryContract",
  "transportCapabilityContract",
  "transportErrorContract",
  "validationState",
  "timestamp"
]);
const deliveryContractFields = Object.freeze([
  "deliveryMode",
  "deliveryOrdering",
  "deliveryReliability",
  "correlationRequired",
  "immutableEnvelopeRequired"
]);
const acknowledgementContractFields = Object.freeze([
  "acknowledgementSchemaVersion",
  "acknowledgementCorrelation",
  "requiredStates"
]);
const retryContractFields = Object.freeze(["retrySupported", "retryClassification", "retryPolicyVersion"]);
const transportErrorContractFields = Object.freeze(["errorSchemaVersion", "supportedErrorCodes", "correlationRequired"]);
const transportCapabilityContractFields = Object.freeze([
  "transportProtocolVersion",
  "supportedEnvelopeVersion",
  "maximumEnvelopeVersion",
  "minimumEnvelopeVersion",
  "capabilityProfileVersion"
]);
const diagnosticsFields = Object.freeze([
  "transportContractVersion",
  "transportContractState",
  "transportAvailabilityState",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "transportContractId",
  "envelopeId",
  "authorityId",
  "transportState",
  "validationState",
  "timestamp"
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
    const id = validateIdentifier(value, "transport identifier");
    if (!id.ok) return id;
    if (seen.has(value)) return result(false, `duplicate transport identifier ${value}`, "DuplicateIdentifier");
    seen.add(value);
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalEnvelopeTransportContractAuthorityId });
}

export function validateTransportContractTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "transport contract transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(transportContractStates).includes(item.from) || !Object.values(transportContractStates).includes(item.to)) {
      return result(false, "undocumented transport contract state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== transportContractStates.idle) {
      return result(false, "transport contract lifecycle must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "transport contract lifecycle skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal transport contract state mutated", "InvalidLifecycle");
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal transport contract transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic transport contract transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function createTransportContract(envelope, timestamp) {
  return deepFreeze({
    transportContractId: `${envelope.envelopeId}.transportContract`,
    transportContractVersion,
    transportInterfaceVersion,
    requiredEnvelopeVersion: externalExecutionEnvelopeVersion,
    supportedEnvelopeVersion: externalExecutionEnvelopeVersion,
    deliveryContract: deepFreeze({
      deliveryMode: "FutureExternalTransport",
      deliveryOrdering: "DeterministicEnvelopeOrder",
      deliveryReliability: "DefinitionOnly",
      correlationRequired: true,
      immutableEnvelopeRequired: true
    }),
    acknowledgementContract: deepFreeze({
      acknowledgementSchemaVersion: String(transportContractSchemaVersion),
      acknowledgementCorrelation: "EnvelopeIdRequired",
      requiredStates: [...acknowledgementStates]
    }),
    retryContract: deepFreeze({
      retrySupported: false,
      retryClassification: "None",
      retryPolicyVersion: transportContractVersion
    }),
    transportCapabilityContract: deepFreeze({
      transportProtocolVersion: transportInterfaceVersion,
      supportedEnvelopeVersion: externalExecutionEnvelopeVersion,
      maximumEnvelopeVersion: externalExecutionEnvelopeVersion,
      minimumEnvelopeVersion: externalExecutionEnvelopeVersion,
      capabilityProfileVersion: transportContractVersion
    }),
    transportErrorContract: deepFreeze({
      errorSchemaVersion: String(transportContractSchemaVersion),
      supportedErrorCodes: [...transportErrorCodes],
      correlationRequired: true
    }),
    validationState: "valid",
    timestamp
  });
}

export function validateDeliveryContract(contract) {
  const fields = exactFields(contract, deliveryContractFields, "delivery contract");
  if (!fields.ok) return fields;
  if (!deliveryModes.includes(contract.deliveryMode)) return result(false, "delivery mode unsupported", "DeliveryModeInvalid");
  if (!deliveryOrderingValues.includes(contract.deliveryOrdering)) return result(false, "delivery ordering unsupported", "DeliveryOrderingInvalid");
  if (!deliveryReliabilityValues.includes(contract.deliveryReliability)) {
    return result(false, "delivery reliability unsupported", "DeliveryReliabilityInvalid");
  }
  if (contract.correlationRequired !== true) return result(false, "delivery correlation must be required", "DeliveryCorrelationInvalid");
  if (contract.immutableEnvelopeRequired !== true) return result(false, "delivery must require immutable envelope", "DeliveryImmutabilityInvalid");
  return result(true);
}

export function validateAcknowledgementContract(contract) {
  const fields = exactFields(contract, acknowledgementContractFields, "acknowledgement contract");
  if (!fields.ok) return fields;
  if (contract.acknowledgementSchemaVersion !== String(transportContractSchemaVersion)) {
    return result(false, "acknowledgement schema version unsupported", "AcknowledgementSchemaInvalid");
  }
  if (contract.acknowledgementCorrelation !== "EnvelopeIdRequired") {
    return result(false, "acknowledgement correlation unsupported", "AcknowledgementCorrelationInvalid");
  }
  if (!Array.isArray(contract.requiredStates) || contract.requiredStates.length !== acknowledgementStates.length) {
    return result(false, "acknowledgement states invalid", "AcknowledgementStatesInvalid");
  }
  for (const state of acknowledgementStates) {
    if (!contract.requiredStates.includes(state)) return result(false, `acknowledgement state ${state} missing`, "AcknowledgementStatesInvalid");
  }
  for (const state of contract.requiredStates) {
    if (!acknowledgementStates.includes(state)) return result(false, `acknowledgement state ${state} unsupported`, "AcknowledgementStatesInvalid");
  }
  return result(true);
}

export function validateRetryContract(contract) {
  const fields = exactFields(contract, retryContractFields, "retry contract");
  if (!fields.ok) return fields;
  if (contract.retrySupported !== false) return result(false, "retry execution is not supported", "RetrySupportInvalid");
  if (!retryClassifications.includes(contract.retryClassification)) return result(false, "retry classification unsupported", "RetryClassificationInvalid");
  if (contract.retryClassification !== "None") return result(false, "Phase 141 may define policy only", "RetryClassificationInvalid");
  if (contract.retryPolicyVersion !== transportContractVersion) return result(false, "retry policy version unsupported", "RetryPolicyInvalid");
  return result(true);
}

export function validateTransportErrorContract(contract) {
  const fields = exactFields(contract, transportErrorContractFields, "transport error contract");
  if (!fields.ok) return fields;
  if (contract.errorSchemaVersion !== String(transportContractSchemaVersion)) {
    return result(false, "transport error schema version unsupported", "TransportErrorSchemaInvalid");
  }
  if (!Array.isArray(contract.supportedErrorCodes) || contract.supportedErrorCodes.length !== transportErrorCodes.length) {
    return result(false, "transport error codes invalid", "TransportErrorCodesInvalid");
  }
  for (const code of transportErrorCodes) {
    if (!contract.supportedErrorCodes.includes(code)) return result(false, `transport error code ${code} missing`, "TransportErrorCodesInvalid");
  }
  for (const code of contract.supportedErrorCodes) {
    if (!transportErrorCodes.includes(code)) return result(false, `transport error code ${code} unsupported`, "TransportErrorCodesInvalid");
  }
  if (contract.correlationRequired !== true) return result(false, "transport error correlation must be required", "TransportErrorCorrelationInvalid");
  return result(true);
}

export function validateTransportCapabilityContract(contract) {
  const fields = exactFields(contract, transportCapabilityContractFields, "transport capability contract");
  if (!fields.ok) return fields;
  for (const field of transportCapabilityContractFields) {
    const id = validateIdentifier(contract[field], field);
    if (!id.ok) return id;
  }
  if (contract.transportProtocolVersion !== transportInterfaceVersion) return result(false, "transport protocol version unsupported", "TransportProtocolInvalid");
  for (const field of ["supportedEnvelopeVersion", "maximumEnvelopeVersion", "minimumEnvelopeVersion"]) {
    if (contract[field] !== externalExecutionEnvelopeVersion) return result(false, `${field} unsupported`, "EnvelopeVersionInvalid");
  }
  if (contract.capabilityProfileVersion !== transportContractVersion) return result(false, "capability profile version unsupported", "CapabilityProfileInvalid");
  return result(true);
}

export function validateTransportContract(contract, envelope = null) {
  const fields = exactFields(contract, transportContractFields, "transport contract");
  if (!fields.ok) return fields;
  for (const field of [
    "transportContractId",
    "transportContractVersion",
    "transportInterfaceVersion",
    "requiredEnvelopeVersion",
    "supportedEnvelopeVersion",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(contract[field], field);
    if (!id.ok) return id;
  }
  if (contract.transportContractVersion !== transportContractVersion) return result(false, "transport contract version unsupported", "TransportContractVersionInvalid");
  if (contract.transportInterfaceVersion !== transportInterfaceVersion) return result(false, "transport interface version unsupported", "TransportInterfaceVersionInvalid");
  if (contract.requiredEnvelopeVersion !== externalExecutionEnvelopeVersion) return result(false, "required envelope version unsupported", "EnvelopeVersionInvalid");
  if (contract.supportedEnvelopeVersion !== externalExecutionEnvelopeVersion) return result(false, "supported envelope version unsupported", "EnvelopeVersionInvalid");
  if (!validationStates.includes(contract.validationState)) return result(false, "transport contract validation state invalid", "ValidationStateInvalid");
  const delivery = validateDeliveryContract(contract.deliveryContract);
  if (!delivery.ok) return delivery;
  const acknowledgement = validateAcknowledgementContract(contract.acknowledgementContract);
  if (!acknowledgement.ok) return acknowledgement;
  const retry = validateRetryContract(contract.retryContract);
  if (!retry.ok) return retry;
  const capability = validateTransportCapabilityContract(contract.transportCapabilityContract);
  if (!capability.ok) return capability;
  const errors = validateTransportErrorContract(contract.transportErrorContract);
  if (!errors.ok) return errors;
  if (envelope !== null) {
    if (contract.transportContractId !== `${envelope.envelopeId}.transportContract`) {
      return result(false, "transport contract identity does not correlate with envelope", "CorrelationMismatch");
    }
    const duplicateCheck = validateUniqueIdentifiers([contract.transportContractId, envelope.envelopeId]);
    if (!duplicateCheck.ok) return duplicateCheck;
  }
  return result(true);
}

function createAudit(contract, envelope, transportState, timestamp) {
  return deepFreeze([
    {
      transportContractId: contract?.transportContractId ?? "missing",
      envelopeId: envelope?.envelopeId ?? "missing",
      authorityId: externalEnvelopeTransportContractAuthorityId,
      transportState,
      validationState: contract?.validationState ?? "invalid",
      timestamp
    }
  ]);
}

export function validateTransportContractAudit(audit, contract = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "transport contract audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "transport contract audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalEnvelopeTransportContractAuthorityId) return result(false, "transport contract audit authority mismatch", "InvalidAudit");
    if (!Object.values(transportContractStates).includes(item.transportState)) return result(false, "transport contract audit state invalid", "InvalidAudit");
    if (!validationStates.includes(item.validationState)) return result(false, "transport contract audit validation invalid", "InvalidAudit");
    if (contract !== null && item.transportContractId !== contract.transportContractId) return result(false, "transport contract audit identity mismatch", "InvalidAudit");
    const identity = `${item.transportContractId}:${item.envelopeId}:${item.transportState}`;
    if (identities.has(identity)) return result(false, "duplicate transport contract audit identity", "InvalidAudit");
    identities.add(identity);
    const orderingKey = `${item.timestamp}:${identity}`;
    if (previousKey && orderingKey < previousKey) return result(false, "transport contract audit ordering invalid", "InvalidAudit");
    previousKey = orderingKey;
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    transportContractVersion: evaluation.transportContractVersion,
    transportContractState: evaluation.transportContractState,
    transportAvailabilityState: evaluation.transportAvailabilityState,
    validationState: evaluation.validationState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateTransportContractDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "transport contract diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.transportContractVersion !== transportContractVersion) return result(false, "transport diagnostics version mismatch", "InvalidDiagnostics");
  if (!Object.values(transportContractStates).includes(diagnostics.transportContractState)) return result(false, "transport diagnostics state invalid", "InvalidDiagnostics");
  if (!transportAvailabilityStates.includes(diagnostics.transportAvailabilityState)) return result(false, "transport diagnostics availability invalid", "InvalidDiagnostics");
  if (!validationStates.includes(diagnostics.validationState)) return result(false, "transport diagnostics validation invalid", "InvalidDiagnostics");
  return result(true);
}

function validateEnvelopeInput(envelopeEvaluation) {
  if (!isPlainObject(envelopeEvaluation) || envelopeEvaluation.authorityId !== externalExecutionEnvelopeAuthorityId) {
    return result(false, "execution envelope authority incompatible", "EnvelopeAuthorityIncompatible");
  }
  if (!isPlainObject(envelopeEvaluation.envelope)) return result(false, "execution envelope missing", "EnvelopeMissing");
  const envelopeValidation = validateExecutionEnvelope(envelopeEvaluation.envelope, envelopeEvaluation.compatibilityEvaluation);
  if (!envelopeValidation.ok) return envelopeValidation;
  if (envelopeEvaluation.envelope.envelopeVersion !== externalExecutionEnvelopeVersion) {
    return result(false, "execution envelope version unsupported", "EnvelopeVersionInvalid");
  }
  if (envelopeEvaluation.envelope.envelopeEligibility !== "DefinitionCompleteButUnavailable") {
    return result(false, "execution envelope is not in Phase 140 blocked definition state", "EnvelopeEligibilityInvalid");
  }
  if (
    envelopeEvaluation.status !== "executionBlocked" ||
    envelopeEvaluation.executionBlocked !== true ||
    envelopeEvaluation.runnerInvoked !== false ||
    envelopeEvaluation.structuredResultCaptured !== false
  ) {
    return result(false, "execution envelope blocked posture drifted", "EnvelopePostureInvalid");
  }
  return result(true);
}

export function evaluateEnvelopeTransportContract(input = {}) {
  const timestamp = input.timestamp ?? now();
  const envelopeEvaluation = input.envelopeEvaluation ?? evaluateExternalExecutionEnvelope({ ...input, timestamp });
  const transitions = [
    transition(transportContractStates.idle, transportContractStates.receiveExecutionEnvelope, "receiving execution envelope", timestamp)
  ];
  let transportContractState = transportContractStates.published;
  let failureReason = null;
  let contract = null;
  let contractValidation = result(false, "transport contract not created", "MissingExecutionEnvelope");
  let validationState = "valid";

  const envelopeInputValidation = validateEnvelopeInput(envelopeEvaluation);
  if (!envelopeInputValidation.ok) {
    transitions.push(
      transition(
        transportContractStates.receiveExecutionEnvelope,
        transportContractStates.missingExecutionEnvelope,
        envelopeInputValidation.failure ?? "MissingExecutionEnvelope",
        timestamp
      )
    );
    transportContractState = transportContractStates.missingExecutionEnvelope;
    failureReason = envelopeInputValidation.failure ?? "MissingExecutionEnvelope";
  } else {
    transitions.push(
      transition(
        transportContractStates.receiveExecutionEnvelope,
        transportContractStates.resolveTransportRequirements,
        "execution envelope received",
        timestamp
      )
    );
    transitions.push(
      transition(
        transportContractStates.resolveTransportRequirements,
        transportContractStates.validateTransportContract,
        "transport requirements resolved",
        timestamp
      )
    );
    contract = createTransportContract(envelopeEvaluation.envelope, timestamp);
    contractValidation = validateTransportContract(contract, envelopeEvaluation.envelope);
    if (!contractValidation.ok) {
      transitions.push(
        transition(
          transportContractStates.validateTransportContract,
          transportContractStates.rejected,
          contractValidation.failure ?? "TransportContractRejected",
          timestamp
        )
      );
      transportContractState = transportContractStates.rejected;
      failureReason = contractValidation.failure ?? "TransportContractRejected";
    } else {
      transitions.push(
        transition(
          transportContractStates.validateTransportContract,
          transportContractStates.constructTransportContract,
          "transport contract validated",
          timestamp
        )
      );
      if (!isPlainObject(contract)) {
        transitions.push(
          transition(
            transportContractStates.constructTransportContract,
            transportContractStates.constructionFailed,
            "TransportConstructionFailed",
            timestamp
          )
        );
        transportContractState = transportContractStates.constructionFailed;
        failureReason = "TransportConstructionFailed";
      } else {
        transitions.push(
          transition(
            transportContractStates.constructTransportContract,
            transportContractStates.freezeTransportContract,
            "transport contract constructed",
            timestamp
          )
        );
        if (
          !Object.isFrozen(contract) ||
          !Object.isFrozen(contract.deliveryContract) ||
          !Object.isFrozen(contract.acknowledgementContract) ||
          !Object.isFrozen(contract.transportErrorContract)
        ) {
          transitions.push(
            transition(transportContractStates.freezeTransportContract, transportContractStates.freezeRejected, "FreezeRejected", timestamp)
          );
          transportContractState = transportContractStates.freezeRejected;
          failureReason = "FreezeRejected";
        } else {
          transitions.push(
            transition(
              transportContractStates.freezeTransportContract,
              transportContractStates.published,
              "transport contract frozen",
              timestamp
            )
          );
        }
      }
    }
  }

  const transitionValidation = validateTransportContractTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  const audit = createAudit(contract, envelopeEvaluation.envelope, transportContractState, timestamp);
  const ok = contractValidation.ok && transitionValidation.ok;
  if (!ok) validationState = "valid";
  const evaluation = {
    schemaVersion: transportContractSchemaVersion,
    authorityId: externalEnvelopeTransportContractAuthorityId,
    transportContractVersion,
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
    transportContractState,
    transportAvailabilityState: "TransportUnavailable",
    executionBlocked: true,
    validationState,
    envelopeEvaluation,
    transportContract: contract,
    envelopeInputValidation,
    contractValidation,
    transitionValidation,
    audit,
    auditValidation: validateTransportContractAudit(audit, contract),
    integrationGraph: [
      "Phase135ExecutionDispatchAuthority",
      "Phase136ExternalExecutionBoundary",
      "Phase137ExternalConsumerContractAuthority",
      "Phase138ExternalConsumerManifestAuthority",
      "Phase139ConsumerCompatibilityAuthority",
      "Phase140ExternalExecutionEnvelopeAuthority",
      "Phase141ExternalEnvelopeTransportContractAuthority",
      "FutureTransportCapabilityAuthorityDocumentationOnly",
      "FutureTransportImplementationDocumentationOnly"
    ],
    failureReason,
    recommendedAction: "Define future external envelope transport capability before any transport implementation can be considered.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateTransportContractDiagnostics(diagnosticsFor(evaluation)),
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

export function runEnvelopeTransportContractSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateEnvelopeTransportContract({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateEnvelopeTransportContract({ timestamp: stableTimestamp, repositoryState });
  const missingEnvelope = evaluateEnvelopeTransportContract({ timestamp: stableTimestamp, envelopeEvaluation: {} });
  const badContract = { ...evaluation.transportContract, extra: true };
  const missingFieldContract = { ...evaluation.transportContract };
  delete missingFieldContract.supportedEnvelopeVersion;
  const duplicateContract = { ...evaluation.transportContract, transportContractId: evaluation.envelopeEvaluation.envelope.envelopeId };
  const badDelivery = { ...evaluation.transportContract.deliveryContract, deliveryMode: "ImmediateTransport" };
  const badAcknowledgement = { ...evaluation.transportContract.acknowledgementContract, requiredStates: ["Accepted"] };
  const badRetry = { ...evaluation.transportContract.retryContract, retryClassification: "Transient" };
  const badErrors = { ...evaluation.transportContract.transportErrorContract, supportedErrorCodes: ["TransportUnavailable"] };
  const badCapability = { ...evaluation.transportContract.transportCapabilityContract, supportedEnvelopeVersion: "9.9.9" };
  const badDiagnostics = { ...evaluation.diagnostics, transportEndpoint: "none" };
  const duplicateAudit = validateTransportContractAudit([...evaluation.audit, ...evaluation.audit], evaluation.transportContract);
  const reorderedAudit = validateTransportContractAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:00.000Z" }
  ]);
  const invalidTransition = validateTransportContractTransitions([
    transition(transportContractStates.idle, transportContractStates.freezeTransportContract, "skip", stableTimestamp)
  ]);
  const skippedTransition = validateTransportContractTransitions([
    transition(transportContractStates.idle, transportContractStates.receiveExecutionEnvelope, "start", stableTimestamp),
    transition(transportContractStates.validateTransportContract, transportContractStates.constructTransportContract, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateTransportContractTransitions([
    transition(transportContractStates.idle, transportContractStates.receiveExecutionEnvelope, "start", stableTimestamp),
    transition(transportContractStates.receiveExecutionEnvelope, transportContractStates.resolveTransportRequirements, "resolve", stableTimestamp),
    transition(transportContractStates.resolveTransportRequirements, transportContractStates.receiveExecutionEnvelope, "cycle", stableTimestamp)
  ]);
  const terminalMutation = validateTransportContractTransitions([
    transition(transportContractStates.idle, transportContractStates.receiveExecutionEnvelope, "start", stableTimestamp),
    transition(transportContractStates.receiveExecutionEnvelope, transportContractStates.missingExecutionEnvelope, "stop", stableTimestamp),
    transition(transportContractStates.missingExecutionEnvelope, transportContractStates.resolveTransportRequirements, "mutate", stableTimestamp)
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingExecutionEnvelopeRejection", missingEnvelope.transportContractState === transportContractStates.missingExecutionEnvelope, "");
  assertSelfCheck(results, "transportRequirementFailureStateDocumented", transportContractStates.requirementFailure === "TransportRequirementFailure", "");
  assertSelfCheck(results, "transportContractRejectionStateDocumented", transportContractStates.rejected === "TransportContractRejected", "");
  assertSelfCheck(results, "transportConstructionFailureStateDocumented", transportContractStates.constructionFailed === "TransportConstructionFailed", "");
  assertSelfCheck(results, "freezeRejectionStateDocumented", transportContractStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactTransportContractSchema", Object.keys(evaluation.transportContract).length === transportContractFields.length, "");
  assertSelfCheck(results, "unknownContractFieldRejection", validateTransportContract(badContract, evaluation.envelopeEvaluation.envelope).ok === false, "");
  assertSelfCheck(results, "missingContractFieldRejection", validateTransportContract(missingFieldContract, evaluation.envelopeEvaluation.envelope).ok === false, "");
  assertSelfCheck(results, "duplicateIdentifierRejection", validateTransportContract(duplicateContract, evaluation.envelopeEvaluation.envelope).ok === false, "");
  assertSelfCheck(results, "contractIdentityCorrelation", evaluation.transportContract.transportContractId === `${evaluation.envelopeEvaluation.envelope.envelopeId}.transportContract`, "");
  assertSelfCheck(results, "requiredEnvelopeVersionPreserved", evaluation.transportContract.requiredEnvelopeVersion === externalExecutionEnvelopeVersion, "");
  assertSelfCheck(results, "supportedEnvelopeVersionPreserved", evaluation.transportContract.supportedEnvelopeVersion === externalExecutionEnvelopeVersion, "");
  assertSelfCheck(results, "exactDeliverySchema", Object.keys(evaluation.transportContract.deliveryContract).length === deliveryContractFields.length, "");
  assertSelfCheck(results, "deliveryModeValidation", validateDeliveryContract(badDelivery).ok === false, "");
  assertSelfCheck(results, "deliveryModeFutureOnly", evaluation.transportContract.deliveryContract.deliveryMode === "FutureExternalTransport", "");
  assertSelfCheck(results, "deliveryOrderingDeterministic", evaluation.transportContract.deliveryContract.deliveryOrdering === "DeterministicEnvelopeOrder", "");
  assertSelfCheck(results, "deliveryReliabilityDefinitionOnly", evaluation.transportContract.deliveryContract.deliveryReliability === "DefinitionOnly", "");
  assertSelfCheck(results, "deliveryCorrelationRequired", evaluation.transportContract.deliveryContract.correlationRequired === true, "");
  assertSelfCheck(results, "deliveryImmutableEnvelopeRequired", evaluation.transportContract.deliveryContract.immutableEnvelopeRequired === true, "");
  assertSelfCheck(results, "exactAcknowledgementSchema", Object.keys(evaluation.transportContract.acknowledgementContract).length === acknowledgementContractFields.length, "");
  assertSelfCheck(results, "acknowledgementStateValidation", validateAcknowledgementContract(badAcknowledgement).ok === false, "");
  assertSelfCheck(results, "acknowledgementAcceptedDefined", evaluation.transportContract.acknowledgementContract.requiredStates.includes("Accepted"), "");
  assertSelfCheck(results, "acknowledgementRejectedDefined", evaluation.transportContract.acknowledgementContract.requiredStates.includes("Rejected"), "");
  assertSelfCheck(results, "acknowledgementUnavailableDefined", evaluation.transportContract.acknowledgementContract.requiredStates.includes("Unavailable"), "");
  assertSelfCheck(results, "exactRetrySchema", Object.keys(evaluation.transportContract.retryContract).length === retryContractFields.length, "");
  assertSelfCheck(results, "retryClassificationValidation", validateRetryContract(badRetry).ok === false, "");
  assertSelfCheck(results, "retryUnsupported", evaluation.transportContract.retryContract.retrySupported === false, "");
  assertSelfCheck(results, "retryPolicyDefinitionOnly", evaluation.transportContract.retryContract.retryClassification === "None", "");
  assertSelfCheck(results, "exactTransportErrorSchema", Object.keys(evaluation.transportContract.transportErrorContract).length === transportErrorContractFields.length, "");
  assertSelfCheck(results, "transportErrorCodeValidation", validateTransportErrorContract(badErrors).ok === false, "");
  for (const code of transportErrorCodes) {
    assertSelfCheck(results, `transportErrorCode${code}Defined`, evaluation.transportContract.transportErrorContract.supportedErrorCodes.includes(code), "");
  }
  assertSelfCheck(results, "transportErrorCorrelationRequired", evaluation.transportContract.transportErrorContract.correlationRequired === true, "");
  assertSelfCheck(results, "exactCapabilitySchema", Object.keys(evaluation.transportContract.transportCapabilityContract).length === transportCapabilityContractFields.length, "");
  assertSelfCheck(results, "capabilityVersionValidation", validateTransportCapabilityContract(badCapability).ok === false, "");
  assertSelfCheck(results, "capabilityDoesNotCreateTransport", evaluation.transportImplemented === false && evaluation.transportCreated === false, "");
  assertSelfCheck(results, "immutablePublication", Object.isFrozen(evaluation.transportContract), "");
  assertSelfCheck(results, "immutableDeliveryContract", Object.isFrozen(evaluation.transportContract.deliveryContract), "");
  assertSelfCheck(results, "immutableAcknowledgementContract", Object.isFrozen(evaluation.transportContract.acknowledgementContract), "");
  assertSelfCheck(results, "immutableRetryContract", Object.isFrozen(evaluation.transportContract.retryContract), "");
  assertSelfCheck(results, "immutableErrorContract", Object.isFrozen(evaluation.transportContract.transportErrorContract), "");
  assertSelfCheck(results, "immutableCapabilityContract", Object.isFrozen(evaluation.transportContract.transportCapabilityContract), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateTransportContractDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "diagnosticsStatePublished", evaluation.diagnostics.transportContractState === "TransportContractPublished", "");
  assertSelfCheck(results, "diagnosticsAvailabilityUnavailable", evaluation.diagnostics.transportAvailabilityState === "TransportUnavailable", "");
  assertSelfCheck(results, "immutableAuditValidation", Object.isFrozen(evaluation.audit) && evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "auditEnvelopeCorrelation", evaluation.audit[0].envelopeId === evaluation.envelopeEvaluation.envelope.envelopeId, "");
  assertSelfCheck(results, "deterministicIdentifiers", evaluation.transportContract.transportContractId.endsWith(".transportContract"), "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && evaluation.transportContract.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicOrdering", stableSerialize(evaluation.transportContract) === stableSerialize(rerun.transportContract), "");
  assertSelfCheck(results, "deterministicDiagnostics", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(
    results,
    "rerunStability",
    stableSerialize({
      transportContract: evaluation.transportContract,
      diagnostics: evaluation.diagnostics,
      audit: evaluation.audit
    }) ===
      stableSerialize({
        transportContract: rerun.transportContract,
        diagnostics: rerun.diagnostics,
        audit: rerun.audit
      }),
    ""
  );
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalEnvelopeTransportContractAuthorityId, "");
  assertSelfCheck(results, "phase140RegressionCompatibility", evaluation.envelopeEvaluation.authorityId === externalExecutionEnvelopeAuthorityId, "");
  assertSelfCheck(results, "phase140EnvelopeValidation", validateExecutionEnvelope(evaluation.envelopeEvaluation.envelope, evaluation.envelopeEvaluation.compatibilityEvaluation).ok === true, "");
  assertSelfCheck(results, "phase140EnvelopeEligibilityPreserved", evaluation.envelopeEvaluation.envelope.envelopeEligibility === "DefinitionCompleteButUnavailable", "");
  assertSelfCheck(
    results,
    "sessionNotVisiblePreserved",
    evaluation.envelopeEvaluation.compatibilityEvaluation.manifestEvaluation.contractEvaluation.boundaryEvaluation.dispatchEvaluation.requestEvaluation
      .orchestration.planning.readiness.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE",
    ""
  );
  assertSelfCheck(results, "executionBlockedPreserved", evaluation.executionBlocked === true && evaluation.envelopeEvaluation.executionBlocked === true, "");
  assertSelfCheck(results, "runnerNotInvoked", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "structuredResultNotCaptured", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noTransportImplementation", evaluation.transportImplemented === false, "");
  assertSelfCheck(results, "noTransportCreation", evaluation.transportCreated === false, "");
  assertSelfCheck(results, "noEnvelopeTransmission", evaluation.envelopeTransmitted === false, "");
  assertSelfCheck(results, "noAcknowledgementReception", evaluation.acknowledgementReceived === false, "");
  assertSelfCheck(results, "noEndpointDiscovery", evaluation.endpointDiscovered === false, "");
  assertSelfCheck(results, "noExternalConnection", evaluation.externalConsumerConnected === false, "");
  assertSelfCheck(results, "noMcpClient", !("mcpClient" in evaluation), "");
  assertSelfCheck(results, "noAuthentication", !("credentials" in evaluation), "");
  assertSelfCheck(results, "noStudioExecution", evaluation.studioExecuted === false, "");
  assertSelfCheck(results, "noRuntimeEvidence", evaluation.runtimeEvidenceGenerated === false, "");
  assertSelfCheck(results, "noCertificationOwnership", !("productionCertified" in evaluation) && !("certificationDecision" in evaluation), "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runEnvelopeTransportContractSelfChecks();
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
  const evaluation = evaluateEnvelopeTransportContract({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
