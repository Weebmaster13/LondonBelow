# Architecture

The stack is Gameplay Flow Runtime -> Save Runtime -> Persistence Runtime -> Save Session Runtime -> Storage Providers.

Save Session Runtime coordinates lifecycle and transaction intent. It does not own gameplay, Save schemas, serialization, storage providers, DataStore access, remotes, analytics, telemetry, or Chapter content.
