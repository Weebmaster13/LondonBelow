import { mkdirSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { createBackendRegistry } from "./backends/index.mjs";

export const backendCatalogPath = "automation/runtime-execution/generated/backend-catalog.json";

export function createBackendCatalog() {
  const registry = createBackendRegistry();
  return {
    schemaVersion: 1,
    generatedBy: "runtimeExecution.phase152.backendCatalog",
    registryId: registry.registryId,
    backends: registry.backends.map((backend) => ({
      backendId: backend.backendId,
      backendKind: backend.backendKind,
      displayName: backend.displayName,
      frameworkVersion: backend.frameworkVersion,
      backendVersion: backend.backendVersion,
      availability: backend.availability,
      availabilityReason: backend.availabilityReason,
      trustLevel: backend.trustLevel,
      supportedExecutionModes: backend.supportedExecutionModes,
      supportsLaunch: backend.supportsLaunch,
      supportsPlayMode: backend.supportsPlayMode,
      supportsRunMode: backend.supportsRunMode,
      supportsServer: backend.supportsServer,
      supportsClient: backend.supportsClient,
      supportsMultiClient: backend.supportsMultiClient,
      supportsStructuredCapture: backend.supportsStructuredCapture,
      requiresHumanAction: backend.requiresHumanAction,
      supportsTimeout: backend.supportsTimeout,
      supportsCleanup: backend.supportsCleanup,
      supportedPlatforms: backend.supportedPlatforms,
      requiredTools: backend.requiredTools,
      evidenceSchemaVersion: backend.evidenceSchemaVersion,
      priority: backend.priority
    })),
    validationPassed: registry.validation.every((entry) => entry.ok)
  };
}

export function writeBackendCatalog(path = backendCatalogPath) {
  const catalog = createBackendCatalog();
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${JSON.stringify(catalog, null, 2)}\n`, "utf8");
  return { ok: catalog.validationPassed, path, catalog };
}
