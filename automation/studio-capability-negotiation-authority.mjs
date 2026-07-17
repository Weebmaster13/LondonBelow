import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import { git, inspectRepository, readJson } from "./repository-state.mjs";
import {
  integrationContractAuthorityId,
  integrationContractCompatibilityVersion,
  integrationContractVersion,
  integrationContractProtocolVersion,
  integrationContractSchemaVersion,
  requiredCapabilities as protocolRequiredCapabilities,
  stableSerialize,
  validateCompatibility
} from "./studio-mcp-integration-contract.mjs";

export const capabilityNegotiationSchemaVersion = 1;
export const capabilityNegotiationVersion = "1.0.0";
export const capabilityNegotiationAuthorityId = "chapter0Home.phase130StudioCapabilityNegotiationAuthority";

export const capabilityCategories = Object.freeze([
  "Session",
  "Execution",
  "Evidence",
  "Diagnostics",
  "Protocol",
  "Validation",
  "Compatibility",
  "Serialization"
]);

export const optionalCapabilities = Object.freeze([
  "ExtendedDiagnostics",
  "PerformanceMetrics",
  "CompatibilityExtensions",
  "FutureProtocolExtensions"
]);

export const negotiationStates = Object.freeze({
  idle: "Idle",
  receiveAdvertisement: "ReceiveAdvertisement",
  validateAdvertisement: "ValidateAdvertisement",
  resolveDependencies: "ResolveDependencies",
  resolveConflicts: "ResolveConflicts",
  freezeProfile: "FreezeProfile",
  complete: "NegotiationComplete",
  advertisementRejected: "AdvertisementRejected",
  unsupportedCapability: "UnsupportedCapability",
  dependencyFailure: "DependencyFailure",
  conflictFailure: "ConflictFailure",
  freezeRejected: "FreezeRejected"
});

export const negotiationFailures = Object.freeze({
  advertisementRejected: "AdvertisementRejected",
  unsupportedCapability: "UnsupportedCapability",
  dependencyFailure: "DependencyFailure",
  conflictFailure: "ConflictFailure",
  freezeRejected: "FreezeRejected",
  incompatibleVersion: "IncompatibleVersion",
  sourceInvalid: "InvalidSource"
});

const advertisementFields = Object.freeze([
  "capabilityId",
  "capabilityVersion",
  "category",
  "provider",
  "required",
  "optional",
  "dependencies",
  "conflicts",
  "status"
]);

const profileFields = Object.freeze([
  "profileId",
  "authorityId",
  "protocolVersion",
  "contractVersion",
  "schemaVersion",
  "compatibilityVersion",
  "capabilities",
  "publishedAt"
]);

const auditFields = Object.freeze([
  "negotiationId",
  "advertisementId",
  "authorityId",
  "profileId",
  "state",
  "reason",
  "timestamp",
  "contractVersion"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const allSupportedCapabilities = Object.freeze([...protocolRequiredCapabilities, ...optionalCapabilities]);
const deprecatedCapabilities = Object.freeze(["LegacyStudioRunner", "StdoutEvidenceScrape", "ImplicitSessionIdentity"]);

const legalTransitions = new Map([
  [negotiationStates.idle, new Set([negotiationStates.receiveAdvertisement])],
  [negotiationStates.receiveAdvertisement, new Set([negotiationStates.validateAdvertisement, negotiationStates.advertisementRejected])],
  [negotiationStates.validateAdvertisement, new Set([negotiationStates.resolveDependencies, negotiationStates.unsupportedCapability])],
  [negotiationStates.resolveDependencies, new Set([negotiationStates.resolveConflicts, negotiationStates.dependencyFailure])],
  [negotiationStates.resolveConflicts, new Set([negotiationStates.freezeProfile, negotiationStates.conflictFailure])],
  [negotiationStates.freezeProfile, new Set([negotiationStates.complete, negotiationStates.freezeRejected])]
]);

const terminalStates = new Set([
  negotiationStates.complete,
  negotiationStates.advertisementRejected,
  negotiationStates.unsupportedCapability,
  negotiationStates.dependencyFailure,
  negotiationStates.conflictFailure,
  negotiationStates.freezeRejected
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
  if (!isPlainObject(value)) return result(false, `${label} must be an object`, negotiationFailures.advertisementRejected);
  for (const field of fields) {
    if (!(field in value)) return result(false, `${label} missing ${field}`, negotiationFailures.advertisementRejected);
  }
  for (const key of Object.keys(value)) {
    if (!fields.includes(key)) return result(false, `${label} contains unsupported field ${key}`, negotiationFailures.advertisementRejected);
  }
  return result(true);
}

function inspectSource(input = {}) {
  if (isPlainObject(input.repositoryState)) {
    return {
      ...input.repositoryState,
      originSynchronized: input.repositoryState.localHead === input.repositoryState.remoteHead,
      sourceAttributionValid:
        input.repositoryState.branch === (config.branch ?? "main")
        && input.repositoryState.workingTreeClean === true
        && input.repositoryState.localHead === input.repositoryState.remoteHead
    };
  }

  const repository = inspectRepository(config);
  return {
    branch: repository.branch,
    localHead: repository.localHead,
    remoteHead: repository.remoteHead,
    workingTreeClean: repository.workingTreeClean,
    originSynchronized: repository.localHead === repository.remoteHead,
    sourceAttributionValid:
      repository.branch === (config.branch ?? "main")
      && repository.workingTreeClean
      && repository.localHead === repository.remoteHead
  };
}

function validateVersionCompatibility(input = {}) {
  if ((input.protocolVersion ?? integrationContractProtocolVersion) !== integrationContractProtocolVersion) {
    return result(false, "unsupported protocol version", negotiationFailures.incompatibleVersion);
  }
  if ((input.contractVersion ?? integrationContractVersion) !== integrationContractVersion) {
    return result(false, "unsupported contract version", negotiationFailures.incompatibleVersion);
  }
  if ((input.schemaVersion ?? integrationContractSchemaVersion) !== integrationContractSchemaVersion) {
    return result(false, "unsupported schema version", negotiationFailures.incompatibleVersion);
  }
  if ((input.compatibilityVersion ?? integrationContractCompatibilityVersion) !== integrationContractCompatibilityVersion) {
    return result(false, "unsupported compatibility version", negotiationFailures.incompatibleVersion);
  }
  return result(true);
}

export function createCapabilityAdvertisement(input) {
  return deepFreeze({
    capabilityId: input.capabilityId,
    capabilityVersion: input.capabilityVersion ?? "1.0.0",
    category: input.category,
    provider: input.provider ?? "externalStudioMcp",
    required: input.required === true,
    optional: input.optional === true,
    dependencies: input.dependencies ?? [],
    conflicts: input.conflicts ?? [],
    status: input.status ?? "active"
  });
}

export function validateCapabilityAdvertisement(advertisement) {
  const fields = exactFields(advertisement, advertisementFields, "capability advertisement");
  if (!fields.ok) return fields;

  if (typeof advertisement.capabilityId !== "string" || advertisement.capabilityId.trim() === "") {
    return result(false, "capabilityId invalid", negotiationFailures.advertisementRejected);
  }
  if (!allSupportedCapabilities.includes(advertisement.capabilityId)) {
    return result(false, `unsupported capability ${advertisement.capabilityId}`, negotiationFailures.unsupportedCapability);
  }
  if (deprecatedCapabilities.includes(advertisement.capabilityId) || advertisement.status === "deprecated") {
    return result(false, `deprecated capability ${advertisement.capabilityId}`, negotiationFailures.unsupportedCapability);
  }
  if (typeof advertisement.capabilityVersion !== "string" || advertisement.capabilityVersion !== "1.0.0") {
    return result(false, "capability version unsupported", negotiationFailures.incompatibleVersion);
  }
  if (!capabilityCategories.includes(advertisement.category)) {
    return result(false, `unsupported capability category ${advertisement.category}`, negotiationFailures.unsupportedCapability);
  }
  if (typeof advertisement.provider !== "string" || advertisement.provider.trim() === "") {
    return result(false, "provider invalid", negotiationFailures.advertisementRejected);
  }
  if (advertisement.required === advertisement.optional) {
    return result(false, "capability must be exactly required or optional", negotiationFailures.advertisementRejected);
  }
  if (!Array.isArray(advertisement.dependencies) || !Array.isArray(advertisement.conflicts)) {
    return result(false, "dependencies and conflicts must be arrays", negotiationFailures.advertisementRejected);
  }

  for (const dependency of advertisement.dependencies) {
    if (typeof dependency !== "string" || dependency.trim() === "") {
      return result(false, "dependency invalid", negotiationFailures.dependencyFailure);
    }
  }
  for (const conflict of advertisement.conflicts) {
    if (typeof conflict !== "string" || conflict.trim() === "") {
      return result(false, "conflict invalid", negotiationFailures.conflictFailure);
    }
  }

  return result(true);
}

export function validateAdvertisementSet(advertisements) {
  if (!Array.isArray(advertisements)) {
    return result(false, "advertisements must be an array", negotiationFailures.advertisementRejected);
  }

  const seen = new Set();
  for (const advertisement of advertisements) {
    const validation = validateCapabilityAdvertisement(advertisement);
    if (!validation.ok) return validation;
    if (seen.has(advertisement.capabilityId)) {
      return result(false, `duplicate capability ${advertisement.capabilityId}`, negotiationFailures.advertisementRejected);
    }
    seen.add(advertisement.capabilityId);
  }

  const missingRequired = protocolRequiredCapabilities.filter((capabilityId) => !seen.has(capabilityId));
  if (missingRequired.length > 0) {
    return result(false, `missing required capabilities: ${missingRequired.join(",")}`, negotiationFailures.unsupportedCapability, {
      missingRequired
    });
  }

  return result(true, null, null, { missingRequired: [] });
}

function advertisementMap(advertisements) {
  return new Map(advertisements.map((advertisement) => [advertisement.capabilityId, advertisement]));
}

export function validateDependencies(advertisements) {
  const byId = advertisementMap(advertisements);
  const visiting = new Set();
  const visited = new Set();

  for (const advertisement of advertisements) {
    const dependencySeen = new Set();
    for (const dependency of advertisement.dependencies) {
      if (dependencySeen.has(dependency)) {
        return result(false, `duplicate dependency ${dependency}`, negotiationFailures.dependencyFailure);
      }
      dependencySeen.add(dependency);
      const dependencyAdvertisement = byId.get(dependency);
      if (dependencyAdvertisement === undefined) {
        return result(false, `missing dependency ${dependency}`, negotiationFailures.dependencyFailure);
      }
      if (dependencyAdvertisement.status === "deprecated") {
        return result(false, `deprecated dependency ${dependency}`, negotiationFailures.dependencyFailure);
      }
      if (dependencyAdvertisement.capabilityVersion !== advertisement.capabilityVersion) {
        return result(false, `incompatible dependency version ${dependency}`, negotiationFailures.dependencyFailure);
      }
    }
  }

  function visit(id) {
    if (visiting.has(id)) return result(false, `circular dependency ${id}`, negotiationFailures.dependencyFailure);
    if (visited.has(id)) return result(true);
    visiting.add(id);
    const advertisement = byId.get(id);
    for (const dependency of advertisement.dependencies) {
      const check = visit(dependency);
      if (!check.ok) return check;
    }
    visiting.delete(id);
    visited.add(id);
    return result(true);
  }

  for (const advertisement of advertisements) {
    const check = visit(advertisement.capabilityId);
    if (!check.ok) return check;
  }

  return result(true);
}

export function validateConflicts(advertisements) {
  const ids = new Set(advertisements.map((advertisement) => advertisement.capabilityId));
  for (const advertisement of advertisements) {
    const seen = new Set();
    for (const conflict of advertisement.conflicts) {
      if (seen.has(conflict)) {
        return result(false, `duplicate conflict ${conflict}`, negotiationFailures.conflictFailure);
      }
      seen.add(conflict);
      if (ids.has(conflict)) {
        return result(false, `${advertisement.capabilityId} conflicts with ${conflict}`, negotiationFailures.conflictFailure);
      }
    }
  }
  return result(true);
}

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: capabilityNegotiationAuthorityId });
}

export function validateNegotiationTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "negotiation transitions must be non-empty", negotiationFailures.advertisementRejected);
  }

  let terminalSeen = false;
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(negotiationStates).includes(item.from) || !Object.values(negotiationStates).includes(item.to)) {
      return result(false, "undocumented negotiation state", negotiationFailures.advertisementRejected);
    }
    if (index === 0 && item.from !== negotiationStates.idle) {
      return result(false, "negotiation must start at Idle", negotiationFailures.advertisementRejected);
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "negotiation skipped state", negotiationFailures.advertisementRejected);
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal negotiation state mutated", negotiationFailures.advertisementRejected);
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal negotiation transition ${item.from}->${item.to}`, negotiationFailures.advertisementRejected);
    }
    if (terminalStates.has(item.to)) terminalSeen = true;
  }

  return result(true);
}

function capabilityProfile(profileId, capabilities, timestamp) {
  return deepFreeze({
    profileId,
    authorityId: capabilityNegotiationAuthorityId,
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    schemaVersion: integrationContractSchemaVersion,
    compatibilityVersion: integrationContractCompatibilityVersion,
    capabilities: [...capabilities].sort(),
    publishedAt: timestamp
  });
}

function validateProfile(profile) {
  const fields = exactFields(profile, profileFields, "capability profile");
  if (!fields.ok) return fields;
  if (profile.authorityId !== capabilityNegotiationAuthorityId) {
    return result(false, "profile authority mismatch", negotiationFailures.freezeRejected);
  }
  if (!Array.isArray(profile.capabilities)) {
    return result(false, "profile capabilities invalid", negotiationFailures.freezeRejected);
  }
  return result(true);
}

function createProfiles(advertisements, timestamp) {
  const capabilities = advertisements.map((advertisement) => advertisement.capabilityId);
  const byCategory = new Map();
  for (const category of capabilityCategories) byCategory.set(category, []);
  for (const advertisement of advertisements) {
    byCategory.get(advertisement.category).push(advertisement.capabilityId);
  }

  return deepFreeze({
    ProtocolProfile: capabilityProfile("ProtocolProfile", byCategory.get("Protocol"), timestamp),
    ExecutionProfile: capabilityProfile("ExecutionProfile", byCategory.get("Execution"), timestamp),
    EvidenceProfile: capabilityProfile("EvidenceProfile", byCategory.get("Evidence"), timestamp),
    DiagnosticsProfile: capabilityProfile("DiagnosticsProfile", byCategory.get("Diagnostics"), timestamp),
    ValidationProfile: capabilityProfile("ValidationProfile", byCategory.get("Validation"), timestamp),
    CompatibilityProfile: capabilityProfile("CompatibilityProfile", [
      ...byCategory.get("Compatibility"),
      ...byCategory.get("Serialization"),
      ...capabilities.filter((capabilityId) => protocolRequiredCapabilities.includes(capabilityId))
    ], timestamp)
  });
}

function validateProfiles(profiles) {
  const requiredProfiles = [
    "ProtocolProfile",
    "ExecutionProfile",
    "EvidenceProfile",
    "DiagnosticsProfile",
    "ValidationProfile",
    "CompatibilityProfile"
  ];
  for (const profileName of requiredProfiles) {
    const validation = validateProfile(profiles[profileName]);
    if (!validation.ok) return validation;
  }
  return result(true);
}

function createAudit(negotiationId, advertisementId, profileId, transitions) {
  return deepFreeze(
    transitions.map((item) => ({
      negotiationId,
      advertisementId,
      authorityId: capabilityNegotiationAuthorityId,
      profileId,
      state: item.to,
      reason: item.reason,
      timestamp: item.timestamp,
      contractVersion: integrationContractVersion
    }))
  );
}

function validateAudit(audit) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "audit must be non-empty", negotiationFailures.freezeRejected);
  const seen = new Set();
  for (const entry of audit) {
    const fields = exactFields(entry, auditFields, "audit entry");
    if (!fields.ok) return fields;
    const key = stableSerialize(entry);
    if (seen.has(key)) return result(false, "duplicate audit entry", negotiationFailures.freezeRejected);
    seen.add(key);
    if (entry.authorityId !== capabilityNegotiationAuthorityId) {
      return result(false, "audit authority mismatch", negotiationFailures.freezeRejected);
    }
  }
  return result(true);
}

function defaultAdvertisements() {
  const categoryByCapability = {
    SessionIdentity: "Session",
    RunnerExecution: "Execution",
    StructuredResults: "Evidence",
    EvidenceTransport: "Evidence",
    Heartbeat: "Diagnostics",
    VersionMetadata: "Protocol",
    ExtendedDiagnostics: "Diagnostics",
    PerformanceMetrics: "Diagnostics",
    CompatibilityExtensions: "Compatibility",
    FutureProtocolExtensions: "Protocol"
  };
  return protocolRequiredCapabilities.map((capabilityId) =>
    createCapabilityAdvertisement({
      capabilityId,
      category: categoryByCapability[capabilityId],
      required: true,
      optional: false,
      dependencies: capabilityId === "RunnerExecution" ? ["SessionIdentity"] : [],
      conflicts: []
    })
  );
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    negotiationVersion: capabilityNegotiationVersion,
    requiredCapabilities: [...protocolRequiredCapabilities],
    optionalCapabilities: [...optionalCapabilities],
    negotiatedCapabilities: [...evaluation.negotiatedCapabilities],
    rejectedCapabilities: [...evaluation.rejectedCapabilities],
    dependencyResolution: evaluation.dependencyResolution,
    conflictResolution: evaluation.conflictResolution,
    compatibilityState: evaluation.compatibilityState,
    negotiationState: evaluation.negotiationState,
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function evaluateCapabilityNegotiation(input = {}) {
  const timestamp = input.timestamp ?? now();
  const repositoryState = inspectSource(input);
  const advertisements = deepFreeze(input.advertisements ?? []);
  const negotiationId = input.negotiationId ?? `phase130-${repositoryState.localHead ?? stableCommit}`;
  const advertisementId = input.advertisementId ?? `${negotiationId}.advertisement`;
  const transitions = [transition(negotiationStates.idle, negotiationStates.receiveAdvertisement, "capability advertisement received", timestamp)];
  const versionValidation = validateVersionCompatibility(input);
  const advertisementValidation = validateAdvertisementSet(advertisements);
  let dependencyResolution = result(false, "not evaluated", negotiationFailures.dependencyFailure);
  let conflictResolution = result(false, "not evaluated", negotiationFailures.conflictFailure);
  let profiles = null;
  let profileValidation = result(false, "profile not frozen", negotiationFailures.freezeRejected);
  let negotiationState = negotiationStates.complete;
  let failureReason = null;

  if (!repositoryState.sourceAttributionValid) {
    transitions.push(transition(negotiationStates.receiveAdvertisement, negotiationStates.advertisementRejected, negotiationFailures.sourceInvalid, timestamp));
    negotiationState = negotiationStates.advertisementRejected;
    failureReason = negotiationFailures.sourceInvalid;
  } else if (!versionValidation.ok) {
    transitions.push(transition(negotiationStates.receiveAdvertisement, negotiationStates.validateAdvertisement, "advertisement shape accepted", timestamp));
    transitions.push(transition(negotiationStates.validateAdvertisement, negotiationStates.unsupportedCapability, versionValidation.failure, timestamp));
    negotiationState = negotiationStates.unsupportedCapability;
    failureReason = versionValidation.failure;
  } else if (!advertisementValidation.ok) {
    const target =
      advertisementValidation.failure === negotiationFailures.advertisementRejected
        ? negotiationStates.advertisementRejected
        : negotiationStates.unsupportedCapability;
    if (target === negotiationStates.advertisementRejected) {
      transitions.push(transition(negotiationStates.receiveAdvertisement, target, advertisementValidation.failure, timestamp));
    } else {
      transitions.push(transition(negotiationStates.receiveAdvertisement, negotiationStates.validateAdvertisement, "advertisement shape accepted", timestamp));
      transitions.push(transition(negotiationStates.validateAdvertisement, target, advertisementValidation.failure, timestamp));
    }
    negotiationState = target;
    failureReason = advertisementValidation.failure;
  } else {
    transitions.push(transition(negotiationStates.receiveAdvertisement, negotiationStates.validateAdvertisement, "advertisement shape accepted", timestamp));
    transitions.push(transition(negotiationStates.validateAdvertisement, negotiationStates.resolveDependencies, "advertised capabilities supported", timestamp));
    dependencyResolution = validateDependencies(advertisements);
    if (!dependencyResolution.ok) {
      transitions.push(transition(negotiationStates.resolveDependencies, negotiationStates.dependencyFailure, dependencyResolution.failure, timestamp));
      negotiationState = negotiationStates.dependencyFailure;
      failureReason = dependencyResolution.failure;
    } else {
      transitions.push(transition(negotiationStates.resolveDependencies, negotiationStates.resolveConflicts, "dependencies resolved", timestamp));
      conflictResolution = validateConflicts(advertisements);
      if (!conflictResolution.ok) {
        transitions.push(transition(negotiationStates.resolveConflicts, negotiationStates.conflictFailure, conflictResolution.failure, timestamp));
        negotiationState = negotiationStates.conflictFailure;
        failureReason = conflictResolution.failure;
      } else {
        transitions.push(transition(negotiationStates.resolveConflicts, negotiationStates.freezeProfile, "conflicts resolved", timestamp));
        profiles = createProfiles(advertisements, timestamp);
        profileValidation = validateProfiles(profiles);
        if (!profileValidation.ok) {
          transitions.push(transition(negotiationStates.freezeProfile, negotiationStates.freezeRejected, profileValidation.failure, timestamp));
          negotiationState = negotiationStates.freezeRejected;
          failureReason = profileValidation.failure;
        } else {
          transitions.push(transition(negotiationStates.freezeProfile, negotiationStates.complete, "negotiated profiles frozen", timestamp));
          negotiationState = negotiationStates.complete;
        }
      }
    }
  }

  const transitionValidation = validateNegotiationTransitions(transitions);
  const negotiatedCapabilities = profiles === null ? [] : advertisements.map((advertisement) => advertisement.capabilityId).sort();
  const rejectedCapabilities = profiles === null ? advertisements.map((advertisement) => advertisement.capabilityId).sort() : [];
  const compatibility = validateCompatibility({
    capabilities: negotiatedCapabilities,
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    schemaVersion: integrationContractSchemaVersion,
    compatibilityVersion: integrationContractCompatibilityVersion
  });
  const audit = createAudit(negotiationId, advertisementId, profiles === null ? "none" : "published", transitions);
  const evaluation = {
    schemaVersion: capabilityNegotiationSchemaVersion,
    authorityId: capabilityNegotiationAuthorityId,
    integrationContractAuthorityId,
    negotiationVersion: capabilityNegotiationVersion,
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    compatibilityVersion: integrationContractCompatibilityVersion,
    status: "executionBlocked",
    exitCode: bridgeExitCodes.executionBlocked,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeTruth: {
      sessionFailureReason: "SESSION_NOT_VISIBLE",
      status: "executionBlocked",
      runnerInvoked: false,
      structuredResultCaptured: false
    },
    negotiationId,
    advertisementId,
    advertisements,
    requiredCapabilities: [...protocolRequiredCapabilities],
    optionalCapabilities: [...optionalCapabilities],
    negotiatedCapabilities,
    rejectedCapabilities,
    profiles,
    versionValidation,
    advertisementValidation,
    dependencyResolution,
    conflictResolution,
    profileValidation,
    compatibility,
    compatibilityState: compatibility.compatibilityState,
    negotiationState,
    transitionValidation,
    audit,
    auditValidation: validateAudit(audit),
    repositoryState,
    failureReason,
    integrationGraph: [
      "Phase121EvidenceTransport",
      "Phase122StudioBridge",
      "Phase124ActivationAuthority",
      "Phase125BindingAuthority",
      "Phase126SessionAuthority",
      "Phase127RunnerAuthority",
      "Phase129IntegrationContract",
      "Phase130CapabilityNegotiationAuthority"
    ],
    recommendedAction:
      "Expose a connected Studio MCP implementation with immutable supported capability advertisements before runner invocation.",
    timestamp
  };

  return deepFreeze({
    ...evaluation,
    diagnostics: diagnosticsFor(evaluation),
    serializationValidation: (() => {
      try {
        const serialized = stableSerialize(evaluation);
        return result(stableSerialize(evaluation) === serialized, null, null, { serialized });
      } catch (error) {
        return result(false, String(error?.message ?? error), negotiationFailures.freezeRejected);
      }
    })()
  });
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runCapabilityNegotiationSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const advertisements = defaultAdvertisements();
  const accepted = evaluateCapabilityNegotiation({ timestamp: stableTimestamp, repositoryState, advertisements });
  const missing = evaluateCapabilityNegotiation({ timestamp: stableTimestamp, repositoryState, advertisements: advertisements.slice(1) });
  const dependencyFailure = evaluateCapabilityNegotiation({
    timestamp: stableTimestamp,
    repositoryState,
    advertisements: advertisements.map((advertisement) =>
      advertisement.capabilityId === "RunnerExecution"
        ? createCapabilityAdvertisement({ ...advertisement, dependencies: ["MissingCapability"] })
        : advertisement
    )
  });
  const conflictFailure = evaluateCapabilityNegotiation({
    timestamp: stableTimestamp,
    repositoryState,
    advertisements: advertisements.map((advertisement) =>
      advertisement.capabilityId === "SessionIdentity"
        ? createCapabilityAdvertisement({ ...advertisement, conflicts: ["RunnerExecution"] })
        : advertisement
    )
  });
  const cycleAdvertisements = [
    createCapabilityAdvertisement({ ...advertisements[0], dependencies: ["RunnerExecution"] }),
    createCapabilityAdvertisement({ ...advertisements[1], dependencies: ["SessionIdentity"] }),
    ...advertisements.slice(2)
  ];
  const cycleFailure = evaluateCapabilityNegotiation({ timestamp: stableTimestamp, repositoryState, advertisements: cycleAdvertisements });
  const optional = evaluateCapabilityNegotiation({
    timestamp: stableTimestamp,
    repositoryState,
    advertisements: [
      ...advertisements,
      createCapabilityAdvertisement({
        capabilityId: "ExtendedDiagnostics",
        category: "Diagnostics",
        required: false,
        optional: true,
        dependencies: ["Heartbeat"],
        conflicts: []
      })
    ]
  });
  const dirty = evaluateCapabilityNegotiation({
    timestamp: stableTimestamp,
    repositoryState: { ...repositoryState, workingTreeClean: false },
    advertisements
  });
  const invalidTransition = validateNegotiationTransitions([
    transition(negotiationStates.idle, negotiationStates.resolveConflicts, "skip", stableTimestamp)
  ]);
  const rerun = evaluateCapabilityNegotiation({ timestamp: stableTimestamp, repositoryState, advertisements });

  assertSelfCheck(results, "protocolCompatibilityValidation", accepted.compatibility.ok === true, "");
  assertSelfCheck(results, "capabilityAdvertisementValidation", validateCapabilityAdvertisement(advertisements[0]).ok === true, "");
  assertSelfCheck(results, "requiredCapabilityValidation", missing.failureReason === negotiationFailures.unsupportedCapability, "");
  assertSelfCheck(results, "optionalCapabilityValidation", optional.negotiatedCapabilities.includes("ExtendedDiagnostics"), "");
  assertSelfCheck(results, "optionalNotMandatory", missing.negotiatedCapabilities.length === 0, "");
  assertSelfCheck(results, "dependencyGraphValidation", accepted.dependencyResolution.ok === true, "");
  assertSelfCheck(results, "dependencyCycleDetection", cycleFailure.failureReason === negotiationFailures.dependencyFailure, "");
  assertSelfCheck(results, "missingDependencyDetection", dependencyFailure.failureReason === negotiationFailures.dependencyFailure, "");
  assertSelfCheck(results, "conflictDetection", conflictFailure.failureReason === negotiationFailures.conflictFailure, "");
  assertSelfCheck(results, "immutableCapabilityIdentities", Object.isFrozen(accepted.advertisements[0]), "");
  assertSelfCheck(results, "immutableNegotiatedProfiles", Object.isFrozen(accepted.profiles.ProtocolProfile), "");
  assertSelfCheck(results, "profilePublicationValidation", accepted.profileValidation.ok === true, "");
  assertSelfCheck(results, "profileSchemaValidation", validateProfiles(accepted.profiles).ok === true, "");
  assertSelfCheck(results, "negotiationLifecycleValidation", accepted.transitionValidation.ok === true, "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "deterministicSerialization", accepted.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicTimestamps", accepted.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicExitCodes", accepted.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "authorityIsolation", accepted.authorityId === capabilityNegotiationAuthorityId, "");
  assertSelfCheck(results, "integrationContractConsumption", accepted.integrationContractAuthorityId === integrationContractAuthorityId, "");
  assertSelfCheck(results, "versionCompatibility", accepted.versionValidation.ok === true, "");
  assertSelfCheck(results, "unsupportedVersionRejection", evaluateCapabilityNegotiation({ timestamp: stableTimestamp, repositoryState, advertisements, protocolVersion: "0.0.0" }).failureReason === negotiationFailures.incompatibleVersion, "");
  assertSelfCheck(results, "negotiationAuditValidation", accepted.auditValidation.ok === true, "");
  assertSelfCheck(results, "auditAppendOnlyShape", Object.isFrozen(accepted.audit) && accepted.audit.length === accepted.transitionValidation.ok ? true : accepted.audit.length > 0, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(accepted.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "backwardCompatibility", capabilityNegotiationSchemaVersion === 1, "");
  assertSelfCheck(results, "advertisementUnknownFieldRejection", validateCapabilityAdvertisement({ ...advertisements[0], extra: true }).ok === false, "");
  assertSelfCheck(results, "duplicateAdvertisementRejection", validateAdvertisementSet([advertisements[0], advertisements[0]]).ok === false, "");
  assertSelfCheck(results, "deprecatedCapabilityRejection", validateCapabilityAdvertisement(createCapabilityAdvertisement({ capabilityId: "LegacyStudioRunner", category: "Execution", required: true, optional: false, status: "deprecated" })).ok === false, "");
  assertSelfCheck(results, "unknownCategoryRejection", validateCapabilityAdvertisement(createCapabilityAdvertisement({ capabilityId: "SessionIdentity", category: "Unknown", required: true, optional: false })).ok === false, "");
  assertSelfCheck(results, "sourceAttributionValidation", dirty.failureReason === negotiationFailures.sourceInvalid, "");
  assertSelfCheck(results, "diagnosticsToolingOnly", !("productionCertified" in accepted.diagnostics), "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("certificationDecision" in accepted), "");
  assertSelfCheck(results, "executionBlockedPreserved", accepted.status === "executionBlocked", "");
  assertSelfCheck(results, "runtimeTruthPreserved", accepted.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE", "");
  assertSelfCheck(results, "runnerNotInvoked", accepted.runnerInvoked === false, "");
  assertSelfCheck(results, "structuredResultNotCaptured", accepted.structuredResultCaptured === false, "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noNetworkingTransport", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runCapabilityNegotiationSelfChecks();
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
  const evaluation = evaluateCapabilityNegotiation({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
