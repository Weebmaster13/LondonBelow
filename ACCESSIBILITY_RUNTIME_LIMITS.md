# Accessibility Runtime Limits

Accessibility Runtime is bounded by design.

- Setting schemas are capped.
- Visual safety rules are capped.
- Audio safety rules are capped.
- Input assist schemas are capped.
- Motion comfort schemas are capped.
- Readability schemas are capped.
- Content warning schemas are capped.
- Validation failures and snapshots are capped.
- Payload depth, node count, tag count, and string length are capped.

All ids share one global accessibility schema namespace. Hitting a limit is a safe rejection, never UI, setting execution, input remapping, effect execution, or source-of-truth eviction.

## Certified Limits

- `MaxSettings` bounds accessibility setting schemas.
- `MaxVisuals` bounds visual safety rule schemas.
- `MaxAudios` bounds audio safety rule schemas.
- `MaxInputs` bounds input assist schemas.
- `MaxMotions` bounds motion comfort schemas.
- `MaxReadabilities` bounds readability schemas.
- `MaxContentWarnings` bounds content warning schemas.
- `MaxValidationFailures` bounds sanitized rejection history.
- `MaxSnapshotHistory` bounds snapshot history.
- `MaxPayloadDepth`, `MaxPayloadNodes`, `MaxPayloadStringLength`, and `MaxTags` bound serialization and metadata shape.

Every limit is enforced before registration mutates runtime state. Exceeding a limit is a normal validation failure and must not trigger fallback execution, automatic deletion of older schema truth, client authority, or runtime effect application.
