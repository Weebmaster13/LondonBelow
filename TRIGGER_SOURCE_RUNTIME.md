# TRIGGER SOURCE RUNTIME

Trigger sources are metadata describing possible future origins. They are not emitters, not EventBus handles, not callbacks, not remotes, and not live Workspace references.

## Production Hardening

Production hardening: sources reject unsupported schema types, unsafe payloads, publisher markers, event emitter markers, runtime handles, callbacks, services, remotes, Workspace references, and Chapter content. Sources are metadata, not publishers.
