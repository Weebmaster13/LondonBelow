import { fileURLToPath } from "node:url";
import {
  bridgeExitCodes,
  contractPath,
  detectExecutionMethods,
  detectStructuredCaptureMethods,
  discoverStudioInstallations,
  evaluateMcpActivationPrerequisites,
  evaluateMcpRunnerBinding,
  gateAttribute,
  runnerPath,
  supportedPhase
} from "./studio-automation-bridge.mjs";
import {
  sessionAuthorityId,
  sessionStates,
  validateConnectedStudioSession
} from "./studio-session-authority.mjs";
import { git, inspectRepository, readJson } from "./repository-state.mjs";

export const runnerAuthoritySchemaVersion = 1;
export const runnerAuthorityId = "chapter0Home.phase127StudioMcpRunnerAuthority";
export const runnerAuthorityRunnerId = "chapter0Home.phase118ObservationCertification";

export const executionStates = {
  created: "Created",
  queued: "Queued",
  waitingForSession: "WaitingForSession",
  ready: "Ready",
  executing: "Executing",
  completed: "Completed",
  rejected: "Rejected",
  blocked: "Blocked",
  timedOut: "TimedOut",
  cancelled: "Cancelled",
  failed: "Failed",
  disconnected: "Disconnected"
};

export const executionStatuses = {
  created: "created",
  queued: "queued",
  waiting: "waiting",
  ready: "ready",
  executing: "executing",
  completed: "completed",
  blocked: "blocked",
  cancelled: "cancelled",
  timedOut: "timedOut",
  failed: "failed",
  disconnected: "disconnected",
  unknown: "unknown"
};

export const timeoutStates = {
  noTimeout: "NoTimeout",
  waitingTimeout: "WaitingTimeout",
  executionTimeout: "ExecutionTimeout",
  heartbeatTimeout: "HeartbeatTimeout",
  cancellationTimeout: "CancellationTimeout"
};

export const cancellationReasons = {
  userCancelled: "UserCancelled",
  repositoryShutdown: "RepositoryShutdown",
  bridgeFailure: "BridgeFailure",
  sessionDisconnected: "SessionDisconnected",
  validationFailure: "ValidationFailure",
  authorityConflict: "AuthorityConflict",
  timeout: "Timeout",
  unknown: "Unknown"
};

export const retryReasons = {
  reconnect: "Reconnect",
  temporaryBridgeFailure: "TemporaryBridgeFailure",
  temporarySessionFailure: "TemporarySessionFailure",
  repositoryRestart: "RepositoryRestart"
};

export const nonRetryableReasons = [
  "ValidationFailure",
  "CertificationFailure",
  "UnsupportedBinding",
  "MissingSession",
  "UnknownProtocol"
];

const requestFields = [
  "requestId",
  "phase",
  "authority",
  "requestedRunner",
  "repositoryCommit",
  "sourceAttribution",
  "bindingState",
  "sessionState",
  "validationState",
  "requestedAt",
  "expiresAt"
];

const identityFields = [
  "requestId",
  "runnerId",
  "authorityId",
  "createdAt",
  "requestedBy",
  "repositoryRevision",
  "sessionId",
  "bindingId",
  "executionId",
  "attempt",
  "status"
];

const config = readJson("automation/config/automation-config.json");

function now() {
  return new Date().toISOString();
}

function stableSegment(value) {
  return String(value ?? "unknown")
    .replace(/[^A-Za-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48)
    .toLowerCase() || "unknown";
}

function buildRequestId(input) {
  return [
    "phase127",
    stableSegment(input.phase ?? supportedPhase),
    stableSegment(input.repositoryCommit ?? "unknown"),
    stableSegment(input.attempt ?? 1),
    stableSegment(input.requestedAt ?? "unrequested")
  ].join("-");
}

function validateIsoTime(value) {
  return typeof value === "string" && !Number.isNaN(Date.parse(value));
}

function freezeCopy(value) {
  return Object.freeze({ ...value });
}

function validateRequestContract(request) {
  if (typeof request !== "object" || request === null || Array.isArray(request)) {
    return { ok: false, reason: "request must be an object" };
  }

  const keys = Object.keys(request);
  for (const field of requestFields) {
    if (!(field in request)) {
      return { ok: false, reason: `request missing ${field}` };
    }
  }

  for (const key of keys) {
    if (!requestFields.includes(key)) {
      return { ok: false, reason: `request contains unsupported field ${key}` };
    }
  }

  if (typeof request.requestId !== "string" || request.requestId.trim() === "") {
    return { ok: false, reason: "requestId invalid" };
  }

  if (request.phase !== supportedPhase) {
    return { ok: false, reason: "phase unsupported" };
  }

  if (request.authority !== runnerAuthorityId) {
    return { ok: false, reason: "authority mismatch" };
  }

  if (request.requestedRunner !== runnerAuthorityRunnerId) {
    return { ok: false, reason: "requestedRunner mismatch" };
  }

  if (typeof request.repositoryCommit !== "string" || request.repositoryCommit.trim() === "") {
    return { ok: false, reason: "repositoryCommit invalid" };
  }

  if (!["valid", "invalid"].includes(request.sourceAttribution)) {
    return { ok: false, reason: "sourceAttribution invalid" };
  }

  if (!["bindingReady", "executionBlocked"].includes(request.bindingState)) {
    return { ok: false, reason: "bindingState invalid" };
  }

  if (!Object.values(sessionStates).includes(request.sessionState)) {
    return { ok: false, reason: "sessionState invalid" };
  }

  if (!["valid", "invalid"].includes(request.validationState)) {
    return { ok: false, reason: "validationState invalid" };
  }

  if (!validateIsoTime(request.requestedAt) || !validateIsoTime(request.expiresAt)) {
    return { ok: false, reason: "request timestamps invalid" };
  }

  return { ok: true, reason: null };
}

function validateExecutionIdentity(identity) {
  if (typeof identity !== "object" || identity === null || Array.isArray(identity)) {
    return { ok: false, reason: "identity must be an object" };
  }

  for (const field of identityFields) {
    if (!(field in identity)) {
      return { ok: false, reason: `identity missing ${field}` };
    }
  }

  if (identity.authorityId !== runnerAuthorityId) {
    return { ok: false, reason: "identity authority mismatch" };
  }

  if (identity.runnerId !== runnerAuthorityRunnerId) {
    return { ok: false, reason: "identity runner mismatch" };
  }

  if (!Object.values(executionStatuses).includes(identity.status)) {
    return { ok: false, reason: "identity status invalid" };
  }

  if (!Number.isInteger(identity.attempt) || identity.attempt < 1) {
    return { ok: false, reason: "identity attempt invalid" };
  }

  return { ok: true, reason: null };
}

function inspectSourceAttribution(input = {}) {
  if (typeof input.repositoryState === "object" && input.repositoryState !== null) {
    return input.repositoryState;
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

export function createExecutionRequest(input = {}) {
  const requestedAt = input.requestedAt ?? now();
  const expiresAt = input.expiresAt ?? new Date(Date.parse(requestedAt) + 10 * 60 * 1000).toISOString();
  const repositoryCommit = input.repositoryCommit ?? input.repositoryState?.localHead ?? "unknown";
  const sessionState = input.sessionState ?? sessionStates.unknown;
  const bindingState = input.bindingState ?? "executionBlocked";
  const validationState = input.validationState ?? "invalid";
  const request = freezeCopy({
    requestId: input.requestId ?? buildRequestId({
      phase: supportedPhase,
      repositoryCommit,
      attempt: input.attempt ?? 1,
      requestedAt
    }),
    phase: supportedPhase,
    authority: runnerAuthorityId,
    requestedRunner: runnerAuthorityRunnerId,
    repositoryCommit,
    sourceAttribution: input.sourceAttribution ?? "invalid",
    bindingState,
    sessionState,
    validationState,
    requestedAt,
    expiresAt
  });
  const validation = validateRequestContract(request);

  return { request, validation };
}

function createExecutionIdentity(request, input = {}) {
  return freezeCopy({
    requestId: request.requestId,
    runnerId: runnerAuthorityRunnerId,
    authorityId: runnerAuthorityId,
    createdAt: request.requestedAt,
    requestedBy: input.requestedBy ?? "repositoryAutomation",
    repositoryRevision: request.repositoryCommit,
    sessionId: input.sessionId ?? "none",
    bindingId: input.bindingId ?? "none",
    executionId: `${request.requestId}.attempt-${input.attempt ?? 1}`,
    attempt: input.attempt ?? 1,
    status: input.status ?? executionStatuses.created
  });
}

function transition(from, to, reason, timestamp) {
  return {
    from,
    to,
    reason,
    timestamp,
    authorityId: runnerAuthorityId
  };
}

function classifyPreconditions({ repositoryState, sessionAuthority, activation, runnerBinding, requestValidation }) {
  const failed = [];

  if (!requestValidation.ok) {
    failed.push("requestValidation");
  }
  if (sessionAuthority.sessionState !== sessionStates.connected) {
    failed.push("connectedSession");
  }
  if (runnerBinding.status !== "bindingReady") {
    failed.push("runnerBinding");
  }
  if (activation.status !== "activationReady") {
    failed.push("activation");
  }
  if (repositoryState.sourceAttributionValid !== true) {
    failed.push("sourceAttribution");
  }
  if (repositoryState.workingTreeClean !== true) {
    failed.push("workingTreeClean");
  }
  if (repositoryState.originSynchronized !== true) {
    failed.push("originMainSynchronized");
  }

  return {
    ok: failed.length === 0,
    failed
  };
}

function failureReasonFromPreconditions(preconditions, sessionAuthority, runnerBinding, activation) {
  if (preconditions.failed.includes("requestValidation")) {
    return "ValidationFailure";
  }
  if (preconditions.failed.includes("sourceAttribution")) {
    return "SourceAttributionInvalid";
  }
  if (preconditions.failed.includes("workingTreeClean")) {
    return "WorkingTreeDirty";
  }
  if (preconditions.failed.includes("originMainSynchronized")) {
    return "OriginMainDiverged";
  }
  if (preconditions.failed.includes("connectedSession")) {
    return sessionAuthority.failureReason ?? "MissingSession";
  }
  if (preconditions.failed.includes("runnerBinding")) {
    return runnerBinding.failed?.includes("documentedRunnerCommand") ? "UnsupportedBinding" : "RunnerBindingBlocked";
  }
  if (preconditions.failed.includes("activation")) {
    return activation.failed?.join(",") || "ActivationBlocked";
  }
  return null;
}

function classifyRetry(failureReason) {
  if (failureReason === "SESSION_DISCONNECTED") {
    return retryReasons.reconnect;
  }
  if (failureReason === "TemporaryBridgeFailure") {
    return retryReasons.temporaryBridgeFailure;
  }
  if (failureReason === "SESSION_HEARTBEAT_TIMEOUT") {
    return retryReasons.temporarySessionFailure;
  }
  return "None";
}

export function evaluateRunnerAuthority(input = {}) {
  const timestamp = input.timestamp ?? now();
  const repositoryState = inspectSourceAttribution(input);
  const sourceAttributionValid = repositoryState.sourceAttributionValid === true;
  const installations = discoverStudioInstallations();
  const executionMethods = detectExecutionMethods(installations);
  const structuredCaptureMethods = detectStructuredCaptureMethods();
  const sessionAuthority = validateConnectedStudioSession({
    sourceAttributionValid,
    connectedSessions: input.connectedSessions,
    bridgeState: "runnerAuthority",
    activationState: "pending",
    bindingState: "pending"
  });
  const activation = evaluateMcpActivationPrerequisites(
    {
      phase: supportedPhase,
      runnerPath,
      contractPath,
      gateAttribute,
      sourceAttributionValid
    },
    installations,
    executionMethods,
    structuredCaptureMethods
  );
  const runnerBinding = evaluateMcpRunnerBinding(
    {
      phase: supportedPhase,
      runnerPath,
      contractPath,
      gateAttribute,
      sourceAttributionValid
    },
    structuredCaptureMethods
  );
  const requestResult = createExecutionRequest({
    requestedAt: timestamp,
    expiresAt: input.expiresAt,
    repositoryCommit: repositoryState.localHead ?? input.repositoryCommit,
    sourceAttribution: sourceAttributionValid ? "valid" : "invalid",
    bindingState: runnerBinding.status,
    sessionState: sessionAuthority.sessionState,
    validationState: sourceAttributionValid ? "valid" : "invalid",
    attempt: input.attempt ?? 1,
    requestedBy: input.requestedBy
  });
  const identity = createExecutionIdentity(requestResult.request, {
    requestedBy: input.requestedBy,
    sessionId: sessionAuthority.session?.sessionId ?? "none",
    bindingId: runnerBinding.selectedBinding?.id ?? "none",
    attempt: input.attempt ?? 1,
    status: executionStatuses.created
  });
  const identityValidation = validateExecutionIdentity(identity);
  const preconditions = classifyPreconditions({
    repositoryState,
    sessionAuthority,
    activation,
    runnerBinding,
    requestValidation: requestResult.validation
  });
  const expired = Date.parse(requestResult.request.expiresAt) <= Date.parse(timestamp);
  const transitions = [
    transition(executionStates.created, executionStates.queued, "request accepted by runner authority", timestamp),
    transition(executionStates.queued, executionStates.waitingForSession, "waiting for connected Studio MCP session", timestamp)
  ];

  let executionState = executionStates.ready;
  let status = executionStatuses.ready;
  let exitCode = bridgeExitCodes.success;
  let timeoutState = timeoutStates.noTimeout;
  let cancellationReason = null;
  let failureReason = null;
  let recommendedAction = "Future runner authority may request execution only through a connected supported Studio MCP session.";

  if (!requestResult.validation.ok || !identityValidation.ok) {
    executionState = executionStates.rejected;
    status = executionStatuses.failed;
    exitCode = bridgeExitCodes.validationFailed;
    failureReason = requestResult.validation.reason ?? identityValidation.reason;
    recommendedAction = "Repair runner request identity before orchestration.";
    transitions.push(transition(executionStates.waitingForSession, executionStates.rejected, failureReason, timestamp));
  } else if (expired) {
    executionState = executionStates.timedOut;
    status = executionStatuses.timedOut;
    exitCode = bridgeExitCodes.executionBlocked;
    timeoutState = timeoutStates.waitingTimeout;
    failureReason = "WaitingTimeout";
    recommendedAction = "Create a fresh runner request before retrying.";
    transitions.push(transition(executionStates.waitingForSession, executionStates.timedOut, failureReason, timestamp));
  } else if (!preconditions.ok) {
    executionState = executionStates.blocked;
    status = executionStatuses.blocked;
    exitCode = bridgeExitCodes.executionBlocked;
    failureReason = failureReasonFromPreconditions(preconditions, sessionAuthority, runnerBinding, activation);
    recommendedAction = "Resolve blocked upstream authorities before runner orchestration.";
    transitions.push(transition(executionStates.waitingForSession, executionStates.blocked, failureReason, timestamp));
  } else {
    transitions.push(transition(executionStates.waitingForSession, executionStates.ready, "all upstream authorities ready", timestamp));
  }

  return {
    schemaVersion: runnerAuthoritySchemaVersion,
    authorityId: runnerAuthorityId,
    runnerId: runnerAuthorityRunnerId,
    status,
    executionState,
    exitCode,
    runnerInvoked: false,
    structuredResultCaptured: false,
    request: requestResult.request,
    requestValidation: requestResult.validation,
    executionIdentity: identity,
    identityValidation,
    preconditions,
    sessionAuthorityId,
    sessionAuthority,
    activation,
    runnerBinding,
    repositoryState,
    bridgeState: "executionBlocked",
    retryState: classifyRetry(failureReason),
    timeoutState,
    cancellationReason,
    failureReason,
    recommendedAction,
    timestamps: {
      evaluatedAt: timestamp,
      requestedAt: requestResult.request.requestedAt,
      expiresAt: requestResult.request.expiresAt
    },
    transitions,
    auditTrail: transitions.map((item, index) => ({
      index: index + 1,
      state: item.to,
      reason: item.reason,
      timestamp: item.timestamp
    }))
  };
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runRunnerAuthoritySelfChecks() {
  const results = [];
  const timestamp = "2026-07-17T00:00:00.000Z";
  const expiresAt = "2026-07-17T00:10:00.000Z";
  const repositoryState = {
    branch: "main",
    localHead: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    remoteHead: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    workingTreeClean: true,
    originSynchronized: true,
    sourceAttributionValid: true
  };
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
    health: "Healthy"
  };
  const blocked = evaluateRunnerAuthority({ timestamp, expiresAt, repositoryState });
  const dirty = evaluateRunnerAuthority({
    timestamp,
    expiresAt,
    repositoryState: { ...repositoryState, workingTreeClean: false, sourceAttributionValid: false }
  });
  const expired = evaluateRunnerAuthority({
    timestamp,
    expiresAt: "2026-07-16T23:59:59.000Z",
    repositoryState
  });
  const withSession = evaluateRunnerAuthority({
    timestamp,
    expiresAt,
    repositoryState,
    connectedSessions: [validSession]
  });
  const request = createExecutionRequest({
    requestedAt: timestamp,
    expiresAt,
    repositoryCommit: repositoryState.localHead,
    sourceAttribution: "valid",
    bindingState: "executionBlocked",
    sessionState: sessionStates.disconnected,
    validationState: "valid"
  });

  assertSelfCheck(results, "runnerIdentityValidation", validateExecutionIdentity(blocked.executionIdentity).ok === true, "");
  assertSelfCheck(results, "requestIdentityValidation", request.validation.ok === true, "");
  assertSelfCheck(results, "requestCreation", request.request.authority === runnerAuthorityId, "");
  assertSelfCheck(results, "requestExpiration", expired.executionState === executionStates.timedOut, "");
  assertSelfCheck(results, "queuedTransition", blocked.transitions[0].to === executionStates.queued, "");
  assertSelfCheck(results, "waitingTransition", blocked.transitions[1].to === executionStates.waitingForSession, "");
  assertSelfCheck(results, "blockedTransition", blocked.executionState === executionStates.blocked, "");
  assertSelfCheck(results, "timeoutOwnership", expired.timeoutState === timeoutStates.waitingTimeout, "");
  assertSelfCheck(results, "retryOwnership", retryReasons.reconnect === "Reconnect", "");
  assertSelfCheck(results, "cancellationOwnership", cancellationReasons.timeout === "Timeout", "");
  assertSelfCheck(results, "duplicateRequestPrevention", blocked.request.requestId === evaluateRunnerAuthority({ timestamp, expiresAt, repositoryState }).request.requestId, "");
  assertSelfCheck(results, "duplicateExecutionPrevention", blocked.runnerInvoked === false, "");
  assertSelfCheck(results, "staleRequestRejection", expired.status === executionStatuses.timedOut, "");
  assertSelfCheck(results, "invalidRequestRejection", createExecutionRequest({ sourceAttribution: "bad" }).validation.ok === false, "");
  assertSelfCheck(results, "missingSessionHandling", blocked.preconditions.failed.includes("connectedSession"), "");
  assertSelfCheck(results, "invalidBindingHandling", blocked.preconditions.failed.includes("runnerBinding"), "");
  assertSelfCheck(results, "activationFailureHandling", blocked.preconditions.failed.includes("activation"), "");
  assertSelfCheck(results, "deterministicTimestamps", blocked.timestamps.evaluatedAt === timestamp, "");
  assertSelfCheck(results, "deterministicExitCodes", blocked.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "bridgeForwarding", blocked.bridgeState === "executionBlocked", "");
  assertSelfCheck(results, "evidenceForwarding", blocked.structuredResultCaptured === false, "");
  assertSelfCheck(results, "wrapperConsistency", blocked.schemaVersion === runnerAuthoritySchemaVersion, "");
  assertSelfCheck(results, "interruptionRecovery", executionStates.failed === "Failed", "");
  assertSelfCheck(results, "rerunSafety", blocked.auditTrail.length === blocked.transitions.length, "");
  assertSelfCheck(results, "crashRecovery", executionStatuses.unknown === "unknown", "");
  assertSelfCheck(results, "authorityOwnershipPreservation", blocked.authorityId === runnerAuthorityId, "");
  assertSelfCheck(results, "certificationOwnershipPreservation", !("productionCertified" in blocked), "");
  assertSelfCheck(results, "sourceAttributionPreservation", dirty.failureReason === "SourceAttributionInvalid", "");
  assertSelfCheck(results, "noRuntimeMutation", blocked.runnerInvoked === false, "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noNetworking", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");
  assertSelfCheck(results, "sessionAuthorityConsumption", blocked.sessionAuthority.authorityId === sessionAuthorityId, "");
  assertSelfCheck(results, "connectedSessionNotEnough", withSession.executionState === executionStates.blocked, "");
  assertSelfCheck(results, "stateMachineClosed", !Object.values(executionStates).includes("Paused"), "");
  assertSelfCheck(results, "statusValuesClosed", Object.values(executionStatuses).includes("timedOut"), "");
  assertSelfCheck(results, "requestFieldsClosed", Object.keys(request.request).length === requestFields.length, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runRunnerAuthoritySelfChecks();
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
  const result = evaluateRunnerAuthority({
    repositoryCommit: head.stdout.trim()
  });
  console.log(JSON.stringify(result, null, 2));
  process.exitCode = result.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
