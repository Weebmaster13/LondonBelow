# Architecture

Runtime messaging remains split into three constitutional layers:

- Commands request authoritative mutations.
- Events record authoritative facts.
- Queries retrieve authoritative information.

Phase 166 implements the read path only. Query handlers return immutable results from projections, read models, immutable snapshots, or cache metadata without changing authoritative state.
