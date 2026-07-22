# Architecture

Dialogue Runtime Capability registers through `RuntimeDomainCapabilityCoordinator` as:

- category: Gameplay;
- domain: Dialogue;
- authority: Server;
- workflow participation: Coordinator;
- provider: `dialogueRuntimeCapability`.

The runtime exposes interfaces only. Internal implementation remains private, and future execution must flow through Commands, Events, Queries, Messaging, Workflow Orchestration, Domain Capability Foundation, and Capability Framework.
