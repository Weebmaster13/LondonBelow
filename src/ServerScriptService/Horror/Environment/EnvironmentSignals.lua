--!strict
--[[
	Server-only EventBus signal names for Environment Director integration.
]]

local EnvironmentSignals = {}

EnvironmentSignals.ApprovalDecided = "EnvironmentDirector.ApprovalDecided"
EnvironmentSignals.ReactionSelected = "EnvironmentDirector.ReactionSelected"
EnvironmentSignals.ReactionRejected = "EnvironmentDirector.ReactionRejected"
EnvironmentSignals.ReactionDeferred = "EnvironmentDirector.ReactionDeferred"
EnvironmentSignals.ReactionExpired = "EnvironmentDirector.ReactionExpired"
EnvironmentSignals.ReactionCancelled = "EnvironmentDirector.ReactionCancelled"
EnvironmentSignals.PressureChanged = "EnvironmentDirector.PressureChanged"
EnvironmentSignals.ZonePressureChanged = "EnvironmentDirector.ZonePressureChanged"
EnvironmentSignals.ExecutionRequested = "EnvironmentDirector.ExecutionRequested"
EnvironmentSignals.Diagnostics = "EnvironmentDirector.Diagnostics"

return EnvironmentSignals
