# Provider Model

Supported provider records:

- `MemoryProvider`: executable in-memory storage for validation and local runtime smoke attempts.
- `NullProvider`: executable rejection provider returning `NotSupported`.
- `FutureDataStoreProvider`: interface only.
- `FutureProfileServiceProvider`: interface only.

Future providers expose shape and diagnostics only. They do not call Roblox services in Phase 162.
