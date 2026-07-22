# Architecture

Commands request authoritative work. Events communicate facts. Queries retrieve information.

The Runtime Command Bus is Core infrastructure. It initializes after Runtime Event Bus and before domain coordinators so authoritative mutation requests have a single deterministic gateway.

Phase 165 does not migrate existing domain runtimes. It establishes the shared authority model future phases can adopt.
