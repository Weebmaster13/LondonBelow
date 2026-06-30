# Director Capabilities

Capabilities describe what each Director can interpret or approve. They are registered in `DirectorCapabilities.lua` and surfaced through diagnostics.

Each capability includes:

- `id`
- `description`
- `requestKinds`

## Foundation Capability Domains

- Psychological Horror: tension and pressure interpretation.
- Narrative: beat gates and reveal windows.
- Story: lore timing and story clarity.
- Environment: fog, rain, building, and prop reaction permissions.
- Lighting: flicker, dimming, shadows, and visibility pressure.
- Audio: whispers, footsteps, breathing, silence, and pressure cues.
- Music: stingers, tension beds, chase score, and silence.
- Monster: reveal, stalk, chase, retreat, fake-leave, and watch permissions.
- Puzzle: hint timing and puzzle fairness.
- Save: checkpoint and recovery policy.
- Difficulty: adaptive tuning recommendations.
- Performance: budget, throttle, and cleanup pressure.

Capabilities are promises about interpretation. They are not permission to execute final gameplay, art, audio, or monster behavior.
