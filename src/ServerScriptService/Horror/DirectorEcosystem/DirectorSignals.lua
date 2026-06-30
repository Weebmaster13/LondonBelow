--!strict
--[[
	EventBus signal names for the Director Ecosystem.
]]

local DirectorSignals = {}

DirectorSignals.CoordinatorReady = "DirectorCoordinator.Ready"
DirectorSignals.DirectorRegistered = "DirectorCoordinator.DirectorRegistered"
DirectorSignals.DirectorFailed = "DirectorCoordinator.DirectorFailed"
DirectorSignals.ObservationRouted = "DirectorCoordinator.ObservationRouted"
DirectorSignals.RequestSubmitted = "DirectorCoordinator.RequestSubmitted"
DirectorSignals.RequestResolved = "DirectorCoordinator.RequestResolved"
DirectorSignals.RequestExpired = "DirectorCoordinator.RequestExpired"

return DirectorSignals
