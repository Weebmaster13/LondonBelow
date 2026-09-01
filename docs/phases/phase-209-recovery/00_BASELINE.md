# Phase 209 Baseline

Starting pushed batch baseline: `2c000957bc509843424b1b04e407fa2ecdd1489b`.

Current additive baseline before this corrective pass: `9c3006ad73d915482fffc723db6fa2aa3cd886b9`.

Existing relevant implementation:

* `BlackwaterAudioManifest.lua` defines ten candidate-only audio entries.
* `BlackwaterStreetAudioRuntime.lua` exposes captions and visual equivalents.
* `BlackwaterAudioExecutionConfig.lua` defines surfaces, movement states, acoustic zones, mix snapshots, music stem briefs, silence states, Bailiff audio states, and ward language.
* `BlackwaterAudioExecutionRuntime.lua` creates deterministic plans, voice counters, mix state, acoustic-zone state, silence state, and captions.
* `BlackwaterProductionCoordinator.lua` consumes these states during Blackwater objective flow.

Known weakness: no approved source files, no Roblox audio IDs, no real `Sound` playback, no measured voice cleanup, and no Studio listening evidence.
