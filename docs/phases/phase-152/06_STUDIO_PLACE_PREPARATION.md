# Studio Place Preparation

Phase 152 integrates temporary place preparation through `StudioPlaceBuilder.mjs`.

The builder uses:

`rojo build default.project.json --output automation/local-state/runtime-execution/<session-id>/runtime-execution.rbxlx`

It records command, start/end timestamps, exit code, output path, size, checksum, stale status, and cleanup policy. Empty or failed artifacts are rejected.

Generated `.rbxlx` files remain under `automation/local-state` and are not committed.
