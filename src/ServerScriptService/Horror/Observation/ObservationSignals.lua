--!strict
--[[
	EventBus signal names for the Observation Engine.

	Owns server-process observation integration names.

	Does not own RemoteEvents or client networking. These are internal engine
	signals for trusted server systems only.
]]

local ObservationSignals = {}

ObservationSignals.Submitted = "Observation.Submitted"
ObservationSignals.Accepted = "Observation.Accepted"
ObservationSignals.Rejected = "Observation.Rejected"
ObservationSignals.PatternDetected = "Observation.PatternDetected"
ObservationSignals.ContextUpdated = "Observation.ContextUpdated"
ObservationSignals.TimelineRecorded = "Observation.TimelineRecorded"
ObservationSignals.DirectorForwarded = "Observation.DirectorForwarded"

return ObservationSignals
