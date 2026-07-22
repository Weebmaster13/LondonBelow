# Architecture

The Runtime Capability Framework lives at:

`src/ServerScriptService/Core/Capabilities`

The provider name is:

`runtimeCapabilityFramework`

The Bootstrap coordinator is:

`RuntimeCapabilityCoordinator`

Bootstrap order is after `RuntimeWorkflowCoordinator` and before gameplay/domain services.

Capabilities communicate only through commands, events, queries, and workflow orchestration. The framework owns capability metadata and lifecycle only; it never exposes implementation modules as cross-runtime references.
