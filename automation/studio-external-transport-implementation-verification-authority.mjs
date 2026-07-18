import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateExternalTransportImplementationValidation,
  externalTransportImplementationValidationAuthorityId,
  implementationValidationDefinitionVersion,
  implementationValidationStates,
  validateImplementationValidationDefinition,
  validateImplementationValidationDiagnostics
} from "./studio-external-transport-implementation-validation-authority.mjs";
import { stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const implementationVerificationDefinitionSchemaVersion = 1;
export const implementationVerificationDefinitionVersion = "1.0.0";
export const externalTransportImplementationVerificationAuthorityId =
  "chapter0Home.phase147StudioExternalTransportImplementationVerificationAuthority";

export const implementationVerificationStates = Object.freeze({
  idle: "Idle",
  receiveValidationDefinition: "ReceiveValidationDefinition",
  resolveVerificationRequirements: "ResolveVerificationRequirements",
  validateVerificationDefinition: "ValidateVerificationDefinition",
  constructVerificationDefinition: "ConstructVerificationDefinition",
  freezeVerificationDefinition: "FreezeVerificationDefinition",
  published: "ImplementationVerificationPublished",
  missingValidationDefinition: "MissingValidationDefinition",
  requirementResolutionFailed: "VerificationRequirementResolutionFailed",
  rejected: "VerificationDefinitionRejected",
  constructionFailed: "VerificationConstructionFailed",
  freezeRejected: "FreezeRejected"
});

export const implementationVerificationClassifications = Object.freeze(["DefinitionOnly", "DefinitionIncomplete", "DefinitionInvalid"]);
export const futureExecutionEligibilityValues = Object.freeze([
  "DefinitionEligibleForExecutionPlanning",
  "DefinitionIneligibleIncomplete",
  "DefinitionIneligibleInvalid"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-18T02:30:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  implementationVerificationStates.published,
  implementationVerificationStates.missingValidationDefinition,
  implementationVerificationStates.requirementResolutionFailed,
  implementationVerificationStates.rejected,
  implementationVerificationStates.constructionFailed,
  implementationVerificationStates.freezeRejected
]);
const legalTransitions = new Map([
  [implementationVerificationStates.idle, new Set([implementationVerificationStates.receiveValidationDefinition])],
  [
    implementationVerificationStates.receiveValidationDefinition,
    new Set([implementationVerificationStates.resolveVerificationRequirements, implementationVerificationStates.missingValidationDefinition])
  ],
  [
    implementationVerificationStates.resolveVerificationRequirements,
    new Set([implementationVerificationStates.validateVerificationDefinition, implementationVerificationStates.requirementResolutionFailed])
  ],
  [
    implementationVerificationStates.validateVerificationDefinition,
    new Set([implementationVerificationStates.constructVerificationDefinition, implementationVerificationStates.rejected])
  ],
  [
    implementationVerificationStates.constructVerificationDefinition,
    new Set([implementationVerificationStates.freezeVerificationDefinition, implementationVerificationStates.constructionFailed])
  ],
  [
    implementationVerificationStates.freezeVerificationDefinition,
    new Set([implementationVerificationStates.published, implementationVerificationStates.freezeRejected])
  ]
]);

const verificationDefinitionFields = Object.freeze([
  "verificationEvaluationId",
  "verificationEvaluationVersion",
  "validationEvaluationId",
  "verificationCheckpointDefinitions",
  "verificationBoundaryDefinitions",
  "verificationPrerequisiteDefinitions",
  "implementationVerificationState",
  "futureExecutionEligibility",
  "validationState",
  "timestamp"
]);
const checkpointDefinitionFields = Object.freeze([
  "checkpointDefinitionVersion",
  "requiredVerificationCheckpoints",
  "strictOrderingRequired",
  "validationCorrelationRequired",
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
  "requiredValidationDefinitionState",
  "requiredImplementationValidationState",
  "requiredFutureVerificationEligibility",
  "requiredTransportAvailabilityState",
  "requiredExecutionEligibility",
  "executionBlockedRequired"
]);
const diagnosticsFields = Object.freeze([
  "verificationEvaluationVersion",
  "verificationDefinitionState",
  "implementationVerificationState",
  "futureExecutionEligibility",
  "executionBlocked",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "verificationEvaluationId",
  "validationEvaluationId",
  "authorityId",
  "implementationVerificationState",
  "futureExecutionEligibility",
  "timestamp",
  "verificationEvaluationVersion"
]);
const requiredVerificationCheckpoints = Object.freeze([
  "ValidationDefinitionValidated",
  "ValidationVersionValidated",
  "ValidationCorrelationValidated",
  "PrerequisiteDefinitionsValidated",
  "BoundaryDefinitionsValidated",
  "BlockedExecutionValidated",
  "FutureExecutionEligibilityValidated",
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
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalTransportImplementationVerificationAuthorityId });
}

export function validateImplementationVerificationTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "implementation verification transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(implementationVerificationStates).includes(item.from) || !Object.values(implementationVerificationStates).includes(item.to)) {
      return result(false, "undocumented implementation verification state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== implementationVerificationStates.idle) return result(false, "implementation verification lifecycle must start at Idle", "InvalidLifecycle");
    if (index > 0 && transitions[index - 1].to !== item.from) return result(false, "implementation verification lifecycle skipped state", "InvalidLifecycle");
    if (terminalStates.has(item.from) || terminalSeen) return result(false, "terminal implementation verification state mutated", "InvalidLifecycle");
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal implementation verification transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic implementation verification transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function createCheckpointDefinitions() {
  return deepFreeze({
    checkpointDefinitionVersion: implementationVerificationDefinitionVersion,
    requiredVerificationCheckpoints: [...requiredVerificationCheckpoints],
    strictOrderingRequired: true,
    validationCorrelationRequired: true,
    immutableResultsRequired: true
  });
}

function createBoundaryDefinitions() {
  return deepFreeze({
    boundaryDefinitionVersion: implementationVerificationDefinitionVersion,
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
    prerequisiteDefinitionVersion: implementationVerificationDefinitionVersion,
    requiredValidationDefinitionState: implementationValidationStates.published,
    requiredImplementationValidationState: "DefinitionOnly",
    requiredFutureVerificationEligibility: "DefinitionEligibleForVerification",
    requiredTransportAvailabilityState: "TransportUnavailable",
    requiredExecutionEligibility: "DefinitionCompatibleButUnavailable",
    executionBlockedRequired: true
  });
}

export function validateVerificationCheckpointDefinitions(definitions) {
  const fields = exactFields(definitions, checkpointDefinitionFields, "implementation verification checkpoint definitions");
  if (!fields.ok) return fields;
  if (definitions.checkpointDefinitionVersion !== implementationVerificationDefinitionVersion) return result(false, "checkpoint definition version unsupported", "CheckpointDefinitionInvalid");
  const checkpoints = exactList(definitions.requiredVerificationCheckpoints, requiredVerificationCheckpoints, "implementation verification checkpoints");
  if (!checkpoints.ok) return checkpoints;
  if (definitions.strictOrderingRequired !== true) return result(false, "checkpoint ordering must be strict", "CheckpointDefinitionInvalid");
  if (definitions.validationCorrelationRequired !== true) return result(false, "readiness correlation must be required", "CheckpointDefinitionInvalid");
  if (definitions.immutableResultsRequired !== true) return result(false, "checkpoint immutability must be required", "CheckpointDefinitionInvalid");
  return result(true);
}

export function validateVerificationBoundaryDefinitions(definitions) {
  const fields = exactFields(definitions, boundaryDefinitionFields, "implementation verification boundary definitions");
  if (!fields.ok) return fields;
  if (definitions.boundaryDefinitionVersion !== implementationVerificationDefinitionVersion) return result(false, "boundary definition version unsupported", "BoundaryDefinitionInvalid");
  for (const field of boundaryDefinitionFields.filter((key) => key !== "boundaryDefinitionVersion")) {
    if (definitions[field] !== true) return result(false, `${field} must be true`, "BoundaryDefinitionInvalid");
  }
  return result(true);
}

export function validateVerificationPrerequisiteDefinitions(definitions) {
  const fields = exactFields(definitions, prerequisiteDefinitionFields, "implementation verification prerequisite definitions");
  if (!fields.ok) return fields;
  if (definitions.prerequisiteDefinitionVersion !== implementationVerificationDefinitionVersion) return result(false, "prerequisite definition version unsupported", "PrerequisiteDefinitionInvalid");
  if (definitions.requiredValidationDefinitionState !== implementationValidationStates.published) return result(false, "validation definition state prerequisite invalid", "PrerequisiteDefinitionInvalid");
  if (definitions.requiredImplementationValidationState !== "DefinitionOnly") {
    return result(false, "implementation validation prerequisite invalid", "PrerequisiteDefinitionInvalid");
  }
  if (definitions.requiredFutureVerificationEligibility !== "DefinitionEligibleForVerification") {
    return result(false, "future verification prerequisite invalid", "PrerequisiteDefinitionInvalid");
  }
  if (definitions.requiredTransportAvailabilityState !== "TransportUnavailable") return result(false, "availability prerequisite invalid", "PrerequisiteDefinitionInvalid");
  if (definitions.requiredExecutionEligibility !== "DefinitionCompatibleButUnavailable") return result(false, "execution eligibility prerequisite invalid", "PrerequisiteDefinitionInvalid");
  if (definitions.executionBlockedRequired !== true) return result(false, "execution blocked prerequisite invalid", "PrerequisiteDefinitionInvalid");
  return result(true);
}

function validateValidationPreconditions(validationEvaluation) {
  if (!isPlainObject(validationEvaluation)) return result(false, "validation authority missing", "MissingValidationDefinition");
  if (!isPlainObject(validationEvaluation.validationDefinition)) return result(false, "validation definition missing", "MissingValidationDefinition");
  if (validationEvaluation.authorityId !== externalTransportImplementationValidationAuthorityId) {
    return result(false, "validation authority mismatch", "VerificationRequirementResolutionFailed");
  }
  const definitionValidation = validateImplementationValidationDefinition(
    validationEvaluation.validationDefinition,
    validationEvaluation.readinessEvaluation
  );
  if (!definitionValidation.ok) return definitionValidation;
  const diagnosticsValidation = validateImplementationValidationDiagnostics(validationEvaluation.diagnostics);
  if (!diagnosticsValidation.ok) return diagnosticsValidation;
  if (validationEvaluation.validationDefinitionState !== implementationValidationStates.published) {
    return result(false, "validation definition not published", "VerificationRequirementResolutionFailed");
  }
  if (validationEvaluation.implementationValidationState !== "DefinitionOnly") {
    return result(false, "implementation validation definition is not definition-only", "VerificationRequirementResolutionFailed");
  }
  if (validationEvaluation.futureVerificationEligibility !== "DefinitionEligibleForVerification") {
    return result(false, "future verification eligibility not granted", "VerificationRequirementResolutionFailed");
  }
  if (validationEvaluation.executionBlocked !== true) return result(false, "execution must remain blocked", "VerificationRequirementResolutionFailed");
  return result(true);
}

function createVerificationDefinition(validationEvaluation, timestamp) {
  return deepFreeze({
    verificationEvaluationId: `${validationEvaluation.validationDefinition.validationEvaluationId}.verificationDefinition`,
    verificationEvaluationVersion: implementationVerificationDefinitionVersion,
    validationEvaluationId: validationEvaluation.validationDefinition.validationEvaluationId,
    verificationCheckpointDefinitions: createCheckpointDefinitions(),
    verificationBoundaryDefinitions: createBoundaryDefinitions(),
    verificationPrerequisiteDefinitions: createPrerequisiteDefinitions(),
    implementationVerificationState: "DefinitionOnly",
    futureExecutionEligibility: "DefinitionEligibleForExecutionPlanning",
    validationState: "valid",
    timestamp
  });
}

export function validateImplementationVerificationDefinition(definition, validationEvaluation = null) {
  const fields = exactFields(definition, verificationDefinitionFields, "implementation verification definition");
  if (!fields.ok) return fields;
  for (const field of [
    "verificationEvaluationId",
    "verificationEvaluationVersion",
    "validationEvaluationId",
    "implementationVerificationState",
    "futureExecutionEligibility",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(definition[field], field);
    if (!id.ok) return id;
  }
  if (definition.verificationEvaluationVersion !== implementationVerificationDefinitionVersion) {
    return result(false, "verification evaluation version unsupported", "ValidationVersionInvalid");
  }
  if (!implementationVerificationClassifications.includes(definition.implementationVerificationState)) {
    return result(false, "implementation verification state unsupported", "ImplementationVerificationStateInvalid");
  }
  if (definition.implementationVerificationState !== "DefinitionOnly") {
    return result(false, "Phase 147 can publish DefinitionOnly only", "ImplementationVerificationStateInvalid");
  }
  if (!futureExecutionEligibilityValues.includes(definition.futureExecutionEligibility)) {
    return result(false, "future execution eligibility unsupported", "FutureExecutionEligibilityInvalid");
  }
  if (definition.futureExecutionEligibility !== "DefinitionEligibleForExecutionPlanning") {
    return result(false, "Phase 147 normal publication must remain verification definition eligible", "FutureExecutionEligibilityInvalid");
  }
  if (definition.validationState !== "valid") return result(false, "validation state invalid", "ValidationStateInvalid");
  const checkpoints = validateVerificationCheckpointDefinitions(definition.verificationCheckpointDefinitions);
  if (!checkpoints.ok) return checkpoints;
  const boundaries = validateVerificationBoundaryDefinitions(definition.verificationBoundaryDefinitions);
  if (!boundaries.ok) return boundaries;
  const prerequisites = validateVerificationPrerequisiteDefinitions(definition.verificationPrerequisiteDefinitions);
  if (!prerequisites.ok) return prerequisites;
  if (validationEvaluation !== null) {
    if (definition.validationEvaluationId !== validationEvaluation.validationDefinition.validationEvaluationId) {
      return result(false, "validation evaluation ID drift", "CorrelationMismatch");
    }
    if (definition.verificationEvaluationId !== `${validationEvaluation.validationDefinition.validationEvaluationId}.verificationDefinition`) {
      return result(false, "verification definition ID drift", "CorrelationMismatch");
    }
    const ids = new Set([definition.verificationEvaluationId, definition.validationEvaluationId]);
    if (ids.size !== 2) return result(false, "duplicate validation definition identifiers", "DuplicateIdentifier");
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    verificationEvaluationVersion: implementationVerificationDefinitionVersion,
    verificationDefinitionState: evaluation.verificationDefinitionState,
    implementationVerificationState: evaluation.implementationVerificationState,
    futureExecutionEligibility: evaluation.futureExecutionEligibility,
    executionBlocked: evaluation.executionBlocked,
    validationState: evaluation.validationState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateImplementationVerificationDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "implementation verification diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.verificationEvaluationVersion !== implementationVerificationDefinitionVersion) return result(false, "diagnostics version unsupported", "DiagnosticsInvalid");
  if (!Object.values(implementationVerificationStates).includes(diagnostics.verificationDefinitionState)) return result(false, "diagnostics definition state invalid", "DiagnosticsInvalid");
  if (diagnostics.implementationVerificationState !== "DefinitionOnly") return result(false, "diagnostics classification invalid", "DiagnosticsInvalid");
  if (diagnostics.futureExecutionEligibility !== "DefinitionEligibleForExecutionPlanning") return result(false, "diagnostics verification eligibility invalid", "DiagnosticsInvalid");
  if (diagnostics.executionBlocked !== true) return result(false, "diagnostics execution must remain blocked", "DiagnosticsInvalid");
  if (diagnostics.validationState !== "valid") return result(false, "diagnostics validation state invalid", "DiagnosticsInvalid");
  return result(true);
}

function createAudit(definition, verificationDefinitionState, timestamp) {
  return deepFreeze([
    {
      verificationEvaluationId: definition?.verificationEvaluationId ?? "missing",
      validationEvaluationId: definition?.validationEvaluationId ?? "missing",
      authorityId: externalTransportImplementationVerificationAuthorityId,
      implementationVerificationState: definition?.implementationVerificationState ?? "DefinitionIncomplete",
      futureExecutionEligibility: definition?.futureExecutionEligibility ?? "DefinitionIneligibleIncomplete",
      timestamp,
      verificationEvaluationVersion: implementationVerificationDefinitionVersion
    }
  ]);
}

export function validateImplementationVerificationAudit(audit, definition = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "implementation verification audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "implementation verification audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalTransportImplementationVerificationAuthorityId) return result(false, "implementation verification audit authority mismatch", "InvalidAudit");
    if (!implementationVerificationClassifications.includes(item.implementationVerificationState)) {
      return result(false, "implementation verification audit classification invalid", "InvalidAudit");
    }
    if (!futureExecutionEligibilityValues.includes(item.futureExecutionEligibility)) {
      return result(false, "implementation verification audit verification eligibility invalid", "InvalidAudit");
    }
    if (definition !== null && item.verificationEvaluationId !== definition.verificationEvaluationId) {
      return result(false, "implementation verification audit identity mismatch", "InvalidAudit");
    }
    const identity = `${item.verificationEvaluationId}:${item.validationEvaluationId}:${item.authorityId}`;
    if (identities.has(identity)) return result(false, "duplicate implementation verification audit identity", "InvalidAudit");
    identities.add(identity);
    const orderingKey = `${item.timestamp}:${identity}`;
    if (previousKey && orderingKey < previousKey) return result(false, "implementation verification audit ordering invalid", "InvalidAudit");
    previousKey = orderingKey;
  }
  return result(true);
}

export function evaluateExternalTransportImplementationVerification(input = {}) {
  const timestamp = input.timestamp ?? now();
  const repositoryState =
    input.repositoryState ?? {
      branch: "main",
      localHead: input.repositoryRevision ?? stableCommit,
      remoteHead: input.repositoryRevision ?? stableCommit,
      workingTreeClean: true,
      originSynchronized: true
    };
  const validationEvaluation =
    input.validationEvaluation ??
    evaluateExternalTransportImplementationValidation({
      timestamp,
      repositoryState,
      repositoryRevision: input.repositoryRevision
    });
  const transitions = [];
  transitions.push(transition(implementationVerificationStates.idle, implementationVerificationStates.receiveValidationDefinition, "start", timestamp));

  let verificationDefinitionState = implementationVerificationStates.published;
  let validationState = "valid";
  let failureReason = null;
  let verificationDefinition = null;
  const preconditions = validateValidationPreconditions(validationEvaluation);
  if (!preconditions.ok) {
    verificationDefinitionState =
      preconditions.failure === "MissingValidationDefinition"
        ? implementationVerificationStates.missingValidationDefinition
        : implementationVerificationStates.requirementResolutionFailed;
    failureReason = preconditions.reason;
    validationState = "invalid";
    transitions.push(transition(implementationVerificationStates.receiveValidationDefinition, verificationDefinitionState, failureReason, timestamp));
  } else {
    transitions.push(
      transition(implementationVerificationStates.receiveValidationDefinition, implementationVerificationStates.resolveVerificationRequirements, "validation definition received", timestamp)
    );
    transitions.push(
      transition(implementationVerificationStates.resolveVerificationRequirements, implementationVerificationStates.validateVerificationDefinition, "requirements resolved", timestamp)
    );
    verificationDefinition = createVerificationDefinition(validationEvaluation, timestamp);
    const definitionValidation = validateImplementationVerificationDefinition(verificationDefinition, validationEvaluation);
    if (!definitionValidation.ok) {
      verificationDefinitionState = implementationVerificationStates.rejected;
      failureReason = definitionValidation.reason;
      validationState = "invalid";
      transitions.push(transition(implementationVerificationStates.validateVerificationDefinition, verificationDefinitionState, failureReason, timestamp));
    } else {
      transitions.push(
        transition(implementationVerificationStates.validateVerificationDefinition, implementationVerificationStates.constructVerificationDefinition, "definition valid", timestamp)
      );
      transitions.push(
        transition(implementationVerificationStates.constructVerificationDefinition, implementationVerificationStates.freezeVerificationDefinition, "definition constructed", timestamp)
      );
      if (!Object.isFrozen(verificationDefinition) || !Object.isFrozen(verificationDefinition.verificationCheckpointDefinitions)) {
        verificationDefinitionState = implementationVerificationStates.freezeRejected;
        failureReason = "verification definition was not frozen";
        validationState = "invalid";
        transitions.push(transition(implementationVerificationStates.freezeVerificationDefinition, verificationDefinitionState, failureReason, timestamp));
      } else {
        transitions.push(transition(implementationVerificationStates.freezeVerificationDefinition, implementationVerificationStates.published, "definition frozen", timestamp));
      }
    }
  }

  const transitionValidation = validateImplementationVerificationTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) {
    verificationDefinitionState = implementationVerificationStates.constructionFailed;
    failureReason = transitionValidation.reason;
    validationState = "invalid";
  }

  const implementationVerificationState = verificationDefinition?.implementationVerificationState ?? "DefinitionIncomplete";
  const futureExecutionEligibility = verificationDefinition?.futureExecutionEligibility ?? "DefinitionIneligibleIncomplete";
  const evaluation = {
    phase: 147,
    authorityId: externalTransportImplementationVerificationAuthorityId,
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
    verificationDefinitionState,
    implementationVerificationState,
    futureExecutionEligibility,
    validationDefinitionState: validationEvaluation?.validationDefinitionState ?? "MissingValidationDefinition",
    upstreamImplementationValidationState: validationEvaluation?.implementationValidationState ?? "DefinitionIncomplete",
    upstreamFutureVerificationEligibility: validationEvaluation?.futureVerificationEligibility ?? "DefinitionIneligibleIncomplete",
    readinessState: validationEvaluation?.readinessState ?? "MissingReadinessEvaluation",
    overallImplementationReadiness: validationEvaluation?.overallImplementationReadiness ?? "IncompleteDefinition",
    futureValidationEligibility: validationEvaluation?.futureValidationEligibility ?? "DefinitionIneligibleIncomplete",
    implementationContractState: validationEvaluation?.implementationContractState ?? "MissingImplementationContract",
    implementationReadiness: validationEvaluation?.implementationReadiness ?? "DefinitionOnly",
    overallTransportCompatibility: validationEvaluation?.overallTransportCompatibility ?? "IncompleteDefinition",
    transportAvailabilityState: validationEvaluation?.transportAvailabilityState ?? "TransportUnavailable",
    executionEligibility: validationEvaluation?.executionEligibility ?? "DefinitionCompatibleButUnavailable",
    validationState,
    failureReason,
    validationEvaluation,
    verificationDefinition,
    transitions,
    transitionValidation,
    audit: createAudit(verificationDefinition, verificationDefinitionState, timestamp),
    timestamp,
    sourceAuthorities: [
      "Phase140ExternalExecutionEnvelopeAuthority",
      "Phase141ExternalEnvelopeTransportContractAuthority",
      "Phase142ExternalEnvelopeTransportCapabilityAuthority",
      "Phase143ExternalTransportCompatibilityAuthority",
      "Phase144ExternalTransportImplementationContractAuthority",
      "Phase145ExternalTransportImplementationReadinessAuthority",
      "Phase146ExternalTransportImplementationValidationAuthority"
    ],
    nextRecommendedAuthority: "Phase148ExternalTransportExecutionPlanningAuthority",
    recommendedAction: "Define future execution planning authority before any implementation may be inspected, loaded, or executed."
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateImplementationVerificationDiagnostics(diagnosticsFor(evaluation)),
    auditValidation: validateImplementationVerificationAudit(evaluation.audit, verificationDefinition),
    verificationDefinitionValidation: verificationDefinition ? validateImplementationVerificationDefinition(verificationDefinition, validationEvaluation) : result(false),
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

export function runExternalTransportImplementationVerificationSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExternalTransportImplementationVerification({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExternalTransportImplementationVerification({ timestamp: stableTimestamp, repositoryState });
  const validation = evaluation.validationEvaluation;
  const definition = evaluation.verificationDefinition;
  const missingValidation = evaluateExternalTransportImplementationVerification({ timestamp: stableTimestamp, validationEvaluation: {} });
  const requirementFailure = evaluateExternalTransportImplementationVerification({
    timestamp: stableTimestamp,
    validationEvaluation: { ...validation, authorityId: "wrong" }
  });
  const badDefinition = { ...definition, extra: true };
  const missingDefinitionField = { ...definition };
  delete missingDefinitionField.futureExecutionEligibility;
  const duplicateDefinition = { ...definition, verificationEvaluationId: definition.validationEvaluationId };
  const badEnum = { ...definition, implementationVerificationState: "ValidationReady" };
  const badFutureEligibility = { ...definition, futureExecutionEligibility: "DefinitionEligibleForRuntime" };
  const badCheckpoint = {
    ...definition,
    verificationCheckpointDefinitions: {
      ...definition.verificationCheckpointDefinitions,
      requiredVerificationCheckpoints: [...requiredVerificationCheckpoints].reverse()
    }
  };
  const missingCheckpoint = {
    ...definition,
    verificationCheckpointDefinitions: { ...definition.verificationCheckpointDefinitions }
  };
  delete missingCheckpoint.verificationCheckpointDefinitions.strictOrderingRequired;
  const badBoundary = {
    ...definition,
    verificationBoundaryDefinitions: { ...definition.verificationBoundaryDefinitions, networkingProhibited: false }
  };
  const missingBoundary = {
    ...definition,
    verificationBoundaryDefinitions: { ...definition.verificationBoundaryDefinitions }
  };
  delete missingBoundary.verificationBoundaryDefinitions.certificationProhibited;
  const badPrerequisite = {
    ...definition,
    verificationPrerequisiteDefinitions: {
      ...definition.verificationPrerequisiteDefinitions,
      requiredTransportAvailabilityState: "TransportAvailable"
    }
  };
  const missingPrerequisite = {
    ...definition,
    verificationPrerequisiteDefinitions: { ...definition.verificationPrerequisiteDefinitions }
  };
  delete missingPrerequisite.verificationPrerequisiteDefinitions.executionBlockedRequired;
  const incompleteValidation = evaluateExternalTransportImplementationVerification({
    timestamp: stableTimestamp,
    validationEvaluation: { ...validation, implementationValidationState: "DefinitionIncomplete" }
  });
  const invalidValidation = evaluateExternalTransportImplementationVerification({
    timestamp: stableTimestamp,
    validationEvaluation: { ...validation, futureVerificationEligibility: "DefinitionIneligibleInvalid" }
  });
  const duplicateAudit = validateImplementationVerificationAudit([...evaluation.audit, ...evaluation.audit], definition);
  const reorderedAudit = validateImplementationVerificationAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-18T02:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-18T02:30:00.000Z" }
  ]);
  const badDiagnostics = { ...evaluation.diagnostics, runtimeEvidence: "none" };
  const invalidTransition = validateImplementationVerificationTransitions([
    transition(implementationVerificationStates.idle, implementationVerificationStates.freezeVerificationDefinition, "skip", stableTimestamp)
  ]);
  const skippedTransition = validateImplementationVerificationTransitions([
    transition(implementationVerificationStates.idle, implementationVerificationStates.receiveValidationDefinition, "start", stableTimestamp),
    transition(implementationVerificationStates.validateVerificationDefinition, implementationVerificationStates.constructVerificationDefinition, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateImplementationVerificationTransitions([
    transition(implementationVerificationStates.idle, implementationVerificationStates.receiveValidationDefinition, "start", stableTimestamp),
    transition(implementationVerificationStates.receiveValidationDefinition, implementationVerificationStates.resolveVerificationRequirements, "resolve", stableTimestamp),
    transition(implementationVerificationStates.resolveVerificationRequirements, implementationVerificationStates.receiveValidationDefinition, "cycle", stableTimestamp)
  ]);
  const repeatedTerminal = validateImplementationVerificationTransitions([
    transition(implementationVerificationStates.idle, implementationVerificationStates.receiveValidationDefinition, "start", stableTimestamp),
    transition(implementationVerificationStates.receiveValidationDefinition, implementationVerificationStates.missingValidationDefinition, "stop", stableTimestamp),
    transition(implementationVerificationStates.missingValidationDefinition, implementationVerificationStates.missingValidationDefinition, "repeat", stableTimestamp)
  ]);
  const terminalMutation = validateImplementationVerificationTransitions([
    transition(implementationVerificationStates.idle, implementationVerificationStates.receiveValidationDefinition, "start", stableTimestamp),
    transition(implementationVerificationStates.receiveValidationDefinition, implementationVerificationStates.missingValidationDefinition, "stop", stableTimestamp),
    transition(implementationVerificationStates.missingValidationDefinition, implementationVerificationStates.resolveVerificationRequirements, "mutate", stableTimestamp)
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingValidationDefinitionRejection", missingValidation.verificationDefinitionState === implementationVerificationStates.missingValidationDefinition, "");
  assertSelfCheck(results, "requirementResolutionFailure", requirementFailure.verificationDefinitionState === implementationVerificationStates.requirementResolutionFailed, "");
  assertSelfCheck(results, "verificationDefinitionRejection", validateImplementationVerificationDefinition(badDefinition, validation).ok === false, "");
  assertSelfCheck(results, "verificationConstructionFailureStateDocumented", implementationVerificationStates.constructionFailed === "VerificationConstructionFailed", "");
  assertSelfCheck(results, "freezeRejectionStateDocumented", implementationVerificationStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "repeatedTerminalTransitionRejection", repeatedTerminal.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactTopLevelSchema", Object.keys(definition).length === verificationDefinitionFields.length, "");
  assertSelfCheck(results, "unknownTopLevelFieldRejection", validateImplementationVerificationDefinition(badDefinition, validation).ok === false, "");
  assertSelfCheck(results, "missingTopLevelFieldRejection", validateImplementationVerificationDefinition(missingDefinitionField, validation).ok === false, "");
  assertSelfCheck(results, "duplicateIdRejection", validateImplementationVerificationDefinition(duplicateDefinition, validation).ok === false, "");
  assertSelfCheck(results, "unsupportedEnumRejection", validateImplementationVerificationDefinition(badEnum, validation).ok === false, "");
  assertSelfCheck(results, "unsupportedVerificationEligibilityRejection", validateImplementationVerificationDefinition(badFutureEligibility, validation).ok === false, "");
  assertSelfCheck(results, "exactCheckpointDefinitionSchema", Object.keys(definition.verificationCheckpointDefinitions).length === checkpointDefinitionFields.length, "");
  assertSelfCheck(results, "exactBoundaryDefinitionSchema", Object.keys(definition.verificationBoundaryDefinitions).length === boundaryDefinitionFields.length, "");
  assertSelfCheck(results, "exactPrerequisiteDefinitionSchema", Object.keys(definition.verificationPrerequisiteDefinitions).length === prerequisiteDefinitionFields.length, "");
  assertSelfCheck(results, "checkpointUnknownOrOrderingRejection", validateImplementationVerificationDefinition(badCheckpoint, validation).ok === false, "");
  assertSelfCheck(results, "checkpointMissingFieldRejection", validateImplementationVerificationDefinition(missingCheckpoint, validation).ok === false, "");
  assertSelfCheck(results, "boundaryUnsafeRejection", validateImplementationVerificationDefinition(badBoundary, validation).ok === false, "");
  assertSelfCheck(results, "boundaryMissingFieldRejection", validateImplementationVerificationDefinition(missingBoundary, validation).ok === false, "");
  assertSelfCheck(results, "prerequisiteUnsafeRejection", validateImplementationVerificationDefinition(badPrerequisite, validation).ok === false, "");
  assertSelfCheck(results, "prerequisiteMissingFieldRejection", validateImplementationVerificationDefinition(missingPrerequisite, validation).ok === false, "");
  assertSelfCheck(results, "validationEvaluationIdCorrelation", definition.validationEvaluationId === validation.validationDefinition.validationEvaluationId, "");
  assertSelfCheck(results, "verificationEvaluationIdCorrelation", definition.verificationEvaluationId === `${validation.validationDefinition.validationEvaluationId}.verificationDefinition`, "");
  assertSelfCheck(results, "validationVersionPreservation", validation.validationDefinition.validationEvaluationVersion === implementationValidationDefinitionVersion, "");
  assertSelfCheck(results, "validationPublishedPrerequisite", validation.validationDefinitionState === implementationValidationStates.published, "");
  assertSelfCheck(results, "definitionOnlyValidationPrerequisite", validation.implementationValidationState === "DefinitionOnly", "");
  assertSelfCheck(results, "futureVerificationPrerequisite", validation.futureVerificationEligibility === "DefinitionEligibleForVerification", "");
  assertSelfCheck(results, "incompleteValidationRejection", incompleteValidation.verificationDefinitionState === implementationVerificationStates.requirementResolutionFailed, "");
  assertSelfCheck(results, "invalidValidationRejection", invalidValidation.verificationDefinitionState === implementationVerificationStates.requirementResolutionFailed, "");
  assertSelfCheck(results, "definitionOnlyClassification", definition.implementationVerificationState === "DefinitionOnly", "");
  assertSelfCheck(results, "futureExecutionEligibility", definition.futureExecutionEligibility === "DefinitionEligibleForExecutionPlanning", "");
  assertSelfCheck(results, "exactVerificationCheckpoints", exactList(definition.verificationCheckpointDefinitions.requiredVerificationCheckpoints, requiredVerificationCheckpoints, "checkpoints").ok === true, "");
  assertSelfCheck(results, "checkpointOrderingRequired", definition.verificationCheckpointDefinitions.strictOrderingRequired === true, "");
  assertSelfCheck(results, "validationCorrelationRequired", definition.verificationCheckpointDefinitions.validationCorrelationRequired === true, "");
  assertSelfCheck(results, "immutableResultsRequired", definition.verificationCheckpointDefinitions.immutableResultsRequired === true, "");
  assertSelfCheck(results, "definitionOnlyBoundary", definition.verificationBoundaryDefinitions.definitionOnlyRequired === true, "");
  assertSelfCheck(results, "implementationDiscoveryBoundary", definition.verificationBoundaryDefinitions.implementationDiscoveryProhibited === true, "");
  assertSelfCheck(results, "implementationInspectionBoundary", definition.verificationBoundaryDefinitions.implementationInspectionProhibited === true, "");
  assertSelfCheck(results, "implementationLoadingBoundary", definition.verificationBoundaryDefinitions.implementationLoadingProhibited === true, "");
  assertSelfCheck(results, "transportExecutionBoundary", definition.verificationBoundaryDefinitions.transportExecutionProhibited === true, "");
  assertSelfCheck(results, "networkingBoundary", definition.verificationBoundaryDefinitions.networkingProhibited === true, "");
  assertSelfCheck(results, "endpointDiscoveryBoundary", definition.verificationBoundaryDefinitions.endpointDiscoveryProhibited === true, "");
  assertSelfCheck(results, "credentialBoundary", definition.verificationBoundaryDefinitions.credentialHandlingProhibited === true, "");
  assertSelfCheck(results, "runtimeEvidenceBoundary", definition.verificationBoundaryDefinitions.runtimeEvidenceProhibited === true, "");
  assertSelfCheck(results, "certificationBoundary", definition.verificationBoundaryDefinitions.certificationProhibited === true, "");
  assertSelfCheck(results, "immutableTopLevelPublication", Object.isFrozen(definition), "");
  assertSelfCheck(results, "immutableNestedPublication", Object.isFrozen(definition.verificationCheckpointDefinitions), "");
  assertSelfCheck(results, "deepFreezeValidation", Object.isFrozen(evaluation.audit) && Object.isFrozen(evaluation.diagnostics), "");
  assertSelfCheck(results, "topLevelMutationRejects", rejectsMutation(definition, (target) => { target.validationState = "invalid"; }), "");
  assertSelfCheck(results, "nestedMutationRejects", rejectsMutation(definition.verificationBoundaryDefinitions, (target) => { target.networkingProhibited = false; }), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateImplementationVerificationDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "auditValidation", evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicIds", definition.verificationEvaluationId.endsWith(".verificationDefinition"), "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && definition.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicDefinition", stableSerialize(definition) === stableSerialize(rerun.verificationDefinition), "");
  assertSelfCheck(results, "deterministicDiagnostics", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "deterministicAudit", stableSerialize(evaluation.audit) === stableSerialize(rerun.audit), "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.verificationDefinition) === stableSerialize(rerun.verificationDefinition), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalTransportImplementationVerificationAuthorityId, "");
  assertSelfCheck(results, "phase146RegressionCompatibility", validation.authorityId === externalTransportImplementationValidationAuthorityId, "");
  assertSelfCheck(results, "phase145RegressionCompatibility", validation.readinessEvaluation.authorityId.includes("phase145"), "");
  assertSelfCheck(results, "phase144RegressionCompatibility", validation.readinessEvaluation.implementationContractEvaluation.authorityId.includes("phase144"), "");
  assertSelfCheck(results, "phase143RegressionCompatibility", validation.readinessEvaluation.implementationContractEvaluation.compatibilityEvaluation.authorityId.includes("phase143"), "");
  assertSelfCheck(results, "phase142RegressionCompatibility", validation.readinessEvaluation.implementationContractEvaluation.compatibilityEvaluation.capabilityEvaluation.authorityId.includes("phase142"), "");
  assertSelfCheck(results, "phase141RegressionCompatibility", validation.readinessEvaluation.implementationContractEvaluation.compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.authorityId.includes("phase141"), "");
  assertSelfCheck(results, "phase140RegressionCompatibility", validation.readinessEvaluation.implementationContractEvaluation.compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.authorityId.includes("phase140"), "");
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
    validation.readinessEvaluation.implementationContractEvaluation.compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.compatibilityEvaluation
      .manifestEvaluation.contractEvaluation.boundaryEvaluation.dispatchEvaluation.requestEvaluation.orchestration.planning.readiness.runtimeTruth.sessionFailureReason ===
      "SESSION_NOT_VISIBLE",
    ""
  );

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExternalTransportImplementationVerificationSelfChecks();
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
  const evaluation = evaluateExternalTransportImplementationVerification({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
