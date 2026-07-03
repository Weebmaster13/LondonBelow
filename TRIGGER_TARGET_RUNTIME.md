# TRIGGER TARGET RUNTIME

Trigger targets are metadata describing possible future destinations. They are not receivers, not callable objects, not gameplay endpoints, and not runtime object handles.

## Production Hardening

Production hardening: targets reject unsupported schema types, unsafe payloads, receiver execution markers, listener markers, callbacks, services, remotes, Workspace references, and Chapter content. Targets are metadata, not receivers.
