# Phase 196 Architecture

## Ownership

The runtime accepts exact declarative component composition records and compiles them into existing Roblox GUI rendering contracts. The existing rendering runtime remains the only mutation path for GUI instances.

## Non-Ownership

The composition runtime does not create a second renderer, duplicate theme/application logic, handle remotes, or grant client gameplay authority.

## Certification Boundary

Architecture certification remains evidence-gated because runtime Studio execution is not imported.
