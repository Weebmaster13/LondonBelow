# World Affordances

Affordances describe what a space can support. They are permissions and context hints, not automatic actions.

## Atmosphere Affordances

- `AllowWhispers`: future Audio Director may consider whispers.
- `AllowHeartbeat`: heartbeat pressure is thematically valid.
- `AllowBreathing`: breathing effects are valid.
- `AllowLanternFlicker`: lantern instability is valid.
- `AllowFog`: fog pressure is valid.
- `AllowRainMuffle`: rain muffling or exterior dampening is valid.
- `AllowSilenceDrop`: sudden quiet is valid.

## Environment Affordances

- `AllowDoorReaction`: doors may react if approved.
- `AllowPropShift`: small environmental shifts may be requested.
- `AllowLightDimming`: lighting may dim within policy.
- `AllowCooperativePressure`: multiplayer-aware pressure is valid.

## Monster Affordances

- `AllowMonsterPresence`: future Monster Director may consider unseen presence.
- `AllowMonsterReveal`: future Monster Director may request a reveal.
- `AllowCrawlerPresence`: future crawler systems may be allowed here.
- `AllowChase`: chase start or continuation is allowed only if policy and Director approval agree.

These affordances do not implement Monster AI.

## Protection Affordances

- `ProtectPuzzleFocus`: pressure must not make puzzle-solving unfair.
- `ProtectSafeRoom`: major hostile actions should be suppressed.

## Future Use

Observation Engine should report affordance-relevant facts. DirectorCoordinator should use affordances when resolving conflicts. Environment, Lighting, Audio, and Monster Directors should treat affordances as one input among pressure, narrative beat, player state, party state, and cooldowns.

No affordance bypasses governance, validation, or server authority.

