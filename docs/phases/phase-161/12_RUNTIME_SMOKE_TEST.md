# Runtime Smoke Test

Smoke test flow:

1. Initialize Save Runtime.
2. Load Chapter 0 metadata.
3. Serialize objectives.
4. Serialize checkpoints.
5. Validate save.
6. Deserialize save.
7. Compare reconstructed metadata.
8. Shutdown.

If Roblox Studio evidence is unavailable, the Runtime Execution Framework reports `executionBlocked`.
