# Horror Pressure Budget

The pressure budget is a bounded model for deciding when horror should rise, hold, release, or stay silent.

## Tracked Values

- Current pressure.
- Target pressure.
- Pressure debt.
- Release need.
- Silence need.
- Chase readiness.
- Sensory load.
- Emotional load.
- Multiplayer load.

## Rules

Pressure is clamped from 0 to 100. It decays. It should not spike constantly. Safe rooms and puzzle rooms suppress unfair pressure. Player overload suppresses escalation.

## Design Intent

Pressure budget prevents every system from screaming at once. The Building should feel intentional because pressure rises and releases with rhythm, not because scripts randomly fire.

## Future Use

Future Directors can consume pressure budget snapshots when deciding whether to approve lighting, audio, environment, monster, narrative, or presentation requests.
