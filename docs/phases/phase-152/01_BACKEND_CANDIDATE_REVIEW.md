# Backend Candidate Review

Reviewed candidates:

- Existing Studio bridge: importable and integrated read-only. It preserves `runnerInvoked = false`, `structuredResultCaptured = false`, and `executionBlocked`.
- Studio MCP: detection path exists, but no connected documented MCP runner command is exposed to the repository.
- Manual Studio backend: supported as a source-bound handoff/import workflow. It prepares a Rojo place artifact, session-bound manifest/instructions, expected evidence path, timeout policy, cleanup policy, and structured result validation.
- Future Roblox CLI/headless/multiplayer/certification backends: registered as future contracts only.

Selected backend for Phase 152 smoke: `runtimeExecution.studioManual`.

Rejection reasons:

- Automated Studio bridge: no supported Play/Run structured capture route.
- Studio MCP: no documented runner command binding.
- Direct CLI launch: opening Studio cannot be treated as Play/Run evidence.
