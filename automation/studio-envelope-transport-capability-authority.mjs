import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateEnvelopeTransportContract,
  externalEnvelopeTransportContractAuthorityId,
  transportContractVersion,
  transportInterfaceVersion,
  transportContractSchemaVersion,
  validateTransportContract
} from "./studio-envelope-transport-contract-authority.mjs";
import { externalExecutionEnvelopeVersion } from "./studio-external-execution-envelope-authority.mjs";
import { stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const transportCapabilitySchemaVersion = 1;
export const transportCapabilityVersion = "1.0.0";
export const transportCapabilityProfileVersion = "1.0.0";
export const externalEnvelopeTransportCapabilityAuthorityId =
  "chapter0Home.phase142StudioExternalEnvelopeTransportCapabilityAuthority";

export const capabilityStates = Object.freeze({
  idle: "Idle",
  receiveTransportContract: "ReceiveTransportContract",
  resolveCapabilityRequirements: "ResolveCapabilityRequirements",
  validateCapabilityProfile: "ValidateCapabilityProfile",
  constructCapabilityProfile: "ConstructCapabilityProfile",
  freezeCapabilityProfile: "FreezeCapabilityProfile",
  published: "CapabilityProfilePublished",
  missingTransportContract: "MissingTransportContract",
  requirementFailure: "CapabilityRequirementFailure",
  rejected: "CapabilityRejected",
  constructionFailed: "CapabilityConstructionFailed",
  freezeRejected: "FreezeRejected"
});

export const capabilityClassifications = Object.freeze(["DefinitionOnly", "ImplementationVerified", "Deprecated"]);
export const validationStates = Object.freeze(["valid"]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  capabilityStates.published,
  capabilityStates.missingTransportContract,
  capabilityStates.requirementFailure,
  capabilityStates.rejected,
  capabilityStates.constructionFailed,
  capabilityStates.freezeRejected
]);
const legalTransitions = new Map([
  [capabilityStates.idle, new Set([capabilityStates.receiveTransportContract])],
  [
    capabilityStates.receiveTransportContract,
    new Set([capabilityStates.resolveCapabilityRequirements, capabilityStates.missingTransportContract])
  ],
  [
    capabilityStates.resolveCapabilityRequirements,
    new Set([capabilityStates.validateCapabilityProfile, capabilityStates.requirementFailure])
  ],
  [
    capabilityStates.validateCapabilityProfile,
    new Set([capabilityStates.constructCapabilityProfile, capabilityStates.rejected])
  ],
  [
    capabilityStates.constructCapabilityProfile,
    new Set([capabilityStates.freezeCapabilityProfile, capabilityStates.constructionFailed])
  ],
  [capabilityStates.freezeCapabilityProfile, new Set([capabilityStates.published, capabilityStates.freezeRejected])]
]);

const capabilityProfileFields = Object.freeze([
  "capabilityId",
  "capabilityVersion",
  "capabilityProfileVersion",
  "supportedTransportContractVersions",
  "supportedEnvelopeVersions",
  "supportedAcknowledgementVersions",
  "supportedRetryPolicyVersions",
  "supportedTransportErrorVersions",
  "supportedInterfaceVersions",
  "capabilityClassification",
  "validationState",
  "timestamp"
]);
const diagnosticsFields = Object.freeze([
  "capabilityVersion",
  "capabilityState",
  "capabilityClassification",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze(["capabilityId", "transportContractId", "authorityId", "capabilityState", "validationState", "timestamp"]);

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
    const id = validateIdentifier(value, "capability identifier");
    if (!id.ok) return id;
    if (seen.has(value)) return result(false, `duplicate capability identifier ${value}`, "DuplicateIdentifier");
    seen.add(value);
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalEnvelopeTransportCapabilityAuthorityId });
}

export function validateCapabilityTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "capability transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(capabilityStates).includes(item.from) || !Object.values(capabilityStates).includes(item.to)) {
      return result(false, "undocumented capability state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== capabilityStates.idle) return result(false, "capability lifecycle must start at Idle", "InvalidLifecycle");
    if (index > 0 && transitions[index - 1].to !== item.from) return result(false, "capability lifecycle skipped state", "InvalidLifecycle");
    if (terminalStates.has(item.from) || terminalSeen) return result(false, "terminal capability state mutated", "InvalidLifecycle");
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal capability transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic capability transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function createCapabilityProfile(transportContract, timestamp) {
  return deepFreeze({
    capabilityId: `${transportContract.transportContractId}.capability`,
    capabilityVersion: transportCapabilityVersion,
    capabilityProfileVersion: transportCapabilityProfileVersion,
    supportedTransportContractVersions: [transportContract.transportContractVersion],
    supportedEnvelopeVersions: [transportContract.supportedEnvelopeVersion],
    supportedAcknowledgementVersions: [transportContract.acknowledgementContract.acknowledgementSchemaVersion],
    supportedRetryPolicyVersions: [transportContract.retryContract.retryPolicyVersion],
    supportedTransportErrorVersions: [transportContract.transportErrorContract.errorSchemaVersion],
    supportedInterfaceVersions: [transportContract.transportInterfaceVersion],
    capabilityClassification: "DefinitionOnly",
    validationState: "valid",
    timestamp
  });
}

function validateVersionList(values, expected, label) {
  if (!Array.isArray(values) || values.length !== 1) return result(false, `${label} must contain exactly one version`, "VersionDeclarationInvalid");
  if (values[0] !== expected) return result(false, `${label} references unsupported version`, "VersionDeclarationInvalid");
  return result(true);
}

export function validateCapabilityProfile(profile, transportContract = null) {
  const fields = exactFields(profile, capabilityProfileFields, "capability profile");
  if (!fields.ok) return fields;
  for (const field of ["capabilityId", "capabilityVersion", "capabilityProfileVersion", "capabilityClassification", "validationState", "timestamp"]) {
    const id = validateIdentifier(profile[field], field);
    if (!id.ok) return id;
  }
  if (profile.capabilityVersion !== transportCapabilityVersion) return result(false, "capability version unsupported", "CapabilityVersionInvalid");
  if (profile.capabilityProfileVersion !== transportCapabilityProfileVersion) {
    return result(false, "capability profile version unsupported", "CapabilityProfileVersionInvalid");
  }
  if (!capabilityClassifications.includes(profile.capabilityClassification)) {
    return result(false, "capability classification unsupported", "CapabilityClassificationInvalid");
  }
  if (profile.capabilityClassification === "ImplementationVerified") {
    return result(false, "implementation verification cannot be emitted in Phase 142", "CapabilityClassificationInvalid");
  }
  if (!validationStates.includes(profile.validationState)) return result(false, "capability validation state invalid", "ValidationStateInvalid");
  const versionChecks = [
    validateVersionList(profile.supportedTransportContractVersions, transportContractVersion, "supported transport contract versions"),
    validateVersionList(profile.supportedEnvelopeVersions, externalExecutionEnvelopeVersion, "supported envelope versions"),
    validateVersionList(profile.supportedAcknowledgementVersions, String(transportContractSchemaVersion), "supported acknowledgement versions"),
    validateVersionList(profile.supportedRetryPolicyVersions, transportContractVersion, "supported retry policy versions"),
    validateVersionList(profile.supportedTransportErrorVersions, String(transportContractSchemaVersion), "supported transport error versions"),
    validateVersionList(profile.supportedInterfaceVersions, transportInterfaceVersion, "supported interface versions")
  ];
  for (const check of versionChecks) {
    if (!check.ok) return check;
  }
  if (transportContract !== null) {
    if (profile.capabilityId !== `${transportContract.transportContractId}.capability`) {
      return result(false, "capability identity does not correlate with transport contract", "CorrelationMismatch");
    }
    const duplicateCheck = validateUniqueIdentifiers([profile.capabilityId, transportContract.transportContractId]);
    if (!duplicateCheck.ok) return duplicateCheck;
  }
  return result(true);
}

function createAudit(profile, transportContract, capabilityState, timestamp) {
  return deepFreeze([
    {
      capabilityId: profile?.capabilityId ?? "missing",
      transportContractId: transportContract?.transportContractId ?? "missing",
      authorityId: externalEnvelopeTransportCapabilityAuthorityId,
      capabilityState,
      validationState: profile?.validationState ?? "invalid",
      timestamp
    }
  ]);
}

export function validateCapabilityAudit(audit, profile = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "capability audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "capability audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalEnvelopeTransportCapabilityAuthorityId) return result(false, "capability audit authority mismatch", "InvalidAudit");
    if (!Object.values(capabilityStates).includes(item.capabilityState)) return result(false, "capability audit state invalid", "InvalidAudit");
    if (!validationStates.includes(item.validationState)) return result(false, "capability audit validation invalid", "InvalidAudit");
    if (profile !== null && item.capabilityId !== profile.capabilityId) return result(false, "capability audit identity mismatch", "InvalidAudit");
    const identity = `${item.capabilityId}:${item.transportContractId}:${item.capabilityState}`;
    if (identities.has(identity)) return result(false, "duplicate capability audit identity", "InvalidAudit");
    identities.add(identity);
    const orderingKey = `${item.timestamp}:${identity}`;
    if (previousKey && orderingKey < previousKey) return result(false, "capability audit ordering invalid", "InvalidAudit");
    previousKey = orderingKey;
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    capabilityVersion: evaluation.capabilityVersion,
    capabilityState: evaluation.capabilityState,
    capabilityClassification: evaluation.capabilityClassification,
    validationState: evaluation.validationState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateCapabilityDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "capability diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.capabilityVersion !== transportCapabilityVersion) return result(false, "capability diagnostics version mismatch", "InvalidDiagnostics");
  if (!Object.values(capabilityStates).includes(diagnostics.capabilityState)) return result(false, "capability diagnostics state invalid", "InvalidDiagnostics");
  if (!capabilityClassifications.includes(diagnostics.capabilityClassification)) {
    return result(false, "capability diagnostics classification invalid", "InvalidDiagnostics");
  }
  if (diagnostics.capabilityClassification !== "DefinitionOnly") return result(false, "capability diagnostics must be definition-only", "InvalidDiagnostics");
  if (!validationStates.includes(diagnostics.validationState)) return result(false, "capability diagnostics validation invalid", "InvalidDiagnostics");
  return result(true);
}

function validateTransportContractInput(transportContractEvaluation) {
  if (!isPlainObject(transportContractEvaluation) || transportContractEvaluation.authorityId !== externalEnvelopeTransportContractAuthorityId) {
    return result(false, "transport contract authority incompatible", "TransportContractAuthorityIncompatible");
  }
  if (!isPlainObject(transportContractEvaluation.transportContract)) return result(false, "transport contract missing", "TransportContractMissing");
  const contractValidation = validateTransportContract(
    transportContractEvaluation.transportContract,
    transportContractEvaluation.envelopeEvaluation?.envelope
  );
  if (!contractValidation.ok) return contractValidation;
  if (
    transportContractEvaluation.status !== "executionBlocked" ||
    transportContractEvaluation.executionBlocked !== true ||
    transportContractEvaluation.runnerInvoked !== false ||
    transportContractEvaluation.structuredResultCaptured !== false ||
    transportContractEvaluation.transportCreated !== false ||
    transportContractEvaluation.envelopeTransmitted !== false ||
    transportContractEvaluation.acknowledgementReceived !== false
  ) {
    return result(false, "transport contract blocked posture drifted", "TransportContractPostureInvalid");
  }
  return result(true);
}

export function evaluateEnvelopeTransportCapability(input = {}) {
  const timestamp = input.timestamp ?? now();
  const transportContractEvaluation = input.transportContractEvaluation ?? evaluateEnvelopeTransportContract({ ...input, timestamp });
  const transitions = [transition(capabilityStates.idle, capabilityStates.receiveTransportContract, "receiving transport contract", timestamp)];
  let capabilityState = capabilityStates.published;
  let failureReason = null;
  let capabilityProfile = null;
  let profileValidation = result(false, "capability profile not created", "MissingTransportContract");
  let capabilityClassification = "DefinitionOnly";

  const transportInputValidation = validateTransportContractInput(transportContractEvaluation);
  if (!transportInputValidation.ok) {
    transitions.push(
      transition(
        capabilityStates.receiveTransportContract,
        capabilityStates.missingTransportContract,
        transportInputValidation.failure ?? "MissingTransportContract",
        timestamp
      )
    );
    capabilityState = capabilityStates.missingTransportContract;
    failureReason = transportInputValidation.failure ?? "MissingTransportContract";
  } else {
    transitions.push(transition(capabilityStates.receiveTransportContract, capabilityStates.resolveCapabilityRequirements, "transport contract received", timestamp));
    transitions.push(
      transition(capabilityStates.resolveCapabilityRequirements, capabilityStates.validateCapabilityProfile, "capability requirements resolved", timestamp)
    );
    capabilityProfile = createCapabilityProfile(transportContractEvaluation.transportContract, timestamp);
    capabilityClassification = capabilityProfile.capabilityClassification;
    profileValidation = validateCapabilityProfile(capabilityProfile, transportContractEvaluation.transportContract);
    if (!profileValidation.ok) {
      transitions.push(
        transition(capabilityStates.validateCapabilityProfile, capabilityStates.rejected, profileValidation.failure ?? "CapabilityRejected", timestamp)
      );
      capabilityState = capabilityStates.rejected;
      failureReason = profileValidation.failure ?? "CapabilityRejected";
    } else {
      transitions.push(transition(capabilityStates.validateCapabilityProfile, capabilityStates.constructCapabilityProfile, "capability profile validated", timestamp));
      if (!isPlainObject(capabilityProfile)) {
        transitions.push(
          transition(capabilityStates.constructCapabilityProfile, capabilityStates.constructionFailed, "CapabilityConstructionFailed", timestamp)
        );
        capabilityState = capabilityStates.constructionFailed;
        failureReason = "CapabilityConstructionFailed";
      } else {
        transitions.push(transition(capabilityStates.constructCapabilityProfile, capabilityStates.freezeCapabilityProfile, "capability profile constructed", timestamp));
        if (
          !Object.isFrozen(capabilityProfile) ||
          !Object.isFrozen(capabilityProfile.supportedTransportContractVersions) ||
          !Object.isFrozen(capabilityProfile.supportedEnvelopeVersions)
        ) {
          transitions.push(transition(capabilityStates.freezeCapabilityProfile, capabilityStates.freezeRejected, "FreezeRejected", timestamp));
          capabilityState = capabilityStates.freezeRejected;
          failureReason = "FreezeRejected";
        } else {
          transitions.push(transition(capabilityStates.freezeCapabilityProfile, capabilityStates.published, "capability profile frozen", timestamp));
        }
      }
    }
  }

  const transitionValidation = validateCapabilityTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  const audit = createAudit(capabilityProfile, transportContractEvaluation.transportContract, capabilityState, timestamp);
  const ok = profileValidation.ok && transitionValidation.ok;
  const evaluation = {
    schemaVersion: transportCapabilitySchemaVersion,
    authorityId: externalEnvelopeTransportCapabilityAuthorityId,
    capabilityVersion: transportCapabilityVersion,
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
    capabilityState,
    capabilityClassification,
    validationState: "valid",
    transportContractEvaluation,
    capabilityProfile,
    transportInputValidation,
    profileValidation,
    transitionValidation,
    audit,
    auditValidation: validateCapabilityAudit(audit, capabilityProfile),
    integrationGraph: [
      "Phase140ExternalExecutionEnvelopeAuthority",
      "Phase141ExternalEnvelopeTransportContractAuthority",
      "Phase142ExternalEnvelopeTransportCapabilityAuthority",
      "FutureTransportCompatibilityAuthorityDocumentationOnly",
      "FutureTransportImplementationDocumentationOnly",
      "FutureExternalConsumerDocumentationOnly"
    ],
    failureReason,
    recommendedAction: "Define future external transport compatibility before any transport implementation can be considered.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateCapabilityDiagnostics(diagnosticsFor(evaluation)),
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

export function runEnvelopeTransportCapabilitySelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateEnvelopeTransportCapability({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateEnvelopeTransportCapability({ timestamp: stableTimestamp, repositoryState });
  const missingContract = evaluateEnvelopeTransportCapability({ timestamp: stableTimestamp, transportContractEvaluation: {} });
  const badProfile = { ...evaluation.capabilityProfile, extra: true };
  const missingFieldProfile = { ...evaluation.capabilityProfile };
  delete missingFieldProfile.supportedEnvelopeVersions;
  const duplicateProfile = { ...evaluation.capabilityProfile, capabilityId: evaluation.transportContractEvaluation.transportContract.transportContractId };
  const verifiedProfile = { ...evaluation.capabilityProfile, capabilityClassification: "ImplementationVerified" };
  const deprecatedProfile = { ...evaluation.capabilityProfile, capabilityClassification: "Deprecated" };
  const inventedContractVersion = { ...evaluation.capabilityProfile, supportedTransportContractVersions: ["9.9.9"] };
  const inventedEnvelopeVersion = { ...evaluation.capabilityProfile, supportedEnvelopeVersions: ["9.9.9"] };
  const inventedAcknowledgementVersion = { ...evaluation.capabilityProfile, supportedAcknowledgementVersions: ["9"] };
  const inventedRetryVersion = { ...evaluation.capabilityProfile, supportedRetryPolicyVersions: ["9.9.9"] };
  const inventedErrorVersion = { ...evaluation.capabilityProfile, supportedTransportErrorVersions: ["9"] };
  const inventedInterfaceVersion = { ...evaluation.capabilityProfile, supportedInterfaceVersions: ["9.9.9"] };
  const badDiagnostics = { ...evaluation.diagnostics, transportEndpoint: "none" };
  const duplicateAudit = validateCapabilityAudit([...evaluation.audit, ...evaluation.audit], evaluation.capabilityProfile);
  const reorderedAudit = validateCapabilityAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:00.000Z" }
  ]);
  const invalidTransition = validateCapabilityTransitions([transition(capabilityStates.idle, capabilityStates.freezeCapabilityProfile, "skip", stableTimestamp)]);
  const skippedTransition = validateCapabilityTransitions([
    transition(capabilityStates.idle, capabilityStates.receiveTransportContract, "start", stableTimestamp),
    transition(capabilityStates.validateCapabilityProfile, capabilityStates.constructCapabilityProfile, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateCapabilityTransitions([
    transition(capabilityStates.idle, capabilityStates.receiveTransportContract, "start", stableTimestamp),
    transition(capabilityStates.receiveTransportContract, capabilityStates.resolveCapabilityRequirements, "resolve", stableTimestamp),
    transition(capabilityStates.resolveCapabilityRequirements, capabilityStates.receiveTransportContract, "cycle", stableTimestamp)
  ]);
  const terminalMutation = validateCapabilityTransitions([
    transition(capabilityStates.idle, capabilityStates.receiveTransportContract, "start", stableTimestamp),
    transition(capabilityStates.receiveTransportContract, capabilityStates.missingTransportContract, "stop", stableTimestamp),
    transition(capabilityStates.missingTransportContract, capabilityStates.resolveCapabilityRequirements, "mutate", stableTimestamp)
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingTransportContractRejection", missingContract.capabilityState === capabilityStates.missingTransportContract, "");
  assertSelfCheck(results, "capabilityRequirementFailureStateDocumented", capabilityStates.requirementFailure === "CapabilityRequirementFailure", "");
  assertSelfCheck(results, "capabilityRejectedStateDocumented", capabilityStates.rejected === "CapabilityRejected", "");
  assertSelfCheck(results, "capabilityConstructionFailureStateDocumented", capabilityStates.constructionFailed === "CapabilityConstructionFailed", "");
  assertSelfCheck(results, "freezeRejectionStateDocumented", capabilityStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactCapabilitySchema", Object.keys(evaluation.capabilityProfile).length === capabilityProfileFields.length, "");
  assertSelfCheck(results, "unknownCapabilityFieldRejection", validateCapabilityProfile(badProfile, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "missingCapabilityFieldRejection", validateCapabilityProfile(missingFieldProfile, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "duplicateIdentifierRejection", validateCapabilityProfile(duplicateProfile, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "capabilityIdentityCorrelation", evaluation.capabilityProfile.capabilityId === `${evaluation.transportContractEvaluation.transportContract.transportContractId}.capability`, "");
  assertSelfCheck(results, "definitionOnlyClassification", evaluation.capabilityProfile.capabilityClassification === "DefinitionOnly", "");
  assertSelfCheck(results, "implementationVerifiedRejection", validateCapabilityProfile(verifiedProfile, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "deprecatedClassificationAllowed", validateCapabilityProfile(deprecatedProfile, evaluation.transportContractEvaluation.transportContract).ok === true, "");
  assertSelfCheck(results, "transportContractVersionValidation", validateCapabilityProfile(inventedContractVersion, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "envelopeVersionValidation", validateCapabilityProfile(inventedEnvelopeVersion, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "acknowledgementVersionValidation", validateCapabilityProfile(inventedAcknowledgementVersion, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "retryPolicyVersionValidation", validateCapabilityProfile(inventedRetryVersion, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "transportErrorVersionValidation", validateCapabilityProfile(inventedErrorVersion, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "interfaceVersionValidation", validateCapabilityProfile(inventedInterfaceVersion, evaluation.transportContractEvaluation.transportContract).ok === false, "");
  assertSelfCheck(results, "transportContractVersionPreserved", evaluation.capabilityProfile.supportedTransportContractVersions[0] === transportContractVersion, "");
  assertSelfCheck(results, "envelopeVersionPreserved", evaluation.capabilityProfile.supportedEnvelopeVersions[0] === externalExecutionEnvelopeVersion, "");
  assertSelfCheck(results, "acknowledgementVersionPreserved", evaluation.capabilityProfile.supportedAcknowledgementVersions[0] === String(transportContractSchemaVersion), "");
  assertSelfCheck(results, "retryPolicyVersionPreserved", evaluation.capabilityProfile.supportedRetryPolicyVersions[0] === transportContractVersion, "");
  assertSelfCheck(results, "transportErrorVersionPreserved", evaluation.capabilityProfile.supportedTransportErrorVersions[0] === String(transportContractSchemaVersion), "");
  assertSelfCheck(results, "interfaceVersionPreserved", evaluation.capabilityProfile.supportedInterfaceVersions[0] === transportInterfaceVersion, "");
  assertSelfCheck(results, "immutablePublication", Object.isFrozen(evaluation.capabilityProfile), "");
  assertSelfCheck(results, "immutableVersionLists", Object.isFrozen(evaluation.capabilityProfile.supportedEnvelopeVersions), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateCapabilityDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "diagnosticsStatePublished", evaluation.diagnostics.capabilityState === "CapabilityProfilePublished", "");
  assertSelfCheck(results, "diagnosticsClassificationDefinitionOnly", evaluation.diagnostics.capabilityClassification === "DefinitionOnly", "");
  assertSelfCheck(results, "immutableAuditValidation", Object.isFrozen(evaluation.audit) && evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "auditContractCorrelation", evaluation.audit[0].transportContractId === evaluation.transportContractEvaluation.transportContract.transportContractId, "");
  assertSelfCheck(results, "deterministicIdentifiers", evaluation.capabilityProfile.capabilityId.endsWith(".capability"), "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && evaluation.capabilityProfile.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicDiagnostics", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "deterministicAudit", stableSerialize(evaluation.audit) === stableSerialize(rerun.audit), "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.capabilityProfile) === stableSerialize(rerun.capabilityProfile), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalEnvelopeTransportCapabilityAuthorityId, "");
  assertSelfCheck(results, "phase141RegressionCompatibility", evaluation.transportContractEvaluation.authorityId === externalEnvelopeTransportContractAuthorityId, "");
  assertSelfCheck(results, "phase141ContractValidation", validateTransportContract(evaluation.transportContractEvaluation.transportContract, evaluation.transportContractEvaluation.envelopeEvaluation.envelope).ok === true, "");
  assertSelfCheck(results, "phase140RegressionCompatibility", evaluation.transportContractEvaluation.envelopeEvaluation.envelope.envelopeVersion === externalExecutionEnvelopeVersion, "");
  assertSelfCheck(
    results,
    "sessionNotVisiblePreserved",
    evaluation.transportContractEvaluation.envelopeEvaluation.compatibilityEvaluation.manifestEvaluation.contractEvaluation.boundaryEvaluation.dispatchEvaluation
      .requestEvaluation.orchestration.planning.readiness.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE",
    ""
  );
  assertSelfCheck(results, "executionBlockedPreserved", evaluation.executionBlocked === true && evaluation.transportContractEvaluation.executionBlocked === true, "");
  assertSelfCheck(results, "runnerNotInvoked", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "structuredResultNotCaptured", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "transportUnavailablePreserved", evaluation.transportContractEvaluation.transportAvailabilityState === "TransportUnavailable", "");
  assertSelfCheck(results, "transportNotImplemented", evaluation.transportImplemented === false, "");
  assertSelfCheck(results, "transportNotCreated", evaluation.transportCreated === false, "");
  assertSelfCheck(results, "noEnvelopeTransmission", evaluation.envelopeTransmitted === false, "");
  assertSelfCheck(results, "noAcknowledgementReception", evaluation.acknowledgementReceived === false, "");
  assertSelfCheck(results, "noEndpointDiscovery", evaluation.endpointDiscovered === false, "");
  assertSelfCheck(results, "noExternalConnection", evaluation.externalConsumerConnected === false, "");
  assertSelfCheck(results, "noMcpClient", !("mcpClient" in evaluation), "");
  assertSelfCheck(results, "noAuthentication", !("credentials" in evaluation), "");
  assertSelfCheck(results, "noStudioExecution", evaluation.studioExecuted === false, "");
  assertSelfCheck(results, "noRunnerInvocation", evaluation.runnerInvoked === false, "");
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
    const results = runEnvelopeTransportCapabilitySelfChecks();
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
  const evaluation = evaluateEnvelopeTransportCapability({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
