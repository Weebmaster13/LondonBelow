# Runtime Execution Framework Architecture

Phase 151 establishes `automation/runtime-execution` as London's reusable execution framework for future runtime validation, QA sessions, regression suites, vertical-slice checks, and certification runs.

The framework owns execution session modeling, manifests, environment capture, backend contracts, capability negotiation, lifecycle tracking, assertion records, evidence category separation, cleanup records, history metadata, serialization, reporting, and framework self-checks.

The framework does not own gameplay, Observation, Interaction, Narrative, Presentation, Monster AI, Governance, Bootstrap, persistence, networking, analytics, telemetry, or certification decisions.

## Modules

- `RuntimeExecutionCoordinator.mjs` is the public command entry point.
- `ExecutionPipeline.mjs` composes configuration, environment, registry, capability, lifecycle, manifest, and session outputs.
- `ExecutionSchema.mjs` validates sessions, manifests, backend contracts, capabilities, assertions, evidence records, summaries, and lifecycle entries.
- `ExecutionRegistry.mjs` defines interchangeable backend contracts.
- `ExecutionCapabilities.mjs` records Supported, Unsupported, Blocked, or Unknown capability states.
- `ExecutionSession.mjs` creates immutable session records.
- `ExecutionManifest.mjs` creates deterministic execution manifests.
- `ExecutionReporter.mjs` creates JSON and Markdown report payloads.
- `SelfChecks.mjs` verifies the framework contract without invoking a runtime backend.

## Evidence Separation

Evidence categories are distinct and cannot be merged:

- Static
- Build
- Runtime
- ManualQA
- Certification

Phase 151 records static framework metadata only. Runtime and certification evidence remain blocked until a supported backend is bound in a future phase.
