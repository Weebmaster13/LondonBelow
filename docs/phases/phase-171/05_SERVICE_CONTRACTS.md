# Service Contracts

Domain service contracts are represented by declared interfaces and dependencies.

Future domains can declare owned interfaces and required dependency interfaces without exposing implementation modules. The Runtime Capability Framework remains responsible for capability-level dependency validation and interface resolution.

Phase 171 only binds domain identity to capability metadata. It does not implement concrete Dialogue, Inventory, Save, AI, Objective, Presentation, Audio, Weather, or World Simulation services.
