# Registries

Phase 165 adds:

- `CommandRegistry.lua` for typed command definitions.
- `CommandRequesterRegistry.lua` for authorized server-side requesters.
- `CommandHandlerRegistry.lua` for exactly-one handler per command type.

Duplicate definitions, duplicate requesters, duplicate handlers, unknown command types, client-authoritative requesters, and ambiguous owners reject before mutation.
