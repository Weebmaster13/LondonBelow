# London Engine Psychological Horror Director

The Psychological Horror Director is the central pacing intelligence for London Below. It is not monster AI, chapter gameplay, final UI, final art, or a random jumpscare script.

It is one Director inside the larger London Engine Director ecosystem defined in `ENGINE_CONSTITUTION.md`. Ordinary gameplay systems should not call the Horror Director directly. They report trusted server facts to the Observation Engine, and the Director interprets validated knowledge.

The Director decides:

- if horror pressure should happen
- when it should happen
- why it should happen
- who should experience it
- how intense it should be
- when silence is stronger than a scare

## Architecture

The Director is intentionally modular:

- `HorrorDirector.lua`: lifecycle, EventBus intake, scheduled evaluation, public API, diagnostics, snapshots.
- `HorrorDirectorTypes.lua`: shared Luau types and constants.
- `HorrorDirectorConfig.lua`: safe tuning defaults.
- `TensionModel.lua`: per-player and party tension states.
- `PlayerFearProfile.lua`: run-local behavior profiles.
- `ScareRegistry.lua`: metadata-only scare definitions.
- `ScareSelector.lua`: adaptive selection and silence decisions.
- `ScareCooldowns.lua`: global, category, player, and scare-specific cooldowns.
- `DirectorMemory.lua`: recent decisions, routes, hiding patterns, blocked scares, and scare history.
- `DirectorSignals.lua`: EventBus signal names.
- `DirectorDiagnostics.lua`: inspectable debug state.

## Tension Curve

Tension is modeled as:

- `Calm`
- `Uneasy`
- `Tense`
- `Dread`
- `Panic`
- `Release`

The Director avoids constant high tension. Recent scares and future chases create release pressure, which makes silence or lower-pressure events more likely. Panic is soft-capped when a player appears overwhelmed.

The goal is rhythm:

1. quiet observation
2. unease
3. focused pressure
4. release
5. changed expectation

## Player Profiling

Profiles are run-local and are not permanent personal data.

The Director tracks behavior signals such as:

- time alone
- time with party
- sprinting
- hiding
- lantern use
- time in darkness
- looking behind
- door hesitation
- puzzle/objective progress
- exploration
- repeated routes
- repeated hiding spots
- scare and chase recency

These signals produce traits:

- cautious
- brave
- isolated
- lantern-dependent
- darkness-tolerant
- hiding-prone
- sprint-heavy
- curious
- avoidant
- overwhelmed

## Scare Categories

Scares are metadata definitions only. They are not final scare scripts.

Supported categories:

- Ambient
- Psychological
- Visual
- Audio
- Environmental
- MonsterOpportunity
- MajorClimax

Each scare definition includes category, intensity, cooldowns, max repeats, solo/group support, allowed tension states, allowed chapter phases, tags, and requirements.

## Why Silence Matters

Silence is a valid Director decision. The Director may choose silence when:

- the player is already overwhelmed
- a scare would repeat a recent pattern
- cooldowns block fair options
- the pacing curve needs a release
- the best horror choice is expectation without payoff

This prevents spam and keeps the game psychological first.

## Adaptive Selection

`ScareSelector` weighs scare metadata against:

- player profile traits
- current tension
- chapter phase
- cooldowns
- recent scare history
- requirements
- fairness

Examples:

- Lantern-heavy players can receive lantern-related pressure.
- Hiding-prone players can receive close audio pressure later.
- Cautious players can receive deception-oriented events.
- Players who are overwhelmed are more likely to receive silence or release.
- Major climax events are blocked until future chapter climax phases.
- Monster opportunity events are metadata only until Monster AI exists.

## Server Authority

The server owns all Director decisions.

Clients do not send trusted fear state. Clients may later receive presentation events only. Internal compatibility still uses `DirectorSignals.Observation`, but future gameplay systems should report to `ObservationService` first.

No exploitable client remotes were added.

## Director Ecosystem Boundary

The Horror Director owns fear pacing, tension, silence, scare opportunity selection, and psychological pressure.

It does not own:

- Narrative climax readiness.
- Lore timing.
- Physical environment execution.
- Final audio, music, or lighting playback.
- Monster movement, perception, pathfinding, attacks, or animation.
- Puzzle fairness.
- Save rules.
- Performance budgets.

Those belong to future Directors and execution systems described in the London Engine Constitution.

## Future Monster AI Integration

Future Monster AI should subscribe to Director events such as:

- `HorrorDirector.ScareSelected`
- `HorrorDirector.DecisionMade`
- `HorrorDirector.FutureMonsterOpportunity`

The Director can later create opportunities like watching, smiling, fake leaving, returning, blocking path, or choosing not to chase. The monster should still own movement and perception.

## Future Chapter Integration

Chapter systems should send observations to the Observation Engine:

- objective progress
- puzzle progress
- door hesitation
- route keys
- hiding spot usage
- darkness exposure
- party separation
- chase results

Director phase changes should eventually come from Narrative/Chapter flow systems. Direct `HorrorDirector.setChapterPhase` use is a compatibility path, not the ordinary feature integration model.

## Future Client Effects

Future client effects should be presentation only:

- whispers
- heartbeat
- breathing
- lantern flicker
- fake sounds
- screen effects
- silence and audio ducking

Client effects should never decide whether a scare is valid.

## Fairness Rules

- Do not spam scares.
- Do not repeat the same category too often.
- Do not punish cautious play.
- Do not punish brave play.
- Do not force high intensity when the player is overwhelmed.
- Save loud or major events for climax or major transitions.
- Make repeat playthroughs vary through memory, cooldowns, and silence.

## Current Limitations

- Scare definitions are metadata and hook points only.
- No final scare scripts are implemented.
- No Monster AI is required.
- No Chapter 1 gameplay is required.
- No final UI or art is included.
- Live multi-client tuning should happen after chapter prototype signals exist.
