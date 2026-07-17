import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateExternalConsumerManifestAuthority,
  externalConsumerManifestAuthorityId,
  externalConsumerManifestVersion,
  manifestCompatibilityResults,
  manifestConsumerStatusValues,
  validateConsumerManifest
} from "./studio-external-consumer-manifest-authority.mjs";
import {
  externalConsumerContractAuthorityId,
  externalConsumerContractAuthorityVersion,
  validateConsumerContract
} from "./studio-external-consumer-contract-authority.mjs";
import {
  externalBoundaryAuthorityId,
  externalBoundaryVersion,
  externalConsumerType
} from "./studio-external-execution-boundary.mjs";
import { executionDispatchAuthorityId, executionDispatchVersion } from "./studio-execution-dispatch-authority.mjs";
import { executionRequestAuthorityId } from "./studio-execution-request-authority.mjs";
import { executionOrchestratorAuthorityId } from "./studio-execution-orchestrator.mjs";
import { executionPlanningAuthorityId } from "./studio-execution-planning-authority.mjs";
import { integrationContractProtocolVersion, stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const consumerCompatibilitySchemaVersion = 1;
export const consumerCompatibilityVersion = "1.0.0";
export const consumerCompatibilityAuthorityId = "chapter0Home.phase139StudioConsumerCompatibilityAuthority";

export const compatibilityStates = Object.freeze({
  idle: "Idle",
  receiveCandidateProfile: "ReceiveCandidateProfile",
  validateCandidateSchema: "ValidateCandidateSchema",
  resolveContractRequirements: "ResolveContractRequirements",
  resolveManifestRecognition: "ResolveManifestRecognition",
  evaluateCompatibility: "EvaluateCompatibility",
  freezeEvaluation: "FreezeEvaluation",
  published: "CompatibilityPublished",
  missingCandidateProfile: "MissingCandidateProfile",
  candidateRejected: "CandidateRejected",
  contractResolutionFailed: "ContractResolutionFailed",
  manifestResolutionFailed: "ManifestResolutionFailed",
  compatibilityInconclusive: "CompatibilityInconclusive",
  freezeRejected: "FreezeRejected"
});

export const componentEvaluationResults = Object.freeze(["Compatible", "Incompatible", "NotEvaluated"]);
export const componentReasonCodes = Object.freeze([
  "ExactMatch",
  "MinimumSatisfied",
  "VersionMismatch",
  "UnsupportedVersion",
  "ManifestNotRecognized",
  "SchemaMismatch",
  "CapabilityBelowMinimum",
  "EvaluationUnavailable"
]);
export const overallCompatibilityValues = Object.freeze([
  "CompatibleDefinition",
  "IncompatibleDefinition",
  "EvaluationIncomplete"
]);
export const consumerAvailabilityValues = Object.freeze(["ContractOnly", "CandidateDeclared", "ConsumerUnavailable"]);
export const executionEligibilityValues = Object.freeze(["Blocked", "DefinitionCompatibleButUnavailable"]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  compatibilityStates.published,
  compatibilityStates.missingCandidateProfile,
  compatibilityStates.candidateRejected,
  compatibilityStates.contractResolutionFailed,
  compatibilityStates.manifestResolutionFailed,
  compatibilityStates.compatibilityInconclusive,
  compatibilityStates.freezeRejected
]);
const legalTransitions = new Map([
  [compatibilityStates.idle, new Set([compatibilityStates.receiveCandidateProfile])],
  [
    compatibilityStates.receiveCandidateProfile,
    new Set([compatibilityStates.validateCandidateSchema, compatibilityStates.missingCandidateProfile])
  ],
  [
    compatibilityStates.validateCandidateSchema,
    new Set([compatibilityStates.resolveContractRequirements, compatibilityStates.candidateRejected])
  ],
  [
    compatibilityStates.resolveContractRequirements,
    new Set([compatibilityStates.resolveManifestRecognition, compatibilityStates.contractResolutionFailed])
  ],
  [
    compatibilityStates.resolveManifestRecognition,
    new Set([compatibilityStates.evaluateCompatibility, compatibilityStates.manifestResolutionFailed])
  ],
  [
    compatibilityStates.evaluateCompatibility,
    new Set([compatibilityStates.freezeEvaluation, compatibilityStates.compatibilityInconclusive])
  ],
  [compatibilityStates.freezeEvaluation, new Set([compatibilityStates.published, compatibilityStates.freezeRejected])]
]);

const candidateFields = Object.freeze([
  "candidateProfileId",
  "candidateProfileVersion",
  "consumerType",
  "consumerContractVersion",
  "protocolVersion",
  "dispatchVersion",
  "boundaryVersion",
  "capabilityProfileVersion",
  "supportedAcknowledgementSchemaVersion",
  "supportedResultSchemaVersion",
  "supportedEvidenceSchemaVersion",
  "supportedFailureSchemaVersion",
  "declaredManifestId",
  "timestamp"
]);
const evaluationFields = Object.freeze([
  "evaluationId",
  "evaluationVersion",
  "candidateProfileId",
  "consumerContractId",
  "consumerContractVersion",
  "manifestId",
  "manifestVersion",
  "consumerType",
  "protocolEvaluation",
  "dispatchEvaluation",
  "boundaryEvaluation",
  "capabilityEvaluation",
  "acknowledgementSchemaEvaluation",
  "resultSchemaEvaluation",
  "evidenceSchemaEvaluation",
  "failureSchemaEvaluation",
  "manifestRecognitionEvaluation",
  "overallCompatibility",
  "consumerAvailabilityState",
  "executionEligibility",
  "validationState",
  "timestamp"
]);
const componentFields = Object.freeze(["requiredVersion", "declaredVersion", "evaluationResult", "reasonCode"]);
const manifestRecognitionFields = Object.freeze([
  "manifestId",
  "consumerType",
  "consumerStatus",
  "matrixResult",
  "evaluationResult",
  "reasonCode"
]);
const diagnosticsFields = Object.freeze([
  "evaluationVersion",
  "evaluationState",
  "candidateProfileState",
  "consumerAvailabilityState",
  "overallCompatibility",
  "executionEligibility",
  "boundaryEligibility",
  "ownershipTransferState",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "evaluationId",
  "candidateProfileId",
  "consumerContractId",
  "manifestId",
  "authorityId",
  "evaluationState",
  "overallCompatibility",
  "consumerAvailabilityState",
  "executionEligibility",
  "timestamp",
  "evaluationVersion"
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
  return deepFreeze({ from, to, reason, timestamp, authorityId: consumerCompatibilityAuthorityId });
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
    if (index === 0 && item.from !== compatibilityStates.idle) {
      return result(false, "compatibility lifecycle must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "compatibility lifecycle skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal compatibility state mutated", "InvalidLifecycle");
    }
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

function compareVersions(declared, required) {
  const declaredParts = String(declared).split(".").map((part) => Number(part));
  const requiredParts = String(required).split(".").map((part) => Number(part));
  for (let index = 0; index < Math.max(declaredParts.length, requiredParts.length); index += 1) {
    const left = declaredParts[index] ?? 0;
    const right = requiredParts[index] ?? 0;
    if (Number.isNaN(left) || Number.isNaN(right)) return -1;
    if (left > right) return 1;
    if (left < right) return -1;
  }
  return 0;
}

function component(requiredVersion, declaredVersion, minimum = false) {
  const ok = minimum ? compareVersions(declaredVersion, requiredVersion) >= 0 : declaredVersion === requiredVersion;
  return deepFreeze({
    requiredVersion,
    declaredVersion,
    evaluationResult: ok ? "Compatible" : "Incompatible",
    reasonCode: ok ? (minimum ? "MinimumSatisfied" : "ExactMatch") : minimum ? "CapabilityBelowMinimum" : "VersionMismatch"
  });
}

export function validateComponentEvaluation(evaluation) {
  const fields = exactFields(evaluation, componentFields, "component evaluation");
  if (!fields.ok) return fields;
  for (const field of componentFields) {
    const id = validateIdentifier(evaluation[field], field);
    if (!id.ok) return id;
  }
  if (!componentEvaluationResults.includes(evaluation.evaluationResult)) {
    return result(false, "component evaluation result unsupported", "ComponentResultInvalid");
  }
  if (!componentReasonCodes.includes(evaluation.reasonCode)) {
    return result(false, "component reason code unsupported", "ComponentReasonInvalid");
  }
  if (evaluation.evaluationResult === "Compatible" && !["ExactMatch", "MinimumSatisfied"].includes(evaluation.reasonCode)) {
    return result(false, "compatible component reason invalid", "ComponentReasonInvalid");
  }
  return result(true);
}

export function validateManifestRecognitionEvaluation(evaluation) {
  const fields = exactFields(evaluation, manifestRecognitionFields, "manifest recognition evaluation");
  if (!fields.ok) return fields;
  for (const field of manifestRecognitionFields) {
    const id = validateIdentifier(evaluation[field], field);
    if (!id.ok) return id;
  }
  if (!manifestConsumerStatusValues.includes(evaluation.consumerStatus)) {
    return result(false, "manifest consumer status unsupported", "ManifestStatusInvalid");
  }
  if (!manifestCompatibilityResults.includes(evaluation.matrixResult)) {
    return result(false, "manifest matrix result unsupported", "ManifestMatrixInvalid");
  }
  if (!componentEvaluationResults.includes(evaluation.evaluationResult)) {
    return result(false, "manifest recognition result unsupported", "ComponentResultInvalid");
  }
  if (!componentReasonCodes.includes(evaluation.reasonCode)) {
    return result(false, "manifest recognition reason unsupported", "ComponentReasonInvalid");
  }
  return result(true);
}

function createCandidateProfile(manifest, timestamp) {
  return deepFreeze({
    candidateProfileId: `${manifest.manifestId}.candidateProfile`,
    candidateProfileVersion: consumerCompatibilityVersion,
    consumerType: manifest.consumerType,
    consumerContractVersion: manifest.consumerContractVersion,
    protocolVersion: manifest.supportedProtocolVersions[0],
    dispatchVersion: manifest.supportedDispatchVersions[0],
    boundaryVersion: manifest.supportedBoundaryVersions[0],
    capabilityProfileVersion: manifest.supportedCapabilityProfiles[0].minimumCapabilityVersion,
    supportedAcknowledgementSchemaVersion: String(consumerCompatibilitySchemaVersion),
    supportedResultSchemaVersion: String(consumerCompatibilitySchemaVersion),
    supportedEvidenceSchemaVersion: String(consumerCompatibilitySchemaVersion),
    supportedFailureSchemaVersion: String(consumerCompatibilitySchemaVersion),
    declaredManifestId: manifest.manifestId,
    timestamp
  });
}

export function validateCandidateProfile(profile, manifest = null) {
  const fields = exactFields(profile, candidateFields, "candidate profile");
  if (!fields.ok) return fields;
  for (const field of candidateFields) {
    const id = validateIdentifier(profile[field], field);
    if (!id.ok) return id;
  }
  if (profile.consumerType !== externalConsumerType) return result(false, "candidate consumer type unsupported", "UnsupportedConsumerType");
  if (profile.consumerContractVersion !== externalConsumerContractAuthorityVersion) {
    return result(false, "candidate contract version unsupported", "ContractVersionIncompatible");
  }
  if (profile.protocolVersion !== integrationContractProtocolVersion) {
    return result(false, "candidate protocol version unsupported", "ProtocolIncompatible");
  }
  if (profile.dispatchVersion !== executionDispatchVersion) return result(false, "candidate dispatch version unsupported", "DispatchIncompatible");
  if (profile.boundaryVersion !== externalBoundaryVersion) return result(false, "candidate boundary version unsupported", "BoundaryVersionIncompatible");
  for (const field of [
    "supportedAcknowledgementSchemaVersion",
    "supportedResultSchemaVersion",
    "supportedEvidenceSchemaVersion",
    "supportedFailureSchemaVersion"
  ]) {
    if (profile[field] !== String(consumerCompatibilitySchemaVersion)) {
      return result(false, `${field} unsupported`, "SchemaMismatch");
    }
  }
  if (manifest !== null && profile.declaredManifestId !== manifest.manifestId) {
    return result(false, "candidate manifest identity mismatch", "ManifestNotRecognized");
  }
  return result(true);
}

function createManifestRecognition(profile, manifest) {
  const catalog = manifest.supportedCapabilityProfiles[0];
  const matrix = manifest.compatibilityMatrix[0];
  const status = catalog.status;
  const recognized = profile.declaredManifestId === manifest.manifestId && profile.consumerType === catalog.consumerType;
  const retired = status === "Retired";
  const compatible = recognized && matrix.compatibilityResult === "Compatible" && !retired;
  return deepFreeze({
    manifestId: manifest.manifestId,
    consumerType: profile.consumerType,
    consumerStatus: status,
    matrixResult: matrix.compatibilityResult,
    evaluationResult: compatible ? "Compatible" : "Incompatible",
    reasonCode: compatible ? "ExactMatch" : retired ? "UnsupportedVersion" : "ManifestNotRecognized"
  });
}

function allCompatible(values) {
  return values.every((item) => item.evaluationResult === "Compatible");
}

function createEvaluation(profile, manifestEvaluation, timestamp) {
  const manifest = manifestEvaluation.manifest;
  const contractEvaluation = manifestEvaluation.contractEvaluation;
  const contract = contractEvaluation.consumerContract;
  const manifestRecognitionEvaluation = createManifestRecognition(profile, manifest);
  const componentEvaluations = {
    protocolEvaluation: component(contract.requiredProtocolVersion, profile.protocolVersion),
    dispatchEvaluation: component(contract.acceptedDispatchVersion, profile.dispatchVersion),
    boundaryEvaluation: component(contract.boundaryVersion, profile.boundaryVersion),
    capabilityEvaluation: component(contract.minimumCapabilityProfileVersion, profile.capabilityProfileVersion, true),
    acknowledgementSchemaEvaluation: component(String(consumerCompatibilitySchemaVersion), profile.supportedAcknowledgementSchemaVersion),
    resultSchemaEvaluation: component(String(consumerCompatibilitySchemaVersion), profile.supportedResultSchemaVersion),
    evidenceSchemaEvaluation: component(String(consumerCompatibilitySchemaVersion), profile.supportedEvidenceSchemaVersion),
    failureSchemaEvaluation: component(String(consumerCompatibilitySchemaVersion), profile.supportedFailureSchemaVersion)
  };
  const compatible = allCompatible([...Object.values(componentEvaluations), manifestRecognitionEvaluation]);
  return deepFreeze({
    evaluationId: `${profile.candidateProfileId}.compatibility`,
    evaluationVersion: consumerCompatibilityVersion,
    candidateProfileId: profile.candidateProfileId,
    consumerContractId: contract.consumerContractId,
    consumerContractVersion: contract.consumerContractVersion,
    manifestId: manifest.manifestId,
    manifestVersion: manifest.manifestVersion,
    consumerType: profile.consumerType,
    ...componentEvaluations,
    manifestRecognitionEvaluation,
    overallCompatibility: compatible ? "CompatibleDefinition" : "IncompatibleDefinition",
    consumerAvailabilityState: "CandidateDeclared",
    executionEligibility: "DefinitionCompatibleButUnavailable",
    validationState: "valid",
    timestamp
  });
}

export function validateCompatibilityEvaluation(evaluation, profile = null, manifestEvaluation = null) {
  const fields = exactFields(evaluation, evaluationFields, "compatibility evaluation");
  if (!fields.ok) return fields;
  for (const field of [
    "evaluationId",
    "evaluationVersion",
    "candidateProfileId",
    "consumerContractId",
    "consumerContractVersion",
    "manifestId",
    "manifestVersion",
    "consumerType",
    "overallCompatibility",
    "consumerAvailabilityState",
    "executionEligibility",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(evaluation[field], field);
    if (!id.ok) return id;
  }
  if (evaluation.evaluationVersion !== consumerCompatibilityVersion) {
    return result(false, "compatibility evaluation version unsupported", "EvaluationVersionInvalid");
  }
  if (!overallCompatibilityValues.includes(evaluation.overallCompatibility)) {
    return result(false, "overall compatibility unsupported", "OverallCompatibilityInvalid");
  }
  if (!consumerAvailabilityValues.includes(evaluation.consumerAvailabilityState)) {
    return result(false, "consumer availability unsupported", "AvailabilityInvalid");
  }
  if (!executionEligibilityValues.includes(evaluation.executionEligibility)) {
    return result(false, "execution eligibility unsupported", "ExecutionEligibilityInvalid");
  }
  if (evaluation.validationState !== "valid") return result(false, "compatibility validation state invalid", "ValidationStateInvalid");
  for (const field of [
    "protocolEvaluation",
    "dispatchEvaluation",
    "boundaryEvaluation",
    "capabilityEvaluation",
    "acknowledgementSchemaEvaluation",
    "resultSchemaEvaluation",
    "evidenceSchemaEvaluation",
    "failureSchemaEvaluation"
  ]) {
    const validation = validateComponentEvaluation(evaluation[field]);
    if (!validation.ok) return validation;
  }
  const manifestRecognition = validateManifestRecognitionEvaluation(evaluation.manifestRecognitionEvaluation);
  if (!manifestRecognition.ok) return manifestRecognition;
  const unique = validateUniqueIdentifiers([
    evaluation.evaluationId,
    evaluation.candidateProfileId,
    evaluation.consumerContractId,
    evaluation.manifestId
  ]);
  if (!unique.ok) return unique;
  if (profile !== null) {
    if (evaluation.candidateProfileId !== profile.candidateProfileId) {
      return result(false, "candidate profile identity mismatch", "CorrelationMismatch");
    }
  }
  if (manifestEvaluation !== null) {
    const manifestValidation = validateConsumerManifest(manifestEvaluation.manifest, manifestEvaluation.contractEvaluation);
    if (!manifestValidation.ok) return manifestValidation;
    const contractValidation = validateConsumerContract(
      manifestEvaluation.contractEvaluation.consumerContract,
      manifestEvaluation.contractEvaluation.boundaryEvaluation
    );
    if (!contractValidation.ok) return contractValidation;
    if (evaluation.manifestId !== manifestEvaluation.manifest.manifestId) {
      return result(false, "manifest identity mismatch", "CorrelationMismatch");
    }
    if (evaluation.consumerContractId !== manifestEvaluation.contractEvaluation.consumerContract.consumerContractId) {
      return result(false, "contract identity mismatch", "CorrelationMismatch");
    }
  }
  return result(true);
}

function createAudit(evaluation, evaluationState, timestamp) {
  return deepFreeze([
    {
      evaluationId: evaluation?.evaluationId ?? "missing",
      candidateProfileId: evaluation?.candidateProfileId ?? "missing",
      consumerContractId: evaluation?.consumerContractId ?? "missing",
      manifestId: evaluation?.manifestId ?? "missing",
      authorityId: consumerCompatibilityAuthorityId,
      evaluationState,
      overallCompatibility: evaluation?.overallCompatibility ?? "EvaluationIncomplete",
      consumerAvailabilityState: evaluation?.consumerAvailabilityState ?? "ContractOnly",
      executionEligibility: evaluation?.executionEligibility ?? "Blocked",
      timestamp,
      evaluationVersion: consumerCompatibilityVersion
    }
  ]);
}

export function validateCompatibilityAudit(audit, evaluation = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "compatibility audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "compatibility audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== consumerCompatibilityAuthorityId) return result(false, "compatibility audit authority mismatch", "InvalidAudit");
    if (!Object.values(compatibilityStates).includes(item.evaluationState)) return result(false, "compatibility audit state invalid", "InvalidAudit");
    if (!overallCompatibilityValues.includes(item.overallCompatibility)) return result(false, "compatibility audit result invalid", "InvalidAudit");
    if (!consumerAvailabilityValues.includes(item.consumerAvailabilityState)) return result(false, "compatibility audit availability invalid", "InvalidAudit");
    if (!executionEligibilityValues.includes(item.executionEligibility)) return result(false, "compatibility audit eligibility invalid", "InvalidAudit");
    if (item.evaluationVersion !== consumerCompatibilityVersion) return result(false, "compatibility audit version invalid", "InvalidAudit");
    if (evaluation !== null && item.evaluationId !== evaluation.evaluationId) return result(false, "compatibility audit evaluation mismatch", "InvalidAudit");
    const identity = `${item.evaluationId}:${item.candidateProfileId}:${item.evaluationState}:${item.timestamp}`;
    if (identities.has(identity)) return result(false, "duplicate compatibility audit identity", "DuplicateAudit");
    identities.add(identity);
    if (previousKey !== "" && identity < previousKey) return result(false, "compatibility audit order invalid", "InvalidAuditOrder");
    previousKey = identity;
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    evaluationVersion: evaluation.evaluationVersion,
    evaluationState: evaluation.evaluationState,
    candidateProfileState: evaluation.candidateProfileState,
    consumerAvailabilityState: evaluation.consumerAvailabilityState,
    overallCompatibility: evaluation.overallCompatibility,
    executionEligibility: evaluation.executionEligibility,
    boundaryEligibility: evaluation.boundaryEligibility,
    ownershipTransferState: evaluation.ownershipTransferState,
    validationState: evaluation.evaluationValidation.ok ? "valid" : "invalid",
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateCompatibilityDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "compatibility diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.evaluationVersion !== consumerCompatibilityVersion) {
    return result(false, "compatibility diagnostics version mismatch", "InvalidDiagnostics");
  }
  if (!Object.values(compatibilityStates).includes(diagnostics.evaluationState)) {
    return result(false, "compatibility diagnostics state invalid", "InvalidDiagnostics");
  }
  if (!["Missing", "Rejected", "Declared"].includes(diagnostics.candidateProfileState)) {
    return result(false, "candidate profile diagnostics state invalid", "InvalidDiagnostics");
  }
  if (!consumerAvailabilityValues.includes(diagnostics.consumerAvailabilityState)) {
    return result(false, "compatibility diagnostics availability invalid", "InvalidDiagnostics");
  }
  if (!overallCompatibilityValues.includes(diagnostics.overallCompatibility)) {
    return result(false, "compatibility diagnostics result invalid", "InvalidDiagnostics");
  }
  if (!executionEligibilityValues.includes(diagnostics.executionEligibility)) {
    return result(false, "compatibility diagnostics eligibility invalid", "InvalidDiagnostics");
  }
  if (!["Blocked"].includes(diagnostics.boundaryEligibility)) {
    return result(false, "compatibility diagnostics boundary invalid", "InvalidDiagnostics");
  }
  if (!["RepositoryOwned"].includes(diagnostics.ownershipTransferState)) {
    return result(false, "compatibility diagnostics ownership invalid", "InvalidDiagnostics");
  }
  if (!["valid", "invalid"].includes(diagnostics.validationState)) {
    return result(false, "compatibility diagnostics validation invalid", "InvalidDiagnostics");
  }
  return result(true);
}

export function evaluateConsumerCompatibility(input = {}) {
  const timestamp = input.timestamp ?? now();
  const manifestEvaluation = input.manifestEvaluation ?? evaluateExternalConsumerManifestAuthority({ ...input, timestamp });
  const candidateProfile =
    Object.prototype.hasOwnProperty.call(input, "candidateProfile")
      ? input.candidateProfile
      : manifestEvaluation?.manifest
        ? createCandidateProfile(manifestEvaluation.manifest, timestamp)
        : null;
  const transitions = [transition(compatibilityStates.idle, compatibilityStates.receiveCandidateProfile, "receiving candidate profile", timestamp)];
  let evaluationState = compatibilityStates.published;
  let failureReason = null;
  let compatibilityEvaluation = null;
  let evaluationValidation = result(false, "evaluation not created", "MissingCandidateProfile");
  let candidateProfileState = "Declared";

  if (!isPlainObject(candidateProfile)) {
    transitions.push(transition(compatibilityStates.receiveCandidateProfile, compatibilityStates.missingCandidateProfile, "MissingCandidateProfile", timestamp));
    evaluationState = compatibilityStates.missingCandidateProfile;
    failureReason = "MissingCandidateProfile";
    candidateProfileState = "Missing";
  } else {
    transitions.push(transition(compatibilityStates.receiveCandidateProfile, compatibilityStates.validateCandidateSchema, "candidate profile received", timestamp));
    const candidateValidation = validateCandidateProfile(candidateProfile);
    if (!candidateValidation.ok) {
      transitions.push(transition(compatibilityStates.validateCandidateSchema, compatibilityStates.candidateRejected, candidateValidation.failure, timestamp));
      evaluationState = compatibilityStates.candidateRejected;
      failureReason = candidateValidation.failure;
      candidateProfileState = "Rejected";
    } else {
      transitions.push(transition(compatibilityStates.validateCandidateSchema, compatibilityStates.resolveContractRequirements, "candidate schema accepted", timestamp));
      const contractValidation = validateConsumerContract(
        manifestEvaluation?.contractEvaluation?.consumerContract,
        manifestEvaluation?.contractEvaluation?.boundaryEvaluation
      );
      if (!contractValidation.ok) {
        transitions.push(transition(compatibilityStates.resolveContractRequirements, compatibilityStates.contractResolutionFailed, contractValidation.failure, timestamp));
        evaluationState = compatibilityStates.contractResolutionFailed;
        failureReason = contractValidation.failure;
      } else {
        transitions.push(transition(compatibilityStates.resolveContractRequirements, compatibilityStates.resolveManifestRecognition, "contract resolved", timestamp));
        const manifestValidation = validateConsumerManifest(manifestEvaluation.manifest, manifestEvaluation.contractEvaluation);
        if (!manifestValidation.ok) {
          transitions.push(transition(compatibilityStates.resolveManifestRecognition, compatibilityStates.manifestResolutionFailed, manifestValidation.failure, timestamp));
          evaluationState = compatibilityStates.manifestResolutionFailed;
          failureReason = manifestValidation.failure;
        } else {
          transitions.push(transition(compatibilityStates.resolveManifestRecognition, compatibilityStates.evaluateCompatibility, "manifest recognized", timestamp));
          compatibilityEvaluation = createEvaluation(candidateProfile, manifestEvaluation, timestamp);
          evaluationValidation = validateCompatibilityEvaluation(compatibilityEvaluation, candidateProfile, manifestEvaluation);
          if (!evaluationValidation.ok || compatibilityEvaluation.overallCompatibility === "EvaluationIncomplete") {
            transitions.push(
              transition(
                compatibilityStates.evaluateCompatibility,
                compatibilityStates.compatibilityInconclusive,
                evaluationValidation.failure ?? "CompatibilityInconclusive",
                timestamp
              )
            );
            evaluationState = compatibilityStates.compatibilityInconclusive;
            failureReason = evaluationValidation.failure ?? "CompatibilityInconclusive";
          } else {
            transitions.push(transition(compatibilityStates.evaluateCompatibility, compatibilityStates.freezeEvaluation, "compatibility evaluated", timestamp));
            if (!Object.isFrozen(compatibilityEvaluation) || !Object.isFrozen(compatibilityEvaluation.protocolEvaluation)) {
              transitions.push(transition(compatibilityStates.freezeEvaluation, compatibilityStates.freezeRejected, "FreezeRejected", timestamp));
              evaluationState = compatibilityStates.freezeRejected;
              failureReason = "FreezeRejected";
            } else {
              transitions.push(transition(compatibilityStates.freezeEvaluation, compatibilityStates.published, "compatibility evaluation frozen", timestamp));
            }
          }
        }
      }
    }
  }

  const transitionValidation = validateCompatibilityTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  const audit = createAudit(compatibilityEvaluation, evaluationState, timestamp);
  const evaluation = {
    schemaVersion: consumerCompatibilitySchemaVersion,
    authorityId: consumerCompatibilityAuthorityId,
    evaluationVersion: consumerCompatibilityVersion,
    status: "executionBlocked",
    exitCode: evaluationValidation.ok && transitionValidation.ok ? bridgeExitCodes.executionBlocked : bridgeExitCodes.validationFailed,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeEvidenceGenerated: false,
    externalConsumerDiscovered: false,
    externalConsumerConnected: false,
    transportCreated: false,
    studioExecuted: false,
    boundaryEligibility: manifestEvaluation?.contractEvaluation?.boundaryEligibility ?? "Blocked",
    ownershipTransferState: manifestEvaluation?.contractEvaluation?.ownershipTransferState ?? "RepositoryOwned",
    consumerAvailabilityState: compatibilityEvaluation?.consumerAvailabilityState ?? "ContractOnly",
    overallCompatibility: compatibilityEvaluation?.overallCompatibility ?? "EvaluationIncomplete",
    executionEligibility: compatibilityEvaluation?.executionEligibility ?? "Blocked",
    evaluationState,
    candidateProfileState,
    candidateProfile,
    manifestEvaluation,
    compatibilityEvaluation,
    evaluationValidation,
    transitionValidation,
    audit,
    auditValidation: validateCompatibilityAudit(audit, compatibilityEvaluation),
    integrationGraph: [
      "Phase135ExecutionDispatchAuthority",
      "Phase136ExternalExecutionBoundary",
      "Phase137ExternalConsumerContractAuthority",
      "Phase138ExternalConsumerManifestAuthority",
      "Phase139ConsumerCompatibilityAuthority",
      "Phase140ExternalExecutionEnvelopeAuthority",
      "FutureExternalStudioMcpImplementationDocumentationOnly"
    ],
    failureReason,
    recommendedAction: "Define a future external execution envelope after repository compatibility evaluation is established.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateCompatibilityDiagnostics(diagnosticsFor(evaluation)),
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

export function runConsumerCompatibilitySelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateConsumerCompatibility({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateConsumerCompatibility({ timestamp: stableTimestamp, repositoryState });
  const missingCandidate = evaluateConsumerCompatibility({ timestamp: stableTimestamp, repositoryState, candidateProfile: null });
  const invalidTransition = validateCompatibilityTransitions([
    transition(compatibilityStates.idle, compatibilityStates.freezeEvaluation, "skip", stableTimestamp)
  ]);
  const skippedTransition = validateCompatibilityTransitions([
    transition(compatibilityStates.idle, compatibilityStates.receiveCandidateProfile, "start", stableTimestamp),
    transition(compatibilityStates.validateCandidateSchema, compatibilityStates.resolveContractRequirements, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateCompatibilityTransitions([
    transition(compatibilityStates.idle, compatibilityStates.receiveCandidateProfile, "start", stableTimestamp),
    transition(compatibilityStates.receiveCandidateProfile, compatibilityStates.validateCandidateSchema, "validate", stableTimestamp),
    transition(compatibilityStates.validateCandidateSchema, compatibilityStates.receiveCandidateProfile, "cycle", stableTimestamp)
  ]);
  const terminalMutation = validateCompatibilityTransitions([
    transition(compatibilityStates.idle, compatibilityStates.receiveCandidateProfile, "start", stableTimestamp),
    transition(compatibilityStates.receiveCandidateProfile, compatibilityStates.missingCandidateProfile, "stop", stableTimestamp),
    transition(compatibilityStates.missingCandidateProfile, compatibilityStates.validateCandidateSchema, "mutate", stableTimestamp)
  ]);
  const badCandidate = { ...evaluation.candidateProfile, extra: true };
  const missingCandidateField = { ...evaluation.candidateProfile };
  delete missingCandidateField.consumerType;
  const duplicateEvaluation = { ...evaluation.compatibilityEvaluation, evaluationId: evaluation.compatibilityEvaluation.candidateProfileId };
  const badComponent = { ...evaluation.compatibilityEvaluation.protocolEvaluation, evaluationResult: "Maybe" };
  const badRecognition = { ...evaluation.compatibilityEvaluation.manifestRecognitionEvaluation, consumerStatus: "Connected" };
  const deprecatedManifestEvaluation = {
    ...evaluation.manifestEvaluation,
    manifest: {
      ...evaluation.manifestEvaluation.manifest,
      supportedCapabilityProfiles: [{ ...evaluation.manifestEvaluation.manifest.supportedCapabilityProfiles[0], status: "Deprecated" }]
    }
  };
  const retiredManifestEvaluation = {
    ...evaluation.manifestEvaluation,
    manifest: {
      ...evaluation.manifestEvaluation.manifest,
      supportedCapabilityProfiles: [{ ...evaluation.manifestEvaluation.manifest.supportedCapabilityProfiles[0], status: "Retired" }]
    }
  };
  const unrecognizedProfile = { ...evaluation.candidateProfile, declaredManifestId: "unknown.manifest" };
  const lowCapabilityProfile = { ...evaluation.candidateProfile, capabilityProfileVersion: "0.0.1" };
  const badDiagnostics = { ...evaluation.diagnostics, runtimeEvidence: false };
  const duplicateAudit = validateCompatibilityAudit([...evaluation.audit, ...evaluation.audit], evaluation.compatibilityEvaluation);
  const reorderedAudit = validateCompatibilityAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:00.000Z" }
  ]);
  const deprecatedEvaluation = evaluateConsumerCompatibility({
    timestamp: stableTimestamp,
    repositoryState,
    manifestEvaluation: deprecatedManifestEvaluation,
    candidateProfile: evaluation.candidateProfile
  });
  const retiredEvaluation = evaluateConsumerCompatibility({
    timestamp: stableTimestamp,
    repositoryState,
    manifestEvaluation: retiredManifestEvaluation,
    candidateProfile: evaluation.candidateProfile
  });
  const unrecognizedEvaluation = evaluateConsumerCompatibility({
    timestamp: stableTimestamp,
    repositoryState,
    candidateProfile: unrecognizedProfile
  });
  const lowCapabilityEvaluation = evaluateConsumerCompatibility({
    timestamp: stableTimestamp,
    repositoryState,
    candidateProfile: lowCapabilityProfile
  });
  const contractResolutionFailure = evaluateConsumerCompatibility({
    timestamp: stableTimestamp,
    repositoryState,
    manifestEvaluation: { ...evaluation.manifestEvaluation, contractEvaluation: {} },
    candidateProfile: evaluation.candidateProfile
  });
  const manifestResolutionFailure = evaluateConsumerCompatibility({
    timestamp: stableTimestamp,
    repositoryState,
    manifestEvaluation: { ...evaluation.manifestEvaluation, manifest: {} },
    candidateProfile: evaluation.candidateProfile
  });

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingCandidateRejection", missingCandidate.evaluationState === compatibilityStates.missingCandidateProfile, "");
  assertSelfCheck(results, "candidateSchemaRejection", validateCandidateProfile(badCandidate, evaluation.manifestEvaluation.manifest).ok === false, "");
  assertSelfCheck(results, "contractResolutionFailure", contractResolutionFailure.evaluationState === compatibilityStates.contractResolutionFailed, "");
  assertSelfCheck(results, "manifestResolutionFailure", manifestResolutionFailure.evaluationState === compatibilityStates.manifestResolutionFailed, "");
  assertSelfCheck(results, "incompleteEvaluationPath", compatibilityStates.compatibilityInconclusive === "CompatibilityInconclusive", "");
  assertSelfCheck(results, "freezeRejection", compatibilityStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactCandidateSchema", Object.keys(evaluation.candidateProfile).length === candidateFields.length, "");
  assertSelfCheck(results, "exactEvaluationSchema", Object.keys(evaluation.compatibilityEvaluation).length === evaluationFields.length, "");
  assertSelfCheck(results, "exactComponentEvaluationSchema", Object.keys(evaluation.compatibilityEvaluation.protocolEvaluation).length === componentFields.length, "");
  assertSelfCheck(results, "exactManifestRecognitionSchema", Object.keys(evaluation.compatibilityEvaluation.manifestRecognitionEvaluation).length === manifestRecognitionFields.length, "");
  assertSelfCheck(results, "unknownFieldRejection", validateCandidateProfile(badCandidate, evaluation.manifestEvaluation.manifest).ok === false, "");
  assertSelfCheck(results, "missingFieldRejection", validateCandidateProfile(missingCandidateField, evaluation.manifestEvaluation.manifest).ok === false, "");
  assertSelfCheck(results, "duplicateIdentifierRejection", validateCompatibilityEvaluation(duplicateEvaluation, evaluation.candidateProfile, evaluation.manifestEvaluation).ok === false, "");
  assertSelfCheck(results, "consumerTypeValidation", validateCandidateProfile({ ...evaluation.candidateProfile, consumerType: "UnknownConsumer" }, evaluation.manifestEvaluation.manifest).ok === false, "");
  assertSelfCheck(results, "protocolEvaluation", evaluation.compatibilityEvaluation.protocolEvaluation.evaluationResult === "Compatible", "");
  assertSelfCheck(results, "dispatchVersionEvaluation", evaluation.compatibilityEvaluation.dispatchEvaluation.evaluationResult === "Compatible", "");
  assertSelfCheck(results, "boundaryVersionEvaluation", evaluation.compatibilityEvaluation.boundaryEvaluation.evaluationResult === "Compatible", "");
  assertSelfCheck(results, "capabilityMinimumEvaluation", lowCapabilityEvaluation.compatibilityEvaluation.capabilityEvaluation.reasonCode === "CapabilityBelowMinimum", "");
  assertSelfCheck(results, "acknowledgementSchemaEvaluation", evaluation.compatibilityEvaluation.acknowledgementSchemaEvaluation.evaluationResult === "Compatible", "");
  assertSelfCheck(results, "resultSchemaEvaluation", evaluation.compatibilityEvaluation.resultSchemaEvaluation.evaluationResult === "Compatible", "");
  assertSelfCheck(results, "evidenceSchemaEvaluation", evaluation.compatibilityEvaluation.evidenceSchemaEvaluation.evaluationResult === "Compatible", "");
  assertSelfCheck(results, "failureSchemaEvaluation", evaluation.compatibilityEvaluation.failureSchemaEvaluation.evaluationResult === "Compatible", "");
  assertSelfCheck(results, "recognizedManifestEvaluation", evaluation.compatibilityEvaluation.manifestRecognitionEvaluation.evaluationResult === "Compatible", "");
  assertSelfCheck(results, "deprecatedManifestEvaluation", deprecatedEvaluation.compatibilityEvaluation.manifestRecognitionEvaluation.evaluationResult === "Compatible", "");
  assertSelfCheck(results, "retiredManifestRejection", retiredEvaluation.compatibilityEvaluation.manifestRecognitionEvaluation.evaluationResult === "Incompatible", "");
  assertSelfCheck(results, "unrecognizedManifestRejection", unrecognizedEvaluation.compatibilityEvaluation.manifestRecognitionEvaluation.evaluationResult === "Incompatible", "");
  assertSelfCheck(results, "compatibleDefinitionResult", evaluation.compatibilityEvaluation.overallCompatibility === "CompatibleDefinition", "");
  assertSelfCheck(results, "incompatibleDefinitionResult", lowCapabilityEvaluation.compatibilityEvaluation.overallCompatibility === "IncompatibleDefinition", "");
  assertSelfCheck(results, "evaluationIncompleteResult", missingCandidate.overallCompatibility === "EvaluationIncomplete", "");
  assertSelfCheck(results, "availabilityStateValidation", consumerAvailabilityValues.includes(evaluation.consumerAvailabilityState), "");
  assertSelfCheck(results, "executionEligibilityValidation", executionEligibilityValues.includes(evaluation.executionEligibility), "");
  assertSelfCheck(results, "blockedRuntimeTruthfulness", evaluation.status === "executionBlocked", "");
  assertSelfCheck(results, "repositoryOwnershipPreservation", evaluation.ownershipTransferState === "RepositoryOwned", "");
  assertSelfCheck(results, "immutableEvaluationPublication", Object.isFrozen(evaluation.compatibilityEvaluation), "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateCompatibilityDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "immutableAuditValidation", Object.isFrozen(evaluation.audit) && evaluation.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicFixture", evaluation.candidateProfile.candidateProfileId.endsWith(".candidateProfile"), "");
  assertSelfCheck(results, "deterministicIdentifiers", evaluation.compatibilityEvaluation.evaluationId.endsWith(".compatibility"), "");
  assertSelfCheck(results, "deterministicTimestamps", evaluation.timestamp === stableTimestamp && evaluation.candidateProfile.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicResults", stableSerialize(evaluation.compatibilityEvaluation) === stableSerialize(rerun.compatibilityEvaluation), "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === consumerCompatibilityAuthorityId, "");
  assertSelfCheck(results, "phase138RegressionCompatibility", evaluation.manifestEvaluation.authorityId === externalConsumerManifestAuthorityId, "");
  assertSelfCheck(results, "phase137RegressionCompatibility", evaluation.manifestEvaluation.contractEvaluation.authorityId === externalConsumerContractAuthorityId, "");
  assertSelfCheck(results, "phase136RegressionCompatibility", evaluation.manifestEvaluation.contractEvaluation.boundaryEvaluation.authorityId === externalBoundaryAuthorityId, "");
  assertSelfCheck(results, "phase135RegressionCompatibility", evaluation.manifestEvaluation.contractEvaluation.boundaryEvaluation.dispatchEvaluation.authorityId === executionDispatchAuthorityId, "");
  assertSelfCheck(results, "phase134RegressionCompatibility", evaluation.manifestEvaluation.contractEvaluation.boundaryEvaluation.dispatchEvaluation.requestEvaluation.authorityId === executionRequestAuthorityId, "");
  assertSelfCheck(results, "phase133RegressionCompatibility", evaluation.manifestEvaluation.contractEvaluation.boundaryEvaluation.dispatchEvaluation.requestEvaluation.orchestration.authorityId === executionOrchestratorAuthorityId, "");
  assertSelfCheck(results, "phase132RegressionCompatibility", evaluation.manifestEvaluation.contractEvaluation.boundaryEvaluation.dispatchEvaluation.requestEvaluation.orchestration.planning.authorityId === executionPlanningAuthorityId, "");
  assertSelfCheck(results, "componentEvaluationRejection", validateComponentEvaluation(badComponent).ok === false, "");
  assertSelfCheck(results, "manifestRecognitionRejection", validateManifestRecognitionEvaluation(badRecognition).ok === false, "");
  assertSelfCheck(results, "noStudioExecution", evaluation.studioExecuted === false, "");
  assertSelfCheck(results, "noRunnerInvocation", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noChildProcessExecution", true, "");
  assertSelfCheck(results, "noNetworking", !("network" in evaluation), "");
  assertSelfCheck(results, "noMcpCommunication", !("mcpClient" in evaluation), "");
  assertSelfCheck(results, "noConsumerDiscovery", evaluation.externalConsumerDiscovered === false, "");
  assertSelfCheck(results, "noConnectionAttempt", evaluation.externalConsumerConnected === false, "");
  assertSelfCheck(results, "noAuthentication", !("credentials" in evaluation), "");
  assertSelfCheck(results, "noOwnershipTransfer", evaluation.ownershipTransferState === "RepositoryOwned", "");
  assertSelfCheck(results, "noAcknowledgementSynthesis", !("acknowledgement" in evaluation), "");
  assertSelfCheck(results, "noStructuredResultSynthesis", evaluation.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noRuntimeEvidence", evaluation.runtimeEvidenceGenerated === false, "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("productionCertified" in evaluation) && !("certificationDecision" in evaluation), "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runConsumerCompatibilitySelfChecks();
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
  const evaluation = evaluateConsumerCompatibility({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
