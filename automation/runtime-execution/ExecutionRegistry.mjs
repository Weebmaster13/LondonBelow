import { executionBackends } from "./ExecutionStatus.mjs";
import { validateBackendContract } from "./ExecutionSchema.mjs";
import { deepFreeze } from "./ExecutionUtilities.mjs";

export function createBackendContract(backendKind, overrides = {}) {
  if (!executionBackends.includes(backendKind)) {
    throw new Error(`Unsupported backend kind: ${backendKind}`);
  }

  return deepFreeze({
    backendId: overrides.backendId ?? `runtimeExecution.${backendKind}`,
    backendKind,
    availability: overrides.availability ?? "blocked",
    canLaunch: overrides.canLaunch ?? false,
    canCaptureStructuredResults: overrides.canCaptureStructuredResults ?? false,
    canReplay: overrides.canReplay ?? false,
    requiresHuman: overrides.requiresHuman ?? backendKind === "StudioManual",
    reason:
      overrides.reason ??
      "Backend contract is registered for future execution but is not launch-authorized by Phase 151."
  });
}

export function createExecutionRegistry() {
  const backends = executionBackends.map((backendKind) =>
    createBackendContract(backendKind, {
      availability: backendKind === "StudioManual" ? "available" : "blocked",
      reason:
        backendKind === "StudioManual"
          ? "Manual Studio evidence can be represented by the framework, but Phase 151 does not launch Studio."
          : "No supported automated backend is available to Phase 151."
    })
  );

  return deepFreeze({
    registryId: "runtimeExecution.backendRegistry.v1",
    backends,
    validation: backends.map((backend) => validateBackendContract(backend))
  });
}

export function selectBackend(registry, requestedBackend) {
  return registry.backends.find((backend) => backend.backendKind === requestedBackend) ?? registry.backends[0];
}
