# TRIGGER EVENT RUNTIME

Trigger events are descriptions of possible future event kinds such as Enter, Exit, Begin, End, Activate, Deactivate, Enable, Disable, Acquire, Release, Register, and Unregister. They are not dispatched events.

## Production Hardening

Production hardening: events reject unsupported schema types, unsupported event kinds, invalid trigger references, unsafe payloads, dispatch/fire/emit markers, callbacks, listener handles, services, remotes, and Workspace references.
