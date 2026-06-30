--!strict
-- EventBus names owned or consumed by the Horror Director.

local DirectorSignals = {}

DirectorSignals.Observation = "HorrorDirector.Observation"
DirectorSignals.DecisionMade = "HorrorDirector.DecisionMade"
DirectorSignals.ScareSelected = "HorrorDirector.ScareSelected"
DirectorSignals.SilenceSelected = "HorrorDirector.SilenceSelected"
DirectorSignals.ProfileUpdated = "HorrorDirector.ProfileUpdated"
DirectorSignals.TensionChanged = "HorrorDirector.TensionChanged"
DirectorSignals.PhaseChanged = "HorrorDirector.PhaseChanged"
DirectorSignals.FutureMonsterOpportunity = "HorrorDirector.FutureMonsterOpportunity"
DirectorSignals.FutureClientPresentation = "HorrorDirector.FutureClientPresentation"

return DirectorSignals
