# Asset Execution Adapter Registry Diagnostics

Diagnostics remain health-only.

Diagnostics expose copied metadata for runtime identity, provider identity, registry identity, snapshot identity, coordinator identity, registration counts, validation counts, runtime limits, health, certification posture, registration posture, ownership posture, registry posture, documentation posture, Bootstrap posture, and Governance posture.

LowerCamelCase posture keys include `assetExecutionAdapterRegistryRuntimePosture`, `assetExecutionAdapterRegistryValidationPosture`, `assetExecutionAdapterRegistryRegistrationPosture`, `assetExecutionAdapterRegistryOwnershipPosture`, `assetExecutionAdapterRegistryCompatibilityPosture`, `assetExecutionAdapterRegistryBoundaryPosture`, `assetExecutionAdapterRegistryAuditPosture`, and `assetExecutionAdapterRegistryCertificationPosture`.

Diagnostics never expose executable registries, callbacks, listeners, services, managers, runtime handles, execution handles, adapter implementations, or mutable references.
