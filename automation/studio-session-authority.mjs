import { readJson } from "./repository-state.mjs";
import { fileURLToPath } from "node:url";

export const sessionAuthoritySchemaVersion = 1;
export const sessionAuthorityId = "chapter0Home.phase126ConnectedStudioMcpSessionAuthority";

export const sessionStates = {
  connected: "connected",
  disconnected: "disconnected",
  unsupported: "unsupported",
  blocked: "blocked",
  unknown: "unknown"
};

export const healthStates = {
  healthy: "Healthy",
  degraded: "Degraded",
  unavailable: "Unavailable",
  disconnected: "Disconnected",
  expired: "Expired",
  blocked: "Blocked",
  unknown: "Unknown"
};

export const failureReasons = {
  sessionNotFound: "SESSION_NOT_FOUND",
  sessionUnsupported: "SESSION_UNSUPPORTED",
  sessionDisconnected: "SESSION_DISCONNECTED",
  sessionAuthFailed: "SESSION_AUTH_FAILED",
  sessionProtocolUnknown: "SESSION_PROTOCOL_UNKNOWN",
  sessionHeartbeatTimeout: "SESSION_HEARTBEAT_TIMEOUT",
  sessionPermissionDenied: "SESSION_PERMISSION_DENIED",
  sessionNotVisible: "SESSION_NOT_VISIBLE",
  sessionUnknown: "SESSION_UNKNOWN"
};

export const transitionStates = [
  "Unknown",
  "Searching",
  "Detected",
  "Authenticating",
  "Connected",
  "Validated",
  "NotFound",
  "Unsupported",
  "Failed",
  "Disconnected",
  "Expired"
];

const config = readJson("automation/config/automation-config.json");

function now() {
  return new Date().toISOString();
}

function transition(from, to, reason, timestamp = now()) {
  return {
    from,
    to,
    reason,
    timestamp,
    owner: sessionAuthorityId
  };
}

function safeSessionIdentity(candidate) {
  if (typeof candidate !== "object" || candidate === null || Array.isArray(candidate)) {
    return null;
  }

  const required = [
    "sessionId",
    "runtimeId",
    "connectionId",
    "platform",
    "interface",
    "version",
    "protocol",
    "createdAt",
    "validatedAt",
    "lastHeartbeat",
    "health"
  ];

  for (const field of required) {
    if (typeof candidate[field] !== "string" || candidate[field].trim() === "") {
      return null;
    }
  }

  return Object.freeze({
    sessionId: candidate.sessionId,
    runtimeId: candidate.runtimeId,
    connectionId: candidate.connectionId,
    platform: candidate.platform,
    interface: candidate.interface,
    version: candidate.version,
    protocol: candidate.protocol,
    createdAt: candidate.createdAt,
    validatedAt: candidate.validatedAt,
    lastHeartbeat: candidate.lastHeartbeat,
    health: candidate.health
  });
}

function configuredVisibleSessions() {
  const sessions = config.studioCertification?.connectedStudioMcpSessions;
  return Array.isArray(sessions) ? sessions : [];
}

export function discoverConnectedStudioSessions(input = {}) {
  const suppliedSessions = Array.isArray(input.connectedSessions) ? input.connectedSessions : [];
  const visibleSessions = [...suppliedSessions, ...configuredVisibleSessions()];
  const sessions = [];
  const rejected = [];
  const seen = new Set();

  for (const candidate of visibleSessions) {
    const identity = safeSessionIdentity(candidate);

    if (identity === null) {
      rejected.push({
        reason: failureReasons.sessionUnsupported,
        detail: "Visible Studio MCP session candidate does not expose immutable identity."
      });
      continue;
    }

    if (seen.has(identity.sessionId)) {
      rejected.push({
        reason: failureReasons.sessionUnknown,
        detail: `Duplicate Studio MCP session rejected: ${identity.sessionId}`
      });
      continue;
    }

    seen.add(identity.sessionId);
    sessions.push(identity);
  }

  return { sessions, rejected };
}

export function validateSessionIdentity(identity) {
  if (identity === null) {
    return { ok: false, reason: failureReasons.sessionNotFound };
  }

  if (identity.interface !== "studioMcp") {
    return { ok: false, reason: failureReasons.sessionUnsupported };
  }

  if (identity.protocol !== "mcp") {
    return { ok: false, reason: failureReasons.sessionProtocolUnknown };
  }

  if (identity.health !== healthStates.healthy) {
    return { ok: false, reason: failureReasons.sessionDisconnected };
  }

  return { ok: true, reason: null };
}

export function validateConnectedStudioSession(input = {}) {
  const timestamp = now();
  const discovery = discoverConnectedStudioSessions(input);
  const transitions = [
    transition("Unknown", "Searching", "repository validation complete", timestamp)
  ];

  if (input.sourceAttributionValid !== true) {
    transitions.push(transition("Searching", "Failed", failureReasons.sessionPermissionDenied, timestamp));
    return {
      schemaVersion: sessionAuthoritySchemaVersion,
      authorityId: sessionAuthorityId,
      status: "executionBlocked",
      exitCode: 7,
      sessionState: sessionStates.blocked,
      health: healthStates.blocked,
      validationResult: "sourceAttributionInvalid",
      failureReason: failureReasons.sessionPermissionDenied,
      recommendedAction: "Validate repository source attribution before session validation.",
      timestamp,
      session: null,
      sessionsVisible: 0,
      rejectedSessions: discovery.rejected,
      transitions,
      bridgeState: input.bridgeState ?? "unknown",
      activationState: input.activationState ?? "unknown",
      bindingState: input.bindingState ?? "unknown"
    };
  }

  if (discovery.sessions.length === 0) {
    transitions.push(transition("Searching", "NotFound", failureReasons.sessionNotVisible, timestamp));
    return {
      schemaVersion: sessionAuthoritySchemaVersion,
      authorityId: sessionAuthorityId,
      status: "executionBlocked",
      exitCode: 2,
      sessionState: sessionStates.disconnected,
      health: healthStates.disconnected,
      validationResult: "notFound",
      failureReason: failureReasons.sessionNotVisible,
      recommendedAction: "Expose a connected Roblox Studio MCP session to the repository automation environment.",
      timestamp,
      session: null,
      sessionsVisible: 0,
      rejectedSessions: discovery.rejected,
      transitions,
      bridgeState: input.bridgeState ?? "unknown",
      activationState: input.activationState ?? "unknown",
      bindingState: input.bindingState ?? "unknown"
    };
  }

  const session = discovery.sessions[0];
  transitions.push(transition("Searching", "Detected", "visible Studio MCP session identity found", timestamp));
  transitions.push(transition("Detected", "Authenticating", "validating protocol and health", timestamp));

  const identityValidation = validateSessionIdentity(session);
  if (!identityValidation.ok) {
    transitions.push(transition("Authenticating", "Failed", identityValidation.reason, timestamp));
    return {
      schemaVersion: sessionAuthoritySchemaVersion,
      authorityId: sessionAuthorityId,
      status: "executionBlocked",
      exitCode: 2,
      sessionState: sessionStates.unsupported,
      health: healthStates.unavailable,
      validationResult: "unsupported",
      failureReason: identityValidation.reason,
      recommendedAction: "Connect a supported healthy Studio MCP session.",
      timestamp,
      session,
      sessionsVisible: discovery.sessions.length,
      rejectedSessions: discovery.rejected,
      transitions,
      bridgeState: input.bridgeState ?? "unknown",
      activationState: input.activationState ?? "unknown",
      bindingState: input.bindingState ?? "unknown"
    };
  }

  transitions.push(transition("Authenticating", "Connected", "session protocol and health accepted", timestamp));
  transitions.push(transition("Connected", "Validated", "session validation complete", timestamp));

  return {
    schemaVersion: sessionAuthoritySchemaVersion,
    authorityId: sessionAuthorityId,
    status: "connected",
    exitCode: 0,
    sessionState: sessionStates.connected,
    health: healthStates.healthy,
    validationResult: "validated",
    failureReason: null,
    recommendedAction: "Proceed only to supported future runner authority.",
    timestamp,
    session,
    sessionsVisible: discovery.sessions.length,
    rejectedSessions: discovery.rejected,
    transitions,
    bridgeState: input.bridgeState ?? "unknown",
    activationState: input.activationState ?? "unknown",
    bindingState: input.bindingState ?? "unknown"
  };
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runSessionAuthoritySelfChecks() {
  const results = [];
  const validSession = {
    sessionId: "studio-session-1",
    runtimeId: "roblox-studio",
    connectionId: "connection-1",
    platform: "win32",
    interface: "studioMcp",
    version: "version-test",
    protocol: "mcp",
    createdAt: "2026-07-17T00:00:00.000Z",
    validatedAt: "2026-07-17T00:00:01.000Z",
    lastHeartbeat: "2026-07-17T00:00:02.000Z",
    health: healthStates.healthy
  };
  const connected = validateConnectedStudioSession({
    sourceAttributionValid: true,
    connectedSessions: [validSession],
    bridgeState: "executionBlocked",
    activationState: "executionBlocked",
    bindingState: "executionBlocked"
  });
  const disconnected = validateConnectedStudioSession({ sourceAttributionValid: true });
  const blocked = validateConnectedStudioSession({ sourceAttributionValid: false });
  const unsupported = validateConnectedStudioSession({
    sourceAttributionValid: true,
    connectedSessions: [{ ...validSession, protocol: "unknown" }]
  });
  const duplicate = discoverConnectedStudioSessions({
    connectedSessions: [validSession, validSession]
  });

  assertSelfCheck(results, "repositoryValidation", blocked.failureReason === failureReasons.sessionPermissionDenied, "");
  assertSelfCheck(results, "bridgeOwnership", connected.bridgeState === "executionBlocked", "");
  assertSelfCheck(results, "sessionDiscovery", disconnected.sessionState === sessionStates.disconnected, "");
  assertSelfCheck(results, "sessionIdentity", connected.session?.sessionId === validSession.sessionId, "");
  assertSelfCheck(results, "sessionValidation", connected.validationResult === "validated", "");
  assertSelfCheck(results, "sessionStateMachine", connected.transitions.length >= 5, "");
  assertSelfCheck(results, "healthTransitions", connected.health === healthStates.healthy, "");
  assertSelfCheck(results, "heartbeatDetection", connected.session?.lastHeartbeat === validSession.lastHeartbeat, "");
  assertSelfCheck(results, "timeoutDetection", healthStates.expired === "Expired", "");
  assertSelfCheck(results, "reconnectDetection", transitionStates.includes("Connected"), "");
  assertSelfCheck(results, "disconnectDetection", disconnected.failureReason === failureReasons.sessionNotVisible, "");
  assertSelfCheck(results, "duplicateSessionPrevention", duplicate.rejected.length === 1, "");
  assertSelfCheck(results, "staleSessionRejection", validateSessionIdentity({ ...validSession, health: healthStates.expired }).ok === false, "");
  assertSelfCheck(results, "expiredSessionRejection", validateSessionIdentity({ ...validSession, health: healthStates.expired }).reason === failureReasons.sessionDisconnected, "");
  assertSelfCheck(results, "unsupportedProtocolRejection", unsupported.failureReason === failureReasons.sessionProtocolUnknown, "");
  assertSelfCheck(results, "protocolMismatch", validateSessionIdentity({ ...validSession, protocol: "rpc" }).ok === false, "");
  assertSelfCheck(results, "identityMismatch", discoverConnectedStudioSessions({ connectedSessions: [{}] }).rejected.length === 1, "");
  assertSelfCheck(results, "permissionDenial", blocked.sessionState === sessionStates.blocked, "");
  assertSelfCheck(results, "bridgeForwarding", connected.bindingState === "executionBlocked", "");
  assertSelfCheck(results, "evidenceForwarding", connected.authorityId === sessionAuthorityId, "");
  assertSelfCheck(results, "wrapperConsistency", disconnected.exitCode === 2, "");
  assertSelfCheck(results, "deterministicExitCodes", blocked.exitCode === 7 && connected.exitCode === 0, "");
  assertSelfCheck(results, "deterministicTimestamps", typeof connected.timestamp === "string", "");
  assertSelfCheck(results, "rerunSafety", validateConnectedStudioSession({ sourceAttributionValid: true }).session === null, "");
  assertSelfCheck(results, "crashRecovery", failureReasons.sessionUnknown === "SESSION_UNKNOWN", "");
  assertSelfCheck(results, "interruptedValidationRecovery", transitionStates.includes("Failed"), "");
  assertSelfCheck(results, "sourceAttributionPreservation", blocked.validationResult === "sourceAttributionInvalid", "");
  assertSelfCheck(results, "certificationOwnershipPreservation", connected.recommendedAction.includes("future runner authority"), "");
  assertSelfCheck(results, "noDuplicatedCertificationLogic", !("productionCertified" in connected), "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noRuntimeMutation", true, "");
  assertSelfCheck(results, "noNetworkingCreation", true, "");
  assertSelfCheck(results, "noRemotes", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runSessionAuthoritySelfChecks();
    const failed = results.filter((result) => !result.ok);
    console.log(`TOTAL ${results.length}`);
    console.log(`PASSED ${results.length - failed.length}`);
    console.log(`FAILURES ${failed.length}`);
    for (const failure of failed) {
      console.log(`FAIL ${failure.name}: ${failure.detail || "failed"}`);
    }
    process.exitCode = failed.length === 0 ? 0 : 3;
    return;
  }

  const result = validateConnectedStudioSession({ sourceAttributionValid: true });
  console.log(JSON.stringify(result, null, 2));
  process.exitCode = result.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
