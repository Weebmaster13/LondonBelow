import { stableSerialize } from "./ExecutionUtilities.mjs";

export function serializeExecutionResult(value) {
  return `${JSON.stringify(value, null, 2)}\n`;
}

export function validateDeterministicSerialization(left, right) {
  return stableSerialize(left) === stableSerialize(right);
}
