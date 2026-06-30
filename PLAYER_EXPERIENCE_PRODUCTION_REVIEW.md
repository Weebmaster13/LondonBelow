# Player Experience Production Review

This production hardening review treats the Player Experience Framework as reusable London Engine infrastructure for multiple future games.

No Chapter 1, Monster AI, final UI, final art, or new gameplay content was added.

## Issues Found

- Interaction requests accepted `requestId` metadata but did not use it to reject duplicate or replayed requests.
- Non-replayable interactions had no busy guard, so two players could attempt to consume the same object at nearly the same time.
- Object handler exceptions could leave interaction state ambiguous.
- Client focus responses could arrive out of order and revive a stale prompt after the camera had moved away.
- Player runtime state patches accepted invalid lifecycle, ground, or movement values from future server code.
- Diagnostics did not expose active busy interactions or request replay pressure.

## Fixes

- Added per-player request replay detection with a bounded 30-second request ID memory.
- Added per-interaction busy locks for non-replayable interactions.
- Wrapped object handler execution in `pcall` and release busy locks on every path.
- Added stale focus sequence handling between client focus requests and server focus responses.
- Added authoritative state validation for lifecycle, ground, and movement modes.
- Expanded interaction diagnostics with cooldown and busy interaction counts.

## Why These Changes Matter

- Replayed packets should not duplicate observations or object state changes.
- Two players targeting the same key or collectible should not both win the same one-shot interaction.
- Bad future server integrations should fail fast instead of corrupting player runtime state.
- Slow focus responses should not cause confusing prompts or stale interaction requests.
- Production debugging needs to reveal pressure points before they become live issues.

## Remaining Risks

- The framework does not yet include automated multi-client tests.
- `Movement.Stop` remains reserved until trusted movement-vector or humanoid stop sampling exists.
- Mobile/controller support is hook-level, not final UX.
- Prompt and feedback presentation are debug-quality surfaces.
- Specialized systems still need to own final truth for doors, inventory, puzzles, hiding, lantern, and cutscenes.
- The camera controller still needs future cutscene takeover, FOV effects, and character orientation integration.

## Future Scalability Considerations

- Add deterministic interaction test harnesses for simultaneous players.
- Add per-object ownership policies for cooperative and contested interactions.
- Add a presentation diagnostics channel for client camera/prompt state.
- Add configurable per-remote rate limits instead of one namespace-level default.
- Add trusted movement sampling for stop, landing, surface, and footstep quality.
- Add remappable control settings once settings persistence exists.

## Production-Ready Rationale

The framework is considered production-ready as an engine foundation because:

- Server authority is preserved.
- Client scripts request and present; they do not decide truth.
- Interaction validation is centralized and reusable.
- Player runtime state has explicit contracts and validation.
- Observations are emitted after trusted server facts.
- Remotes are registered through `RemoteManager`.
- Diagnostics and snapshots expose core runtime state.
- Cleanup paths exist for disconnects, shutdown, cooldowns, and busy interaction state.
- Governance contracts document ownership and non-ownership boundaries.

Production-ready here means safe to build future systems on. It does not mean final player feel, final UI, final art, final chapter objects, or final accessibility UX are complete.

