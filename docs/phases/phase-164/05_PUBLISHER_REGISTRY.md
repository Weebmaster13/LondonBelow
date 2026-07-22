# Publisher Registry

`EventPublisherRegistry.lua` owns server-authoritative publisher registration.

Publishers declare `publisherId`, `runtimeId`, `allowedEventTypes`, and authority posture. Client-authoritative publishers are rejected.

Publisher permission is validated before queue admission.
