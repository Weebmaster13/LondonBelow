# Serialization

`SaveSerializer` validates a save record before producing an immutable envelope and stable deterministic encoding.

Serialization includes:

- schema version
- migration version
- objective progress
- checkpoint progress
- metadata

Serialization rejects runtime objects, unknown fields, duplicate identifiers, invalid states, unsupported versions, and unsafe payloads.
