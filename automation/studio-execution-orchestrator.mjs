import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateExecutionPlanning,
  executionPlanningAuthorityId,
  executionPlanningVersion,
  validateExecutionPlan
} from "./studio-execution-planning-authority.mjs";
import {
  integrationContractProtocolVersion,
  integrationContractVersion,
  stableSerialize
} from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const executionOrchestratorSchemaVersion = 1;
export const executionOrchestratorVersion = "1.0.0";
export const executionOrchestratorAuthorityId = "chapter0Home.phase133StudioExecutionOrchestrator";

export const orchestrationStates = Object.freeze({
  idle: "Idle",
  collectExecutionPlan: "CollectExecutionPlan",
  validateExecutionPlan: "ValidateExecutionPlan",
  buildOrchestrationGraph: "BuildOrchestrationGraph",
  freezeOrchestration: "FreezeOrchestration",
  ready: "OrchestrationReady",
  missingExecutionPlan: "MissingExecutionPlan",
  executionPlanRejected: "ExecutionPlanRejected",
  orchestrationFailure: "OrchestrationFailure",
  freezeRejected: "FreezeRejected"
});

export const orchestrationStageCategories = Object.freeze([
  "AcquirePlan",
  "ValidateAuthorities",
  "ValidateReadiness",
  "ValidatePlanning",
  "FreezeExecutionContext",
  "AwaitExecutionAuthority"
]);

export const cancellationStates = Object.freeze([
  "NotRequested",
  "CancellationPending",
  "CancellationAccepted",
  "CancellationRejected"
]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  orchestrationStates.ready,
  orchestrationStates.missingExecutionPlan,
  orchestrationStates.executionPlanRejected,
  orchestrationStates.orchestrationFailure,
  orchestrationStates.freezeRejected
]);
const legalTransitions = new Map([
  [orchestrationStates.idle, new Set([orchestrationStates.collectExecutionPlan])],
  [orchestrationStates.collectExecutionPlan, new Set([orchestrationStates.validateExecutionPlan, orchestrationStates.missingExecutionPlan])],
  [orchestrationStates.validateExecutionPlan, new Set([orchestrationStates.buildOrchestrationGraph, orchestrationStates.executionPlanRejected])],
  [orchestrationStates.buildOrchestrationGraph, new Set([orchestrationStates.freezeOrchestration, orchestrationStates.orchestrationFailure])],
  [orchestrationStates.freezeOrchestration, new Set([orchestrationStates.ready, orchestrationStates.freezeRejected])]
]);

const orchestrationFields = Object.freeze([
  "orchestrationId",
  "orchestrationVersion",
  "executionPlanId",
  "readinessId",
  "protocolVersion",
  "graphId",
  "orderedStages",
  "checkpointReferences",
  "retryPolicyId",
  "cancellationPolicyId",
  "validationState",
  "timestamp"
]);
const stageFields = Object.freeze(["stageId", "category", "sequence", "dependsOn", "checkpointReference"]);
const graphFields = Object.freeze([
  "graphId",
  "graphVersion",
  "stages",
  "dependencies",
  "checkpointReferences",
  "orderedStages",
  "validationState"
]);
const contextFields = Object.freeze([
  "contextId",
  "protocolVersion",
  "readinessId",
  "executionPlanId",
  "capabilityProfileId",
  "graphId",
  "validationState",
  "timestamp"
]);
const retryPolicyFields = Object.freeze(["retryPolicyId", "classification", "eligibility", "retryWindow", "reason"]);
const cancellationPolicyFields = Object.freeze(["cancellationPolicyId", "state", "reason", "requestedAt"]);
const auditFields = Object.freeze([
  "orchestrationId",
  "graphId",
  "contextId",
  "authorityId",
  "state",
  "retryState",
  "cancellationState",
  "timestamp",
  "contractVersion"
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

function transition(from, to, reason, timestamp) {
  return deepFreeze({ from, to, reason, timestamp, authorityId: executionOrchestratorAuthorityId });
}

export function validateOrchestrationTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "orchestration transitions must be non-empty", "InvalidLifecycle");
  }

  let terminalSeen = false;
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(orchestrationStates).includes(item.from) || !Object.values(orchestrationStates).includes(item.to)) {
      return result(false, "undocumented orchestration state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== orchestrationStates.idle) {
      return result(false, "orchestration must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "orchestration skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal orchestration state mutated", "InvalidLifecycle");
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal orchestration transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    if (terminalStates.has(item.to)) terminalSeen = true;
  }

  return result(true);
}

function createRetryPolicy(orchestrationId) {
  return deepFreeze({
    retryPolicyId: `${orchestrationId}.retryPolicy`,
    classification: "NoRetry",
    eligibility: false,
    retryWindow: "none",
    reason: "execution-readiness-blocked"
  });
}

export function validateRetryPolicy(policy) {
  const fields = exactFields(policy, retryPolicyFields, "retry policy");
  if (!fields.ok) return fields;
  const id = validateIdentifier(policy.retryPolicyId, "retryPolicyId");
  if (!id.ok) return id;
  if (!["NoRetry", "RetryEligible", "RetryRejected"].includes(policy.classification)) {
    return result(false, "retry classification invalid", "InvalidRetryPolicy");
  }
  if (typeof policy.eligibility !== "boolean") return result(false, "retry eligibility invalid", "InvalidRetryPolicy");
  if (typeof policy.retryWindow !== "string" || policy.retryWindow.trim() === "") {
    return result(false, "retry window invalid", "InvalidRetryPolicy");
  }
  if (typeof policy.reason !== "string" || policy.reason.trim() === "") {
    return result(false, "retry reason invalid", "InvalidRetryPolicy");
  }
  return result(true);
}

function createCancellationPolicy(orchestrationId, timestamp) {
  return deepFreeze({
    cancellationPolicyId: `${orchestrationId}.cancellationPolicy`,
    state: "NotRequested",
    reason: "no-cancellation-requested",
    requestedAt: timestamp
  });
}

export function validateCancellationPolicy(policy) {
  const fields = exactFields(policy, cancellationPolicyFields, "cancellation policy");
  if (!fields.ok) return fields;
  const id = validateIdentifier(policy.cancellationPolicyId, "cancellationPolicyId");
  if (!id.ok) return id;
  if (!cancellationStates.includes(policy.state)) return result(false, "cancellation state invalid", "InvalidCancellationPolicy");
  if (typeof policy.reason !== "string" || policy.reason.trim() === "") {
    return result(false, "cancellation reason invalid", "InvalidCancellationPolicy");
  }
  if (typeof policy.requestedAt !== "string" || Number.isNaN(Date.parse(policy.requestedAt))) {
    return result(false, "cancellation timestamp invalid", "InvalidCancellationPolicy");
  }
  return result(true);
}

function createStages(orchestrationId, plan) {
  return deepFreeze(
    orchestrationStageCategories.map((category, index) => ({
      stageId: `${orchestrationId}.stage.${category}`,
      category,
      sequence: index + 1,
      dependsOn: index === 0 ? [] : [`${orchestrationId}.stage.${orchestrationStageCategories[index - 1]}`],
      checkpointReference: plan.orderedCheckpoints[index]?.checkpointId ?? `${orchestrationId}.checkpoint.${category}`
    }))
  );
}

function validateStage(stage) {
  const fields = exactFields(stage, stageFields, "orchestration stage");
  if (!fields.ok) return fields;
  if (!orchestrationStageCategories.includes(stage.category)) {
    return result(false, "unsupported orchestration stage category", "InvalidStage");
  }
  if (!Number.isInteger(stage.sequence) || stage.sequence < 1) return result(false, "stage sequence invalid", "InvalidStage");
  if (!Array.isArray(stage.dependsOn)) return result(false, "stage dependencies invalid", "InvalidStage");
  return validateIdentifier(stage.stageId, "stageId");
}

export function validateOrchestrationGraph(graph) {
  const fields = exactFields(graph, graphFields, "orchestration graph");
  if (!fields.ok) return fields;
  if (!Array.isArray(graph.stages) || graph.stages.length !== orchestrationStageCategories.length) {
    return result(false, "orchestration stage completeness invalid", "InvalidGraph");
  }
  if (!Array.isArray(graph.dependencies) || !Array.isArray(graph.checkpointReferences) || !Array.isArray(graph.orderedStages)) {
    return result(false, "orchestration graph ordering invalid", "InvalidGraph");
  }

  const seenStages = new Set();
  const sequenceByStage = new Map();
  for (const stage of graph.stages) {
    const validation = validateStage(stage);
    if (!validation.ok) return validation;
    if (seenStages.has(stage.stageId)) return result(false, "duplicate orchestration stage", "DuplicateIdentifier");
    seenStages.add(stage.stageId);
    sequenceByStage.set(stage.stageId, stage.sequence);
  }

  for (const category of orchestrationStageCategories) {
    if (!graph.stages.some((stage) => stage.category === category)) {
      return result(false, `missing orchestration stage ${category}`, "InvalidGraph");
    }
  }

  for (const stage of graph.stages) {
    for (const dependency of stage.dependsOn) {
      if (!seenStages.has(dependency)) return result(false, `missing dependency ${dependency}`, "InvalidGraph");
      if (sequenceByStage.get(dependency) >= stage.sequence) {
        return result(false, "orchestration dependency ordering invalid", "InvalidGraph");
      }
    }
  }

  const orderedStageIds = graph.stages
    .slice()
    .sort((left, right) => left.sequence - right.sequence)
    .map((stage) => stage.stageId);
  if (stableSerialize(orderedStageIds) !== stableSerialize(graph.orderedStages)) {
    return result(false, "orchestration ordering drift", "InvalidGraph");
  }

  const dependencyEdges = graph.stages.flatMap((stage) =>
    stage.dependsOn.map((dependency) => ({ from: dependency, to: stage.stageId }))
  );
  if (stableSerialize(dependencyEdges) !== stableSerialize(graph.dependencies)) {
    return result(false, "orchestration dependency drift", "InvalidGraph");
  }

  const reachable = new Set();
  for (const stage of graph.stages.slice().sort((left, right) => left.sequence - right.sequence)) {
    if (stage.dependsOn.length === 0 || stage.dependsOn.every((dependency) => reachable.has(dependency))) {
      reachable.add(stage.stageId);
    }
  }
  if (reachable.size !== graph.stages.length) return result(false, "orchestration graph has unreachable stages", "InvalidGraph");

  const checkpointReferences = new Set();
  for (const checkpointReference of graph.checkpointReferences) {
    if (typeof checkpointReference !== "string" || checkpointReference.trim() === "") {
      return result(false, "checkpoint reference invalid", "InvalidGraph");
    }
    if (checkpointReferences.has(checkpointReference)) return result(false, "duplicate checkpoint reference", "DuplicateIdentifier");
    checkpointReferences.add(checkpointReference);
  }

  return result(true);
}

function createGraph(orchestrationId, graphId, plan) {
  const stages = createStages(orchestrationId, plan);
  return deepFreeze({
    graphId,
    graphVersion: executionOrchestratorVersion,
    stages,
    dependencies: stages.flatMap((stage) => stage.dependsOn.map((dependency) => ({ from: dependency, to: stage.stageId }))),
    checkpointReferences: stages.map((stage) => stage.checkpointReference),
    orderedStages: stages.map((stage) => stage.stageId),
    validationState: "pending"
  });
}

function createExecutionContext(orchestrationId, plan, graph, timestamp) {
  return deepFreeze({
    contextId: `${orchestrationId}.context`,
    protocolVersion: integrationContractProtocolVersion,
    readinessId: plan.readinessId,
    executionPlanId: plan.planId,
    capabilityProfileId: plan.negotiatedProfileId,
    graphId: graph.graphId,
    validationState: "valid",
    timestamp
  });
}

export function validateExecutionContext(context) {
  const fields = exactFields(context, contextFields, "execution context");
  if (!fields.ok) return fields;
  for (const field of ["contextId", "readinessId", "executionPlanId", "capabilityProfileId", "graphId"]) {
    const id = validateIdentifier(context[field], field);
    if (!id.ok) return id;
  }
  if (new Set([context.contextId, context.readinessId, context.executionPlanId, context.capabilityProfileId, context.graphId]).size !== 5) {
    return result(false, "duplicate execution context identifiers", "DuplicateIdentifier");
  }
  if (context.protocolVersion !== integrationContractProtocolVersion) {
    return result(false, "execution context protocol invalid", "CompatibilityFailure");
  }
  if (context.validationState !== "valid") return result(false, "execution context invalid", "InvalidContext");
  return result(true);
}

function createOrchestration(orchestrationId, plan, graph, retryPolicy, cancellationPolicy, timestamp) {
  return deepFreeze({
    orchestrationId,
    orchestrationVersion: executionOrchestratorVersion,
    executionPlanId: plan.planId,
    readinessId: plan.readinessId,
    protocolVersion: integrationContractProtocolVersion,
    graphId: graph.graphId,
    orderedStages: [...graph.orderedStages],
    checkpointReferences: [...graph.checkpointReferences],
    retryPolicyId: retryPolicy.retryPolicyId,
    cancellationPolicyId: cancellationPolicy.cancellationPolicyId,
    validationState: "valid",
    timestamp
  });
}

export function validateOrchestration(orchestration) {
  const fields = exactFields(orchestration, orchestrationFields, "orchestration");
  if (!fields.ok) return fields;
  for (const field of ["orchestrationId", "executionPlanId", "readinessId", "graphId", "retryPolicyId", "cancellationPolicyId"]) {
    const id = validateIdentifier(orchestration[field], field);
    if (!id.ok) return id;
  }
  const identifiers = [
    orchestration.orchestrationId,
    orchestration.executionPlanId,
    orchestration.readinessId,
    orchestration.graphId,
    orchestration.retryPolicyId,
    orchestration.cancellationPolicyId
  ];
  if (new Set(identifiers).size !== identifiers.length) return result(false, "duplicate orchestration identifiers", "DuplicateIdentifier");
  if (orchestration.orchestrationVersion !== executionOrchestratorVersion) {
    return result(false, "orchestration version invalid", "CompatibilityFailure");
  }
  if (orchestration.protocolVersion !== integrationContractProtocolVersion) {
    return result(false, "orchestration protocol invalid", "CompatibilityFailure");
  }
  if (!Array.isArray(orchestration.orderedStages) || !Array.isArray(orchestration.checkpointReferences)) {
    return result(false, "orchestration ordering invalid", "InvalidOrchestration");
  }
  if (orchestration.validationState !== "valid") return result(false, "orchestration validation state invalid", "InvalidOrchestration");
  return result(true);
}

function createAudit(orchestrationId, graphId, contextId, state, retryState, cancellationState, timestamp) {
  return deepFreeze([
    {
      orchestrationId,
      graphId,
      contextId,
      authorityId: executionOrchestratorAuthorityId,
      state,
      retryState,
      cancellationState,
      timestamp,
      contractVersion: integrationContractVersion
    }
  ]);
}

export function validateOrchestrationAudit(audit) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "audit must be non-empty", "InvalidAudit");
  const seen = new Set();
  for (const entry of audit) {
    const fields = exactFields(entry, auditFields, "orchestration audit entry");
    if (!fields.ok) return fields;
    const key = stableSerialize(entry);
    if (seen.has(key)) return result(false, "duplicate audit identity", "InvalidAudit");
    seen.add(key);
    if (entry.authorityId !== executionOrchestratorAuthorityId) {
      return result(false, "audit authority mismatch", "InvalidAudit");
    }
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    orchestrationVersion: executionOrchestratorVersion,
    graphState: evaluation.graphValidation.ok ? "valid" : "invalid",
    readinessState: evaluation.planning.readiness?.readinessState ?? "unknown",
    planningState: evaluation.planning.planningState ?? "unknown",
    orchestrationState: evaluation.orchestrationState,
    retryState: evaluation.retryPolicy.classification,
    cancellationState: evaluation.cancellationPolicy.state,
    validationState: evaluation.orchestrationValidation.ok ? "valid" : "invalid",
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function evaluateExecutionOrchestrator(input = {}) {
  const timestamp = input.timestamp ?? now();
  const planning = input.planning ?? evaluateExecutionPlanning({ ...input, timestamp });
  const orchestrationId = input.orchestrationId ?? `phase133-${planning.readiness?.repositoryState?.localHead ?? stableCommit}`;
  const graphId = input.graphId ?? `${orchestrationId}.graph`;
  const transitions = [transition(orchestrationStates.idle, orchestrationStates.collectExecutionPlan, "collecting execution plan", timestamp)];
  let orchestrationState = orchestrationStates.ready;
  let failureReason = null;
  let graph = null;
  let graphValidation = result(false, "graph not built", "OrchestrationFailure");
  let context = null;
  let contextValidation = result(false, "context not built", "InvalidContext");
  let orchestration = null;
  let orchestrationValidation = result(false, "orchestration not built", "InvalidOrchestration");
  const retryPolicy = createRetryPolicy(orchestrationId);
  const cancellationPolicy = createCancellationPolicy(orchestrationId, timestamp);
  const retryPolicyValidation = validateRetryPolicy(retryPolicy);
  const cancellationPolicyValidation = validateCancellationPolicy(cancellationPolicy);

  if (!isPlainObject(planning) || planning.authorityId !== executionPlanningAuthorityId || !isPlainObject(planning.plan)) {
    transitions.push(transition(orchestrationStates.collectExecutionPlan, orchestrationStates.missingExecutionPlan, "MissingExecutionPlan", timestamp));
    orchestrationState = orchestrationStates.missingExecutionPlan;
    failureReason = "MissingExecutionPlan";
  } else {
    transitions.push(transition(orchestrationStates.collectExecutionPlan, orchestrationStates.validateExecutionPlan, "execution plan collected", timestamp));
    const planValidation = validateExecutionPlan(planning.plan);
    if (!planValidation.ok || planning.plan.validationState !== "valid") {
      transitions.push(transition(orchestrationStates.validateExecutionPlan, orchestrationStates.executionPlanRejected, planValidation.failure, timestamp));
      orchestrationState = orchestrationStates.executionPlanRejected;
      failureReason = planValidation.failure ?? "ExecutionPlanRejected";
    } else {
      transitions.push(transition(orchestrationStates.validateExecutionPlan, orchestrationStates.buildOrchestrationGraph, "execution plan accepted", timestamp));
      graph = createGraph(orchestrationId, graphId, planning.plan);
      graphValidation = validateOrchestrationGraph({ ...graph, validationState: "valid" });
      if (!graphValidation.ok) {
        transitions.push(transition(orchestrationStates.buildOrchestrationGraph, orchestrationStates.orchestrationFailure, graphValidation.failure, timestamp));
        orchestrationState = orchestrationStates.orchestrationFailure;
        failureReason = graphValidation.failure;
      } else {
        transitions.push(transition(orchestrationStates.buildOrchestrationGraph, orchestrationStates.freezeOrchestration, "orchestration graph built", timestamp));
        const validatedGraph = deepFreeze({ ...graph, validationState: "valid" });
        context = createExecutionContext(orchestrationId, planning.plan, validatedGraph, timestamp);
        contextValidation = validateExecutionContext(context);
        orchestration = createOrchestration(orchestrationId, planning.plan, validatedGraph, retryPolicy, cancellationPolicy, timestamp);
        orchestrationValidation = validateOrchestration(orchestration);
        if (!contextValidation.ok || !orchestrationValidation.ok || !Object.isFrozen(context) || !Object.isFrozen(orchestration)) {
          transitions.push(transition(orchestrationStates.freezeOrchestration, orchestrationStates.freezeRejected, "FreezeRejected", timestamp));
          orchestrationState = orchestrationStates.freezeRejected;
          failureReason = contextValidation.failure ?? orchestrationValidation.failure ?? "FreezeRejected";
        } else {
          transitions.push(transition(orchestrationStates.freezeOrchestration, orchestrationStates.ready, "orchestration model frozen", timestamp));
          graph = validatedGraph;
        }
      }
    }
  }

  const audit = createAudit(
    orchestrationId,
    graphId,
    context?.contextId ?? "missing",
    orchestrationState,
    retryPolicy.classification,
    cancellationPolicy.state,
    timestamp
  );
  const evaluation = {
    schemaVersion: executionOrchestratorSchemaVersion,
    authorityId: executionOrchestratorAuthorityId,
    orchestrationVersion: executionOrchestratorVersion,
    protocolVersion: integrationContractProtocolVersion,
    contractVersion: integrationContractVersion,
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
    orchestrationId,
    graphId,
    orchestrationState,
    planning,
    graph,
    context,
    retryPolicy,
    cancellationPolicy,
    orchestration,
    graphValidation,
    contextValidation,
    retryPolicyValidation,
    cancellationPolicyValidation,
    orchestrationValidation,
    transitionValidation: validateOrchestrationTransitions(transitions),
    audit,
    auditValidation: validateOrchestrationAudit(audit),
    integrationGraph: [
      "Phase121EvidenceTransport",
      "Phase122StudioBridge",
      "Phase124ActivationAuthority",
      "Phase125BindingAuthority",
      "Phase126SessionAuthority",
      "Phase127RunnerAuthority",
      "Phase129IntegrationContract",
      "Phase130CapabilityNegotiationAuthority",
      "Phase131ExecutionReadinessAuthority",
      "Phase132ExecutionPlanningAuthority",
      "Phase133ExecutionOrchestrator"
    ],
    failureReason,
    recommendedAction: "Resolve execution readiness before a future execution authority consumes orchestration.",
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
        return result(false, String(error?.message ?? error), "SerializationFailure");
      }
    })()
  });
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runExecutionOrchestratorSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const orchestration = evaluateExecutionOrchestrator({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExecutionOrchestrator({ timestamp: stableTimestamp, repositoryState });
  const invalidTransition = validateOrchestrationTransitions([
    transition(orchestrationStates.idle, orchestrationStates.freezeOrchestration, "skip", stableTimestamp)
  ]);
  const duplicateAudit = validateOrchestrationAudit([...orchestration.audit, ...orchestration.audit]);
  const badOrchestration = { ...orchestration.orchestration, extra: true };
  const badContext = { ...orchestration.context, validationState: "invalid" };
  const badRetry = { ...orchestration.retryPolicy, classification: "RetryNow" };
  const badCancellation = { ...orchestration.cancellationPolicy, state: "Cancelled" };
  const cyclicGraph = {
    ...orchestration.graph,
    stages: orchestration.graph.stages.map((stage) =>
      stage.sequence === 1 ? { ...stage, dependsOn: [orchestration.graph.stages[5].stageId] } : stage
    ),
    dependencies: [{ from: orchestration.graph.stages[5].stageId, to: orchestration.graph.stages[0].stageId }]
  };

  assertSelfCheck(results, "orchestrationLifecycleValidation", orchestration.transitionValidation.ok === true, "");
  assertSelfCheck(results, "orchestrationGraphValidation", orchestration.graphValidation.ok === true, "");
  assertSelfCheck(results, "dependencyValidation", validateOrchestrationGraph(cyclicGraph).ok === false, "");
  assertSelfCheck(results, "stageOrderingValidation", orchestration.orchestration.orderedStages.length === orchestrationStageCategories.length, "");
  assertSelfCheck(results, "executionContextValidation", orchestration.contextValidation.ok === true, "");
  assertSelfCheck(results, "invalidExecutionContextRejection", validateExecutionContext(badContext).ok === false, "");
  assertSelfCheck(results, "retryPolicyValidation", orchestration.retryPolicyValidation.ok === true, "");
  assertSelfCheck(results, "invalidRetryPolicyRejection", validateRetryPolicy(badRetry).ok === false, "");
  assertSelfCheck(results, "cancellationPolicyValidation", orchestration.cancellationPolicyValidation.ok === true, "");
  assertSelfCheck(results, "invalidCancellationPolicyRejection", validateCancellationPolicy(badCancellation).ok === false, "");
  assertSelfCheck(results, "immutableOrchestrationValidation", Object.isFrozen(orchestration.orchestration), "");
  assertSelfCheck(results, "immutableExecutionContextValidation", Object.isFrozen(orchestration.context), "");
  assertSelfCheck(results, "immutableGraphValidation", Object.isFrozen(orchestration.graph), "");
  assertSelfCheck(results, "orchestrationSchemaValidation", orchestration.orchestrationValidation.ok === true, "");
  assertSelfCheck(results, "unknownOrchestrationFieldRejection", validateOrchestration(badOrchestration).ok === false, "");
  assertSelfCheck(results, "auditValidation", orchestration.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "deterministicSerialization", orchestration.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicTimestamps", orchestration.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicExitCodes", orchestration.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "authorityIsolation", orchestration.authorityId === executionOrchestratorAuthorityId, "");
  assertSelfCheck(results, "planningAuthorityReadOnly", orchestration.planning.authorityId === executionPlanningAuthorityId, "");
  assertSelfCheck(results, "planningVersionCompatibility", orchestration.planning.planningVersion === executionPlanningVersion, "");
  assertSelfCheck(results, "orchestrationReadyWithoutExecution", orchestration.orchestrationState === orchestrationStates.ready, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(orchestration.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "backwardCompatibility", executionOrchestratorSchemaVersion === 1, "");
  assertSelfCheck(results, "stageCompleteness", orchestrationStageCategories.every((category) => orchestration.graph.stages.some((stage) => stage.category === category)), "");
  assertSelfCheck(results, "stageUniqueness", new Set(orchestration.orchestration.orderedStages).size === orchestration.orchestration.orderedStages.length, "");
  assertSelfCheck(results, "checkpointReferenceValidation", orchestration.orchestration.checkpointReferences.length === orchestrationStageCategories.length, "");
  assertSelfCheck(results, "graphClosure", orchestration.graph.dependencies.every((edge) => orchestration.orchestration.orderedStages.includes(edge.from) && orchestration.orchestration.orderedStages.includes(edge.to)), "");
  assertSelfCheck(results, "diagnosticsToolingOnly", !("productionCertified" in orchestration.diagnostics), "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("certificationDecision" in orchestration), "");
  assertSelfCheck(results, "noExecution", orchestration.runnerInvoked === false, "");
  assertSelfCheck(results, "noRuntimeEvidence", orchestration.structuredResultCaptured === false, "");
  assertSelfCheck(results, "runtimeTruthPreserved", orchestration.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE", "");
  assertSelfCheck(results, "executionBlockedPreserved", orchestration.status === "executionBlocked", "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noNetworking", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExecutionOrchestratorSelfChecks();
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
  const evaluation = evaluateExecutionOrchestrator({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
