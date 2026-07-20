# Phase 161 Architecture

Runtime hierarchy:

Observation Runtime -> Interaction Runtime -> Environmental Runtime -> Presentation Runtime -> Gameplay Flow Runtime -> Save Runtime.

Gameplay Flow remains authoritative for objective progression. Save Runtime consumes stable identifiers and persistent state metadata only.

The implementation extends the existing `Saving/Core` runtime rather than creating a second save authority.
