# Audio Director

The Audio Director is the server-authoritative foundation for future sound pressure in London Engine.

It approves or suppresses future audio requests. It does not play sounds, create Sound instances, use final assets, create client remotes, or own gameplay truth.

## Owns

- Whisper approval.
- Fake footstep approval.
- Distant knock approval.
- Breathing pressure approval.
- Heartbeat pressure approval.
- Silence drop approval.
- Rain muffling approval.
- Room ambience approval.
- Safe-room audio protection.
- Puzzle-room audio protection.
- Audio pressure state.
- Audio diagnostics and snapshots.

## Does Not Own

- Sound playback.
- Final audio assets.
- Music scoring.
- Client presentation.
- Monster AI.
- Chapter 1 content.
- Horror pacing ownership.

## World Intelligence Rules

Audio requests must resolve World Intelligence context before approval.

Unknown zones deny major audio pressure, silence drops, fake sounds, whispers, and monster-support pressure.

Safe rooms suppress hostile audio pressure.

Puzzle rooms protect reading, puzzle solving, and player cooperation. Major silence drops and deceptive sounds are deferred in puzzle-protected spaces.

Affordances are permissions, not actions. `AllowWhispers` makes whispers eligible for approval; it does not play a whisper.

## Request Flow

```text
Observation or Director Request
-> DirectorCoordinator
-> AudioDirector
-> AudioPolicyResolver
-> AudioRequestSelector
-> Approved / Deferred / Rejected with reason
```

Approved decisions are still approval-only. A future Audio Execution system must perform playback after validation and server approval.

## Diagnostics

`AudioDirector.inspect()` exposes:

- recent requests
- approvals
- rejections and suppressions
- policy suppressions
- safe-room suppressions
- puzzle suppressions
- pressure state
- pressure score
- World policy safety summary
- health

## Future Execution Boundary

Future audio execution must consume approved Audio Director decisions. It must not invent pacing, bypass World Intelligence, play final assets from Director code, or create client-owned fear truth.

