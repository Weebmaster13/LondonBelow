import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  compatibilityStates,
  consumerAvailabilityStates,
  evaluateExternalConsumerContractAuthority,
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
import { integrationContractProtocolVersion, stableSerialize } from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const externalConsumerManifestSchemaVersion = 1;
export const externalConsumerManifestVersion = "1.0.0";
export const externalConsumerManifestAuthorityId = "chapter0Home.phase138StudioExternalConsumerManifestAuthority";

export const manifestStates = Object.freeze({
  idle: "Idle",
  receiveConsumerContract: "ReceiveConsumerContract",
  validateManifest: "ValidateManifest",
  buildManifest: "BuildManifest",
  freezeManifest: "FreezeManifest",
  published: "ManifestPublished",
  missingConsumerContract: "MissingConsumerContract",
  rejected: "ManifestRejected",
  constructionFailed: "ManifestConstructionFailed",
  freezeRejected: "FreezeRejected"
});

export const manifestConsumerStatusValues = Object.freeze(["Defined", "Deprecated", "Retired"]);
export const manifestCompatibilityResults = Object.freeze(["Compatible", "Incompatible"]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  manifestStates.published,
  manifestStates.missingConsumerContract,
  manifestStates.rejected,
  manifestStates.constructionFailed,
  manifestStates.freezeRejected
]);
const legalTransitions = new Map([
  [manifestStates.idle, new Set([manifestStates.receiveConsumerContract])],
  [manifestStates.receiveConsumerContract, new Set([manifestStates.validateManifest, manifestStates.missingConsumerContract])],
  [manifestStates.validateManifest, new Set([manifestStates.buildManifest, manifestStates.rejected])],
  [manifestStates.buildManifest, new Set([manifestStates.freezeManifest, manifestStates.constructionFailed])],
  [manifestStates.freezeManifest, new Set([manifestStates.published, manifestStates.freezeRejected])]
]);

const manifestFields = Object.freeze([
  "manifestId",
  "manifestVersion",
  "consumerContractId",
  "consumerContractVersion",
  "consumerType",
  "supportedProtocolVersions",
  "supportedDispatchVersions",
  "supportedBoundaryVersions",
  "supportedCapabilityProfiles",
  "compatibilityMatrix",
  "validationState",
  "timestamp"
]);
const catalogFields = Object.freeze([
  "consumerId",
  "consumerType",
  "supportedContractVersion",
  "supportedProtocolVersion",
  "minimumCapabilityVersion",
  "status"
]);
const matrixFields = Object.freeze([
  "protocolVersion",
  "contractVersion",
  "boundaryVersion",
  "dispatchVersion",
  "minimumCapabilityVersion",
  "compatibilityResult"
]);
const diagnosticsFields = Object.freeze([
  "manifestVersion",
  "manifestState",
  "consumerAvailabilityState",
  "compatibilityState",
  "validationState",
  "failureReason",
  "timestamp"
]);
const auditFields = Object.freeze([
  "manifestId",
  "consumerContractId",
  "authorityId",
  "manifestState",
  "compatibilityState",
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

function validateUniqueIdentifiers(values, label) {
  const seen = new Set();
  for (const value of values) {
    const id = validateIdentifier(value, label);
    if (!id.ok) return id;
    if (seen.has(value)) return result(false, `duplicate ${label} ${value}`, "DuplicateIdentifier");
    seen.add(value);
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: externalConsumerManifestAuthorityId });
}

export function validateManifestTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "manifest transitions must be non-empty", "InvalidLifecycle");
  }
  let terminalSeen = false;
  const seenEdges = new Set();
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(manifestStates).includes(item.from) || !Object.values(manifestStates).includes(item.to)) {
      return result(false, "undocumented manifest state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== manifestStates.idle) {
      return result(false, "manifest lifecycle must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "manifest lifecycle skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal manifest state mutated", "InvalidLifecycle");
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal manifest transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    const edge = `${item.from}->${item.to}`;
    if (seenEdges.has(edge)) return result(false, "cyclic manifest transition", "InvalidLifecycle");
    seenEdges.add(edge);
    if (terminalStates.has(item.to)) terminalSeen = true;
  }
  return result(true);
}

function createCatalogEntry(contract) {
  return deepFreeze({
    consumerId: `${contract.consumerContractId}.consumer`,
    consumerType: contract.consumerType,
    supportedContractVersion: contract.consumerContractVersion,
    supportedProtocolVersion: contract.requiredProtocolVersion,
    minimumCapabilityVersion: contract.minimumCapabilityProfileVersion,
    status: "Defined"
  });
}

function createCompatibilityEntry(contract) {
  return deepFreeze({
    protocolVersion: contract.requiredProtocolVersion,
    contractVersion: contract.consumerContractVersion,
    boundaryVersion: contract.boundaryVersion,
    dispatchVersion: contract.acceptedDispatchVersion,
    minimumCapabilityVersion: contract.minimumCapabilityProfileVersion,
    compatibilityResult: "Compatible"
  });
}

function createManifest(contract, timestamp) {
  return deepFreeze({
    manifestId: `${contract.consumerContractId}.manifest`,
    manifestVersion: externalConsumerManifestVersion,
    consumerContractId: contract.consumerContractId,
    consumerContractVersion: contract.consumerContractVersion,
    consumerType: contract.consumerType,
    supportedProtocolVersions: [contract.requiredProtocolVersion],
    supportedDispatchVersions: [contract.acceptedDispatchVersion],
    supportedBoundaryVersions: [contract.boundaryVersion],
    supportedCapabilityProfiles: [createCatalogEntry(contract)],
    compatibilityMatrix: [createCompatibilityEntry(contract)],
    validationState: "valid",
    timestamp
  });
}

export function validateConsumerCatalogEntry(entry) {
  const fields = exactFields(entry, catalogFields, "consumer catalog entry");
  if (!fields.ok) return fields;
  for (const field of ["consumerId", "consumerType", "supportedContractVersion", "supportedProtocolVersion", "minimumCapabilityVersion", "status"]) {
    const id = validateIdentifier(entry[field], field);
    if (!id.ok) return id;
  }
  if (entry.consumerType !== externalConsumerType) return result(false, "manifest consumer type unsupported", "UnsupportedConsumerType");
  if (entry.supportedContractVersion !== externalConsumerContractAuthorityVersion) {
    return result(false, "manifest contract version unsupported", "ContractVersionIncompatible");
  }
  if (entry.supportedProtocolVersion !== integrationContractProtocolVersion) {
    return result(false, "manifest protocol version unsupported", "ProtocolIncompatible");
  }
  if (!manifestConsumerStatusValues.includes(entry.status)) return result(false, "manifest consumer status unsupported", "StatusInvalid");
  return result(true);
}

export function validateCompatibilityMatrixEntry(entry) {
  const fields = exactFields(entry, matrixFields, "compatibility matrix entry");
  if (!fields.ok) return fields;
  for (const field of matrixFields) {
    const id = validateIdentifier(entry[field], field);
    if (!id.ok) return id;
  }
  if (entry.protocolVersion !== integrationContractProtocolVersion) return result(false, "matrix protocol version unsupported", "ProtocolIncompatible");
  if (entry.contractVersion !== externalConsumerContractAuthorityVersion) {
    return result(false, "matrix contract version unsupported", "ContractVersionIncompatible");
  }
  if (entry.boundaryVersion !== externalBoundaryVersion) return result(false, "matrix boundary version unsupported", "BoundaryVersionIncompatible");
  if (entry.dispatchVersion !== executionDispatchVersion) return result(false, "matrix dispatch version unsupported", "DispatchIncompatible");
  if (!manifestCompatibilityResults.includes(entry.compatibilityResult)) {
    return result(false, "matrix compatibility result unsupported", "CompatibilityInvalid");
  }
  return result(true);
}

export function validateConsumerManifest(manifest, contractEvaluation = null) {
  const fields = exactFields(manifest, manifestFields, "external consumer manifest");
  if (!fields.ok) return fields;
  for (const field of [
    "manifestId",
    "manifestVersion",
    "consumerContractId",
    "consumerContractVersion",
    "consumerType",
    "validationState",
    "timestamp"
  ]) {
    const id = validateIdentifier(manifest[field], field);
    if (!id.ok) return id;
  }
  if (manifest.manifestVersion !== externalConsumerManifestVersion) return result(false, "manifest version unsupported", "ManifestVersionInvalid");
  if (manifest.consumerContractVersion !== externalConsumerContractAuthorityVersion) {
    return result(false, "manifest contract version unsupported", "ContractVersionIncompatible");
  }
  if (manifest.consumerType !== externalConsumerType) return result(false, "manifest consumer type unsupported", "UnsupportedConsumerType");
  if (manifest.validationState !== "valid") return result(false, "manifest validation state invalid", "ValidationStateInvalid");
  for (const [field, expected] of [
    ["supportedProtocolVersions", [integrationContractProtocolVersion]],
    ["supportedDispatchVersions", [executionDispatchVersion]],
    ["supportedBoundaryVersions", [externalBoundaryVersion]]
  ]) {
    if (!Array.isArray(manifest[field]) || manifest[field].length !== expected.length || manifest[field][0] !== expected[0]) {
      return result(false, `${field} invalid`, "ManifestVersionInvalid");
    }
  }
  if (!Array.isArray(manifest.supportedCapabilityProfiles) || manifest.supportedCapabilityProfiles.length !== 1) {
    return result(false, "consumer catalog invalid", "CatalogInvalid");
  }
  if (!Array.isArray(manifest.compatibilityMatrix) || manifest.compatibilityMatrix.length !== 1) {
    return result(false, "compatibility matrix invalid", "CompatibilityInvalid");
  }
  const catalog = validateConsumerCatalogEntry(manifest.supportedCapabilityProfiles[0]);
  if (!catalog.ok) return catalog;
  const matrix = validateCompatibilityMatrixEntry(manifest.compatibilityMatrix[0]);
  if (!matrix.ok) return matrix;
  const unique = validateUniqueIdentifiers(
    [
      manifest.manifestId,
      manifest.consumerContractId,
      manifest.supportedCapabilityProfiles[0].consumerId
    ],
    "manifest identifier"
  );
  if (!unique.ok) return unique;
  if (contractEvaluation !== null) {
    if (!isPlainObject(contractEvaluation) || contractEvaluation.authorityId !== externalConsumerContractAuthorityId) {
      return result(false, "consumer contract authority incompatible", "ConsumerContractIncompatible");
    }
    const contractValidation = validateConsumerContract(contractEvaluation.consumerContract, contractEvaluation.boundaryEvaluation);
    if (!contractValidation.ok) return contractValidation;
    const contract = contractEvaluation.consumerContract;
    if (manifest.consumerContractId !== contract.consumerContractId) return result(false, "manifest contract identity mismatch", "CorrelationMismatch");
    if (manifest.manifestId !== `${contract.consumerContractId}.manifest`) {
      return result(false, "manifest identity mismatch", "CorrelationMismatch");
    }
    if (manifest.supportedCapabilityProfiles[0].consumerId !== `${contract.consumerContractId}.consumer`) {
      return result(false, "catalog identity mismatch", "CorrelationMismatch");
    }
  }
  return result(true);
}

function createAudit(manifest, manifestState, compatibilityState, validationState, timestamp) {
  return deepFreeze([
    {
      manifestId: manifest?.manifestId ?? "missing",
      consumerContractId: manifest?.consumerContractId ?? "missing",
      authorityId: externalConsumerManifestAuthorityId,
      manifestState,
      compatibilityState,
      validationState,
      timestamp
    }
  ]);
}

export function validateManifestAudit(audit, manifest = null) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "manifest audit must be non-empty", "InvalidAudit");
  const identities = new Set();
  let previousKey = "";
  for (const item of audit) {
    const fields = exactFields(item, auditFields, "manifest audit");
    if (!fields.ok) return fields;
    for (const field of auditFields) {
      const id = validateIdentifier(item[field], field);
      if (!id.ok) return id;
    }
    if (item.authorityId !== externalConsumerManifestAuthorityId) return result(false, "manifest audit authority mismatch", "InvalidAudit");
    if (!Object.values(manifestStates).includes(item.manifestState)) return result(false, "manifest audit state invalid", "InvalidAudit");
    if (!compatibilityStates.includes(item.compatibilityState)) return result(false, "manifest audit compatibility invalid", "InvalidAudit");
    if (!["valid", "invalid"].includes(item.validationState)) return result(false, "manifest audit validation invalid", "InvalidAudit");
    if (manifest !== null && item.manifestId !== manifest.manifestId) return result(false, "manifest audit identity mismatch", "InvalidAudit");
    const identity = `${item.manifestId}:${item.consumerContractId}:${item.manifestState}:${item.timestamp}`;
    if (identities.has(identity)) return result(false, "duplicate manifest audit identity", "DuplicateAudit");
    identities.add(identity);
    if (previousKey !== "" && identity < previousKey) return result(false, "manifest audit order invalid", "InvalidAuditOrder");
    previousKey = identity;
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    manifestVersion: evaluation.manifestVersion,
    manifestState: evaluation.manifestState,
    consumerAvailabilityState: evaluation.consumerAvailabilityState,
    compatibilityState: evaluation.compatibilityState,
    validationState: evaluation.manifestValidation.ok ? "valid" : "invalid",
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function validateManifestDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "manifest diagnostics");
  if (!fields.ok) return fields;
  if (diagnostics.manifestVersion !== externalConsumerManifestVersion) return result(false, "manifest diagnostics version mismatch", "InvalidDiagnostics");
  if (!Object.values(manifestStates).includes(diagnostics.manifestState)) return result(false, "manifest diagnostics state invalid", "InvalidDiagnostics");
  if (!consumerAvailabilityStates.includes(diagnostics.consumerAvailabilityState)) {
    return result(false, "manifest diagnostics availability invalid", "InvalidDiagnostics");
  }
  if (!compatibilityStates.includes(diagnostics.compatibilityState)) {
    return result(false, "manifest diagnostics compatibility invalid", "InvalidDiagnostics");
  }
  if (!["valid", "invalid"].includes(diagnostics.validationState)) {
    return result(false, "manifest diagnostics validation invalid", "InvalidDiagnostics");
  }
  return result(true);
}

export function evaluateExternalConsumerManifestAuthority(input = {}) {
  const timestamp = input.timestamp ?? now();
  const contractEvaluation = input.contractEvaluation ?? evaluateExternalConsumerContractAuthority({ ...input, timestamp });
  const transitions = [transition(manifestStates.idle, manifestStates.receiveConsumerContract, "receiving consumer contract", timestamp)];
  let manifestState = manifestStates.published;
  let failureReason = null;
  let manifest = null;
  let manifestValidation = result(false, "manifest not created", "MissingConsumerContract");
  const consumerAvailabilityState = contractEvaluation?.consumerAvailabilityState ?? "ContractOnly";
  const compatibilityState = contractEvaluation?.compatibilityState ?? "DefinitionCompatible";

  if (!isPlainObject(contractEvaluation) || contractEvaluation.authorityId !== externalConsumerContractAuthorityId || !isPlainObject(contractEvaluation.consumerContract)) {
    transitions.push(transition(manifestStates.receiveConsumerContract, manifestStates.missingConsumerContract, "MissingConsumerContract", timestamp));
    manifestState = manifestStates.missingConsumerContract;
    failureReason = "MissingConsumerContract";
  } else {
    transitions.push(transition(manifestStates.receiveConsumerContract, manifestStates.validateManifest, "consumer contract received", timestamp));
    const contractValidation = validateConsumerContract(contractEvaluation.consumerContract, contractEvaluation.boundaryEvaluation);
    if (!contractValidation.ok || compatibilityState !== "DefinitionCompatible") {
      transitions.push(transition(manifestStates.validateManifest, manifestStates.rejected, contractValidation.failure ?? "ManifestRejected", timestamp));
      manifestState = manifestStates.rejected;
      failureReason = contractValidation.failure ?? "ManifestRejected";
    } else {
      transitions.push(transition(manifestStates.validateManifest, manifestStates.buildManifest, "manifest inputs accepted", timestamp));
      manifest = createManifest(contractEvaluation.consumerContract, timestamp);
      manifestValidation = validateConsumerManifest(manifest, contractEvaluation);
      if (!manifestValidation.ok) {
        transitions.push(transition(manifestStates.buildManifest, manifestStates.constructionFailed, manifestValidation.failure, timestamp));
        manifestState = manifestStates.constructionFailed;
        failureReason = manifestValidation.failure;
      } else {
        transitions.push(transition(manifestStates.buildManifest, manifestStates.freezeManifest, "manifest constructed", timestamp));
        if (!Object.isFrozen(manifest) || !Object.isFrozen(manifest.supportedCapabilityProfiles) || !Object.isFrozen(manifest.compatibilityMatrix)) {
          transitions.push(transition(manifestStates.freezeManifest, manifestStates.freezeRejected, "FreezeRejected", timestamp));
          manifestState = manifestStates.freezeRejected;
          failureReason = "FreezeRejected";
        } else {
          transitions.push(transition(manifestStates.freezeManifest, manifestStates.published, "manifest frozen", timestamp));
        }
      }
    }
  }

  const transitionValidation = validateManifestTransitions(transitions);
  if (!transitionValidation.ok && failureReason === null) failureReason = transitionValidation.failure;
  const audit = createAudit(manifest, manifestState, compatibilityState, manifestValidation.ok ? "valid" : "invalid", timestamp);
  const evaluation = {
    schemaVersion: externalConsumerManifestSchemaVersion,
    authorityId: externalConsumerManifestAuthorityId,
    manifestVersion: externalConsumerManifestVersion,
    contractAuthorityId: externalConsumerContractAuthorityId,
    boundaryAuthorityId: externalBoundaryAuthorityId,
    dispatchAuthorityId: executionDispatchAuthorityId,
    status: "executionBlocked",
    exitCode: manifestValidation.ok && transitionValidation.ok ? bridgeExitCodes.executionBlocked : bridgeExitCodes.validationFailed,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeEvidenceGenerated: false,
    externalConsumerDiscovered: false,
    externalConsumerConnected: false,
    transportCreated: false,
    studioExecuted: false,
    manifestState,
    consumerAvailabilityState,
    compatibilityState,
    contractEvaluation,
    manifest,
    manifestValidation,
    transitionValidation,
    audit,
    auditValidation: validateManifestAudit(audit, manifest),
    integrationGraph: [
      "Phase134ExecutionRequestAuthority",
      "Phase135ExecutionDispatchAuthority",
      "Phase136ExternalExecutionBoundary",
      "Phase137ExternalConsumerContractAuthority",
      "Phase138ExternalConsumerManifestAuthority",
      "FutureExternalStudioMcpImplementationDocumentationOnly"
    ],
    failureReason,
    recommendedAction: "Define the future external consumer implementation after repository manifest recognition is established.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    diagnosticsValidation: validateManifestDiagnostics(diagnosticsFor(evaluation)),
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

export function runExternalConsumerManifestSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const evaluation = evaluateExternalConsumerManifestAuthority({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExternalConsumerManifestAuthority({ timestamp: stableTimestamp, repositoryState });
  const missingContract = evaluateExternalConsumerManifestAuthority({ timestamp: stableTimestamp, contractEvaluation: {} });
  const invalidTransition = validateManifestTransitions([transition(manifestStates.idle, manifestStates.freezeManifest, "skip", stableTimestamp)]);
  const skippedTransition = validateManifestTransitions([
    transition(manifestStates.idle, manifestStates.receiveConsumerContract, "start", stableTimestamp),
    transition(manifestStates.validateManifest, manifestStates.buildManifest, "skip", stableTimestamp)
  ]);
  const cyclicTransition = validateManifestTransitions([
    transition(manifestStates.idle, manifestStates.receiveConsumerContract, "start", stableTimestamp),
    transition(manifestStates.receiveConsumerContract, manifestStates.validateManifest, "validate", stableTimestamp),
    transition(manifestStates.validateManifest, manifestStates.receiveConsumerContract, "cycle", stableTimestamp)
  ]);
  const terminalMutation = validateManifestTransitions([
    transition(manifestStates.idle, manifestStates.receiveConsumerContract, "start", stableTimestamp),
    transition(manifestStates.receiveConsumerContract, manifestStates.missingConsumerContract, "stop", stableTimestamp),
    transition(manifestStates.missingConsumerContract, manifestStates.validateManifest, "mutate", stableTimestamp)
  ]);
  const badManifest = { ...evaluation.manifest, extra: true };
  const missingManifestField = { ...evaluation.manifest };
  delete missingManifestField.consumerType;
  const duplicateManifest = { ...evaluation.manifest, manifestId: evaluation.manifest.consumerContractId };
  const badCatalog = {
    ...evaluation.manifest,
    supportedCapabilityProfiles: [{ ...evaluation.manifest.supportedCapabilityProfiles[0], status: "Connected" }]
  };
  const badCatalogField = {
    ...evaluation.manifest,
    supportedCapabilityProfiles: [{ ...evaluation.manifest.supportedCapabilityProfiles[0], extra: true }]
  };
  const badMatrix = {
    ...evaluation.manifest,
    compatibilityMatrix: [{ ...evaluation.manifest.compatibilityMatrix[0], compatibilityResult: "Execute" }]
  };
  const badMatrixField = {
    ...evaluation.manifest,
    compatibilityMatrix: [{ ...evaluation.manifest.compatibilityMatrix[0], extra: true }]
  };
  const badDiagnostics = { ...evaluation.diagnostics, runtimeEvidence: false };
  const duplicateAudit = validateManifestAudit([...evaluation.audit, ...evaluation.audit], evaluation.manifest);
  const reorderedAudit = validateManifestAudit([
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:01.000Z" },
    { ...evaluation.audit[0], timestamp: "2026-07-17T00:00:00.000Z" }
  ]);

  assertSelfCheck(results, "lifecycleSuccessClosure", evaluation.transitionValidation.ok === true, "");
  assertSelfCheck(results, "missingConsumerContractRejection", missingContract.manifestState === manifestStates.missingConsumerContract, "");
  assertSelfCheck(results, "manifestRejectionPath", manifestStates.rejected === "ManifestRejected", "");
  assertSelfCheck(results, "manifestConstructionFailurePath", manifestStates.constructionFailed === "ManifestConstructionFailed", "");
  assertSelfCheck(results, "freezeRejectionPath", manifestStates.freezeRejected === "FreezeRejected", "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "skippedTransitionRejection", skippedTransition.ok === false, "");
  assertSelfCheck(results, "cyclicTransitionRejection", cyclicTransition.ok === false, "");
  assertSelfCheck(results, "terminalMutationRejection", terminalMutation.ok === false, "");
  assertSelfCheck(results, "exactManifestSchema", Object.keys(evaluation.manifest).length === manifestFields.length, "");
  assertSelfCheck(results, "unknownManifestFieldRejection", validateConsumerManifest(badManifest, evaluation.contractEvaluation).ok === false, "");
  assertSelfCheck(results, "missingManifestFieldRejection", validateConsumerManifest(missingManifestField, evaluation.contractEvaluation).ok === false, "");
  assertSelfCheck(results, "duplicateManifestIdentifierRejection", validateConsumerManifest(duplicateManifest, evaluation.contractEvaluation).ok === false, "");
  assertSelfCheck(results, "manifestPublication", evaluation.manifestState === manifestStates.published, "");
  assertSelfCheck(results, "immutableManifestPublication", Object.isFrozen(evaluation.manifest), "");
  assertSelfCheck(results, "catalogValidation", validateConsumerCatalogEntry(evaluation.manifest.supportedCapabilityProfiles[0]).ok === true, "");
  assertSelfCheck(results, "catalogStatusValidation", validateConsumerManifest(badCatalog, evaluation.contractEvaluation).ok === false, "");
  assertSelfCheck(results, "catalogUnknownFieldRejection", validateConsumerManifest(badCatalogField, evaluation.contractEvaluation).ok === false, "");
  assertSelfCheck(results, "compatibilityMatrixValidation", validateCompatibilityMatrixEntry(evaluation.manifest.compatibilityMatrix[0]).ok === true, "");
  assertSelfCheck(results, "compatibilityMatrixResultValidation", validateConsumerManifest(badMatrix, evaluation.contractEvaluation).ok === false, "");
  assertSelfCheck(results, "compatibilityMatrixUnknownFieldRejection", validateConsumerManifest(badMatrixField, evaluation.contractEvaluation).ok === false, "");
  assertSelfCheck(results, "diagnosticsValidation", evaluation.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "diagnosticsExactFields", validateManifestDiagnostics(badDiagnostics).ok === false, "");
  assertSelfCheck(results, "auditValidation", evaluation.auditValidation.ok === true && Object.isFrozen(evaluation.audit), "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "auditOrderingValidation", reorderedAudit.ok === false, "");
  assertSelfCheck(results, "deterministicIds", evaluation.manifest.manifestId === `${evaluation.contractEvaluation.consumerContract.consumerContractId}.manifest`, "");
  assertSelfCheck(results, "deterministicSerialization", evaluation.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicOrdering", evaluation.manifest.compatibilityMatrix[0].protocolVersion === integrationContractProtocolVersion, "");
  assertSelfCheck(results, "deterministicDiagnostics", stableSerialize(evaluation.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "deterministicAudit", stableSerialize(evaluation.audit) === stableSerialize(rerun.audit), "");
  assertSelfCheck(results, "deterministicExitCodes", evaluation.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(evaluation.manifest) === stableSerialize(rerun.manifest), "");
  assertSelfCheck(results, "authorityIsolation", evaluation.authorityId === externalConsumerManifestAuthorityId, "");
  assertSelfCheck(results, "phase137RegressionCompatibility", evaluation.contractEvaluation.authorityId === externalConsumerContractAuthorityId, "");
  assertSelfCheck(results, "phase136RegressionCompatibility", evaluation.contractEvaluation.boundaryEvaluation.authorityId === externalBoundaryAuthorityId, "");
  assertSelfCheck(results, "phase135RegressionCompatibility", evaluation.contractEvaluation.boundaryEvaluation.dispatchEvaluation.authorityId === executionDispatchAuthorityId, "");
  assertSelfCheck(results, "contractReadOnly", Object.isFrozen(evaluation.contractEvaluation.consumerContract), "");
  assertSelfCheck(results, "consumerAvailabilityPreserved", evaluation.consumerAvailabilityState === "ContractOnly", "");
  assertSelfCheck(results, "compatibilityPreserved", evaluation.compatibilityState === "DefinitionCompatible", "");
  assertSelfCheck(results, "blockedRuntimePreserved", evaluation.status === "executionBlocked", "");
  assertSelfCheck(results, "noNetworking", !("network" in evaluation), "");
  assertSelfCheck(results, "noStudio", evaluation.studioExecuted === false, "");
  assertSelfCheck(results, "noRunner", evaluation.runnerInvoked === false, "");
  assertSelfCheck(results, "noTransport", evaluation.transportCreated === false, "");
  assertSelfCheck(results, "noExecution", evaluation.status === "executionBlocked", "");
  assertSelfCheck(results, "noRuntimeEvidence", evaluation.runtimeEvidenceGenerated === false, "");
  assertSelfCheck(results, "noCertification", !("productionCertified" in evaluation) && !("certificationDecision" in evaluation), "");
  assertSelfCheck(results, "noGameplay", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExternalConsumerManifestSelfChecks();
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
  const evaluation = evaluateExternalConsumerManifestAuthority({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
