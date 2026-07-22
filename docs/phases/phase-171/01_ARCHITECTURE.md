# Architecture

Runtime Domain Capability Foundation sits above the Runtime Capability Framework and below future concrete gameplay domains.

The layer owns:

- domain capability contracts;
- domain identity;
- one-domain-per-capability enforcement;
- interface ownership metadata;
- communication contracts;
- lifecycle integration metadata;
- diagnostics, snapshots, evidence, metrics, profiler metadata, Governance, and certification posture.

The layer does not expose direct subsystem references. Future domains must communicate through Commands, Events, Queries, and Workflow Orchestration.
