--!strict
-- EventBus signal names for server-only Narrative Runtime foundation.

local Signals = {}

Signals.BeatRegistered = "Narrative.BeatRegistered"
Signals.StoryGateRegistered = "Narrative.StoryGateRegistered"
Signals.RevealEligibilityGranted = "Narrative.RevealEligibilityGranted"
Signals.EmotionalProtectionRegistered = "Narrative.EmotionalProtectionRegistered"
Signals.ValidationFailed = "Narrative.ValidationFailed"
Signals.SnapshotCaptured = "Narrative.SnapshotCaptured"

return Signals
