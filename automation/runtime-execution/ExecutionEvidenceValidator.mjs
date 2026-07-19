import { readFileSync } from "node:fs";
import { checksumForText, validateRunnerResult } from "./RunnerResultSchema.mjs";
import { result } from "./ExecutionUtilities.mjs";

export function validateExecutionEvidenceFile(path, context, expectedChecksum = null) {
  let text;
  try {
    text = readFileSync(path, "utf8");
  } catch (error) {
    return result(false, String(error?.message ?? error), "MissingEvidence");
  }

  if (text.includes("\u0000")) return result(false, "evidence contains unsupported value type", "UnsupportedEvidenceType");
  const checksum = checksumForText(text);
  if (expectedChecksum !== null && checksum !== expectedChecksum) {
    return result(false, "evidence checksum mismatch", "ChecksumMismatch", { checksum });
  }

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch (error) {
    return result(false, String(error?.message ?? error), "MalformedJson", { checksum });
  }

  const validation = validateRunnerResult(parsed, context);
  return { ...validation, checksum, evidence: validation.ok ? parsed : null };
}
