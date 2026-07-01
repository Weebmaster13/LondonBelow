# Door Runtime

Door Runtime owns server-authoritative door state truth.

Supported states are `Open`, `Closed`, `Locked`, `Unlocked`, `Bolted`, `Barred`, `Jammed`, `Broken`, `PowerLocked`, `PuzzleLocked`, `DirectorLocked`, `NarrativeLocked`, `Opening`, `Closing`, `Sealed`, and `Disabled`.

Door transitions are validated by `DoorStateMachine`. Invalid transitions fail closed and are counted in diagnostics. Locked, sealed, jammed, barred, bolted, power-locked, puzzle-locked, Director-locked, narrative-locked, and disabled doors reject open attempts.

The runtime does not animate doors, move parts, play audio, create key models, create Chapter 1 locks, or mutate Workspace.
