# TRIGGER FILTER RUNTIME

Trigger filters are descriptive schemas for future filtering. They do not run predicates, evaluate payloads, execute Lua, call callbacks, or route event data.

## Production Hardening

Production hardening: filters reject unsupported schema types, invalid trigger references, unsafe payloads, live filtering markers, payload inspection execution markers, callbacks, service handles, and runtime objects.
