# Diagnostics

Runtime diagnostics are exposed through existing inspection surfaces:

- `BlackwaterProductionCoordinator.inspect()`
- `BlackwaterStreetAudioRuntime.inspect()`
- `BlackwaterBailiffPhysicalRuntime.inspect()`

The street audio runtime reports candidate count, layer state, triggered event count, bounded event log, runtime evidence posture, and blocked Roblox asset upload status.

The Bailiff physical runtime reports initialization, model/root presence, mode, generation, path request count, stuck recovery count, last-known-position count, and final-art status.
