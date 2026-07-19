import { createExecutionConfiguration } from "./ExecutionConfiguration.mjs";
import { collectExecutionEnvironment } from "./ExecutionEnvironment.mjs";
import { resolveCapabilities } from "./ExecutionCapabilities.mjs";
import { createLifecycle } from "./ExecutionLifecycle.mjs";
import { createExecutionManifest } from "./ExecutionManifest.mjs";
import { createExecutionRegistry, selectBackend } from "./ExecutionRegistry.mjs";
import { createExecutionSession, createSessionId } from "./ExecutionSession.mjs";
import { validateExecutionManifest, validateExecutionSession } from "./ExecutionSchema.mjs";
import { stableFrameworkTimestamp } from "./ExecutionVersion.mjs";
import { deepFreeze } from "./ExecutionUtilities.mjs";

export function evaluateRuntimeExecution(input = {}) {
  const timestamp = input.timestamp ?? stableFrameworkTimestamp;
  const configuration = createExecutionConfiguration(input);
  const environment = input.environment ?? collectExecutionEnvironment(input.cwd ?? process.cwd());
  const registry = input.registry ?? createExecutionRegistry();
  const backend = input.backend ?? selectBackend(registry, configuration.requestedBackend);
  const capabilities = resolveCapabilities(environment, backend);
  const lifecycle = createLifecycle(timestamp);
  const sessionId = input.sessionId ?? createSessionId(configuration, environment);
  const manifest = createExecutionManifest(configuration, environment, backend, capabilities, sessionId, timestamp);
  const session = createExecutionSession(configuration, environment, backend, capabilities, lifecycle, timestamp);
  const validation = {
    manifest: validateExecutionManifest(manifest),
    session: validateExecutionSession(session),
    registry: registry.validation
  };

  return deepFreeze({
    configuration,
    environment,
    registry,
    backend,
    capabilities,
    manifest,
    session,
    validation,
    runtimeInvoked: false,
    studioLaunched: false,
    certificationAuthorityInvoked: false,
    status: session.summary.status,
    exitCode: 2,
    timestamp
  });
}
