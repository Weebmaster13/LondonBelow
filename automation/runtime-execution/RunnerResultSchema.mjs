import { createHash } from "node:crypto";
import { runtimeExecutionSchemaVersion } from "./ExecutionVersion.mjs";
import { assertionStatuses } from "./ExecutionStatus.mjs";
import { exactFields, isPlainObject, result } from "./ExecutionUtilities.mjs";

export const runnerResultFields = Object.freeze([
  "schemaVersion",
  "runnerId",
  "sessionId",
  "phase",
  "repositoryCommit",
  "runtime",
  "status",
  "studioVersion",
  "serverStarted",
  "clientStarted",
  "clientCount",
  "assertions",
  "diagnostics",
  "snapshots",
  "audit",
  "errors",
  "warnings",
  "cleanup",
  "productionCertified",
  "capturedAt"
]);

export function checksumForText(text) {
  return createHash("sha256").update(text).digest("hex");
}

export function validateRunnerResult(resultValue, context) {
  const fields = exactFields(resultValue, runnerResultFields, "runner result");
  if (!fields.ok) return fields;
  if (resultValue.schemaVersion !== runtimeExecutionSchemaVersion) {
    return result(false, "runner result schema unsupported", "UnsupportedSchema");
  }
  if (resultValue.sessionId !== context.sessionId) return result(false, "runner result session mismatch", "SessionMismatch");
  if (resultValue.phase !== context.configuration.phase) return result(false, "runner result phase mismatch", "PhaseMismatch");
  if (resultValue.repositoryCommit !== context.environment.localHead) return result(false, "runner result commit mismatch", "CommitMismatch");
  if (resultValue.productionCertified !== false) return result(false, "runner result cannot certify", "CertificationMutation");
  if (!["passed", "failed", "blocked", "notExecuted"].includes(resultValue.status)) {
    return result(false, "runner result status unsupported", "UnsupportedStatus");
  }
  if (!Array.isArray(resultValue.assertions) || !Array.isArray(resultValue.errors) || !Array.isArray(resultValue.warnings)) {
    return result(false, "runner result arrays invalid", "SchemaMismatch");
  }
  for (const assertion of resultValue.assertions) {
    if (!isPlainObject(assertion) || typeof assertion.name !== "string" || !assertionStatuses.includes(assertion.status)) {
      return result(false, "runner assertion invalid", "InvalidAssertion");
    }
  }
  return result(true);
}
