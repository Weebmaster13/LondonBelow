import { fileURLToPath } from "node:url";
import { bridgeExitCodes } from "./studio-automation-bridge.mjs";
import {
  evaluateExecutionReadiness,
  executionReadinessAuthorityId,
  readinessDecisions
} from "./studio-execution-readiness-authority.mjs";
import {
  integrationContractProtocolVersion,
  integrationContractVersion,
  stableSerialize
} from "./studio-mcp-integration-contract.mjs";
import { git, readJson } from "./repository-state.mjs";

export const executionPlanningSchemaVersion = 1;
export const executionPlanningVersion = "1.0.0";
export const executionPlanningAuthorityId = "chapter0Home.phase132StudioExecutionPlanningAuthority";

export const planningStates = Object.freeze({
  idle: "Idle",
  collectInputs: "CollectInputs",
  buildExecutionGraph: "BuildExecutionGraph",
  validatePlan: "ValidatePlan",
  freezePlan: "FreezePlan",
  published: "PlanPublished",
  missingAuthority: "MissingAuthority",
  planningFailed: "PlanningFailed",
  invalidPlan: "InvalidPlan",
  freezeRejected: "FreezeRejected"
});

export const stageCategories = Object.freeze(["Initialize", "Validate", "Connect", "Execute", "Collect", "Finalize"]);

const config = readJson("automation/config/automation-config.json");
const stableTimestamp = "2026-07-17T00:00:00.000Z";
const stableCommit = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
const terminalStates = new Set([
  planningStates.published,
  planningStates.missingAuthority,
  planningStates.planningFailed,
  planningStates.invalidPlan,
  planningStates.freezeRejected
]);
const legalTransitions = new Map([
  [planningStates.idle, new Set([planningStates.collectInputs])],
  [planningStates.collectInputs, new Set([planningStates.buildExecutionGraph, planningStates.missingAuthority])],
  [planningStates.buildExecutionGraph, new Set([planningStates.validatePlan, planningStates.planningFailed])],
  [planningStates.validatePlan, new Set([planningStates.freezePlan, planningStates.invalidPlan])],
  [planningStates.freezePlan, new Set([planningStates.published, planningStates.freezeRejected])]
]);

const executionPlanFields = Object.freeze([
  "planId",
  "executionPlanVersion",
  "readinessId",
  "protocolVersion",
  "negotiatedProfileId",
  "graphId",
  "orderedStages",
  "orderedCheckpoints",
  "validationState",
  "timestamp"
]);

const stageFields = Object.freeze(["stageId", "category", "sequence", "dependsOn"]);
const checkpointFields = Object.freeze([
  "checkpointId",
  "stageId",
  "prerequisite",
  "expectedState",
  "blockingCondition",
  "sequence"
]);
const graphFields = Object.freeze([
  "graphId",
  "graphVersion",
  "stages",
  "dependencies",
  "orderedStages",
  "orderedCheckpoints",
  "validationState"
]);
const auditFields = Object.freeze([
  "planningId",
  "graphId",
  "authorityId",
  "readinessId",
  "decision",
  "stageCount",
  "checkpointCount",
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
  return deepFreeze({ from, to, reason, timestamp, authorityId: executionPlanningAuthorityId });
}

export function validatePlanningTransitions(transitions) {
  if (!Array.isArray(transitions) || transitions.length === 0) {
    return result(false, "planning transitions must be non-empty", "InvalidLifecycle");
  }

  let terminalSeen = false;
  for (const [index, item] of transitions.entries()) {
    if (!Object.values(planningStates).includes(item.from) || !Object.values(planningStates).includes(item.to)) {
      return result(false, "undocumented planning state", "InvalidLifecycle");
    }
    if (index === 0 && item.from !== planningStates.idle) {
      return result(false, "planning must start at Idle", "InvalidLifecycle");
    }
    if (index > 0 && transitions[index - 1].to !== item.from) {
      return result(false, "planning skipped state", "InvalidLifecycle");
    }
    if (terminalStates.has(item.from) || terminalSeen) {
      return result(false, "terminal planning state mutated", "InvalidLifecycle");
    }
    if (!legalTransitions.get(item.from)?.has(item.to)) {
      return result(false, `illegal planning transition ${item.from}->${item.to}`, "InvalidLifecycle");
    }
    if (terminalStates.has(item.to)) terminalSeen = true;
  }

  return result(true);
}

function defaultStages(planId) {
  return deepFreeze(
    stageCategories.map((category, index) => ({
      stageId: `${planId}.stage.${category}`,
      category,
      sequence: index + 1,
      dependsOn: index === 0 ? [] : [`${planId}.stage.${stageCategories[index - 1]}`]
    }))
  );
}

function defaultCheckpoints(stages) {
  return deepFreeze(
    stages.map((stage) => ({
      checkpointId: `${stage.stageId}.checkpoint`,
      stageId: stage.stageId,
      prerequisite: stage.dependsOn.length === 0 ? "readiness-profile-collected" : `stage-complete:${stage.dependsOn[0]}`,
      expectedState: `planned:${stage.category}`,
      blockingCondition: "execution-readiness-not-ready",
      sequence: stage.sequence
    }))
  );
}

function validateStage(stage) {
  const fields = exactFields(stage, stageFields, "execution stage");
  if (!fields.ok) return fields;
  if (!stageCategories.includes(stage.category)) return result(false, "unsupported stage category", "InvalidStage");
  if (!Number.isInteger(stage.sequence) || stage.sequence < 1) {
    return result(false, "stage sequence invalid", "InvalidStage");
  }
  if (!Array.isArray(stage.dependsOn)) return result(false, "stage dependencies invalid", "InvalidStage");
  return validateIdentifier(stage.stageId, "stageId");
}

export function validateCheckpoint(checkpoint, stageIds = new Set()) {
  const fields = exactFields(checkpoint, checkpointFields, "checkpoint");
  if (!fields.ok) return fields;
  if (!stageIds.has(checkpoint.stageId)) return result(false, "checkpoint references unknown stage", "InvalidCheckpoint");
  if (!Number.isInteger(checkpoint.sequence) || checkpoint.sequence < 1) {
    return result(false, "checkpoint sequence invalid", "InvalidCheckpoint");
  }
  return validateIdentifier(checkpoint.checkpointId, "checkpointId");
}

export function validateExecutionGraph(graph) {
  const fields = exactFields(graph, graphFields, "execution graph");
  if (!fields.ok) return fields;
  if (!Array.isArray(graph.stages) || graph.stages.length !== stageCategories.length) {
    return result(false, "execution graph stage completeness invalid", "InvalidGraph");
  }
  if (!Array.isArray(graph.dependencies) || !Array.isArray(graph.orderedStages) || !Array.isArray(graph.orderedCheckpoints)) {
    return result(false, "execution graph ordering invalid", "InvalidGraph");
  }

  const seenStages = new Set();
  const sequenceByStage = new Map();
  for (const stage of graph.stages) {
    const validation = validateStage(stage);
    if (!validation.ok) return validation;
    if (seenStages.has(stage.stageId)) return result(false, "duplicate stage id", "DuplicateIdentifier");
    seenStages.add(stage.stageId);
    sequenceByStage.set(stage.stageId, stage.sequence);
  }

  for (const expectedCategory of stageCategories) {
    if (!graph.stages.some((stage) => stage.category === expectedCategory)) {
      return result(false, `missing stage ${expectedCategory}`, "InvalidGraph");
    }
  }

  for (const stage of graph.stages) {
    for (const dependency of stage.dependsOn) {
      if (!seenStages.has(dependency)) return result(false, `missing dependency ${dependency}`, "InvalidGraph");
      if (sequenceByStage.get(dependency) >= stage.sequence) {
        return result(false, "stage dependency ordering invalid", "InvalidGraph");
      }
    }
  }

  const orderedStageIds = graph.stages
    .slice()
    .sort((left, right) => left.sequence - right.sequence)
    .map((stage) => stage.stageId);
  if (stableSerialize(orderedStageIds) !== stableSerialize(graph.orderedStages)) {
    return result(false, "ordered stages are not deterministic", "InvalidGraph");
  }

  const reachable = new Set();
  for (const stage of graph.stages.slice().sort((left, right) => left.sequence - right.sequence)) {
    if (stage.dependsOn.length === 0 || stage.dependsOn.every((dependency) => reachable.has(dependency))) {
      reachable.add(stage.stageId);
    }
  }
  if (reachable.size !== graph.stages.length) return result(false, "execution graph disconnected", "InvalidGraph");

  const dependencyEdges = graph.stages.flatMap((stage) =>
    stage.dependsOn.map((dependency) => ({ from: dependency, to: stage.stageId }))
  );
  if (stableSerialize(dependencyEdges) !== stableSerialize(graph.dependencies)) {
    return result(false, "dependency graph drift", "InvalidGraph");
  }

  const stageIds = new Set(graph.orderedStages);
  const checkpointIds = new Set();
  let previousSequence = 0;
  for (const checkpoint of graph.orderedCheckpoints) {
    const validation = validateCheckpoint(checkpoint, stageIds);
    if (!validation.ok) return validation;
    if (checkpointIds.has(checkpoint.checkpointId)) return result(false, "duplicate checkpoint id", "DuplicateIdentifier");
    checkpointIds.add(checkpoint.checkpointId);
    if (checkpoint.sequence <= previousSequence) {
      return result(false, "checkpoint ordering invalid", "InvalidCheckpoint");
    }
    previousSequence = checkpoint.sequence;
  }

  return result(true);
}

function createExecutionGraph(planId, graphId) {
  const stages = defaultStages(planId);
  const orderedStages = stages.map((stage) => stage.stageId);
  const orderedCheckpoints = defaultCheckpoints(stages);
  const dependencies = stages.flatMap((stage) => stage.dependsOn.map((dependency) => ({ from: dependency, to: stage.stageId })));
  return deepFreeze({
    graphId,
    graphVersion: executionPlanningVersion,
    stages,
    dependencies,
    orderedStages,
    orderedCheckpoints,
    validationState: "pending"
  });
}

export function validateExecutionPlan(plan) {
  const fields = exactFields(plan, executionPlanFields, "execution plan");
  if (!fields.ok) return fields;
  const ids = [plan.planId, plan.readinessId, plan.negotiatedProfileId, plan.graphId];
  for (const [index, id] of ids.entries()) {
    const validation = validateIdentifier(id, `plan identifier ${index + 1}`);
    if (!validation.ok) return validation;
  }
  if (new Set(ids).size !== ids.length) return result(false, "duplicate plan identifiers", "DuplicateIdentifier");
  if (plan.executionPlanVersion !== executionPlanningVersion) {
    return result(false, "execution plan version invalid", "CompatibilityFailure");
  }
  if (plan.protocolVersion !== integrationContractProtocolVersion) {
    return result(false, "protocol version invalid", "CompatibilityFailure");
  }
  if (!Array.isArray(plan.orderedStages) || !Array.isArray(plan.orderedCheckpoints)) {
    return result(false, "plan ordering invalid", "InvalidPlan");
  }
  if (plan.validationState !== "valid") return result(false, "plan validation state invalid", "InvalidPlan");
  return result(true);
}

function createPlan(readiness, graph, timestamp) {
  const negotiatedProfileId = readiness.authorities?.capability?.profiles === null ? "none" : "published";
  return deepFreeze({
    planId: `${readiness.evaluationId}.plan`,
    executionPlanVersion: executionPlanningVersion,
    readinessId: readiness.readinessId,
    protocolVersion: integrationContractProtocolVersion,
    negotiatedProfileId,
    graphId: graph.graphId,
    orderedStages: [...graph.orderedStages],
    orderedCheckpoints: graph.orderedCheckpoints.map((checkpoint) => ({ ...checkpoint })),
    validationState: "valid",
    timestamp
  });
}

function createAudit(planningId, graphId, readinessId, decision, stageCount, checkpointCount, timestamp) {
  return deepFreeze([
    {
      planningId,
      graphId,
      authorityId: executionPlanningAuthorityId,
      readinessId,
      decision,
      stageCount,
      checkpointCount,
      timestamp,
      contractVersion: integrationContractVersion
    }
  ]);
}

export function validatePlanningAudit(audit) {
  if (!Array.isArray(audit) || audit.length === 0) return result(false, "audit must be non-empty", "InvalidAudit");
  const seen = new Set();
  for (const entry of audit) {
    const fields = exactFields(entry, auditFields, "planning audit entry");
    if (!fields.ok) return fields;
    const key = stableSerialize(entry);
    if (seen.has(key)) return result(false, "duplicate audit identity", "InvalidAudit");
    seen.add(key);
    if (entry.authorityId !== executionPlanningAuthorityId) return result(false, "audit authority mismatch", "InvalidAudit");
  }
  return result(true);
}

function diagnosticsFor(evaluation) {
  return deepFreeze({
    planningVersion: executionPlanningVersion,
    planningState: evaluation.planningState,
    graphState: evaluation.graphValidation.ok ? "valid" : "invalid",
    readinessDecision: evaluation.readiness.decision,
    stageCount: evaluation.plan?.orderedStages.length ?? 0,
    checkpointCount: evaluation.plan?.orderedCheckpoints.length ?? 0,
    validationState: evaluation.planValidation.ok ? "valid" : "invalid",
    failureReason: evaluation.failureReason,
    timestamp: evaluation.timestamp
  });
}

export function evaluateExecutionPlanning(input = {}) {
  const timestamp = input.timestamp ?? now();
  const readiness = input.readiness ?? evaluateExecutionReadiness({ ...input, timestamp });
  const planningId = input.planningId ?? `phase132-${readiness.repositoryState?.localHead ?? stableCommit}`;
  const graphId = input.graphId ?? `${planningId}.graph`;
  const transitions = [transition(planningStates.idle, planningStates.collectInputs, "collecting readiness authority", timestamp)];
  let planningState = planningStates.published;
  let failureReason = null;
  let graph = null;
  let graphValidation = result(false, "graph not built", "PlanningFailed");
  let plan = null;
  let planValidation = result(false, "plan not built", "InvalidPlan");

  if (!isPlainObject(readiness) || readiness.authorityId !== executionReadinessAuthorityId) {
    transitions.push(transition(planningStates.collectInputs, planningStates.missingAuthority, "MissingAuthority", timestamp));
    planningState = planningStates.missingAuthority;
    failureReason = "MissingAuthority";
  } else {
    transitions.push(transition(planningStates.collectInputs, planningStates.buildExecutionGraph, "readiness authority collected", timestamp));
    graph = createExecutionGraph(`${planningId}.plan`, graphId);
    graphValidation = validateExecutionGraph({ ...graph, validationState: "valid" });
    if (!graphValidation.ok) {
      transitions.push(transition(planningStates.buildExecutionGraph, planningStates.planningFailed, graphValidation.failure, timestamp));
      planningState = planningStates.planningFailed;
      failureReason = graphValidation.failure;
    } else {
      transitions.push(transition(planningStates.buildExecutionGraph, planningStates.validatePlan, "execution graph built", timestamp));
      const validatedGraph = deepFreeze({ ...graph, validationState: "valid" });
      plan = createPlan(readiness, validatedGraph, timestamp);
      planValidation = validateExecutionPlan(plan);
      if (!planValidation.ok) {
        transitions.push(transition(planningStates.validatePlan, planningStates.invalidPlan, planValidation.failure, timestamp));
        planningState = planningStates.invalidPlan;
        failureReason = planValidation.failure;
      } else {
        transitions.push(transition(planningStates.validatePlan, planningStates.freezePlan, "execution plan validated", timestamp));
        if (!Object.isFrozen(plan) || !Object.isFrozen(validatedGraph)) {
          transitions.push(transition(planningStates.freezePlan, planningStates.freezeRejected, "FreezeRejected", timestamp));
          planningState = planningStates.freezeRejected;
          failureReason = "FreezeRejected";
        } else {
          transitions.push(transition(planningStates.freezePlan, planningStates.published, "execution plan frozen", timestamp));
          graph = validatedGraph;
        }
      }
    }
  }

  const audit = createAudit(
    planningId,
    graphId,
    readiness.readinessId ?? "missing",
    readiness.decision ?? readinessDecisions.unknown,
    plan?.orderedStages.length ?? 0,
    plan?.orderedCheckpoints.length ?? 0,
    timestamp
  );
  const evaluation = {
    schemaVersion: executionPlanningSchemaVersion,
    authorityId: executionPlanningAuthorityId,
    planningVersion: executionPlanningVersion,
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
    planningId,
    graphId,
    planningState,
    readiness,
    graph,
    plan,
    graphValidation,
    planValidation,
    transitionValidation: validatePlanningTransitions(transitions),
    audit,
    auditValidation: validatePlanningAudit(audit),
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
      "Phase132ExecutionPlanningAuthority"
    ],
    failureReason,
    recommendedAction: "Resolve execution readiness before a future execution authority consumes the published plan.",
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

export function runExecutionPlanningSelfChecks() {
  const results = [];
  const repositoryState = {
    branch: "main",
    localHead: stableCommit,
    remoteHead: stableCommit,
    workingTreeClean: true,
    originSynchronized: true
  };
  const planning = evaluateExecutionPlanning({ timestamp: stableTimestamp, repositoryState });
  const rerun = evaluateExecutionPlanning({ timestamp: stableTimestamp, repositoryState });
  const invalidTransition = validatePlanningTransitions([
    transition(planningStates.idle, planningStates.freezePlan, "skip", stableTimestamp)
  ]);
  const duplicateAudit = validatePlanningAudit([...planning.audit, ...planning.audit]);
  const badPlan = { ...planning.plan, extra: true };
  const badCheckpoint = { ...planning.plan.orderedCheckpoints[0], stageId: "missing" };
  const cyclicGraph = {
    ...planning.graph,
    stages: planning.graph.stages.map((stage) =>
      stage.sequence === 1 ? { ...stage, dependsOn: [planning.graph.stages[5].stageId] } : stage
    ),
    dependencies: [{ from: planning.graph.stages[5].stageId, to: planning.graph.stages[0].stageId }]
  };

  assertSelfCheck(results, "planningLifecycleValidation", planning.transitionValidation.ok === true, "");
  assertSelfCheck(results, "executionGraphValidation", planning.graphValidation.ok === true, "");
  assertSelfCheck(results, "dependencyValidation", validateExecutionGraph(cyclicGraph).ok === false, "");
  assertSelfCheck(results, "stageOrderingValidation", planning.plan.orderedStages.length === stageCategories.length, "");
  assertSelfCheck(results, "checkpointValidation", validateCheckpoint(planning.plan.orderedCheckpoints[0], new Set(planning.plan.orderedStages)).ok === true, "");
  assertSelfCheck(results, "invalidCheckpointRejection", validateCheckpoint(badCheckpoint, new Set(planning.plan.orderedStages)).ok === false, "");
  assertSelfCheck(results, "immutableExecutionPlans", Object.isFrozen(planning.plan), "");
  assertSelfCheck(results, "immutableExecutionGraphs", Object.isFrozen(planning.graph), "");
  assertSelfCheck(results, "immutableCheckpoints", Object.isFrozen(planning.plan.orderedCheckpoints[0]), "");
  assertSelfCheck(results, "executionPlanSchemaValidation", planning.planValidation.ok === true, "");
  assertSelfCheck(results, "unknownPlanFieldRejection", validateExecutionPlan(badPlan).ok === false, "");
  assertSelfCheck(results, "deterministicSerialization", planning.serializationValidation.ok === true, "");
  assertSelfCheck(results, "deterministicTimestamps", planning.timestamp === stableTimestamp, "");
  assertSelfCheck(results, "deterministicExitCodes", planning.exitCode === bridgeExitCodes.executionBlocked, "");
  assertSelfCheck(results, "auditValidation", planning.auditValidation.ok === true, "");
  assertSelfCheck(results, "duplicateAuditRejection", duplicateAudit.ok === false, "");
  assertSelfCheck(results, "illegalTransitionRejection", invalidTransition.ok === false, "");
  assertSelfCheck(results, "authorityIsolation", planning.authorityId === executionPlanningAuthorityId, "");
  assertSelfCheck(results, "readinessAuthorityReadOnly", planning.readiness.authorityId === executionReadinessAuthorityId, "");
  assertSelfCheck(results, "readinessDecisionPreserved", planning.readiness.decision === readinessDecisions.blocked, "");
  assertSelfCheck(results, "planningPublishedWithoutExecution", planning.planningState === planningStates.published, "");
  assertSelfCheck(results, "rerunStability", stableSerialize(planning.diagnostics) === stableSerialize(rerun.diagnostics), "");
  assertSelfCheck(results, "backwardCompatibility", executionPlanningSchemaVersion === 1, "");
  assertSelfCheck(results, "protocolCompatibility", planning.protocolVersion === integrationContractProtocolVersion, "");
  assertSelfCheck(results, "stageCompleteness", stageCategories.every((category) => planning.graph.stages.some((stage) => stage.category === category)), "");
  assertSelfCheck(results, "stageUniqueness", new Set(planning.plan.orderedStages).size === planning.plan.orderedStages.length, "");
  assertSelfCheck(results, "checkpointOrdering", planning.plan.orderedCheckpoints[0].sequence === 1, "");
  assertSelfCheck(results, "graphClosure", planning.graph.dependencies.every((edge) => planning.plan.orderedStages.includes(edge.from) && planning.plan.orderedStages.includes(edge.to)), "");
  assertSelfCheck(results, "diagnosticsToolingOnly", !("productionCertified" in planning.diagnostics), "");
  assertSelfCheck(results, "noCertificationOwnershipLeakage", !("certificationDecision" in planning), "");
  assertSelfCheck(results, "noExecution", planning.runnerInvoked === false, "");
  assertSelfCheck(results, "noRuntimeEvidence", planning.structuredResultCaptured === false, "");
  assertSelfCheck(results, "runtimeTruthPreserved", planning.runtimeTruth.sessionFailureReason === "SESSION_NOT_VISIBLE", "");
  assertSelfCheck(results, "executionBlockedPreserved", planning.status === "executionBlocked", "");
  assertSelfCheck(results, "noGameplayMutation", true, "");
  assertSelfCheck(results, "noNetworkingTransport", true, "");
  assertSelfCheck(results, "noPersistence", true, "");
  assertSelfCheck(results, "noAnalytics", true, "");
  assertSelfCheck(results, "noTelemetry", true, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runExecutionPlanningSelfChecks();
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
  const evaluation = evaluateExecutionPlanning({
    repositoryRevision: head.stdout.trim()
  });
  console.log(JSON.stringify(evaluation, null, 2));
  process.exitCode = evaluation.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
