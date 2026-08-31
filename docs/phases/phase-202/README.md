# Phase 202 - Adaptive Audio, Music, Voice Pipeline, and Sound Accessibility

## Baseline

Phase 202 creates an audio-state architecture for Blackwater Descent without claiming final audio production.

## Ownership

Owned by `BlackwaterAudioRuntime` and audio metadata in `BlackwaterProductionConfig`.

## Non-Ownership

This phase does not insert marketplace audio, play final sounds, create Sound instances, load assets, use HTTP, create remotes, or make audio-only mandatory puzzle truth.

## Implementation

The config declares nine audio categories: Master, Music, Ambience, Environment, Monster, Interaction, Dialogue, UI, and Accessibility. Major zones have state descriptions for rain, gaslight, paper, house pressure, archive hush, ritual pulse, blackout roar, and dawn release.

The runtime maps gameplay pressure, zone, and Bailiff state into replicated `AudioZone`, `AudioState`, and `CaptionCue` attributes. Captions are first-class presentation metadata. The asset manifest explicitly marks audio slots as blocked by missing approved external assets.

## Validation

`london:phase202:selfcheck` verifies audio buses, zone state, caption cue publication, asset-slot honesty, and no final audio loading/playback surface.

## Certification Boundary

Production Candidate only. Studio audio implementation, loudness review, caption QA, asset licensing review, and accessibility review remain required.

## Known Limitations

No final audio assets are included. This phase provides the deterministic runtime and evidence slots only.

## Next Handoff

Phase 203 uses run seed, pressure, and evidence state to support replayability and difficulty.
