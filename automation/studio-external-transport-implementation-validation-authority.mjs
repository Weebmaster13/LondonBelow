import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateExternalTransportImplementationReadiness,
  externalTransportImplementationReadinessAuthorityId,
  implementationReadinessEvaluationVersion,
  implementationReadinessStates,
  validateImplementationReadinessDiagnostics,
  validateImplementationReadinessEvaluation
} from "./studio-external-transport-implementation-readiness-authority.mjs";
import { stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const implementationValidationDefinitionSchemaVersion = 1;
export const implementationValidationDefinitionVersion = "1.0.0";
export const externalTransportImplementationValidationAuthorityId =
  "chapter0Home.phase146StudioExternalTransportImplementationValidationAuthority";

export const implementationValidationStates = Object.freeze({
  idle: "Idle",
  receiveReadinessEvaluation: "ReceiveReadinessEvaluation",
  resolveValidationRequirements: "ResolveValidationRequirements",
  validateValidationDefinition: "ValidateValidationDefinition",
  constructValidationDefinition: "ConstructValidationDefinition",
  freezeValidationDefinition: "FreezeValidationDefinition",
  published: "ImplementationValidationPublished",
  missingReadinessEvaluation: "MissingReadinessEvaluation",
  requirementResolutionFailed: "ValidationRequirementResolutionFailed",
  rejected: "ValidationDefinitionRejected",
  constructionFailed: "ValidationConstructionFailed",
  freezeRejected: "FreezeRejected"
});

export const implementationValidationClassifications = Object.freeze(["DefinitionOnly", "DefinitionIncomplete", "DefinitionInvalid"]);
export const futureVerificationEligibilityValues = Object.freeze([
  "DefinitionEligibleForVerification",
  "DefinitionIneligibleIncomplete",
  "DefinitionIneligibleInvalid"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-18T02:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  implementationValidationStates.published,
  implementationValidationStates.missingReadinessEvaluation,
  implementationValidationStates.requirementResolutionFailed,
  implementationValidationStates.rejected,
  implementationValidationStates.constructionFailed,
  implementationValidationStates.freezeRejected
]);
const legalTransitions = new Map([
  [implementationValidationStates.idle, new Set([implementationValidationStates.receiveReadinessEvaluation])],
  [
    implementationValidationStates.receiveReadinessEvaluation,
    new Set([implementationValidationStates.resolveValidationRequirements, implementationValidationStates.missingReadinessEvaluation])
  ],
  [
    implementationValidationStates.resolveValidationRequirements,
    new Set([implementationValidationStates.validateValidationDefinition, implementationValidationStates.requirementResolutionFailed])
  ],
  [
    implementationValidationStates.validateValidationDefinition,
    new Set([implementationValidationStates.constructValidationDefinition, implementationValidationStates.rejected])
  ],
  [
    implementationValidationStates.constructValidationDefinition,
    new Set([implementationValidationStates.freezeValidationDefinition, implementationValidationStates.constructionFailed])
  ],
  [
    implementationValidationStates.freezeValidationDefinition,
    new Set([implementationValidationStates.published, implementationValidationStates.freezeRejected])
  ]
]);

const validationDefinitionFields = Object.freeze([
  "validationEvaluationId",
  "validationEvaluationVersion",
  "readinessEvaluationId",
  "validationCheckpointDefinitions",
  "validationBoundaryDefinitions",
  "validationPrerequisiteDefinitions",
  "implementationValidationState",
  "futureVerificationEligibility",
  "validationState",
  "timestamp"
]);
const checkpointDefinitionFields = Object.freeze([
  "checkpointDefinitionVersion",
  "requiredValidationCheckpoints",
  "strictOrderingRequired",
  "readinessCorrelationRequired",
  "immutableResultsRequired"
]);
const boundaryDefinitionFields = Object.freeze([
  "boundaryDefinitionVersion",
  "definitionOnlyRequired",
  "implementationDiscoveryProhibited",
  "implementationInspectionProhibited",
  "implementationLoadingProhibited",
  "transportExecutionProhibited",
  "networkingProhibited",
  "endpointDiscoveryProhibited",
  "credentialHandlingProhibited",
  "runtimeEvidenceProhibited",
  "certificationProhibited"
]);
const prerequisiteDefinitionFields = Object.freeze([
  "prerequisiteDefinitionVersion",
  "requiredReadinessState",
  "requiredOverallImplementationReadiness",
  "requiredFutureValidationEligibility",
  "requiredTransportAvailabilityState",
  "requiredExecutionEligibility",
  "executionBlockedRequired"
]);
const diagnosticsFields = Object.freeze([
  "validationEvaluationVersion",
  "validationDefinitionState",
  "implementationValidationState",
  "futureVerificationEligibility",
  "executionBlocked",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "validationEvaluationId",
  "readinessEvaluationId",
  "authorityId",
  "implementationValidationState",
  "futureVerificationEligibility",
  "timestamp",
  "validationEvaluationVersion"
]);
const requiredValidationCheckpoints = Object.freeze([
  "ReadinessEvaluationValidated",
  "ReadinessVersionValidated",
  "ReadinessCorrelationValidated",
  "PrerequisiteDefinitionsValidated",
  "BoundaryDefinitionsValidated",
  "BlockedExecutionValidated",
  "FutureVerificationEligibilityValidated",
  "PublicationImmutabilityValidated"
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

function exactList(values, expected, label) {
  if (!Array.isArray(values) || values.length !== expected.length) return result(false, `${label} invalid`, "SchemaMismatch");
  for (let index = 0; index < expected.length; index += 1) {
    if (values[index] !== expected[index]) return result(false, `${label} ordering invalid`, "SchemaMismatch");
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalTransportImplementationValidationAuthorityId });
}

export function validateImplementationValidationTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "implementation validation transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(implementationValidationStates).includes(item.from) || !Object.values(implementationValidationStates).includes(item.to)) {
      return result(false, "undocumented implementation validation state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== implementationValidationStates.idle) return result(false, "implementation validation lifecycle must start at Idle", "InvalidLifecycle");
    if (index > 0 && transitions[index - 1].to !== item.from) return result(false, "implementation validation lifecycle skipped state", "InvalidLifecycle");
    if (terminalStates.has(item.from) || terminalSeen) return result(false, "terminal implementation validation state mutated", "InvalidLifecycle");
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal implementation validation transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic implementation validation transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function createCheckpointDefinitions() {
  return deepFreeze({
    checkpointDefinitionVersion: implementationValidationDefinitionVersion,
    requiredValidationCheckpoints: [...requiredValidationCheckpoints],
    strictOrderingRequired: true,
    readinessCorrelationRequired: true,
    immutableResultsRequired: true
  });
}

function createBoundaryDefinitions() {
  return deepFreeze({
    boundaryDefinitionVersion: implementationValidationDefinitionVersion,
    definitionOnlyRequired: true,
    implementationDiscoveryProhibited: true,
    implementationInspectionProhibited: true,
    implementationLoadingProhibited: true,
    transportExecutionProhibited: true,
    networkingProhibited: true,
    endpointDiscoveryProhibited: true,
    credentialHandlingProhibited: true,
    runtimeEvidenceProhibited: true,
    certificationProhibited: true
  });
}

function createPrerequisiteDefinitions() {
  return deepFreeze({
    prerequisiteDefinitionVersion: implementationValidationDefinitionVersion,
    requiredReadinessState: implementationReadinessStates.published,
    requiredOverallImplementationReadiness: "StructurallyReadyDefinition",
    requiredFutureValidationEligibility: "DefinitionEligibleForFutureValidation",
    requiredTransportAvailabilityState: "TransportUnavailable",
    requiredExecutionEligibility: "DefinitionCompatibleButUnavailable",
    executionBlockedRequired: true
  });
}

export function validateValidationCheckpointDefinitions(definitions) {
  const fields = exactFields(definitions, checkpointDefinitionFields, "implementation validation checkpoint definitions");
  if (!fields.ok) return fields;
  if (definitions.checkpointDefinitionVersion !== implementationValidationDefinitionVersion) return result(false, "checkpoint definition version unsupported", "CheckpointDefinitionInvalid");
  const checkpoints = exactList(definitions.requiredValidationCheckpoints, requiredValidationCheckpoints, "implementation validation checkpoints");
  if (!checkpoints.ok) return checkpoints;
  if (definitions.strictOrderingRequired !== true) return result(false, "checkpoint ordering must be strict", "CheckpointDefinitionInvalid");
  if (definitions.readinessCorrelationRequired !== true) return result(false, "readiness correlation must be required", "CheckpointDefinitionInvalid");
  if (definitions.immutableResultsRequired !== true) return result(false, "checkpoint immutability must be required", "CheckpointDefinitionInvalid");
  return result(true);
}

export function validateValidationBoundaryDefinitions(definitions) {
  const fields = exactFields(definitions, boundaryDefinitionFields, "implementation validation boundary definitions");
  if (!fields.ok) return fields;
  if (definitions.boundaryDefinitionVersion !== implementationValidationDefinitionVersion) return result(false, "boundary definition version unsupported", "BoundaryDefinitionInvalid");
  for (const field of boundaryDefinitionFields.filter((key) => key !== "boundaryDefinitionVersion")) {
    if (definitions[field] !== true) return result(false, `${field} must be true`, "BoundaryDefinitionInvalid");
  }
  return result(true);
}

export function validateValidationPrerequisiteDefinitions(definitions) {
  const fields = exactFields(definitions, prerequisiteDefinitionFields, "implementation validation prerequisite definitions");
  if (!fields.ok) return fields;
  if (definitions.prerequisiteDefinitionVersion !== implementationValidationDefinitionVersion) return result(false, "prerequisite definition version unsupported", "PrerequisiteDefinitionInvalid");
  if (definitions.requiredReadinessState !== implementationReadinessStates.published) return result(false, "readiness state prerequisite invalid", "PrerequisiteDefinitionInvalid");
  if (definitions.requiredOverallImplementationReadiness !== "StructurallyReadyDefinition") {
    return result(false, "overall readiness prerequisite invalid", "PrerequisiteDefinitionInvalid");
  }
  if (definitions.requiredFutureValidationEligibility !== "DefinitionEligibleForFutureValidation") {
    return result(false, "future validation prerequisite invalid", "PrerequisiteDefinitionInvalid");
  }
  if (definitions.requiredTransportAvailabilityState !== "TransportUnavailable") return result(false, "availability prerequisite invalid", "PrerequisiteDefinitionInvalid");
  if (definitions.requiredExecutionEligibility !== "DefinitionCompatibleButUnavailable") return result(false, "execution eligibility prerequisite invalid", "PrerequisiteDefinitionInvalid");
  if (definitions.executionBlockedRequired !== true) return result(false, "execution blocked prerequisite invalid", "PrerequisiteDefinitionInvalid");
  return result(true);
}

function validateReadinessPreconditions(readinessEvaluation) {
  if (!isPlainObject(readinessEvaluation)) return result(false, "readiness authority missing", "MissingReadinessEvaluation");
  if (!isPlainObject(readinessEvaluation.readinessEvaluation)) return result(false, "readiness evaluation missing", "MissingReadinessEvaluation");
  if (readinessEvaluation.authorityId !== externalTransportImplementationReadinessAuthorityId) {
    return result(false, "readiness authority mismatch", "ValidationRequirementResolutionFailed");
  }
  const readinessValidation = validateImplementationReadinessEvaluation(
    readinessEvaluation.readinessEvaluation,
    readinessEvaluation.implementationContractEvaluation?.implementationContract
  );
  if (!readinessValidation.ok) return readinessValidation;
  const diagnosticsValidation = validateImplementationReadinessDiagnostics(readinessEvaluation.diagnostics);
  if (!diagnosticsValidation.ok) return diagnosticsValidation;
  if (readinessEvaluation.readinessState !== implementationReadinessStates.published) return result(false, "readiness not published", "ValidationRequirementResolutionFailed");
  if (readinessEvaluation.overallImplementationReadiness !== "StructurallyReadyDefinition") {
    return result(false, "readiness definition is not structurally ready", "ValidationRequirementResolutionFailed");
  }
  if (readinessEvaluation.futureValidationEligibility !== "DefinitionEligibleForFutureValidation") {
    return result(false, "future validation eligibility not granted", "ValidationRequirementResolutionFailed");
  }
  if (readinessEvaluation.executionBlocked !== true) return result(false, "execution must remain blocked", "ValidationRequirementResolutionFailed");
  return result(true);
}

function createValidationDefinition(readinessEvaluation, timestamp) {
  return deepFreeze({
    validationEvaluationId: `${readinessEvaluation.readinessEvaluation.readinessEvaluationId}.validationDefinition`,
    validationEvaluationVersion: implementationValidationDefinitionVersion,
    readinessEvaluationId: readinessEvaluation.readinessEvaluation.readinessEvaluationId,
    validationCheckpointDefinitions: createCheckpointDefinitions(),
    validationBoundaryDefinitions: createBoundaryDefinitions(),
    validationPrerequisiteDefinitions: createPrerequisiteDefinitions(),
    implementationValidationState: "DefinitionOnly",
    futureVerificationEligibility: "DefinitionEligibleForVerification",
    validationState: "valid",
    timestamp
  });
}

export function validateImplementationValidationDefinition(definition, readinessEvaluation = null) {
  const fields = exactFields(definition, validationDefinitionFields, "implementation validation definition");
  if (!fields.ok) return fields;
  for (const field of [
    "validationEvaluationId",
    "validationEvaluationVersion",
    "readinessEvaluationId",
    "implementationValidationState",
    "futureVerificationEligibility",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(definition[field], field);
    if (!id.ok) return id;
  }
  if (definition.validationEvaluationVersion !== implementationValidationDefinitionVersion) {
    return result(false, "validation evaluation version unsupported", "ValidationVersionInvalid");
  }
  if (!implementationValidationClassifications.includes(definition.implementationValidationState)) {
    return result(false, "implementation validation state unsupported", "ImplementationValidationStateInvalid");
  }
  if (definition.implementationValidationState !== "DefinitionOnly") {
    return result(false, "Phase 146 can publish DefinitionOnly only", "ImplementationValidationStateInvalid");
  }
  if (!futureVerificationEligibilityValues.includes(definition.futureVerificationEligibility)) {
    return result(false, "future verification eligibility unsupported", "FutureVerificationEligibilityInvalid");
  }
  if (definition.futureVerificationEligibility !== "DefinitionEligibleForVerification") {
    return result(false, "Phase 146 normal publication must remain verification definition eligible", "FutureVerificationEligibilityInvalid");
  }
  if (definition.validationState !== "valid") return result(false, "validation state invalid", "ValidationStateInvalid");
  const checkpoints = validateValidationCheckpointDefinitions(definition.validationCheckpointDefinitions);
  if (!checkpoints.ok) return checkpoints;
  const boundaries = validateValidationBoundaryDefinitions(definition.validationBoundaryDefinitions);
  if (!boundaries.ok) return boundaries;
  const prerequisites = validateValidationPrerequisiteDefinitions(definition.validationPrerequisiteDefinitions);
  if (!prerequisites.ok) return prerequisites;
  if (readinessEvaluation !== null) {
    if (definition.readinessEvaluationId !== readinessEvaluation.readinessEvaluation.readinessEvaluationId) {
      return result(false, "readiness evaluation ID drift", "CorrelationMismatch");
    }
    if (definition.validationEvaluationId !== `${readinessEvaluation.readinessEvaluation.readinessEvaluationId}.validationDefinition`) {
      return result(false, "validation definition ID drift", "CorrelationMismatch");
    }
    const ids = new Set([definition.validationEvaluationId, definition.readinessEvaluationId]);
    if (ids.size !== 2) return result(false, "duplicate validation definition identifiers", "DuplicateIdentifier");
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    validationEvaluationVersion: implementationValidationDefinitionVersion,
    validationDefinitionState: evaluation.validationDefinitionState,
    implementationValidationState: evaluation.implementationValidationState,
    futureVerificationEligibility: evaluation.futureVerificationEligibility,
    executionBlocked: evaluation.executionBlocked,
    validationState: evaluation.validationState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateImplementationValidationDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "implementation validation diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.validationEvaluationVersion !== implementationValidationDefinitionVersion) return result(false, "diagnostics version unsupported", "DiagnosticsInvalid");
  if (!Object.values(implementationValidationStates).includes(diagnostics.validationDefinitionState)) return result(false, "diagnostics definition state invalid", "DiagnosticsInvalid");
  if (diagnostics.implementationValidationState !== "DefinitionOnly") return result(false, "diagnostics classification invalid", "DiagnosticsInvalid");
  if (diagnostics.futureVerificationEligibility !== "DefinitionEligibleForVerification") return result(false, "diagnostics verification eligibility invalid", "DiagnosticsInvalid");
  if (diagnostics.executionBlocked !== true) return result(false, "diagnostics execution must remain blocked", "DiagnosticsInvalid");
  if (diagnostics.validationState !== "valid") return result(false, "diagnostics validation state invalid", "DiagnosticsInvalid");
  return result(true);
}

function createAudit(definition, validationDefinitionState, timestamp) {
  return deepFreeze([
    {
      validationEvaluationId: definition?.validationEvaluationId ?? "missing",
      readinessEvaluationId: definition?.readinessEvaluationId ?? "missing",
      authorityId: externalTransportImplementationValidationAuthorityId,
      implementationValidationState: definition?.implementationValidationState ?? "DefinitionIncomplete",
      futureVerificationEligibility: definition?.futureVerificationEligibility ?? "DefinitionIneligibleIncomplete",
      timestamp,
      validationEvaluationVersion: implementationValidationDefinitionVersion
    }
  ]);
}

export function validateImplementationValidationAudit(audit, definition = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "implementation validation audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "implementation validation audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalTransportImplementationValidationAuthorityId) return result(false, "implementation validation audit authority mismatch", "InvalidAudit");
    if (!implementationValidationClassifications.includes(item.implementationValidationState)) {
      return result(false, "implementation validation audit classification invalid", "InvalidAudit");
    }
    if (!futureVerificationEligibilityValues.includes(item.futureVerificationEligibility)) {
      return result(false, "implementation validation audit verification eligibility invalid", "InvalidAudit");
    }
    if (definition !== null && item.validationEvaluationId !== definition.validationEvaluationId) {
      return result(false, "implementation validation audit identity mismatch", "InvalidAudit");
    }
    const identity = `${item.validationEvaluationId}:${item.readinessEvaluationId}:${item.authorityId}`;
    if (identities.has(identity)) return result(false, "duplicate implementation validation audit identity", "InvalidAudit");
    identities.add(identity);
    const orderingKey = `${item.timestamp}:${identity}`;
    if (previousKey && orderingKey < previousKey) return result(false, "implementation validation audit ordering invalid", "InvalidAudit");
    previousKey = orderingKey;
  }
  return result(true);
}

export function evaluateExternalTransportImplementationValidation(input = {}) {
  const timestamp = input.timestamp ?? now();
  const repositoryState =
    input.repositoryState ?? {
      branch: "main",
      localHead: input.repositoryRevision ?? stableCommit,
      remoteHead: input.repositoryRevision ?? stableCommit,
      workingTreeClean: true,
      originSynchronized: true
    };
  const readinessEvaluation =
    input.readinessEvaluation ??
    evaluateExternalTransportImplementationReadiness({
      timestamp,
      repositoryState,
      repositoryRevision: input.repositoryRevision
    });
  const transitions = [];
  transitions.push(transition(implementationValidationStates.idle, implementationValidationStates.receiveReadinessEvaluation, "start", timestamp));

  let validationDefinitionState = implementationValidationStates.published;
  let validationState = "valid";
  let failureReason = null;
  let validationDefinition = null;
  const preconditions = validateReadinessPreconditions(readinessEvaluation);
  if (!preconditions.ok) {
    validationDefinitionState =
      preconditions.failure === "MissingReadinessEvaluation"
        ? implementationValidationStates.missingReadinessEvaluation
        : implementationValidationStates.requirementResolutionFailed;
    failureReason = preconditions.reason;
    validationState = "invalid";
    transitions.push(transition(implementationValidationStates.receiveReadinessEvaluation, validationDefinitionState, failureReason, timestamp));
  } else {
    transitions.push(
      transition(implementationValidationStates.receiveReadinessEvaluation, implementationValidationStates.resolveValidationRequirements, "readiness received", timestamp)
    );
    transitions.push(
      transition(implementationValidationStates.resolveValidationRequirements, implementationValidationStates.validateValidationDefinition, "requirements resolved", timestamp)
    );
    validationDefinition = createValidationDefinition(readinessEvaluation, timestamp);
    const definitionValidation = validateImplementationValidationDefinition(validationDefinition, readinessEvaluation);
    if (!definitionValidation.ok) {
      validationDefinitionState = implementationValidationStates.rejected;
      failureReason = definitionValidation.reason;
      validationState = "invalid";
      transitions.push(transition(implementationValidationStates.validateValidationDefinition, validationDefinitionState, failureReason, timestamp));
    } else {
      transitions.push(
        transition(implementationValidationStates.validateValidationDefinition, implementationValidationStates.constructValidationDefinition, "definition valid", timestamp)
      );
      transitions.push(
        transition(implementationValidationStates.constructValidationDefinition, implementationValidationStates.freezeValidationDefinition, "definition constructed", timestamp)
      );
      if (!Object.isFrozen(validationDefinition) || !Object.isFrozen(validationDefinition.validationCheckpointDefinitions)) {
        validationDefinitionState = implementationValidationStates.freezeRejected;
        failureReason = "validation definition was not frozen";
        validationState = "invalid";
        transitions.push(transition(implementationValidationStates.freezeValidationDefinition, validationDefinitionState, failureReason, timestamp));
      } else {
        transitions.push(transition(implementationValidationStates.freezeValidationDefinition, implementationValidationStates.published, "definition frozen", timestamp));
      }
    }
  }

  const transitionValidation = validateImplementationValidationTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) {
    validationDefinitionState = implementationValidationStates.constructionFailed;
    failureReason = transitionValidation.reason;
    validationState = "invalid";
  }

  const implementationValidationState = validationDefinition?.implementationValidationState ?? "DefinitionIncomplete";
  const futureVerificationEligibility = validationDefinition?.futureVerificationEligibility ?? "DefinitionIneligibleIncomplete";
  const evaluation = {
    phase: 146,
    authorityId: externalTransportImplementationValidationAuthorityId,
    status: validationState === "valid" ? "executionBlocked" : "validationFailed",
    exitCode: validationState === "valid" ? bridgeExitCodes.executionBlocked : bridgeExitCodes.validationFailed,
    runnerInvoked: false,
    structuredResultCaptured: false,
    implementationDiscovered: false,
    implementationInspected: false,
    implementationLoaded: false,
    implementationExecuted: false,
    transportCreated: false,
    envelopeTransmitted: false,
    acknowledgementReceived: false,
    endpointDiscovered: false,
    studioExecuted: false,
    runtimeEvidenceGenerated: false,
    executionBlocked: true,
    validationDefinitionState,
    implementationValidationState,
    futureVerificationEligibility,
    readinessState: readinessEvaluation?.readinessState ?? "MissingReadinessEvaluation",
    overallImplementationReadiness: readinessEvaluation?.overallImplementationReadiness ?? "IncompleteDefinition",
    futureValidationEligibility: readinessEvaluation?.futureValidationEligibility ?? "DefinitionIneligibleIncomplete",
    implementationContractState: readinessEvaluation?.implementationContractState ?? "MissingImplementationContract",
    implementationReadiness: readinessEvaluation?.implementationReadiness ?? "DefinitionOnly",
    overallTransportCompatibility: readinessEvaluation?.overallTransportCompatibility ?? "IncompleteDefinition",
    transportAvailabilityState: readinessEvaluation?.transportAvailabilityState ?? "TransportUnavailable",
    executionEligibility: readinessEvaluation?.executionEligibility ?? "DefinitionCompatibleButUnavailable",
    validationState,
    failureReason,
    readinessEvaluation,
    validationDefinition,
    transitions,
    transitionValidation,
    audit: createAudit(validationDefinition, validationDefinitionState, timestamp),
    timestamp,
    sourceAuthorities: [
      "Phase140ExternalExecutionEnvelopeAuthority",
      "Phase141ExternalEnvelopeTransportContractAuthority",
      "Phase142ExternalEnvelopeTransportCapabilityAuthority",
      "Phase143ExternalTransportCompatibilityAuthority",
      "Phase144ExternalTransportImplementationContractAuthority",
      "Phase145ExternalTransportImplementationReadinessAuthority"
    ],
    nextRecommendedAuthority: "Phase147ExternalTransportImplementationVerificationAuthority",
    recommendedAction: "Define future implementation verification authority before any implementation may be inspected, loaded, or executed."
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateImplementationValidationDiagnostics(diagnosticsFor(evaluation)),
    auditValidation: validateImplementationValidationAudit(evaluation.audit, validationDefinition),
    validationDefinitionValidation: validationDefinition ? validateImplementationValidationDefinition(validationDefinition, readinessEvaluation) : result(false),
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

function rejectsMutation(target, mutate) {
  try {
    mutate(target);
    return false;
  } catch {
    return true;
  }
}

export function runExternalTransportImplementationValidationSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExternalTransportImplementationValidation({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExternalTransportImplementationValidation({ timestamp: stableTimestamp, repositoryState });
  const readiness = evaluation.readinessEvaluation;
  const definition = evaluation.validationDefinition;
  const missingReadiness = evaluateExternalTransportImplementationValidation({ timestamp: stableTimestamp, readinessEvaluation: {} });
  const requirementFailure = evaluateExternalTransportImplementationValidation({
    timestamp: stableTimestamp,
    readinessEvaluation: { ...readiness, authorityId: "wrong" }
  });
  const badDefinition = { ...definition, extra: true };
  const missingDefinitionField = { ...definition };
  delete missingDefinitionField.futureVerificationEligibility;
  const duplicateDefinition = { ...definition, validationEvaluationId: definition.readinessEvaluationId };
  const badEnum = { ...definition, implementationValidationState: "ValidationReady" };
  const badFutureEligibility = { ...definition, futureVerificationEligibility: "DefinitionEligibleForRuntime" };
  const badCheckpoint = {
    ...definition,
    validationCheckpointDefinitions: {
      ...definition.validationCheckpointDefinitions,
      requiredValidationCheckpoints: [...requiredValidationCheckpoints].reverse()
    }
  };
  const missingCheckpoint = {
    ...definition,
    validationCheckpointDefinitions: { ...definition.validationCheckpointDefinitions }
  };
  delete missingCheckpoint.validationCheckpointDefinitions.strictOrderingRequired;
  const badBoundary = {
    ...definition,
    validationBoundaryDefinitions: { ...definition.validationBoundaryDefinitions, networkingProhibited: false }
  };
  const missingBoundary = {
    ...definition,
    validationBoundaryDefinitions: { ...definition.validationBoundaryDefinitions }
  };
  delete missingBoundary.validationBoundaryDefinitions.certificationProhibited;
  const badPrerequisite = {
    ...definition,
    validationPrerequisiteDefinitions: {
      ...definition.validationPrerequisiteDefinitions,
      requiredTransportAvailabilityState: "TransportAvailable"
    }
  };
  const missingPrerequisite = {
    ...definition,
    validationPrerequisiteDefinitions: { ...definition.validationPrerequisiteDefinitions }
  };
  delete missingPrerequisite.validationPrerequisiteDefinitions.executionBlockedRequired;
  const incompleteReadiness = evaluateExternalTransportImplementationValidation({
    timestamp: stableTimestamp,
    readinessEvaluation: { ...readiness, overallImplementationReadiness: "IncompleteDefinition" }
  });
  const invalidReadiness = evaluateExternalTransportImplementationValidation({
    timestamp: stableTimestamp,
    readinessEvaluation: { ...readiness, futureValidationEligibility: "DefinitionIneligibleInvalid" }
  });
  const duplicateAudit = validateImplementationValidationAudit([...evaluation.audit, ...evaluation.audit], definition);
  const reorderedAudit = validateImplementationValidationAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-18T02:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-18T02:00:00.000Z" }
  ]);
  const badDiagnostics = { ...evaluation.diagnostics, runtimeEvidence: "none" };
  const invalidTransition = validateImplementationValidationTransitions([
    transition(implementationValidationStates.idle, implementationValidationStates.freezeValidationDefinition, "skip", stableTimestamp)
  ]);
  const skippedTransition = validateImplementationValidationTransitions([
    transition(implementationValidationStates.idle, implementationValidationStates.receiveReadinessEvaluation, "start", stableTimestamp),
    transition(implementationValidationStates.validateValidationDefinition, implementationValidationStates.constructValidationDefinition, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateImplementationValidationTransitions([
    transition(implementationValidationStates.idle, implementationValidationStates.receiveReadinessEvaluation, "start", stableTimestamp),
    transition(implementationValidationStates.receiveReadinessEvaluation, implementationValidationStates.resolveValidationRequirements, "resolve", stableTimestamp),
    transition(implementationValidationStates.resolveValidationRequirements, implementationValidationStates.receiveReadinessEvaluation, "cycle", stableTimestamp)
  ]);
  const repeatedTerminal = validateImplementationValidationTransitions([
    transition(implementationValidationStates.idle, implementationValidationStates.receiveReadinessEvaluation, "start", stableTimestamp),
    transition(implementationValidationStates.receiveReadinessEvaluation, implementationValidationStates.missingReadinessEvaluation, "stop", stableTimestamp),
    transition(implementationValidationStates.missingReadinessEvaluation, implementationValidationStates.missingReadinessEvaluation, "repeat", stableTimestamp)
  ]);
  const terminalMutation = validateImplementationValidationTransitions([
    transition(implementationValidationStates.idle, implementationValidationStates.receiveReadinessEvaluation, "start", stableTimestamp),
    transition(implementationValidationStates.receiveReadinessEvaluation, implementationValidationStates.missingReadinessEvaluation, "stop", stableTimestamp),
    transition(implementationValidationStates.missingReadinessEvaluation, implementationValidationStates.resolveValidationRequirements, "mutate", stableTimestamp)
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingReadinessEvaluationRejection", missingReadiness.validationDefinitionState === implementationValidationStates.missingReadinessEvaluation, "");
  assertSelfCheck(results, "requirementResolutionFailure", requirementFailure.validationDefinitionState === implementationValidationStates.requirementResolutionFailed, "");
  assertSelfCheck(results, "validationDefinitionRejection", validateImplementationValidationDefinition(badDefinition, readiness).ok === false, "");
  assertSelfCheck(results, "validationConstructionFailureStateDocumented", implementationValidationStates.constructionFailed === "ValidationConstructionFailed", "");
  assertSelfCheck(results, "freezeRejectionStateDocumented", implementationValidationStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "repeatedTerminalTransitionRejection", repeatedTerminal.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactTopLevelSchema", Object.keys(definition).length === validationDefinitionFields.length, "");
  assertSelfCheck(results, "unknownTopLevelFieldRejection", validateImplementationValidationDefinition(badDefinition, readiness).ok === false, "");
  assertSelfCheck(results, "missingTopLevelFieldRejection", validateImplementationValidationDefinition(missingDefinitionField, readiness).ok === false, "");
  assertSelfCheck(results, "duplicateIdRejection", validateImplementationValidationDefinition(duplicateDefinition, readiness).ok === false, "");
  assertSelfCheck(results, "unsupportedEnumRejection", validateImplementationValidationDefinition(badEnum, readiness).ok === false, "");
  assertSelfCheck(results, "unsupportedVerificationEligibilityRejection", validateImplementationValidationDefinition(badFutureEligibility, readiness).ok === false, "");
  assertSelfCheck(results, "exactCheckpointDefinitionSchema", Object.keys(definition.validationCheckpointDefinitions).length === checkpointDefinitionFields.length, "");
  assertSelfCheck(results, "exactBoundaryDefinitionSchema", Object.keys(definition.validationBoundaryDefinitions).length === boundaryDefinitionFields.length, "");
  assertSelfCheck(results, "exactPrerequisiteDefinitionSchema", Object.keys(definition.validationPrerequisiteDefinitions).length === prerequisiteDefinitionFields.length, "");
  assertSelfCheck(results, "checkpointUnknownOrOrderingRejection", validateImplementationValidationDefinition(badCheckpoint, readiness).ok === false, "");
  assertSelfCheck(results, "checkpointMissingFieldRejection", validateImplementationValidationDefinition(missingCheckpoint, readiness).ok === false, "");
  assertSelfCheck(results, "boundaryUnsafeRejection", validateImplementationValidationDefinition(badBoundary, readiness).ok === false, "");
  assertSelfCheck(results, "boundaryMissingFieldRejection", validateImplementationValidationDefinition(missingBoundary, readiness).ok === false, "");
  assertSelfCheck(results, "prerequisiteUnsafeRejection", validateImplementationValidationDefinition(badPrerequisite, readiness).ok === false, "");
  assertSelfCheck(results, "prerequisiteMissingFieldRejection", validateImplementationValidationDefinition(missingPrerequisite, readiness).ok === false, "");
  assertSelfCheck(results, "readinessEvaluationIdCorrelation", definition.readinessEvaluationId === readiness.readinessEvaluation.readinessEvaluationId, "");
  assertSelfCheck(results, "validationEvaluationIdCorrelation", definition.validationEvaluationId === `${readiness.readinessEvaluation.readinessEvaluationId}.validationDefinition`, "");
  assertSelfCheck(results, "readinessVersionPreservation", readiness.readinessEvaluation.readinessEvaluationVersion === implementationReadinessEvaluationVersion, "");
  assertSelfCheck(results, "readinessPublishedPrerequisite", readiness.readinessState === implementationReadinessStates.published, "");
  assertSelfCheck(results, "structuralReadinessPrerequisite", readiness.overallImplementationReadiness === "StructurallyReadyDefinition", "");
  assertSelfCheck(results, "futureValidationPrerequisite", readiness.futureValidationEligibility === "DefinitionEligibleForFutureValidation", "");
  assertSelfCheck(results, "incompleteReadinessRejection", incompleteReadiness.validationDefinitionState === implementationValidationStates.requirementResolutionFailed, "");
  assertSelfCheck(results, "invalidReadinessRejection", invalidReadiness.validationDefinitionState === implementationValidationStates.requirementResolutionFailed, "");
  assertSelfCheck(results, "definitionOnlyClassification", definition.implementationValidationState === "DefinitionOnly", "");
  assertSelfCheck(results, "futureVerificationEligibility", definition.futureVerificationEligibility === "DefinitionEligibleForVerification", "");
  assertSelfCheck(results, "exactValidationCheckpoints", exactList(definition.validationCheckpointDefinitions.requiredValidationCheckpoints, requiredValidationCheckpoints, "checkpoints").ok === true, "");
  assertSelfCheck(results, "checkpointOrderingRequired", definition.validationCheckpointDefinitions.strictOrderingRequired === true, "");
  assertSelfCheck(results, "readinessCorrelationRequired", definition.validationCheckpointDefinitions.readinessCorrelationRequired === true, "");
  assertSelfCheck(results, "immutableResultsRequired", definition.validationCheckpointDefinitions.immutableResultsRequired === true, "");
  assertSelfCheck(results, "definitionOnlyBoundary", definition.validationBoundaryDefinitions.definitionOnlyRequired === true, "");
  assertSelfCheck(results, "implementationDiscoveryBoundary", definition.validationBoundaryDefinitions.implementationDiscoveryProhibited === true, "");
  assertSelfCheck(results, "implementationInspectionBoundary", definition.validationBoundaryDefinitions.implementationInspectionProhibited === true, "");
  assertSelfCheck(results, "implementationLoadingBoundary", definition.validationBoundaryDefinitions.implementationLoadingProhibited === true, "");
  assertSelfCheck(results, "transportExecutionBoundary", definition.validationBoundaryDefinitions.transportExecutionProhibited === true, "");
  assertSelfCheck(results, "networkingBoundary", definition.validationBoundaryDefinitions.networkingProhibited === true, "");
  assertSelfCheck(results, "endpointDiscoveryBoundary", definition.validationBoundaryDefinitions.endpointDiscoveryProhibited === true, "");
  assertSelfCheck(results, "credentialBoundary", definition.validationBoundaryDefinitions.credentialHandlingProhibited === true, "");
  assertSelfCheck(results, "runtimeEvidenceBoundary", definition.validationBoundaryDefinitions.runtimeEvidenceProhibited === true, "");
  assertSelfCheck(results, "certificationBoundary", definition.validationBoundaryDefinitions.certificationProhibited === true, "");
  assertSelfCheck(results, "immutableTopLevelPublication", Object.isFrozen(definition), "");
  assertSelfCheck(results, "immutableNestedPublication", Object.isFrozen(definition.validationCheckpointDefinitions), "");
  assertSelfCheck(results, "deepFreezeValidation", Object.isFrozen(evaluation.audit) && Object.isFrozen(evaluation.diagnostics), "");
  assertSelfCheck(results, "topLevelMutationRejects", rejectsMutation(definition, (target) => { target.validationState = "invalid"; }), "");
  assertSelfCheck(results, "nestedMutationRejects", rejectsMutation(definition.validationBoundaryDefinitions, (target) => { target.networkingProhibited = false; }), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateImplementationValidationDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "auditValidation", evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicIds", definition.validationEvaluationId.endsWith(".validationDefinition"), "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && definition.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicDefinition", stableSerialize(definition) === stableSerialize(rerun.validationDefinition), "");
  assertSelfCheck(results, "deterministicDiagnostics", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "deterministicAudit", stableSerialize(evaluation.audit) === stableSerialize(rerun.audit), "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.validationDefinition) === stableSerialize(rerun.validationDefinition), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalTransportImplementationValidationAuthorityId, "");
  assertSelfCheck(results, "phase145RegressionCompatibility", readiness.authorityId === externalTransportImplementationReadinessAuthorityId, "");
  assertSelfCheck(results, "phase144RegressionCompatibility", readiness.implementationContractEvaluation.authorityId.includes("phase144"), "");
  assertSelfCheck(results, "phase143RegressionCompatibility", readiness.implementationContractEvaluation.compatibilityEvaluation.authorityId.includes("phase143"), "");
  assertSelfCheck(results, "phase142RegressionCompatibility", readiness.implementationContractEvaluation.compatibilityEvaluation.capabilityEvaluation.authorityId.includes("phase142"), "");
  assertSelfCheck(results, "phase141RegressionCompatibility", readiness.implementationContractEvaluation.compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.authorityId.includes("phase141"), "");
  assertSelfCheck(results, "phase140RegressionCompatibility", readiness.implementationContractEvaluation.compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.authorityId.includes("phase140"), "");
  assertSelfCheck(results, "noImplementationDiscovery", evaluation.implementationDiscovered === false, "");
  assertSelfCheck(results, "noImplementationInspection", evaluation.implementationInspected === false, "");
  assertSelfCheck(results, "noImplementationLoading", evaluation.implementationLoaded === false, "");
  assertSelfCheck(results, "noImplementationExecution", evaluation.implementationExecuted === false, "");
  assertSelfCheck(results, "noNetworking", !("network" in evaluation), "");
  assertSelfCheck(results, "noEndpointDiscovery", evaluation.endpointDiscovered === false, "");
  assertSelfCheck(results, "noCredentialHandling", !("credentialMaterial" in evaluation), "");
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
    readiness.implementationContractEvaluation.compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.compatibilityEvaluation
      .manifestEvaluation.contractEvaluation.boundaryEvaluation.dispatchEvaluation.requestEvaluation.orchestration.planning.readiness.runtimeTruth.sessionFailureReason ===
      "SESSION_NOT_VISIBLE",
    ""
  );

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExternalTransportImplementationValidationSelfChecks();
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
  const evaluation = evaluateExternalTransportImplementationValidation({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
