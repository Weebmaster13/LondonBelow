# Phase 156 Architecture

The authoritative path is:

Runtime caller -> `InteractionCoordinator` -> validation -> target/definition registry -> eligibility -> authorization -> session planning -> optional handler contract -> evidence -> diagnostics/snapshots.

`PlayerExperienceService` remains the owner of existing remotes. `Interaction/Core` creates no remotes and accepts no client authority directly.
