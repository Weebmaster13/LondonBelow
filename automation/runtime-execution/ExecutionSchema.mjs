import {
  assertionStatuses,
  backendAvailabilityStatuses,
  capabilityStatuses,
  evidenceCategories,
  executionBackends,
  executionStatusValues
} from "./ExecutionStatus.mjs";
import {
  runtimeExecutionFrameworkId,
  runtimeExecutionFrameworkVersion,
  runtimeExecutionProtocolVersion,
  runtimeExecutionSchemaVersion
} from "./ExecutionVersion.mjs";
import { exactFields, isPlainObject, result, validateIdentifier } from "./ExecutionUtilities.mjs";

export const sessionFields = Object.freeze([
  "schemaVersion",
  "frameworkId",
  "frameworkVersion",
  "protocolVersion",
  "sessionId",
  "phase",
  "phaseName",
  "repositoryCommit",
  "branch",
  "backend",
  "environment",
  "participants",
  "capabilities",
  "status",
  "lifecycle",
  "timestamps",
  "artifacts",
  "evidence",
  "assertions",
  "errors",
  "warnings",
  "cleanup",
  "summary",
  "history"
]);

export const manifestFields = Object.freeze([
  "schemaVersion",
  "frameworkId",
  "frameworkVersion",
  "manifestId",
  "sessionId",
  "phase",
  "phaseName",
  "backend",
  "targets",
  "policies",
  "environment",
  "capabilities",
  "evidenceCategories",
  "artifactPlan",
  "createdAt"
]);

export const backendFields = Object.freeze([
  "backendId",
  "backendKind",
  "availability",
  "canLaunch",
  "canCaptureStructuredResults",
  "canReplay",
  "requiresHuman",
  "reason"
]);

export const assertionFields = Object.freeze(["assertionId", "name", "status", "category", "message"]);

export const evidenceFields = Object.freeze(["category", "status", "source", "artifactIds", "notes"]);

export const cleanupFields = Object.freeze(["registered", "started", "completed", "artifactIds", "warnings"]);

export const summaryFields = Object.freeze([
  "status",
  "sessionId",
  "phase",
  "backend",
  "runtimeEvidenceClaimed",
  "certificationDecisionMade",
  "totalAssertions",
  "failedAssertions",
  "blockedAssertions",
  "notExecutedAssertions",
  "nextAction"
]);

function validateEnum(value, allowed, label) {
  return allowed.includes(value) ? result(true) : result(false, `${label} unsupported`, "UnsupportedValue");
}

export function validateBackendContract(backend) {
  const fields = exactFields(backend, backendFields, "backend contract");
  if (!fields.ok) return fields;
  const id = validateIdentifier(backend.backendId, "backendId");
  if (!id.ok) return id;
  const kind = validateEnum(backend.backendKind, executionBackends, "backendKind");
  if (!kind.ok) return kind;
  const availability = validateEnum(backend.availability, backendAvailabilityStatuses, "backend availability");
  if (!availability.ok) return availability;
  for (const field of ["canLaunch", "canCaptureStructuredResults", "canReplay", "requiresHuman"]) {
    if (typeof backend[field] !== "boolean") {
      return result(false, `${field} must be boolean`, "SchemaMismatch");
    }
  }
  if (typeof backend.reason !== "string" || backend.reason.trim() === "") {
    return result(false, "backend reason invalid", "InvalidReason");
  }
  return result(true);
}

export function validateCapability(capability) {
  const fields = exactFields(capability, ["capabilityId", "status", "source", "reason"], "capability");
  if (!fields.ok) return fields;
  const id = validateIdentifier(capability.capabilityId, "capabilityId");
  if (!id.ok) return id;
  const status = validateEnum(capability.status, capabilityStatuses, "capability status");
  if (!status.ok) return status;
  if (typeof capability.source !== "string" || capability.source.trim() === "") {
    return result(false, "capability source invalid", "InvalidCapability");
  }
  if (typeof capability.reason !== "string" || capability.reason.trim() === "") {
    return result(false, "capability reason invalid", "InvalidCapability");
  }
  return result(true);
}

export function validateAssertion(assertion) {
  const fields = exactFields(assertion, assertionFields, "assertion");
  if (!fields.ok) return fields;
  const id = validateIdentifier(assertion.assertionId, "assertionId");
  if (!id.ok) return id;
  const status = validateEnum(assertion.status, assertionStatuses, "assertion status");
  if (!status.ok) return status;
  if (typeof assertion.name !== "string" || assertion.name.trim() === "") {
    return result(false, "assertion name invalid", "InvalidAssertion");
  }
  if (!evidenceCategories.includes(assertion.category)) {
    return result(false, "assertion category unsupported", "InvalidAssertion");
  }
  if (typeof assertion.message !== "string") {
    return result(false, "assertion message invalid", "InvalidAssertion");
  }
  return result(true);
}

export function validateEvidenceRecord(evidence) {
  const fields = exactFields(evidence, evidenceFields, "evidence record");
  if (!fields.ok) return fields;
  if (!evidenceCategories.includes(evidence.category)) {
    return result(false, "evidence category unsupported", "InvalidEvidence");
  }
  if (!["Recorded", "Blocked", "NotExecuted"].includes(evidence.status)) {
    return result(false, "evidence status unsupported", "InvalidEvidence");
  }
  if (typeof evidence.source !== "string" || evidence.source.trim() === "") {
    return result(false, "evidence source invalid", "InvalidEvidence");
  }
  if (!Array.isArray(evidence.artifactIds) || !Array.isArray(evidence.notes)) {
    return result(false, "evidence arrays invalid", "InvalidEvidence");
  }
  return result(true);
}

export function validateSummary(summary) {
  const fields = exactFields(summary, summaryFields, "execution summary");
  if (!fields.ok) return fields;
  if (summary.runtimeEvidenceClaimed !== false) {
    return result(false, "Phase 151 cannot claim runtime evidence", "BoundaryViolation");
  }
  if (summary.certificationDecisionMade !== false) {
    return result(false, "Runtime Execution Framework cannot make certification decisions", "BoundaryViolation");
  }
  return result(true);
}

export function validateLifecycle(lifecycle) {
  if (!Array.isArray(lifecycle) || lifecycle.length === 0) {
    return result(false, "lifecycle must be non-empty", "InvalidLifecycle");
  }

  const allowed = Object.values(executionStatusValues);
  for (const [index, entry] of lifecycle.entries()) {
    const fields = exactFields(entry, ["from", "to", "reason", "timestamp"], "lifecycle entry");
    if (!fields.ok) return fields;
    if (index === 0 && entry.from !== executionStatusValues.executionRequested) {
      return result(false, "lifecycle must start at ExecutionRequested", "InvalidLifecycle");
    }
    if (index > 0 && lifecycle[index - 1].to !== entry.from) {
      return result(false, "lifecycle discontinuity", "InvalidLifecycle");
    }
    if (!allowed.includes(entry.from) || !allowed.includes(entry.to)) {
      return result(false, "undocumented lifecycle status", "InvalidLifecycle");
    }
  }

  return result(true);
}

export function validateExecutionManifest(manifest) {
  const fields = exactFields(manifest, manifestFields, "execution manifest");
  if (!fields.ok) return fields;
  if (manifest.schemaVersion !== runtimeExecutionSchemaVersion || manifest.frameworkId !== runtimeExecutionFrameworkId) {
    return result(false, "manifest identity mismatch", "SchemaMismatch");
  }
  if (manifest.frameworkVersion !== runtimeExecutionFrameworkVersion) {
    return result(false, "manifest version mismatch", "SchemaMismatch");
  }
  if (!evidenceCategories.every((category) => manifest.evidenceCategories.includes(category))) {
    return result(false, "manifest evidence categories incomplete", "InvalidManifest");
  }
  return validateIdentifier(manifest.manifestId, "manifestId");
}

export function validateExecutionSession(session) {
  const fields = exactFields(session, sessionFields, "execution session");
  if (!fields.ok) return fields;
  if (session.schemaVersion !== runtimeExecutionSchemaVersion || session.frameworkId !== runtimeExecutionFrameworkId) {
    return result(false, "session identity mismatch", "SchemaMismatch");
  }
  if (session.frameworkVersion !== runtimeExecutionFrameworkVersion || session.protocolVersion !== runtimeExecutionProtocolVersion) {
    return result(false, "session version mismatch", "SchemaMismatch");
  }
  for (const field of ["sessionId", "repositoryCommit", "branch", "backend", "status"]) {
    const id = validateIdentifier(session[field], field);
    if (!id.ok) return id;
  }
  if (!Number.isInteger(session.phase) || session.phase < 1) {
    return result(false, "session phase invalid", "InvalidPhase");
  }
  if (!Object.values(executionStatusValues).includes(session.status)) {
    return result(false, "session status unsupported", "InvalidStatus");
  }
  const lifecycle = validateLifecycle(session.lifecycle);
  if (!lifecycle.ok) return lifecycle;
  for (const capability of session.capabilities) {
    const validation = validateCapability(capability);
    if (!validation.ok) return validation;
  }
  for (const assertion of session.assertions) {
    const validation = validateAssertion(assertion);
    if (!validation.ok) return validation;
  }
  for (const record of session.evidence) {
    const validation = validateEvidenceRecord(record);
    if (!validation.ok) return validation;
  }
  return validateSummary(session.summary);
}
