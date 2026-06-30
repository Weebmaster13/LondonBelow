--!strict

local DirectorSignals = {}

DirectorSignals.CoordinatorReady = "DirectorCoordinator.Ready"
DirectorSignals.DirectorRegistered = "DirectorCoordinator.DirectorRegistered"
DirectorSignals.DirectorFailed = "DirectorCoordinator.DirectorFailed"
DirectorSignals.RequestSubmitted = "DirectorCoordinator.RequestSubmitted"
DirectorSignals.RequestResolved = "DirectorCoordinator.RequestResolved"
DirectorSignals.RequestExpired = "DirectorCoordinator.RequestExpired"
DirectorSignals.ObservationRouted = "DirectorCoordinator.ObservationRouted"

return DirectorSignals
