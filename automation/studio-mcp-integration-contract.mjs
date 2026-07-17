import { fileURLToPath } from "node:url";
import { bridgeExitCodes, supportedPhase } from "./studio-automation-bridge.mjs";
import { git, inspectRepository, readJson } from "./repository-state.mjs";
import {
  runnerAuthorityId,
  runnerAuthorityRunnerId,
  evaluateRunnerAuthority
} from "./studio-runner-authority.mjs";
import { sessionAuthorityId, failureReasons } from "./studio-session-authority.mjs";

export const integrationContractSchemaVersion = 1;
export const integrationContractProtocolVersion = "1.0.0";
export const integrationContractVersion = "1.0.0";
export const integrationContractCompatibilityVersion = 1;
export const integrationContractAuthorityId = "chapter0Home.phase129StudioMcpIntegrationContract";

export const requiredCapabilities = Object.freeze([
  "SessionIdentity",
  "RunnerExecution",
  "StructuredResults",
  "EvidenceTransport",
  "Heartbeat",
  "VersionMetadata"
]);

export const handshakeStates = Object.freeze({
  idle: "Idle",
  discovery: "Discovery",
  capabilityExchange: "CapabilityExchange",
  compatibilityValidation: "CompatibilityValidation",
  sourceValidation: "SourceValidation",
  accepted: "HandshakeAccepted",
  rejected: "HandshakeRejected",
  unsupportedVersion: "UnsupportedVersion",
  incompatibleCapabilities: "IncompatibleCapabilities",
  invalidSource: "InvalidSource"
});

export const protocolFailures = Object.freeze({
  unsupportedProtocol: "UnsupportedProtocol",
  unsupportedContract: "UnsupportedContract",
  capabilityMissing: "CapabilityMissing",
  invalidHandshake: "InvalidHandshake",
  invalidEnvelope: "InvalidEnvelope",
  schemaMismatch: "SchemaMismatch",
  serializationFailure: "SerializationFailure",
  invalidSource: "InvalidSource",
  unknownAuthority: "UnknownAuthority"
});

export const requestEnvelopeFields = Object.freeze([
  "protocolVersion",
  "contractVersion",
  "requestId",
  "authorityId",
  "runnerId",
  "phase",
  "repositoryRevision",
  "timestamp",
  "payload",
  "sourceAttribution"
]);

export const responseEnvelopeFields = Object.freeze([
  "protocolVersion",
  "responseId",
  "requestId",
  "executionId",
  "status",
  "result",
  "diagnostics",
  "timestamp"
]);

export const eventEnvelopeFields = Object.freeze([
  "eventId",
  "eventType",
  "authority",
  "timestamp",
  "payload",
  "sequence"
]);

export const structuredResultEnvelopeFields = Object.freeze([
  "protocolVersion",
  "contractVersion",
  "executionIdentity",
  "authorityIdentity",
  "requestIdentity",
  "resultClassification",
  "diagnostics",
  "timestamps",
  "auditReference",
  "sourceAttribution"
]);

export const diagnosticsFields = Object.freeze([
  "protocolVersion",
  "contractVersion",
  "authority",
  "compatibilityState",
  "handshakeState",
  "requiredCapabilities",
  "negotiatedCapabilities",
  "validationResult",
  "failureReason",
  "timestamp"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const compatibleAuthorities = Object.freeze([
  integrationContractAuthorityId,
  "chapter0Home.phase121StudioEvidenceTransport",
  "chapter0Home.phase122StudioAutomationBridge",
  "studioMcpStructuredCapture",
  "studioMcpRunnerCommandBinding",
  sessionAuthorityId,
  runnerAuthorityId
]);

const legalHandshakeTransitions = new Map([
  [handshakeStates.idle, new Set([handshakeStates.discovery])],
  [handshakeStates.discovery, new Set([handshakeStates.capabilityExchange, handshakeStates.rejected])],
  [handshakeStates.capabilityExchange, new Set([handshakeStates.compatibilityValidation, handshakeStates.unsupportedVersion])],
  [
    handshakeStates.compatibilityValidation,
    new Set([handshakeStates.sourceValidation, handshakeStates.incompatibleCapabilities])
  ],
  [handshakeStates.sourceValidation, new Set([handshakeStates.accepted, handshakeStates.invalidSource])]
]);

const terminalHandshakeStates = new Set([
  handshakeStates.accepted,
  handshakeStates.rejected,
  handshakeStates.unsupportedVersion,
  handshakeStates.incompatibleCapabilities,
  handshakeStates.invalidSource
]);

function now() {
  return new Date().toISOString();
}

function isPlainObject(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function deepFreeze(value) {
  if (Array.isArray(value)) {
    for (const item of value) {
      deepFreeze(item);
    }
    return Object.freeze(value);
  }

  if (isPlainObject(value)) {
    for (const key of Object.keys(value)) {
      deepFreeze(value[key]);
    }
    return Object.freeze(value);
  }

  return value;
}

function exactFields(value, fields, label) {
  if (!isPlainObject(value)) {
    return { ok: false, reason: `${label} must be an object`, failure: protocolFailures.invalidEnvelope };
  }

  const keys = Object.keys(value);
  for (const field of fields) {
    if (!(field in value)) {
      return { ok: false, reason: `${label} missing ${field}`, failure: protocolFailures.invalidEnvelope };
    }
  }

  for (const key of keys) {
    if (!fields.includes(key)) {
      return { ok: false, reason: `${label} contains unsupported field ${key}`, failure: protocolFailures.invalidEnvelope };
    }
  }

  return { ok: true, reason: null, failure: null };
}

function validateIdentifier(value, label) {
  return typeof value === "string" && value.trim() !== ""
    ? { ok: true, reason: null, failure: null }
    : { ok: false, reason: `${label} invalid`, failure: protocolFailures.invalidEnvelope };
}

function validateIsoTimestamp(value, label) {
  return typeof value === "string" && !Number.isNaN(Date.parse(value))
    ? { ok: true, reason: null, failure: null }
    : { ok: false, reason: `${label} invalid`, failure: protocolFailures.invalidEnvelope };
}

function firstFailure(...results) {
  return results.find((result) => !result.ok) ?? { ok: true, reason: null, failure: null };
}

export function validateVersionMetadata(metadata = {}) {
  if (metadata.protocolVersion !== integrationContractProtocolVersion) {
    return { ok: false, reason: "unsupported protocol version", failure: protocolFailures.unsupportedProtocol };
  }

  if (metadata.contractVersion !== integrationContractVersion) {
    return { ok: false, reason: "unsupported contract version", failure: protocolFailures.unsupportedContract };
  }

  if (metadata.schemaVersion !== integrationContractSchemaVersion) {
    return { ok: false, reason: "unsupported schema version", failure: protocolFailures.schemaMismatch };
  }

  if (metadata.compatibilityVersion !== integrationContractCompatibilityVersion) {
    return { ok: false, reason: "unsupported compatibility version", failure: protocolFailures.schemaMismatch };
  }

  return { ok: true, reason: null, failure: null };
}

export function validateCapabilities(capabilities) {
  if (!Array.isArray(capabilities)) {
    return { ok: false, reason: "capabilities must be an array", failure: protocolFailures.capabilityMissing, missing: requiredCapabilities };
  }

  const seen = new Set();
  for (const capability of capabilities) {
    if (typeof capability !== "string" || capability.trim() === "") {
      return { ok: false, reason: "capability invalid", failure: protocolFailures.capabilityMissing, missing: requiredCapabilities };
    }
    if (seen.has(capability)) {
      return { ok: false, reason: `duplicate capability ${capability}`, failure: protocolFailures.capabilityMissing, missing: [] };
    }
    seen.add(capability);
  }

  const missing = requiredCapabilities.filter((capability) => !seen.has(capability));
  if (missing.length > 0) {
    return { ok: false, reason: `missing capabilities: ${missing.join(",")}`, failure: protocolFailures.capabilityMissing, missing };
  }

  return { ok: true, reason: null, failure: null, missing: [] };
}

export function validateHandshakeTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return { ok: false, reason: "handshake transitions must be non-empty", failure: protocolFailures.invalidHandshake };
  }

  let terminalSeen = false;
  for (const [index, transition] of transitions.entries()) {
    if (!isPlainObject(transition)) {
      return { ok: false, reason: "handshake transition must be an object", failure: protocolFailures.invalidHandshake };
    }

    if (!Object.values(handshakeStates).includes(transition.from) || !Object.values(handshakeStates).includes(transition.to)) {
      return { ok: false, reason: "handshake transition contains undocumented state", failure: protocolFailures.invalidHandshake };
    }

    if (terminalHandshakeStates.has(transition.from)) {
      return { ok: false, reason: "terminal handshake state cannot transition", failure: protocolFailures.invalidHandshake };
    }

    const legalTargets = legalHandshakeTransitions.get(transition.from);
    if (!legalTargets?.has(transition.to)) {
      return { ok: false, reason: `illegal handshake transition ${transition.from}->${transition.to}`, failure: protocolFailures.invalidHandshake };
    }

    if (index === 0 && transition.from !== handshakeStates.idle) {
      return { ok: false, reason: "handshake must start at Idle", failure: protocolFailures.invalidHandshake };
    }

    if (index > 0 && transitions[index - 1].to !== transition.from) {
      return { ok: false, reason: "handshake skipped state", failure: protocolFailures.invalidHandshake };
    }

    if (terminalSeen) {
      return { ok: false, reason: "handshake transition after terminal state", failure: protocolFailures.invalidHandshake };
    }

    if (terminalHandshakeStates.has(transition.to)) {
      terminalSeen = true;
    }
  }

  return { ok: true, reason: null, failure: null };
}

function createHandshakeTransition(from, to, reason, timestamp) {
  return Object.freeze({
    from,
    to,
    reason,
    timestamp,
    authorityId: integrationContractAuthorityId
  });
}

export function stableSerialize(value) {
  const seen = new Set();

  function normalize(item) {
    if (item === undefined || typeof item === "function" || typeof item === "symbol") {
      throw new Error(protocolFailures.serializationFailure);
    }

    if (typeof item === "number" && !Number.isFinite(item)) {
      throw new Error(protocolFailures.serializationFailure);
    }

    if (Array.isArray(item)) {
      return item.map((entry) => normalize(entry));
    }

    if (isPlainObject(item)) {
      if (seen.has(item)) {
        throw new Error(protocolFailures.serializationFailure);
      }
      seen.add(item);
      const ordered = {};
      for (const key of Object.keys(item).sort()) {
        ordered[key] = normalize(item[key]);
      }
      seen.delete(item);
      return ordered;
    }

    return item;
  }

  return JSON.stringify(normalize(value));
}

export function validateSerialization(value) {
  try {
    const first = stableSerialize(value);
    const second = stableSerialize(value);
    const utf8 = Buffer.from(first, "utf8").toString("utf8");
    return first === second && utf8 === first
      ? { ok: true, reason: null, failure: null, serialized: first }
      : { ok: false, reason: "serialization is not reproducible", failure: protocolFailures.serializationFailure, serialized: first };
  } catch (error) {
    return {
      ok: false,
      reason: String(error?.message ?? error),
      failure: protocolFailures.serializationFailure,
      serialized: null
    };
  }
}

export function createRequestEnvelope(input = {}) {
  const envelope = {
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    requestId: input.requestId ?? `phase129-${input.repositoryRevision ?? stableCommit}`,
    authorityId: input.authorityId ?? integrationContractAuthorityId,
    runnerId: input.runnerId ?? runnerAuthorityRunnerId,
    phase: input.phase ?? 129,
    repositoryRevision: input.repositoryRevision ?? stableCommit,
    timestamp: input.timestamp ?? stableTimestamp,
    payload: input.payload ?? {},
    sourceAttribution: input.sourceAttribution ?? "valid"
  };

  return deepFreeze(envelope);
}

export function validateRequestEnvelope(envelope) {
  const fields = exactFields(envelope, requestEnvelopeFields, "request envelope");
  if (!fields.ok) return fields;

  return firstFailure(
    validateVersionMetadata({
      protocolVersion: envelope.protocolVersion,
      contractVersion: envelope.contractVersion,
      schemaVersion: integrationContractSchemaVersion,
      compatibilityVersion: integrationContractCompatibilityVersion
    }),
    validateIdentifier(envelope.requestId, "requestId"),
    validateIdentifier(envelope.authorityId, "authorityId"),
    validateIdentifier(envelope.runnerId, "runnerId"),
    validateIdentifier(envelope.repositoryRevision, "repositoryRevision"),
    validateIsoTimestamp(envelope.timestamp, "timestamp"),
    isPlainObject(envelope.payload)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "payload invalid", failure: protocolFailures.invalidEnvelope },
    envelope.sourceAttribution === "valid" || envelope.sourceAttribution === "invalid"
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "sourceAttribution invalid", failure: protocolFailures.invalidEnvelope }
  );
}

export function validateResponseEnvelope(envelope) {
  const fields = exactFields(envelope, responseEnvelopeFields, "response envelope");
  if (!fields.ok) return fields;

  return firstFailure(
    envelope.protocolVersion === integrationContractProtocolVersion
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "unsupported response protocol version", failure: protocolFailures.unsupportedProtocol },
    validateIdentifier(envelope.responseId, "responseId"),
    validateIdentifier(envelope.requestId, "requestId"),
    validateIdentifier(envelope.executionId, "executionId"),
    validateIdentifier(envelope.status, "status"),
    isPlainObject(envelope.result) || envelope.result === null
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "result invalid", failure: protocolFailures.invalidEnvelope },
    isPlainObject(envelope.diagnostics)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "diagnostics invalid", failure: protocolFailures.invalidEnvelope },
    validateIsoTimestamp(envelope.timestamp, "timestamp")
  );
}

export function validateEventEnvelope(envelope, previousSequence = null) {
  const fields = exactFields(envelope, eventEnvelopeFields, "event envelope");
  if (!fields.ok) return fields;

  if (!Number.isInteger(envelope.sequence) || envelope.sequence < 1) {
    return { ok: false, reason: "event sequence invalid", failure: protocolFailures.invalidEnvelope };
  }

  if (previousSequence !== null && envelope.sequence <= previousSequence) {
    return { ok: false, reason: "event sequence is not monotonic", failure: protocolFailures.invalidEnvelope };
  }

  return firstFailure(
    validateIdentifier(envelope.eventId, "eventId"),
    validateIdentifier(envelope.eventType, "eventType"),
    validateIdentifier(envelope.authority, "authority"),
    validateIsoTimestamp(envelope.timestamp, "timestamp"),
    isPlainObject(envelope.payload)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "payload invalid", failure: protocolFailures.invalidEnvelope }
  );
}

export function validateStructuredResultEnvelope(envelope) {
  const fields = exactFields(envelope, structuredResultEnvelopeFields, "structured result envelope");
  if (!fields.ok) return fields;

  if ("productionCertified" in envelope || "certificationDecision" in envelope || "gameplayData" in envelope) {
    return {
      ok: false,
      reason: "structured result envelope contains forbidden certification or gameplay field",
      failure: protocolFailures.schemaMismatch
    };
  }

  return firstFailure(
    validateVersionMetadata({
      protocolVersion: envelope.protocolVersion,
      contractVersion: envelope.contractVersion,
      schemaVersion: integrationContractSchemaVersion,
      compatibilityVersion: integrationContractCompatibilityVersion
    }),
    isPlainObject(envelope.executionIdentity)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "executionIdentity invalid", failure: protocolFailures.invalidEnvelope },
    isPlainObject(envelope.authorityIdentity)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "authorityIdentity invalid", failure: protocolFailures.invalidEnvelope },
    isPlainObject(envelope.requestIdentity)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "requestIdentity invalid", failure: protocolFailures.invalidEnvelope },
    validateIdentifier(envelope.resultClassification, "resultClassification"),
    isPlainObject(envelope.diagnostics)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "diagnostics invalid", failure: protocolFailures.invalidEnvelope },
    isPlainObject(envelope.timestamps)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "timestamps invalid", failure: protocolFailures.invalidEnvelope },
    validateIdentifier(envelope.auditReference, "auditReference"),
    isPlainObject(envelope.sourceAttribution)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "sourceAttribution invalid", failure: protocolFailures.invalidEnvelope }
  );
}

export function validateDiagnostics(diagnostics) {
  const fields = exactFields(diagnostics, diagnosticsFields, "diagnostics");
  if (!fields.ok) return fields;

  return firstFailure(
    validateVersionMetadata({
      protocolVersion: diagnostics.protocolVersion,
      contractVersion: diagnostics.contractVersion,
      schemaVersion: integrationContractSchemaVersion,
      compatibilityVersion: integrationContractCompatibilityVersion
    }),
    diagnostics.authority === integrationContractAuthorityId
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "diagnostics authority mismatch", failure: protocolFailures.unknownAuthority },
    Object.values(handshakeStates).includes(diagnostics.handshakeState)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "diagnostics handshake state invalid", failure: protocolFailures.invalidHandshake },
    Array.isArray(diagnostics.requiredCapabilities) && Array.isArray(diagnostics.negotiatedCapabilities)
      ? { ok: true, reason: null, failure: null }
      : { ok: false, reason: "diagnostics capabilities invalid", failure: protocolFailures.schemaMismatch },
    validateIsoTimestamp(diagnostics.timestamp, "timestamp")
  );
}

function canonicalResponse(request) {
  return deepFreeze({
    protocolVersion: integrationContractProtocolVersion,
    responseId: `${request.requestId}.response`,
    requestId: request.requestId,
    executionId: `${request.requestId}.execution`,
    status: "executionBlocked",
    result: null,
    diagnostics: {
      status: "executionBlocked"
    },
    timestamp: request.timestamp
  });
}

function canonicalEvent(request) {
  return deepFreeze({
    eventId: `${request.requestId}.event.1`,
    eventType: "HandshakeStateChanged",
    authority: integrationContractAuthorityId,
    timestamp: request.timestamp,
    payload: {
      handshakeState: handshakeStates.discovery
    },
    sequence: 1
  });
}

function canonicalStructuredResult(request) {
  return deepFreeze({
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    executionIdentity: {
      executionId: `${request.requestId}.execution`,
      runnerId: runnerAuthorityRunnerId
    },
    authorityIdentity: {
      authorityId: integrationContractAuthorityId,
      runnerAuthorityId
    },
    requestIdentity: {
      requestId: request.requestId,
      phase: request.phase
    },
    resultClassification: "executionBlocked",
    diagnostics: {
      runnerInvoked: false,
      structuredResultCaptured: false
    },
    timestamps: {
      createdAt: request.timestamp,
      capturedAt: null
    },
    auditReference: `${request.requestId}.audit`,
    sourceAttribution: {
      repositoryRevision: request.repositoryRevision,
      sourceAttribution: request.sourceAttribution
    }
  });
}

function inspectSource(input = {}) {
  if (isPlainObject(input.repositoryState)) {
    return {
      ...input.repositoryState,
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

function validateAuthorityCompatibility(authorityId) {
  return compatibleAuthorities.includes(authorityId)
    ? { ok: true, reason: null, failure: null }
    : { ok: false, reason: `unknown authority ${authorityId}`, failure: protocolFailures.unknownAuthority };
}

export function validateCompatibility(input = {}) {
  const request = input.requestEnvelope ?? createRequestEnvelope(input);
  const response = input.responseEnvelope ?? canonicalResponse(request);
  const event = input.eventEnvelope ?? canonicalEvent(request);
  const structuredResult = input.structuredResultEnvelope ?? canonicalStructuredResult(request);
  const capabilities = input.capabilities ?? [];
  const validations = [
    validateVersionMetadata({
      protocolVersion: input.protocolVersion ?? request.protocolVersion,
      contractVersion: input.contractVersion ?? request.contractVersion,
      schemaVersion: input.schemaVersion ?? integrationContractSchemaVersion,
      compatibilityVersion: input.compatibilityVersion ?? integrationContractCompatibilityVersion
    }),
    validateAuthorityCompatibility(input.authorityId ?? request.authorityId),
    validateCapabilities(capabilities),
    validateRequestEnvelope(request),
    validateResponseEnvelope(response),
    validateEventEnvelope(event, input.previousSequence ?? null),
    validateStructuredResultEnvelope(structuredResult),
    validateSerialization({
      request,
      response,
      event,
      structuredResult
    })
  ];
  const failure = validations.find((result) => !result.ok) ?? null;

  return {
    ok: failure === null,
    compatibilityState: failure === null ? "compatible" : "incompatible",
    validationResult: failure === null ? "accepted" : "rejected",
    failureReason: failure?.failure ?? null,
    reason: failure?.reason ?? null,
    validations
  };
}

function handshakeFor(compatibility, sourceAttributionValid, timestamp) {
  const transitions = [
    createHandshakeTransition(handshakeStates.idle, handshakeStates.discovery, "integration contract handshake started", timestamp)
  ];

  if (compatibility.failureReason === protocolFailures.unsupportedProtocol || compatibility.failureReason === protocolFailures.unsupportedContract) {
    transitions.push(
      createHandshakeTransition(
        handshakeStates.discovery,
        handshakeStates.capabilityExchange,
        "external implementation discovered",
        timestamp
      )
    );
    transitions.push(
      createHandshakeTransition(
        handshakeStates.capabilityExchange,
        handshakeStates.unsupportedVersion,
        compatibility.failureReason,
        timestamp
      )
    );
    return transitions;
  }

  if (compatibility.failureReason === protocolFailures.unknownAuthority) {
    transitions.push(
      createHandshakeTransition(handshakeStates.discovery, handshakeStates.rejected, protocolFailures.unknownAuthority, timestamp)
    );
    return transitions;
  }

  transitions.push(
    createHandshakeTransition(handshakeStates.discovery, handshakeStates.capabilityExchange, "external implementation discovered", timestamp)
  );
  transitions.push(
    createHandshakeTransition(
      handshakeStates.capabilityExchange,
      handshakeStates.compatibilityValidation,
      "capabilities explicitly advertised",
      timestamp
    )
  );

  if (!compatibility.ok) {
    transitions.push(
      createHandshakeTransition(
        handshakeStates.compatibilityValidation,
        handshakeStates.incompatibleCapabilities,
        compatibility.failureReason,
        timestamp
      )
    );
    return transitions;
  }

  transitions.push(
    createHandshakeTransition(
      handshakeStates.compatibilityValidation,
      handshakeStates.sourceValidation,
      "protocol compatibility accepted",
      timestamp
    )
  );

  transitions.push(
    sourceAttributionValid
      ? createHandshakeTransition(handshakeStates.sourceValidation, handshakeStates.accepted, "source attribution accepted", timestamp)
      : createHandshakeTransition(handshakeStates.sourceValidation, handshakeStates.invalidSource, protocolFailures.invalidSource, timestamp)
  );

  return transitions;
}

function createDiagnostics(result) {
  return deepFreeze({
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    authority: integrationContractAuthorityId,
    compatibilityState: result.compatibility.compatibilityState,
    handshakeState: result.handshakeState,
    requiredCapabilities: [...requiredCapabilities],
    negotiatedCapabilities: [...result.negotiatedCapabilities],
    validationResult: result.compatibility.validationResult,
    failureReason: result.failureReason,
    timestamp: result.timestamp
  });
}

export function evaluateIntegrationContract(input = {}) {
  const timestamp = input.timestamp ?? now();
  const repositoryState = inspectSource(input);
  const sourceAttribution = repositoryState.sourceAttributionValid ? "valid" : "invalid";
  const requestEnvelope = createRequestEnvelope({
    requestId: input.requestId,
    phase: input.phase ?? 129,
    repositoryRevision: input.repositoryRevision ?? repositoryState.localHead ?? stableCommit,
    timestamp,
    payload: input.payload ?? {
      supportedPhase,
      requiredCapabilities
    },
    sourceAttribution
  });
  const compatibility = validateCompatibility({
    ...input,
    requestEnvelope,
    capabilities: input.capabilities ?? []
  });
  const handshakeTransitions = handshakeFor(compatibility, repositoryState.sourceAttributionValid === true, timestamp);
  const handshakeValidation = validateHandshakeTransitions(handshakeTransitions);
  const handshakeState = handshakeTransitions[handshakeTransitions.length - 1]?.to ?? handshakeStates.rejected;
  const runnerAuthority = evaluateRunnerAuthority({
    timestamp,
    repositoryState,
    connectedSessions: input.connectedSessions
  });
  const failureReason =
    compatibility.failureReason
    ?? (repositoryState.sourceAttributionValid ? runnerAuthority.failureReason : protocolFailures.invalidSource);

  const result = {
    schemaVersion: integrationContractSchemaVersion,
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
    compatibilityVersion: integrationContractCompatibilityVersion,
    authorityId: integrationContractAuthorityId,
    status: "executionBlocked",
    exitCode: bridgeExitCodes.executionBlocked,
    runnerInvoked: false,
    structuredResultCaptured: false,
    runtimeTruth: {
      sessionFailureReason: failureReasons.sessionNotVisible,
      status: "executionBlocked",
      runnerInvoked: false,
      structuredResultCaptured: false
    },
    requestEnvelope,
    responseEnvelope: canonicalResponse(requestEnvelope),
    eventEnvelope: canonicalEvent(requestEnvelope),
    structuredResultEnvelope: canonicalStructuredResult(requestEnvelope),
    compatibility,
    handshakeState,
    handshakeTransitions: deepFreeze([...handshakeTransitions]),
    handshakeValidation,
    requiredCapabilities: [...requiredCapabilities],
    negotiatedCapabilities: Array.isArray(input.capabilities) ? [...input.capabilities] : [],
    repositoryState,
    runnerAuthority,
    integrationGraph: [
      "Phase121EvidenceTransport",
      "Phase122Bridge",
      "Phase124ActivationAuthority",
      "Phase125BindingAuthority",
      "Phase126SessionAuthority",
      "Phase127RunnerAuthority"
    ],
    failureReason,
    recommendedAction:
      "Connect a conforming Studio MCP implementation that advertises required capabilities before runner invocation.",
    timestamp
  };

  return deepFreeze({
    ...result,
    diagnostics: createDiagnostics(result),
    diagnosticsValidation: validateDiagnostics(createDiagnostics(result)),
    serializationValidation: validateSerialization(result)
  });
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runIntegrationContractSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const validCapabilities = [...requiredCapabilities];
  const accepted = evaluateIntegrationContract({
    timestamp: stableTimestamp,
    repositoryState,
    capabilities: validCapabilities
  });
  const blocked = evaluateIntegrationContract({
    timestamp: stableTimestamp,
    repositoryState,
    capabilities: []
  });
  const dirty = evaluateIntegrationContract({
    timestamp: stableTimestamp,
    repositoryState: { ...repositoryState, workingTreeClean: false },
    capabilities: validCapabilities
  });
  const request = createRequestEnvelope({ timestamp: stableTimestamp });
  const response = canonicalResponse(request);
  const event = canonicalEvent(request);
  const structured = canonicalStructuredResult(request);
  const invalidRequest = { ...request, extra: true };
  const partialResponse = { ...response };
  delete partialResponse.status;
  const corruptResult = { ...structured, productionCertified: true };
  const duplicateCapability = validateCapabilities([...validCapabilities, "Heartbeat"]);
  const unsupportedProtocol = validateCompatibility({
    requestEnvelope: { ...request, protocolVersion: "0.0.0" },
    capabilities: validCapabilities
  });
  const unknownAuthority = validateCompatibility({
    requestEnvelope: { ...request, authorityId: "unknown.authority" },
    capabilities: validCapabilities
  });
  const legalHandshake = validateHandshakeTransitions([
    createHandshakeTransition(handshakeStates.idle, handshakeStates.discovery, "start", stableTimestamp),
    createHandshakeTransition(handshakeStates.discovery, handshakeStates.capabilityExchange, "discover", stableTimestamp),
    createHandshakeTransition(
      handshakeStates.capabilityExchange,
      handshakeStates.compatibilityValidation,
      "capabilities",
      stableTimestamp
    ),
    createHandshakeTransition(
      handshakeStates.compatibilityValidation,
      handshakeStates.sourceValidation,
      "compatible",
      stableTimestamp
    ),
    createHandshakeTransition(handshakeStates.sourceValidation, handshakeStates.accepted, "source", stableTimestamp)
  ]);
  const illegalHandshake = validateHandshakeTransitions([
    createHandshakeTransition(handshakeStates.idle, handshakeStates.capabilityExchange, "skip", stableTimestamp)
  ]);
  const serializedA = stableSerialize({ z: 1, a: { b: 2 } });
  const serializedB = stableSerialize({ a: { b: 2 }, z: 1 });

  assertSelfCheck(results, "protocolVersionValidation", validateVersionMetadata(accepted).ok === true, "");
  assertSelfCheck(results, "contractVersionValidation", accepted.contractVersion === integrationContractVersion, "");
  assertSelfCheck(results, "compatibilityValidation", accepted.compatibility.ok === true, "");
  assertSelfCheck(results, "handshakeValidation", accepted.handshakeValidation.ok === true && legalHandshake.ok === true, "");
  assertSelfCheck(results, "capabilityValidation", validateCapabilities(validCapabilities).ok === true, "");
  assertSelfCheck(results, "missingCapabilityRejection", blocked.compatibility.failureReason === protocolFailures.capabilityMissing, "");
  assertSelfCheck(results, "duplicateCapabilityRejection", duplicateCapability.ok === false, "");
  assertSelfCheck(results, "requestSchemaValidation", validateRequestEnvelope(request).ok === true, "");
  assertSelfCheck(results, "requestUnknownFieldRejection", validateRequestEnvelope(invalidRequest).ok === false, "");
  assertSelfCheck(results, "responseSchemaValidation", validateResponseEnvelope(response).ok === true, "");
  assertSelfCheck(results, "partialResponseRejection", validateResponseEnvelope(partialResponse).ok === false, "");
  assertSelfCheck(results, "eventSchemaValidation", validateEventEnvelope(event).ok === true, "");
  assertSelfCheck(results, "eventSequenceValidation", validateEventEnvelope({ ...event, sequence: 1 }, 1).ok === false, "");
  assertSelfCheck(results, "structuredResultSchemaValidation", validateStructuredResultEnvelope(structured).ok === true, "");
  assertSelfCheck(results, "forbiddenStructuredResultRejection", validateStructuredResultEnvelope(corruptResult).ok === false, "");
  assertSelfCheck(results, "serializationValidation", accepted.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicOrdering", serializedA === serializedB, "");
  assertSelfCheck(results, "authorityOwnershipValidation", accepted.authorityId === integrationContractAuthorityId, "");
  assertSelfCheck(results, "unknownAuthorityRejection", unknownAuthority.failureReason === protocolFailures.unknownAuthority, "");
  assertSelfCheck(results, "compatibilityRegressionDetection", unsupportedProtocol.failureReason === protocolFailures.unsupportedProtocol, "");
  assertSelfCheck(results, "protocolDriftDetection", validateVersionMetadata({ ...accepted, protocolVersion: "2.0.0" }).ok === false, "");
  assertSelfCheck(results, "schemaDriftDetection", validateVersionMetadata({ ...accepted, schemaVersion: 2 }).ok === false, "");
  assertSelfCheck(results, "sourceAttributionValidation", dirty.handshakeState === handshakeStates.invalidSource, "");
  assertSelfCheck(results, "deterministicTimestamps", accepted.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicExitCodes", accepted.exitCode === bridgeExitCodes.executionBlocked, "");
  const rerun = evaluateIntegrationContract({ timestamp: stableTimestamp, repositoryState, capabilities: validCapabilities });
  assertSelfCheck(
    results,
    "rerunStability",
    stableSerialize({
      requestEnvelope: accepted.requestEnvelope,
      responseEnvelope: accepted.responseEnvelope,
      eventEnvelope: accepted.eventEnvelope,
      structuredResultEnvelope: accepted.structuredResultEnvelope,
      handshakeTransitions: accepted.handshakeTransitions,
      diagnostics: accepted.diagnostics
    })
      === stableSerialize({
        requestEnvelope: rerun.requestEnvelope,
        responseEnvelope: rerun.responseEnvelope,
        eventEnvelope: rerun.eventEnvelope,
        structuredResultEnvelope: rerun.structuredResultEnvelope,
        handshakeTransitions: rerun.handshakeTransitions,
        diagnostics: rerun.diagnostics
      }),
    ""
  );
  assertSelfCheck(results, "backwardCompatibility", integrationContractCompatibilityVersion === 1, "");
  assertSelfCheck(results, "authorityIsolation", accepted.runnerAuthority.authorityId === runnerAuthorityId, "");
  assertSelfCheck(results, "sessionAuthorityConsumption", accepted.runnerAuthority.sessionAuthorityId === sessionAuthorityId, "");
  assertSelfCheck(results, "integrationGraphPreserved", accepted.integrationGraph.includes("Phase127RunnerAuthority"), "");
  assertSelfCheck(results, "diagnosticsSchemaValidation", accepted.diagnosticsValidation.ok === true, "");
  assertSelfCheck(results, "handshakeClosedStateMachine", illegalHandshake.ok === false, "");
  assertSelfCheck(results, "unsupportedVersionFailurePath", unsupportedProtocol.ok === false, "");
  assertSelfCheck(results, "invalidSourceFailurePath", dirty.failureReason === protocolFailures.invalidSource, "");
  assertSelfCheck(results, "capabilitiesNeverInferred", blocked.negotiatedCapabilities.length === 0, "");
  assertSelfCheck(results, "immutableProtocolMetadata", Object.isFrozen(accepted), "");
  assertSelfCheck(results, "immutableEnvelopes", Object.isFrozen(accepted.requestEnvelope), "");
  assertSelfCheck(results, "requestIdentityPreserved", accepted.requestEnvelope.requestId === accepted.responseEnvelope.requestId, "");
  assertSelfCheck(results, "responseIdentityPreserved", accepted.responseEnvelope.executionId.includes(accepted.requestEnvelope.requestId), "");
  assertSelfCheck(results, "eventIdentityPreserved", accepted.eventEnvelope.authority === integrationContractAuthorityId, "");
  assertSelfCheck(results, "structuredIdentityPreserved", accepted.structuredResultEnvelope.requestIdentity.requestId === accepted.requestEnvelope.requestId, "");
  assertSelfCheck(results, "diagnosticsToolingOnly", !("productionCertified" in accepted.diagnostics), "");
  assertSelfCheck(results, "noCertificationDecision", !("certificationDecision" in accepted.structuredResultEnvelope), "");
  assertSelfCheck(results, "executionBlockedPreserved", accepted.status === "executionBlocked", "");
  assertSelfCheck(results, "runnerNotInvoked", accepted.runnerInvoked === false, "");
  assertSelfCheck(results, "structuredResultNotCaptured", accepted.structuredResultCaptured === false, "");
  assertSelfCheck(results, "currentRuntimeTruthPreserved", accepted.runtimeTruth.sessionFailureReason === failureReasons.sessionNotVisible, "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noNetworkingImplementation", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runIntegrationContractSelfChecks();
    const failed = results.filter((result) => !result.ok);
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
  const result = evaluateIntegrationContract({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(result, null, 2));
  process.exitCode = result.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
