import { createExecutionConfiguration } from "./ExecutionConfiguration.mjs";
import { collectExecutionEnvironment } from "./ExecutionEnvironment.mjs";
import { resolveCapabilities } from "./ExecutionCapabilities.mjs";
import { createLifecycle } from "./ExecutionLifecycle.mjs";
import { createExecutionManifest } from "./ExecutionManifest.mjs";
import { createExecutionSession, createSessionId } from "./ExecutionSession.mjs";
import { validateExecutionManifest, validateExecutionSession } from "./ExecutionSchema.mjs";
import { stableFrameworkTimestamp } from "./ExecutionVersion.mjs";
import { deepFreeze } from "./ExecutionUtilities.mjs";
import { capabilitiesFromBackend } from "./backends/BackendCapabilities.mjs";
import { createBackendRegistry, selectBackend } from "./backends/index.mjs";

export function evaluateRuntimeExecution(input = {}) {
  const timestamp = input.timestamp ?? stableFrameworkTimestamp;
  const configuration = createExecutionConfiguration(input);
  const environment = input.environment ?? collectExecutionEnvironment(input.cwd ?? process.cwd());
  const registry = input.registry ?? createBackendRegistry();
  const selection = input.selection ?? selectBackend(registry, configuration.requestedBackend);
  const backendModule = input.backendModule ?? selection.backend;
  const backend = input.backend ?? selection.contract;
  const capabilities = [...resolveCapabilities(environment, backend), ...capabilitiesFromBackend(backend)];
  const lifecycle = createLifecycle(timestamp);
  const sessionId = input.sessionId ?? createSessionId(configuration, environment);
  const manifest = createExecutionManifest(configuration, environment, backend, capabilities, sessionId, timestamp);
  const session = createExecutionSession(configuration, environment, backend, capabilities, lifecycle, timestamp);
  const context = { configuration, environment, registry, selection, backend, backendModule, sessionId, timestamp };
  const backendResult = backendModule?.prepare ? backendModule.prepare(context) : null;
  const validation = {
    manifest: validateExecutionManifest(manifest),
    session: validateExecutionSession(session),
    registry: registry.validation
  };

  return deepFreeze({
    configuration,
    environment,
    registry,
    selection,
    backend,
    backendResult,
    capabilities,
    manifest,
    session,
    validation,
    runtimeInvoked: backendResult?.runnerInvoked === true,
    studioLaunched: false,
    certificationAuthorityInvoked: false,
    status: session.summary.status,
    exitCode: 2,
    timestamp
  });
}
