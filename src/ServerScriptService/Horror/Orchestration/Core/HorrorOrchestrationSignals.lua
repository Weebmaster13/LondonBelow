--!strict
-- Server-only EventBus signals for Horror Orchestration.

local Signals = {}

Signals.RequestSubmitted = "HorrorOrchestration.RequestSubmitted"
Signals.RequestRejected = "HorrorOrchestration.RequestRejected"
Signals.RequestExpired = "HorrorOrchestration.RequestExpired"
Signals.DecisionMade = "HorrorOrchestration.DecisionMade"
Signals.DecisionSuppressed = "HorrorOrchestration.DecisionSuppressed"
Signals.ReleasePlanned = "HorrorOrchestration.ReleasePlanned"
Signals.BundleCreated = "HorrorOrchestration.BundleCreated"
Signals.ValidationFailed = "HorrorOrchestration.ValidationFailed"

return Signals
