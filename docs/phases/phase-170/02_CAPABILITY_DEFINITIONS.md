# Capability Definitions

Each capability definition contains:

- `capabilityId`;
- `version`;
- `owner`;
- `category`;
- `authority`;
- `interfaces`;
- `dependencies`;
- `healthProvider`;
- `diagnosticsProvider`;
- `snapshotProvider`;
- `metadata`.

Definitions are exact-schema and immutable after registration. Unknown fields, missing fields, unsupported categories, unsupported authority values, duplicate interface ids, malformed dependencies, unsafe payloads, and oversized payloads reject before mutation.
