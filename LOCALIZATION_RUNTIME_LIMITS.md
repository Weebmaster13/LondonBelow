# Localization Runtime Limits

Localization Runtime is bounded by design.

- Language schemas are capped.
- Text key schemas are capped.
- Package schemas are capped.
- Fallback schemas are capped.
- Subtitle schemas are capped.
- Caption schemas are capped.
- Text safety schemas are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, string length, and tag count are capped.

All ids share one global localization namespace. Hitting a limit is a safe rejection, never translation, rendering, content eviction, automatic fallback execution, external service usage, or source-of-truth mutation.

## Certified Limits

- `MaxLanguages` bounds language schemas.
- `MaxTextKeys` bounds text key identifiers.
- `MaxPackages` bounds package schemas.
- `MaxFallbacks` bounds fallback policies.
- `MaxSubtitles` bounds subtitle schemas.
- `MaxCaptions` bounds caption schemas.
- `MaxTextSafetyRules` bounds text safety constraints.
- `MaxValidationFailures` bounds sanitized validation history.
- `MaxSnapshotHistory` bounds snapshot history.
- `MaxPayloadDepth`, `MaxPayloadNodes`, `MaxPayloadStringLength`, and `MaxTags` bound schema shape.

Category limits reject safely before mutation. Hitting a limit must not evict source-of-truth schemas, trigger translation, trigger fallback execution, render UI, or create temporary content.
