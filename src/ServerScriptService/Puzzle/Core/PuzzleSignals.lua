--!strict
-- Server-only EventBus signals for Puzzle Runtime Foundation.

local Signals = {}

Signals.PuzzleRegistered = "Puzzle.Registered"
Signals.ProgressRecorded = "Puzzle.ProgressRecorded"
Signals.ValidationFailed = "Puzzle.ValidationFailed"
Signals.SnapshotCaptured = "Puzzle.SnapshotCaptured"

return Signals
