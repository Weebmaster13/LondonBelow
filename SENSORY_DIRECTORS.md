# Sensory Directors

Phase 11 adds the Lighting Director and Audio Director foundations.

These Directors are the sensory approval layer for London Engine. They decide whether visual or sound pressure is fair, but they do not perform physical execution.

## Shared Rules

- Server authoritative.
- Approval-only.
- No Workspace mutation.
- No Roblox Lighting mutation.
- No Sound playback.
- No final UI, art, audio, or scare content.
- No client remotes.
- No client-owned truth.
- Must respect World Intelligence.
- Must expose diagnostics and snapshots.
- Must register Governance contracts.
- Must integrate with DirectorCoordinator.

## Coordination

Lighting and Audio Directors consume the same golden flow:

```text
Trusted Server Fact
-> Observation Engine
-> Director Ecosystem
-> Lighting/Audio Approval
-> Future Execution System
-> Client Presentation
```

Environment Director remains the world-reaction Director. Lighting and Audio Directors specialize sensory pressure and should respect Environment Director pressure rather than stealing world-reaction ownership.

## Unknown Zones

Unknown zones are conservative. They deny:

- blackout
- major visibility pressure
- major audio pressure
- silence drops
- monster-support pressure
- unfair puzzle disruption

## Safe Rooms

Safe rooms suppress hostile sensory pressure. Future Directors may approve protective ambience or release behavior, but not hostile dimming, oppressive whispers, fake footsteps, or chase-support pressure.

## Puzzle Rooms

Puzzle rooms protect comprehension, reading, and team communication. Subtle ambience may be allowed, but major sensory disruption must defer unless a future profile and Director approval clearly allow it.

## Future Work

Future execution systems should be separate:

- Lighting Execution applies approved dimming/flicker/visibility instructions.
- Audio Execution plays approved ambience/whispers/heartbeat/breathing instructions.
- Client Presentation renders approved local effects only.

No execution system may invent pacing decisions.
