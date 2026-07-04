# Asset Readiness Review Self-Checks

Self-checks are deterministic and run against the runtime state modules before startup.

They prove valid registration, duplicate rejection, invalid id rejection, unsupported kind/status/tier rejection, missing checklist reference rejection, unsafe payload rejection, oversized payload rejection, failed validation no-mutation, bounded validation failures, bounded snapshots, snapshot isolation, diagnostics isolation, shutdown cleanup, global namespace reset, and banned runtime surface absence.

Self-checks are not gameplay tests and do not load, preload, stream, spawn, play, display, mutate, or execute assets.
