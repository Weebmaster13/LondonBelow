import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  checkpointNames,
  evaluateExternalTransportImplementationContract,
  externalTransportImplementationContractAuthorityId,
  failureCodes,
  implementationContractStates,
  implementationContractVersion,
  implementationStates,
  terminalImplementationStates,
  validateBoundaryContract,
  validateCheckpointContract,
  validateFailureContract,
  validateImplementationContract,
  validateImplementationDiagnostics,
  validateLifecycleContract
} from "./studio-external-transport-implementation-contract-authority.mjs";
import { externalTransportCompatibilityVersion } from "./studio-external-transport-compatibility-authority.mjs";
import { transportCapabilityProfileVersion } from "./studio-envelope-transport-capability-authority.mjs";
import { transportContractVersion } from "./studio-envelope-transport-contract-authority.mjs";
import { stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const implementationReadinessEvaluationSchemaVersion = 1;
export const implementationReadinessEvaluationVersion = "1.0.0";
export const externalTransportImplementationReadinessAuthorityId =
  "chapter0Home.phase145StudioExternalTransportImplementationReadinessAuthority";

export const implementationReadinessStates = Object.freeze({
  idle: "Idle",
  receiveImplementationContract: "ReceiveImplementationContract",
  resolveReadinessInputs: "ResolveReadinessInputs",
  validateReadinessCorrelation: "ValidateReadinessCorrelation",
  evaluateImplementationContractReadiness: "EvaluateImplementationContractReadiness",
  constructReadinessEvaluation: "ConstructReadinessEvaluation",
  freezeReadinessEvaluation: "FreezeReadinessEvaluation",
  published: "ImplementationReadinessPublished",
  missingImplementationContract: "MissingImplementationContract",
  inputResolutionFailed: "ReadinessInputResolutionFailed",
  correlationRejected: "ReadinessCorrelationRejected",
  evaluationFailed: "ReadinessEvaluationFailed",
  constructionFailed: "ReadinessConstructionFailed",
  freezeRejected: "FreezeRejected"
});

export const componentReadinessResults = Object.freeze(["ReadyDefinition", "IncompleteDefinition", "InvalidDefinition"]);
export const overallImplementationReadinessValues = Object.freeze([
  "StructurallyReadyDefinition",
  "IncompleteDefinition",
  "InvalidDefinition"
]);
export const futureValidationEligibilityValues = Object.freeze([
  "DefinitionEligibleForFutureValidation",
  "DefinitionIneligibleIncomplete",
  "DefinitionIneligibleInvalid"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-18T01:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const expectedReadinessFields = Object.freeze([
  "readinessEvaluationId",
  "readinessEvaluationVersion",
  "implementationContractId",
  "implementationContractVersion",
  "prerequisiteReadinessResult",
  "lifecycleReadinessResult",
  "checkpointReadinessResult",
  "failureContractReadinessResult",
  "boundaryReadinessResult",
  "overallImplementationReadiness",
  "futureValidationEligibility",
  "correlationSnapshot",
  "validationState",
  "timestamp"
]);
const correlationFields = Object.freeze([
  "implementationContractId",
  "implementationContractVersion",
  "compatibilityEvaluationId",
  "requiredTransportContractVersion",
  "requiredCapabilityProfileVersion",
  "requiredCompatibilityEvaluationVersion",
  "strictCorrelationValidated"
]);
const diagnosticsFields = Object.freeze([
  "readinessEvaluationVersion",
  "readinessState",
  "overallImplementationReadiness",
  "futureValidationEligibility",
  "transportAvailabilityState",
  "executionEligibility",
  "executionBlocked",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "readinessEvaluationId",
  "implementationContractId",
  "compatibilityEvaluationId",
  "transportContractId",
  "capabilityId",
  "authorityId",
  "readinessState",
  "overallImplementationReadiness",
  "futureValidationEligibility",
  "transportAvailabilityState",
  "executionEligibility",
  "timestamp",
  "readinessEvaluationVersion"
]);
const terminalStates = new Set([
  implementationReadinessStates.published,
  implementationReadinessStates.missingImplementationContract,
  implementationReadinessStates.inputResolutionFailed,
  implementationReadinessStates.correlationRejected,
  implementationReadinessStates.evaluationFailed,
  implementationReadinessStates.constructionFailed,
  implementationReadinessStates.freezeRejected
]);
const legalTransitions = new Map([
  [implementationReadinessStates.idle, new Set([implementationReadinessStates.receiveImplementationContract])],
  [
    implementationReadinessStates.receiveImplementationContract,
    new Set([implementationReadinessStates.resolveReadinessInputs, implementationReadinessStates.missingImplementationContract])
  ],
  [
    implementationReadinessStates.resolveReadinessInputs,
    new Set([implementationReadinessStates.validateReadinessCorrelation, implementationReadinessStates.inputResolutionFailed])
  ],
  [
    implementationReadinessStates.validateReadinessCorrelation,
    new Set([implementationReadinessStates.evaluateImplementationContractReadiness, implementationReadinessStates.correlationRejected])
  ],
  [
    implementationReadinessStates.evaluateImplementationContractReadiness,
    new Set([implementationReadinessStates.constructReadinessEvaluation, implementationReadinessStates.evaluationFailed])
  ],
  [
    implementationReadinessStates.constructReadinessEvaluation,
    new Set([implementationReadinessStates.freezeReadinessEvaluation, implementationReadinessStates.constructionFailed])
  ],
  [
    implementationReadinessStates.freezeReadinessEvaluation,
    new Set([implementationReadinessStates.published, implementationReadinessStates.freezeRejected])
  ]
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

function hasRequiredFields(value, fields) {
  if (!isPlainObject(value)) return false;
  return fields.every((field) => field in value);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalTransportImplementationReadinessAuthorityId });
}

export function validateImplementationReadinessTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "implementation readiness transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(implementationReadinessStates).includes(item.from) || !Object.values(implementationReadinessStates).includes(item.to)) {
      return result(false, "undocumented implementation readiness state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== implementationReadinessStates.idle) return result(false, "implementation readiness lifecycle must start at Idle", "InvalidLifecycle");
    if (index > 0 && transitions[index - 1].to !== item.from) return result(false, "implementation readiness lifecycle skipped state", "InvalidLifecycle");
    if (terminalStates.has(item.from) || terminalSeen) return result(false, "terminal implementation readiness state mutated", "InvalidLifecycle");
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal implementation readiness transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic implementation readiness transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function classifyOverall(componentResults) {
  if (componentResults.includes("InvalidDefinition")) return "InvalidDefinition";
  if (componentResults.includes("IncompleteDefinition")) return "IncompleteDefinition";
  return "StructurallyReadyDefinition";
}

function classifyFutureValidationEligibility(overall) {
  if (overall === "StructurallyReadyDefinition") return "DefinitionEligibleForFutureValidation";
  if (overall === "IncompleteDefinition") return "DefinitionIneligibleIncomplete";
  return "DefinitionIneligibleInvalid";
}

function createCorrelationSnapshot(contract) {
  return deepFreeze({
    implementationContractId: contract.implementationContractId,
    implementationContractVersion: contract.implementationContractVersion,
    compatibilityEvaluationId: contract.compatibilityEvaluationId,
    requiredTransportContractVersion: contract.requiredTransportContractVersion,
    requiredCapabilityProfileVersion: contract.requiredCapabilityProfileVersion,
    requiredCompatibilityEvaluationVersion: contract.requiredCompatibilityEvaluationVersion,
    strictCorrelationValidated: true
  });
}

export function validateReadinessCorrelationSnapshot(snapshot, contract = null) {
  const fields = exactFields(snapshot, correlationFields, "implementation readiness correlation");
  if (!fields.ok) return fields;
  for (const field of [
    "implementationContractId",
    "implementationContractVersion",
    "compatibilityEvaluationId",
    "requiredTransportContractVersion",
    "requiredCapabilityProfileVersion",
    "requiredCompatibilityEvaluationVersion"
  ]) {
    const id = validateIdentifier(snapshot[field], field);
    if (!id.ok) return id;
  }
  if (snapshot.strictCorrelationValidated !== true) return result(false, "strict correlation flag invalid", "CorrelationMismatch");
  if (snapshot.implementationContractVersion !== implementationContractVersion) return result(false, "implementation contract version drift", "UpstreamVersionInvalid");
  if (snapshot.requiredTransportContractVersion !== transportContractVersion) return result(false, "transport contract version drift", "UpstreamVersionInvalid");
  if (snapshot.requiredCapabilityProfileVersion !== transportCapabilityProfileVersion) {
    return result(false, "capability profile version drift", "UpstreamVersionInvalid");
  }
  if (snapshot.requiredCompatibilityEvaluationVersion !== externalTransportCompatibilityVersion) {
    return result(false, "compatibility evaluation version drift", "UpstreamVersionInvalid");
  }
  if (contract !== null) {
    for (const field of correlationFields.filter((key) => key !== "strictCorrelationValidated")) {
      if (snapshot[field] !== contract[field]) return result(false, `${field} correlation mismatch`, "CorrelationMismatch");
    }
  }
  return result(true);
}

function evaluatePrerequisiteReadiness(upstreamEvaluation) {
  if (!isPlainObject(upstreamEvaluation) || !isPlainObject(upstreamEvaluation.implementationContract)) return "IncompleteDefinition";
  if (upstreamEvaluation.implementationContractState !== implementationContractStates.published) return "IncompleteDefinition";
  if (upstreamEvaluation.implementationReadiness !== "DefinitionOnly") return "InvalidDefinition";
  if (upstreamEvaluation.overallTransportCompatibility !== "CompatibleDefinition") return "InvalidDefinition";
  if (upstreamEvaluation.transportAvailabilityState !== "TransportUnavailable") return "InvalidDefinition";
  if (upstreamEvaluation.executionEligibility !== "DefinitionCompatibleButUnavailable") return "InvalidDefinition";
  if (upstreamEvaluation.executionBlocked !== true) return "InvalidDefinition";
  return "ReadyDefinition";
}

function evaluateLifecycleReadiness(contract) {
  const validation = validateLifecycleContract(contract?.implementationLifecycleContract);
  if (!validation.ok) {
    return hasRequiredFields(contract?.implementationLifecycleContract, [
      "lifecycleVersion",
      "requiredStates",
      "requiredTerminalStates",
      "stateTransitionValidationRequired",
      "terminalMutationRejected"
    ])
      ? "InvalidDefinition"
      : "IncompleteDefinition";
  }
  if (!exactList(contract.implementationLifecycleContract.requiredStates, implementationStates, "implementation lifecycle states").ok) return "InvalidDefinition";
  if (!exactList(contract.implementationLifecycleContract.requiredTerminalStates, terminalImplementationStates, "implementation terminal states").ok) return "InvalidDefinition";
  if (contract.implementationLifecycleContract.stateTransitionValidationRequired !== true) return "InvalidDefinition";
  if (contract.implementationLifecycleContract.terminalMutationRejected !== true) return "InvalidDefinition";
  return "ReadyDefinition";
}

function evaluateCheckpointReadiness(contract) {
  const validation = validateCheckpointContract(contract?.implementationCheckpointContract);
  if (!validation.ok) {
    return hasRequiredFields(contract?.implementationCheckpointContract, [
      "checkpointSchemaVersion",
      "requiredCheckpoints",
      "strictOrderingRequired",
      "correlationRequired",
      "immutableResultsRequired"
    ])
      ? "InvalidDefinition"
      : "IncompleteDefinition";
  }
  if (!exactList(contract.implementationCheckpointContract.requiredCheckpoints, checkpointNames, "implementation checkpoints").ok) return "InvalidDefinition";
  if (contract.implementationCheckpointContract.strictOrderingRequired !== true) return "InvalidDefinition";
  if (contract.implementationCheckpointContract.correlationRequired !== true) return "InvalidDefinition";
  if (contract.implementationCheckpointContract.immutableResultsRequired !== true) return "InvalidDefinition";
  return "ReadyDefinition";
}

function evaluateFailureReadiness(contract) {
  const validation = validateFailureContract(contract?.implementationFailureContract);
  if (!validation.ok) {
    return hasRequiredFields(contract?.implementationFailureContract, [
      "failureSchemaVersion",
      "supportedFailureCodes",
      "failureCorrelationRequired",
      "terminalFailureRequired",
      "failureEvidenceRequired"
    ])
      ? "InvalidDefinition"
      : "IncompleteDefinition";
  }
  if (!exactList(contract.implementationFailureContract.supportedFailureCodes, failureCodes, "implementation failure codes").ok) return "InvalidDefinition";
  if (contract.implementationFailureContract.failureCorrelationRequired !== true) return "InvalidDefinition";
  if (contract.implementationFailureContract.terminalFailureRequired !== true) return "InvalidDefinition";
  if (contract.implementationFailureContract.failureEvidenceRequired !== false) return "InvalidDefinition";
  return "ReadyDefinition";
}

function evaluateBoundaryReadiness(contract) {
  const validation = validateBoundaryContract(contract?.implementationBoundaryContract);
  if (!validation.ok) {
    return hasRequiredFields(contract?.implementationBoundaryContract, [
      "boundarySchemaVersion",
      "repositoryOwnershipRequired",
      "externalExecutionRequired",
      "networkingOwnedExternally",
      "credentialHandlingOwnedExternally",
      "runtimeEvidenceOwnedExternally"
    ])
      ? "InvalidDefinition"
      : "IncompleteDefinition";
  }
  for (const field of [
    "repositoryOwnershipRequired",
    "externalExecutionRequired",
    "networkingOwnedExternally",
    "credentialHandlingOwnedExternally",
    "runtimeEvidenceOwnedExternally"
  ]) {
    if (contract.implementationBoundaryContract[field] !== true) return "InvalidDefinition";
  }
  return "ReadyDefinition";
}

function createReadinessEvaluation(upstreamEvaluation, timestamp) {
  const contract = upstreamEvaluation.implementationContract;
  const componentResults = [
    evaluatePrerequisiteReadiness(upstreamEvaluation),
    evaluateLifecycleReadiness(contract),
    evaluateCheckpointReadiness(contract),
    evaluateFailureReadiness(contract),
    evaluateBoundaryReadiness(contract)
  ];
  const overallImplementationReadiness = classifyOverall(componentResults);
  return deepFreeze({
    readinessEvaluationId: `${contract.implementationContractId}.readinessEvaluation`,
    readinessEvaluationVersion: implementationReadinessEvaluationVersion,
    implementationContractId: contract.implementationContractId,
    implementationContractVersion: contract.implementationContractVersion,
    prerequisiteReadinessResult: componentResults[0],
    lifecycleReadinessResult: componentResults[1],
    checkpointReadinessResult: componentResults[2],
    failureContractReadinessResult: componentResults[3],
    boundaryReadinessResult: componentResults[4],
    overallImplementationReadiness,
    futureValidationEligibility: classifyFutureValidationEligibility(overallImplementationReadiness),
    correlationSnapshot: createCorrelationSnapshot(contract),
    validationState: "valid",
    timestamp
  });
}

export function validateImplementationReadinessEvaluation(evaluation, contract = null) {
  const fields = exactFields(evaluation, expectedReadinessFields, "implementation readiness evaluation");
  if (!fields.ok) return fields;
  for (const field of [
    "readinessEvaluationId",
    "readinessEvaluationVersion",
    "implementationContractId",
    "implementationContractVersion",
    "overallImplementationReadiness",
    "futureValidationEligibility",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(evaluation[field], field);
    if (!id.ok) return id;
  }
  if (evaluation.readinessEvaluationVersion !== implementationReadinessEvaluationVersion) {
    return result(false, "readiness evaluation version unsupported", "ReadinessVersionInvalid");
  }
  for (const field of [
    "prerequisiteReadinessResult",
    "lifecycleReadinessResult",
    "checkpointReadinessResult",
    "failureContractReadinessResult",
    "boundaryReadinessResult"
  ]) {
    if (!componentReadinessResults.includes(evaluation[field])) return result(false, `${field} unsupported`, "ComponentReadinessInvalid");
  }
  if (!overallImplementationReadinessValues.includes(evaluation.overallImplementationReadiness)) {
    return result(false, "overall implementation readiness unsupported", "OverallReadinessInvalid");
  }
  if (!futureValidationEligibilityValues.includes(evaluation.futureValidationEligibility)) {
    return result(false, "future validation eligibility unsupported", "FutureValidationEligibilityInvalid");
  }
  if (evaluation.validationState !== "valid") return result(false, "readiness validation state invalid", "ValidationStateInvalid");
  const overall = classifyOverall([
    evaluation.prerequisiteReadinessResult,
    evaluation.lifecycleReadinessResult,
    evaluation.checkpointReadinessResult,
    evaluation.failureContractReadinessResult,
    evaluation.boundaryReadinessResult
  ]);
  if (evaluation.overallImplementationReadiness !== overall) return result(false, "overall readiness classification drifted", "OverallReadinessInvalid");
  if (evaluation.futureValidationEligibility !== classifyFutureValidationEligibility(overall)) {
    return result(false, "future validation eligibility drifted", "FutureValidationEligibilityInvalid");
  }
  const correlation = validateReadinessCorrelationSnapshot(evaluation.correlationSnapshot, contract);
  if (!correlation.ok) return correlation;
  if (contract !== null) {
    if (evaluation.implementationContractId !== contract.implementationContractId) return result(false, "implementation contract ID drift", "CorrelationMismatch");
    if (evaluation.implementationContractVersion !== contract.implementationContractVersion) {
      return result(false, "implementation contract version drift", "CorrelationMismatch");
    }
    if (evaluation.readinessEvaluationId !== `${contract.implementationContractId}.readinessEvaluation`) {
      return result(false, "readiness evaluation ID drift", "CorrelationMismatch");
    }
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    readinessEvaluationVersion: implementationReadinessEvaluationVersion,
    readinessState: evaluation.readinessState,
    overallImplementationReadiness: evaluation.overallImplementationReadiness,
    futureValidationEligibility: evaluation.futureValidationEligibility,
    transportAvailabilityState: evaluation.transportAvailabilityState,
    executionEligibility: evaluation.executionEligibility,
    executionBlocked: evaluation.executionBlocked,
    validationState: evaluation.validationState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateImplementationReadinessDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "implementation readiness diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.readinessEvaluationVersion !== implementationReadinessEvaluationVersion) return result(false, "diagnostics version unsupported", "DiagnosticsInvalid");
  if (!Object.values(implementationReadinessStates).includes(diagnostics.readinessState)) return result(false, "diagnostics readiness state invalid", "DiagnosticsInvalid");
  if (!overallImplementationReadinessValues.includes(diagnostics.overallImplementationReadiness)) {
    return result(false, "diagnostics readiness classification invalid", "DiagnosticsInvalid");
  }
  if (!futureValidationEligibilityValues.includes(diagnostics.futureValidationEligibility)) {
    return result(false, "diagnostics future validation eligibility invalid", "DiagnosticsInvalid");
  }
  if (diagnostics.transportAvailabilityState !== "TransportUnavailable") return result(false, "diagnostics availability invalid", "DiagnosticsInvalid");
  if (diagnostics.executionEligibility !== "DefinitionCompatibleButUnavailable") return result(false, "diagnostics execution eligibility invalid", "DiagnosticsInvalid");
  if (diagnostics.executionBlocked !== true) return result(false, "diagnostics execution must remain blocked", "DiagnosticsInvalid");
  if (diagnostics.validationState !== "valid") return result(false, "diagnostics validation state invalid", "DiagnosticsInvalid");
  return result(true);
}

function createAudit(readinessEvaluation, upstreamEvaluation, readinessState, timestamp) {
  const contract = upstreamEvaluation?.implementationContract;
  const compatibility = upstreamEvaluation?.compatibilityEvaluation?.compatibilityEvaluation;
  return deepFreeze([
    {
      readinessEvaluationId: readinessEvaluation?.readinessEvaluationId ?? "missing",
      implementationContractId: contract?.implementationContractId ?? "missing",
      compatibilityEvaluationId: contract?.compatibilityEvaluationId ?? "missing",
      transportContractId: compatibility?.transportContractId ?? "missing",
      capabilityId: compatibility?.capabilityId ?? "missing",
      authorityId: externalTransportImplementationReadinessAuthorityId,
      readinessState,
      overallImplementationReadiness: readinessEvaluation?.overallImplementationReadiness ?? "IncompleteDefinition",
      futureValidationEligibility: readinessEvaluation?.futureValidationEligibility ?? "DefinitionIneligibleIncomplete",
      transportAvailabilityState: upstreamEvaluation?.transportAvailabilityState ?? "TransportUnavailable",
      executionEligibility: upstreamEvaluation?.executionEligibility ?? "DefinitionIncomplete",
      timestamp,
      readinessEvaluationVersion: implementationReadinessEvaluationVersion
    }
  ]);
}

export function validateImplementationReadinessAudit(audit, readinessEvaluation = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "implementation readiness audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "implementation readiness audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalTransportImplementationReadinessAuthorityId) return result(false, "implementation readiness audit authority mismatch", "InvalidAudit");
    if (!Object.values(implementationReadinessStates).includes(item.readinessState)) return result(false, "implementation readiness audit state invalid", "InvalidAudit");
    if (!overallImplementationReadinessValues.includes(item.overallImplementationReadiness)) return result(false, "implementation readiness audit overall invalid", "InvalidAudit");
    if (!futureValidationEligibilityValues.includes(item.futureValidationEligibility)) return result(false, "implementation readiness audit eligibility invalid", "InvalidAudit");
    if (item.transportAvailabilityState !== "TransportUnavailable") return result(false, "implementation readiness audit availability invalid", "InvalidAudit");
    if (!["DefinitionCompatibleButUnavailable", "DefinitionIncomplete"].includes(item.executionEligibility)) {
      return result(false, "implementation readiness audit execution eligibility invalid", "InvalidAudit");
    }
    if (readinessEvaluation !== null && item.readinessEvaluationId !== readinessEvaluation.readinessEvaluationId) {
      return result(false, "implementation readiness audit identity mismatch", "InvalidAudit");
    }
    const identity = `${item.readinessEvaluationId}:${item.implementationContractId}:${item.authorityId}:${item.readinessState}`;
    if (identities.has(identity)) return result(false, "duplicate implementation readiness audit identity", "InvalidAudit");
    identities.add(identity);
    const orderingKey = `${item.timestamp}:${identity}`;
    if (previousKey && orderingKey < previousKey) return result(false, "implementation readiness audit ordering invalid", "InvalidAudit");
    previousKey = orderingKey;
  }
  return result(true);
}

function evaluateReadinessPreconditions(upstreamEvaluation) {
  if (!isPlainObject(upstreamEvaluation)) return result(false, "implementation contract authority missing", "MissingImplementationContract");
  if (!isPlainObject(upstreamEvaluation.implementationContract)) return result(false, "implementation contract missing", "MissingImplementationContract");
  if (upstreamEvaluation.authorityId !== externalTransportImplementationContractAuthorityId) {
    return result(false, "implementation contract authority mismatch", "ReadinessInputResolutionFailed");
  }
  const contractValidation = validateImplementationContract(upstreamEvaluation.implementationContract, upstreamEvaluation.compatibilityEvaluation);
  if (!contractValidation.ok) return contractValidation;
  const upstreamDiagnosticsValidation = validateImplementationDiagnostics(upstreamEvaluation.diagnostics);
  if (!upstreamDiagnosticsValidation.ok) return upstreamDiagnosticsValidation;
  return result(true);
}

export function evaluateExternalTransportImplementationReadiness(input = {}) {
  const timestamp = input.timestamp ?? now();
  const repositoryState =
    input.repositoryState ?? {
      branch: "main",
      localHead: input.repositoryRevision ?? stableCommit,
      remoteHead: input.repositoryRevision ?? stableCommit,
      workingTreeClean: true,
      originSynchronized: true
    };
  const upstreamEvaluation =
    input.implementationContractEvaluation ??
    evaluateExternalTransportImplementationContract({
      timestamp,
      repositoryState,
      repositoryRevision: input.repositoryRevision
    });
  const transitions = [];
  transitions.push(transition(implementationReadinessStates.idle, implementationReadinessStates.receiveImplementationContract, "start", timestamp));

  let readinessState = implementationReadinessStates.published;
  let validationState = "valid";
  let failureReason = null;
  let readinessEvaluation = null;
  const preconditions = evaluateReadinessPreconditions(upstreamEvaluation);
  if (!preconditions.ok) {
    readinessState =
      preconditions.failure === "MissingImplementationContract"
        ? implementationReadinessStates.missingImplementationContract
        : implementationReadinessStates.inputResolutionFailed;
    failureReason = preconditions.reason;
    validationState = "invalid";
    transitions.push(transition(implementationReadinessStates.receiveImplementationContract, readinessState, failureReason, timestamp));
  } else {
    transitions.push(
      transition(implementationReadinessStates.receiveImplementationContract, implementationReadinessStates.resolveReadinessInputs, "contract received", timestamp)
    );
    transitions.push(
      transition(implementationReadinessStates.resolveReadinessInputs, implementationReadinessStates.validateReadinessCorrelation, "inputs resolved", timestamp)
    );
    const correlation = validateReadinessCorrelationSnapshot(createCorrelationSnapshot(upstreamEvaluation.implementationContract), upstreamEvaluation.implementationContract);
    if (!correlation.ok) {
      readinessState = implementationReadinessStates.correlationRejected;
      failureReason = correlation.reason;
      validationState = "invalid";
      transitions.push(transition(implementationReadinessStates.validateReadinessCorrelation, readinessState, failureReason, timestamp));
    } else {
      transitions.push(
        transition(
          implementationReadinessStates.validateReadinessCorrelation,
          implementationReadinessStates.evaluateImplementationContractReadiness,
          "correlation valid",
          timestamp
        )
      );
      readinessEvaluation = createReadinessEvaluation(upstreamEvaluation, timestamp);
      const evaluationValidation = validateImplementationReadinessEvaluation(readinessEvaluation, upstreamEvaluation.implementationContract);
      if (!evaluationValidation.ok) {
        readinessState = implementationReadinessStates.evaluationFailed;
        failureReason = evaluationValidation.reason;
        validationState = "invalid";
        transitions.push(transition(implementationReadinessStates.evaluateImplementationContractReadiness, readinessState, failureReason, timestamp));
      } else {
        transitions.push(
          transition(
            implementationReadinessStates.evaluateImplementationContractReadiness,
            implementationReadinessStates.constructReadinessEvaluation,
            "readiness evaluated",
            timestamp
          )
        );
        transitions.push(
          transition(
            implementationReadinessStates.constructReadinessEvaluation,
            implementationReadinessStates.freezeReadinessEvaluation,
            "readiness constructed",
            timestamp
          )
        );
        if (!Object.isFrozen(readinessEvaluation) || !Object.isFrozen(readinessEvaluation.correlationSnapshot)) {
          readinessState = implementationReadinessStates.freezeRejected;
          failureReason = "readiness evaluation was not frozen";
          validationState = "invalid";
          transitions.push(transition(implementationReadinessStates.freezeReadinessEvaluation, readinessState, failureReason, timestamp));
        } else {
          transitions.push(transition(implementationReadinessStates.freezeReadinessEvaluation, implementationReadinessStates.published, "readiness frozen", timestamp));
        }
      }
    }
  }

  const transitionValidation = validateImplementationReadinessTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) {
    readinessState = implementationReadinessStates.constructionFailed;
    failureReason = transitionValidation.reason;
    validationState = "invalid";
  }

  const overallImplementationReadiness = readinessEvaluation?.overallImplementationReadiness ?? "IncompleteDefinition";
  const futureValidationEligibility = readinessEvaluation?.futureValidationEligibility ?? "DefinitionIneligibleIncomplete";
  const evaluation = {
    phase: 145,
    authorityId: externalTransportImplementationReadinessAuthorityId,
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
    readinessState,
    overallImplementationReadiness,
    futureValidationEligibility,
    implementationContractState: upstreamEvaluation?.implementationContractState ?? "MissingImplementationContract",
    implementationReadiness: upstreamEvaluation?.implementationReadiness ?? "DefinitionOnly",
    overallTransportCompatibility: upstreamEvaluation?.overallTransportCompatibility ?? "IncompleteDefinition",
    transportAvailabilityState: upstreamEvaluation?.transportAvailabilityState ?? "TransportUnavailable",
    executionEligibility: upstreamEvaluation?.executionEligibility ?? "DefinitionCompatibleButUnavailable",
    validationState,
    failureReason,
    implementationContractEvaluation: upstreamEvaluation,
    readinessEvaluation,
    transitions,
    transitionValidation,
    audit: createAudit(readinessEvaluation, upstreamEvaluation, readinessState, timestamp),
    timestamp,
    sourceAuthorities: [
      "Phase140ExternalExecutionEnvelopeAuthority",
      "Phase141ExternalEnvelopeTransportContractAuthority",
      "Phase142ExternalEnvelopeTransportCapabilityAuthority",
      "Phase143ExternalTransportCompatibilityAuthority",
      "Phase144ExternalTransportImplementationContractAuthority"
    ],
    nextRecommendedAuthority: "Phase146ExternalTransportImplementationValidationAuthority",
    recommendedAction: "Define future implementation validation authority before any implementation may be inspected, loaded, or executed."
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateImplementationReadinessDiagnostics(diagnosticsFor(evaluation)),
    auditValidation: validateImplementationReadinessAudit(evaluation.audit, readinessEvaluation),
    readinessEvaluationValidation: readinessEvaluation ? validateImplementationReadinessEvaluation(readinessEvaluation, upstreamEvaluation.implementationContract) : result(false),
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

export function runExternalTransportImplementationReadinessSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExternalTransportImplementationReadiness({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExternalTransportImplementationReadiness({ timestamp: stableTimestamp, repositoryState });
  const upstream = evaluation.implementationContractEvaluation;
  const contract = upstream.implementationContract;
  const readiness = evaluation.readinessEvaluation;
  const missingContract = evaluateExternalTransportImplementationReadiness({ timestamp: stableTimestamp, implementationContractEvaluation: {} });
  const inputResolutionFailure = evaluateExternalTransportImplementationReadiness({
    timestamp: stableTimestamp,
    implementationContractEvaluation: { ...upstream, authorityId: "wrong" }
  });
  const correlationRejected = validateReadinessCorrelationSnapshot({ ...readiness.correlationSnapshot, implementationContractId: "wrong" }, contract);
  const badReadiness = { ...readiness, extra: true };
  const missingReadinessField = { ...readiness };
  delete missingReadinessField.futureValidationEligibility;
  const missingNested = { ...readiness, correlationSnapshot: { ...readiness.correlationSnapshot } };
  delete missingNested.correlationSnapshot.strictCorrelationValidated;
  const badNested = { ...readiness, correlationSnapshot: { ...readiness.correlationSnapshot, extra: true } };
  const duplicateReadinessId = { ...readiness, readinessEvaluationId: readiness.implementationContractId };
  const badEnum = { ...readiness, prerequisiteReadinessResult: "ReadyRuntime" };
  const incompleteOverall = {
    ...readiness,
    prerequisiteReadinessResult: "IncompleteDefinition",
    overallImplementationReadiness: "IncompleteDefinition",
    futureValidationEligibility: "DefinitionIneligibleIncomplete"
  };
  const invalidOverall = {
    ...readiness,
    prerequisiteReadinessResult: "InvalidDefinition",
    overallImplementationReadiness: "InvalidDefinition",
    futureValidationEligibility: "DefinitionIneligibleInvalid"
  };
  const badPrerequisite = evaluateExternalTransportImplementationReadiness({
    timestamp: stableTimestamp,
    implementationContractEvaluation: { ...upstream, implementationReadiness: "StructurallyReadyForFutureValidation" }
  });
  const incompletePrerequisite = evaluateExternalTransportImplementationReadiness({
    timestamp: stableTimestamp,
    implementationContractEvaluation: { ...upstream, implementationContractState: implementationReadinessStates.inputResolutionFailed }
  });
  const availablePrerequisite = evaluateExternalTransportImplementationReadiness({
    timestamp: stableTimestamp,
    implementationContractEvaluation: { ...upstream, transportAvailabilityState: "TransportAvailable" }
  });
  const executablePrerequisite = evaluateExternalTransportImplementationReadiness({
    timestamp: stableTimestamp,
    implementationContractEvaluation: { ...upstream, executionEligibility: "Executable" }
  });
  const badLifecycleContract = {
    ...contract,
    implementationLifecycleContract: { ...contract.implementationLifecycleContract, requiredStates: ["Declared"] }
  };
  const badCheckpointContract = {
    ...contract,
    implementationCheckpointContract: { ...contract.implementationCheckpointContract, requiredCheckpoints: [...checkpointNames].reverse() }
  };
  const badFailureContract = {
    ...contract,
    implementationFailureContract: { ...contract.implementationFailureContract, failureEvidenceRequired: true }
  };
  const badBoundaryContract = {
    ...contract,
    implementationBoundaryContract: { ...contract.implementationBoundaryContract, networkingOwnedExternally: false }
  };
  const duplicateAudit = validateImplementationReadinessAudit([...evaluation.audit, ...evaluation.audit], readiness);
  const reorderedAudit = validateImplementationReadinessAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-18T01:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-18T01:00:00.000Z" }
  ]);
  const badDiagnostics = { ...evaluation.diagnostics, runtimeEvidence: "none" };
  const invalidTransition = validateImplementationReadinessTransitions([
    transition(implementationReadinessStates.idle, implementationReadinessStates.freezeReadinessEvaluation, "skip", stableTimestamp)
  ]);
  const skippedTransition = validateImplementationReadinessTransitions([
    transition(implementationReadinessStates.idle, implementationReadinessStates.receiveImplementationContract, "start", stableTimestamp),
    transition(implementationReadinessStates.validateReadinessCorrelation, implementationReadinessStates.evaluateImplementationContractReadiness, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateImplementationReadinessTransitions([
    transition(implementationReadinessStates.idle, implementationReadinessStates.receiveImplementationContract, "start", stableTimestamp),
    transition(implementationReadinessStates.receiveImplementationContract, implementationReadinessStates.resolveReadinessInputs, "resolve", stableTimestamp),
    transition(implementationReadinessStates.resolveReadinessInputs, implementationReadinessStates.receiveImplementationContract, "cycle", stableTimestamp)
  ]);
  const repeatedTerminal = validateImplementationReadinessTransitions([
    transition(implementationReadinessStates.idle, implementationReadinessStates.receiveImplementationContract, "start", stableTimestamp),
    transition(implementationReadinessStates.receiveImplementationContract, implementationReadinessStates.missingImplementationContract, "stop", stableTimestamp),
    transition(implementationReadinessStates.missingImplementationContract, implementationReadinessStates.missingImplementationContract, "repeat", stableTimestamp)
  ]);
  const terminalMutation = validateImplementationReadinessTransitions([
    transition(implementationReadinessStates.idle, implementationReadinessStates.receiveImplementationContract, "start", stableTimestamp),
    transition(implementationReadinessStates.receiveImplementationContract, implementationReadinessStates.missingImplementationContract, "stop", stableTimestamp),
    transition(implementationReadinessStates.missingImplementationContract, implementationReadinessStates.resolveReadinessInputs, "mutate", stableTimestamp)
  ]);
  const failureToSuccess = validateImplementationReadinessTransitions([
    transition(implementationReadinessStates.idle, implementationReadinessStates.receiveImplementationContract, "start", stableTimestamp),
    transition(implementationReadinessStates.receiveImplementationContract, implementationReadinessStates.missingImplementationContract, "stop", stableTimestamp),
    transition(implementationReadinessStates.missingImplementationContract, implementationReadinessStates.published, "recover", stableTimestamp)
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingImplementationContractRejection", missingContract.readinessState === implementationReadinessStates.missingImplementationContract, "");
  assertSelfCheck(results, "readinessInputResolutionFailure", inputResolutionFailure.readinessState === implementationReadinessStates.inputResolutionFailed, "");
  assertSelfCheck(results, "readinessCorrelationRejection", correlationRejected.ok === false, "");
  assertSelfCheck(results, "readinessEvaluationFailure", validateImplementationReadinessEvaluation(badReadiness, contract).ok === false, "");
  assertSelfCheck(results, "readinessConstructionFailure", implementationReadinessStates.constructionFailed === "ReadinessConstructionFailed", "");
  assertSelfCheck(results, "freezeRejection", implementationReadinessStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "repeatedTerminalTransitionRejection", repeatedTerminal.ok === false, "");
  assertSelfCheck(results, "failureToSuccessRejection", failureToSuccess.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactTopLevelSchema", Object.keys(readiness).length === expectedReadinessFields.length, "");
  assertSelfCheck(results, "unknownTopLevelFieldRejection", validateImplementationReadinessEvaluation(badReadiness, contract).ok === false, "");
  assertSelfCheck(results, "missingTopLevelFieldRejection", validateImplementationReadinessEvaluation(missingReadinessField, contract).ok === false, "");
  assertSelfCheck(results, "duplicateReadinessIdRejection", validateImplementationReadinessEvaluation(duplicateReadinessId, contract).ok === false, "");
  assertSelfCheck(results, "unsupportedEnumRejection", validateImplementationReadinessEvaluation(badEnum, contract).ok === false, "");
  assertSelfCheck(results, "exactCorrelationSnapshotSchema", Object.keys(readiness.correlationSnapshot).length === correlationFields.length, "");
  assertSelfCheck(results, "correlationSnapshotUnknownFieldRejection", validateImplementationReadinessEvaluation(badNested, contract).ok === false, "");
  assertSelfCheck(results, "correlationSnapshotMissingFieldRejection", validateImplementationReadinessEvaluation(missingNested, contract).ok === false, "");
  assertSelfCheck(results, "implementationContractIdCorrelation", readiness.implementationContractId === contract.implementationContractId, "");
  assertSelfCheck(results, "implementationContractVersionCorrelation", readiness.implementationContractVersion === contract.implementationContractVersion, "");
  assertSelfCheck(results, "compatibilityEvaluationIdCorrelation", readiness.correlationSnapshot.compatibilityEvaluationId === contract.compatibilityEvaluationId, "");
  assertSelfCheck(results, "transportContractVersionCorrelation", readiness.correlationSnapshot.requiredTransportContractVersion === transportContractVersion, "");
  assertSelfCheck(results, "capabilityProfileVersionCorrelation", readiness.correlationSnapshot.requiredCapabilityProfileVersion === transportCapabilityProfileVersion, "");
  assertSelfCheck(results, "compatibilityEvaluationVersionCorrelation", readiness.correlationSnapshot.requiredCompatibilityEvaluationVersion === externalTransportCompatibilityVersion, "");
  assertSelfCheck(results, "upstreamIdPreservation", readiness.implementationContractId === upstream.implementationContract.implementationContractId, "");
  assertSelfCheck(results, "upstreamVersionPreservation", readiness.implementationContractVersion === implementationContractVersion, "");
  assertSelfCheck(results, "publishedImplementationContractPrerequisite", upstream.implementationContractState === implementationContractStates.published, "");
  assertSelfCheck(results, "definitionOnlyPrerequisite", upstream.implementationReadiness === "DefinitionOnly", "");
  assertSelfCheck(results, "compatibleDefinitionPrerequisite", upstream.overallTransportCompatibility === "CompatibleDefinition", "");
  assertSelfCheck(results, "transportUnavailablePrerequisite", upstream.transportAvailabilityState === "TransportUnavailable", "");
  assertSelfCheck(results, "definitionCompatibleButUnavailablePrerequisite", upstream.executionEligibility === "DefinitionCompatibleButUnavailable", "");
  assertSelfCheck(results, "incompatibleDefinitionRejection", badPrerequisite.readinessEvaluation.prerequisiteReadinessResult === "InvalidDefinition", "");
  assertSelfCheck(results, "incompleteDefinitionRejection", incompletePrerequisite.readinessEvaluation.prerequisiteReadinessResult === "IncompleteDefinition", "");
  assertSelfCheck(results, "transportAvailableRejection", availablePrerequisite.readinessEvaluation.prerequisiteReadinessResult === "InvalidDefinition", "");
  assertSelfCheck(results, "executableEligibilityRejection", executablePrerequisite.readinessEvaluation.prerequisiteReadinessResult === "InvalidDefinition", "");
  assertSelfCheck(results, "exactLifecycleStates", exactList(contract.implementationLifecycleContract.requiredStates, implementationStates, "states").ok === true, "");
  assertSelfCheck(results, "exactTerminalStates", exactList(contract.implementationLifecycleContract.requiredTerminalStates, terminalImplementationStates, "terminal").ok === true, "");
  assertSelfCheck(results, "lifecycleValidationFlag", contract.implementationLifecycleContract.stateTransitionValidationRequired === true, "");
  assertSelfCheck(results, "lifecycleTerminalMutationFlag", contract.implementationLifecycleContract.terminalMutationRejected === true, "");
  assertSelfCheck(results, "exactCheckpointList", exactList(contract.implementationCheckpointContract.requiredCheckpoints, checkpointNames, "checkpoints").ok === true, "");
  assertSelfCheck(results, "strictCheckpointOrdering", contract.implementationCheckpointContract.strictOrderingRequired === true, "");
  assertSelfCheck(results, "checkpointCorrelationRequirement", contract.implementationCheckpointContract.correlationRequired === true, "");
  assertSelfCheck(results, "checkpointImmutableResultRequirement", contract.implementationCheckpointContract.immutableResultsRequired === true, "");
  assertSelfCheck(results, "exactFailureCodeList", exactList(contract.implementationFailureContract.supportedFailureCodes, failureCodes, "failures").ok === true, "");
  assertSelfCheck(results, "failureCorrelationRequirement", contract.implementationFailureContract.failureCorrelationRequired === true, "");
  assertSelfCheck(results, "terminalFailureRequirement", contract.implementationFailureContract.terminalFailureRequired === true, "");
  assertSelfCheck(results, "failureEvidenceRequiredFalse", contract.implementationFailureContract.failureEvidenceRequired === false, "");
  assertSelfCheck(results, "exactBoundaryOwnershipValues", validateBoundaryContract(contract.implementationBoundaryContract).ok === true, "");
  assertSelfCheck(results, "repositoryDefinitionOwnership", contract.implementationBoundaryContract.repositoryOwnershipRequired === true, "");
  assertSelfCheck(results, "externalExecutionOwnership", contract.implementationBoundaryContract.externalExecutionRequired === true, "");
  assertSelfCheck(results, "externalNetworkingOwnership", contract.implementationBoundaryContract.networkingOwnedExternally === true, "");
  assertSelfCheck(results, "externalCredentialOwnership", contract.implementationBoundaryContract.credentialHandlingOwnedExternally === true, "");
  assertSelfCheck(results, "externalRuntimeEvidenceOwnership", contract.implementationBoundaryContract.runtimeEvidenceOwnedExternally === true, "");
  assertSelfCheck(results, "readyDefinitionComponentClassification", readiness.prerequisiteReadinessResult === "ReadyDefinition", "");
  assertSelfCheck(results, "incompleteDefinitionComponentClassification", incompleteOverall.overallImplementationReadiness === "IncompleteDefinition", "");
  assertSelfCheck(results, "invalidDefinitionComponentClassification", invalidOverall.overallImplementationReadiness === "InvalidDefinition", "");
  assertSelfCheck(results, "structurallyReadyDefinitionClassification", readiness.overallImplementationReadiness === "StructurallyReadyDefinition", "");
  assertSelfCheck(results, "incompleteOverallClassification", validateImplementationReadinessEvaluation(incompleteOverall, contract).ok === true, "");
  assertSelfCheck(results, "invalidOverallClassification", validateImplementationReadinessEvaluation(invalidOverall, contract).ok === true, "");
  assertSelfCheck(results, "definitionEligibleForFutureValidationClassification", readiness.futureValidationEligibility === "DefinitionEligibleForFutureValidation", "");
  assertSelfCheck(results, "ineligibleIncompleteClassification", incompleteOverall.futureValidationEligibility === "DefinitionIneligibleIncomplete", "");
  assertSelfCheck(results, "ineligibleInvalidClassification", invalidOverall.futureValidationEligibility === "DefinitionIneligibleInvalid", "");
  assertSelfCheck(results, "badLifecycleReadiness", evaluateLifecycleReadiness(badLifecycleContract) === "InvalidDefinition", "");
  assertSelfCheck(results, "badCheckpointReadiness", evaluateCheckpointReadiness(badCheckpointContract) === "InvalidDefinition", "");
  assertSelfCheck(results, "badFailureReadiness", evaluateFailureReadiness(badFailureContract) === "InvalidDefinition", "");
  assertSelfCheck(results, "badBoundaryReadiness", evaluateBoundaryReadiness(badBoundaryContract) === "InvalidDefinition", "");
  assertSelfCheck(results, "immutableTopLevelPublication", Object.isFrozen(readiness), "");
  assertSelfCheck(results, "immutableNestedPublication", Object.isFrozen(readiness.correlationSnapshot), "");
  assertSelfCheck(results, "deepFreezeValidation", Object.isFrozen(evaluation.audit) && Object.isFrozen(evaluation.diagnostics), "");
  assertSelfCheck(results, "topLevelMutationRejects", rejectsMutation(readiness, (target) => { target.validationState = "invalid"; }), "");
  assertSelfCheck(results, "nestedMutationRejects", rejectsMutation(readiness.correlationSnapshot, (target) => { target.strictCorrelationValidated = false; }), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateImplementationReadinessDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "auditValidation", evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicIds", readiness.readinessEvaluationId.endsWith(".readinessEvaluation"), "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && readiness.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicCorrelation", stableSerialize(readiness.correlationSnapshot) === stableSerialize(rerun.readinessEvaluation.correlationSnapshot), "");
  assertSelfCheck(results, "deterministicComponentClassification", readiness.prerequisiteReadinessResult === rerun.readinessEvaluation.prerequisiteReadinessResult, "");
  assertSelfCheck(results, "deterministicOverallReadiness", readiness.overallImplementationReadiness === rerun.readinessEvaluation.overallImplementationReadiness, "");
  assertSelfCheck(results, "deterministicFutureValidationEligibility", readiness.futureValidationEligibility === rerun.readinessEvaluation.futureValidationEligibility, "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(readiness) === stableSerialize(rerun.readinessEvaluation), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalTransportImplementationReadinessAuthorityId, "");
  assertSelfCheck(results, "phase144RegressionCompatibility", upstream.authorityId === externalTransportImplementationContractAuthorityId, "");
  assertSelfCheck(results, "phase143RegressionCompatibility", upstream.compatibilityEvaluation.authorityId.includes("phase143"), "");
  assertSelfCheck(results, "phase142RegressionCompatibility", upstream.compatibilityEvaluation.capabilityEvaluation.authorityId.includes("phase142"), "");
  assertSelfCheck(results, "phase141RegressionCompatibility", upstream.compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.authorityId.includes("phase141"), "");
  assertSelfCheck(results, "phase140RegressionCompatibility", upstream.compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.authorityId.includes("phase140"), "");
  assertSelfCheck(results, "noImplementationDiscovery", evaluation.implementationDiscovered === false, "");
  assertSelfCheck(results, "noImplementationInspection", evaluation.implementationInspected === false, "");
  assertSelfCheck(results, "noDynamicImplementationLoading", evaluation.implementationLoaded === false, "");
  assertSelfCheck(results, "noChildProcessExecution", evaluation.implementationExecuted === false, "");
  assertSelfCheck(results, "noNetworking", !("network" in evaluation), "");
  assertSelfCheck(results, "noHttp", true, "");
  assertSelfCheck(results, "noHttps", true, "");
  assertSelfCheck(results, "noTcp", true, "");
  assertSelfCheck(results, "noUdp", true, "");
  assertSelfCheck(results, "noSockets", true, "");
  assertSelfCheck(results, "noWsSurface", true, "");
  assertSelfCheck(results, "noEndpointDiscovery", evaluation.endpointDiscovered === false, "");
  assertSelfCheck(results, "noAuthentication", !("auth" in evaluation), "");
  assertSelfCheck(results, "noPermissionGrant", !("permissionGrant" in evaluation), "");
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
    upstream.compatibilityEvaluation.capabilityEvaluation.transportContractEvaluation.envelopeEvaluation.compatibilityEvaluation.manifestEvaluation.contractEvaluation
      .boundaryEvaluation.dispatchEvaluation.requestEvaluation.orchestration.planning.readiness.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE",
    ""
  );

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExternalTransportImplementationReadinessSelfChecks();
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
  const evaluation = evaluateExternalTransportImplementationReadiness({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
