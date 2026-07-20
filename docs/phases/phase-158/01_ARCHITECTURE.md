# Phase 158 Architecture

Ownership:
- `Interaction/Environmental` owns reusable environmental runtime behavior.
- `Chapter0Home/Environment` owns Chapter 0 Home fixture metadata, authored-instance reference binding, readiness, reconciliation, diagnostics, snapshots, and self-checks.

Bootstrap order:
1. `InteractionCoordinator`
2. `EnvironmentalInteractionCoordinator`
3. `Chapter0EnvironmentalCoordinator`
4. Later Chapter 0 Home gameplay systems

The runtime remains server-authoritative and uses existing Governance, Diagnostics, SnapshotManager, Phase 156 Interaction Runtime, and Phase 157 Environmental Interaction Runtime boundaries.
