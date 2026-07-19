import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { validateExecutionEvidenceFile } from "./ExecutionEvidenceValidator.mjs";
import { result } from "./ExecutionUtilities.mjs";

function isInside(root, candidate) {
  const resolvedRoot = resolve(root);
  const resolvedCandidate = resolve(candidate);
  return resolvedCandidate === resolvedRoot || resolvedCandidate.startsWith(`${resolvedRoot}\\`) || resolvedCandidate.startsWith(`${resolvedRoot}/`);
}

export function importExecutionEvidence(path, context) {
  const allowedRoot = resolve("automation", "local-state", "runtime-execution");
  if (!isInside(allowedRoot, path)) {
    return result(false, "evidence path outside approved root", "PathTraversalRejected");
  }
  if (!existsSync(path)) return result(false, "evidence file not found", "MissingEvidence");
  return validateExecutionEvidenceFile(path, context);
}
