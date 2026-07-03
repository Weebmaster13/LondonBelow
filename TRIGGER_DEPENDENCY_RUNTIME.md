# TRIGGER DEPENDENCY RUNTIME

Trigger dependencies are metadata relationships. The runtime rejects invalid references, self dependencies, and direct cycles, but dependencies do not block runtime behavior.

## Production Hardening

Production hardening: dependencies reject unsupported schema types, invalid source/target triggers, self dependencies, direct cycles, unsafe payloads, blocking execution markers, callbacks, services, remotes, and Workspace references.
