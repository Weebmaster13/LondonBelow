# Director Requests

Directors communicate through typed requests.

Request fields:

- Unique ID.
- Timestamp.
- Source Director.
- Target Director.
- Request kind.
- Priority.
- Reason.
- Supporting observations.
- Context.
- Expiration.
- Approval state.

Examples:

- `RequestMonsterReveal`
- `RequestMonsterAttack`
- `RequestLightingChange`
- `RequestMusicState`
- `RequestEnvironmentReaction`
- `RequestNarrativeBeat`
- `RequestCheckpoint`

Requests are permissions, not execution. A request may later become an instruction to an execution system after approval.

