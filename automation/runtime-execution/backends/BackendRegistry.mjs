import { discoverBackendModules } from "./BackendDiscovery.mjs";
import { validateBackendModuleContract } from "./BackendContract.mjs";
import { deepFreeze, result, stableSerialize } from "../ExecutionUtilities.mjs";

export function createBackendRegistry() {
  const entries = discoverBackendModules().sort((left, right) => left.contract.priority - right.contract.priority);
  const ids = new Set();
  const validation = [];
  for (const entry of entries) {
    const contractValidation = validateBackendModuleContract(entry.contract);
    validation.push(contractValidation);
    if (ids.has(entry.contract.backendId)) {
      validation.push(result(false, `duplicate backendId ${entry.contract.backendId}`, "DuplicateBackendId"));
    }
    ids.add(entry.contract.backendId);
  }
  return deepFreeze({
    registryId: "runtimeExecution.backendRegistry.v2",
    schemaVersion: 2,
    entries,
    backends: entries.map((entry) => entry.contract),
    validation,
    stableCatalog: stableSerialize(entries.map((entry) => entry.contract))
  });
}
