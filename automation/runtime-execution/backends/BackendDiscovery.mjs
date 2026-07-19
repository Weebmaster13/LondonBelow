import { StudioManualBackend } from "./StudioManualBackend.mjs";
import { StudioMcpBackend } from "./StudioMcpBackend.mjs";
import { StudioBridgeBackend } from "./StudioBridgeBackend.mjs";
import { UnsupportedBackend } from "./UnsupportedBackend.mjs";

export function discoverBackendModules() {
  return [StudioManualBackend, StudioBridgeBackend, StudioMcpBackend, UnsupportedBackend].map((backend) => ({
    module: backend,
    contract: backend.contract,
    discovery: backend.discover()
  }));
}
