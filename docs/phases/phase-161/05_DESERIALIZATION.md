# Deserialization

`SaveDeserializer` runs migration first, validates the migrated record, checks stable identifiers against the schema registry, then reconstructs persistent metadata.

Deserialization does not recreate gameplay automatically and does not mutate Gameplay Flow. Gameplay Flow remains the runtime authority.
