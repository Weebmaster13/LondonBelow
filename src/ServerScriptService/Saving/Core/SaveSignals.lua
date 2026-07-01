--!strict
-- EventBus signal names for server-only Save / Journal / Identity runtime.

local Signals = {}

Signals.ProfileCreated = "Save.ProfileCreated"
Signals.CheckpointCreated = "Save.CheckpointCreated"
Signals.JournalEntryUnlocked = "Save.JournalEntryUnlocked"
Signals.MemoryFragmentUnlocked = "Save.MemoryFragmentUnlocked"
Signals.IdentityChanged = "Save.IdentityChanged"
Signals.ReplayRecorded = "Save.ReplayRecorded"
Signals.ValidationFailed = "Save.ValidationFailed"
Signals.SnapshotCaptured = "Save.SnapshotCaptured"

return Signals
