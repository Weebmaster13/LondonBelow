# Phase 201 - Narrative, Characters, Cinematics, Choice, and Emotional Payoff

## Baseline

Phase 201 gives Blackwater Descent a coherent dramatic spine around Constable Vale, The Bailiff, Blackwater House, and the Glass Heart.

## Ownership

Owned by `BlackwaterNarrativeRuntime`, `BlackwaterCinematicRuntime`, `BlackwaterRunState`, and the Chapter 196 HUD presentation.

## Non-Ownership

This phase does not create final cutscenes, voice acting, camera rails, remote calls, client-owned ending truth, or Chapter 1 content.

## Implementation

Narrative beats now explain why the party enters the house, what Constable Vale discovered, what the wards hide, why The Bailiff protects the archive, and why the Glass Heart matters. The cinematic runtime publishes bounded, skippable, reduced-motion-aware beat identifiers for opening arrival, first house testimony, Bailiff reveal, archive opening, Glass Heart reveal, and dawn aftermath.

Ending authority remains server-side through `BlackwaterRunState.chooseEnding`. The current endings are `escape_with_heart`, `seal_the_heart`, and `free_the_presence`. The HUD reads replicated ending text only; it cannot choose or grant an ending.

## Validation

`london:phase201:selfcheck` verifies narrative beats, Glass Heart payoff, three ending variants, cinematic metadata, reduced-motion flags, HUD ending display, and server-authoritative ending selection.

## Certification Boundary

Production Candidate only. Final cinematic timing, localization review, subtitle pass, and human story comprehension testing are required.

## Known Limitations

Cinematics are represented by safe metadata and HUD/state signals. Final camera/audio staging must be created in a later evidence-gated phase.

## Next Handoff

Phase 202 turns narrative and pressure state into an adaptive soundscape.
