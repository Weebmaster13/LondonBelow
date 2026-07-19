import { executionStatusValues } from "./ExecutionStatus.mjs";
import { deepFreeze } from "./ExecutionUtilities.mjs";

export function createLifecycle(timestamp) {
  const sequence = [
    executionStatusValues.executionRequested,
    executionStatusValues.environmentValidated,
    executionStatusValues.capabilitiesResolved,
    executionStatusValues.sessionCreated,
    executionStatusValues.backendSelected,
    executionStatusValues.executionStarted,
    executionStatusValues.executionRunning,
    executionStatusValues.evidenceCollecting,
    executionStatusValues.executionCompleted,
    executionStatusValues.cleanupRunning,
    executionStatusValues.cleanupComplete,
    executionStatusValues.summaryGenerated,
    executionStatusValues.sessionArchived
  ];

  return deepFreeze(
    sequence.slice(0, -1).map((from, index) => ({
      from,
      to: sequence[index + 1],
      reason:
        sequence[index + 1] === executionStatusValues.executionStarted
          ? "backend launch blocked before runtime invocation"
          : "framework lifecycle checkpoint recorded",
      timestamp
    }))
  );
}
