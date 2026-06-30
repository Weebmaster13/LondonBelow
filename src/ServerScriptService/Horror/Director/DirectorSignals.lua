--!strict
--[[
	EventBus signal names owned or consumed by the Horror Director.

	Owns stable internal server event names.

	Does not own RemoteEvents, client presentation contracts, or event payload
	validation. Signals are server-process integration points, not network APIs.

	Future systems should import these names instead of hard-coding strings.
	Monster AI, chapter logic, audio, and client presentation bridges can listen
	to selected signals later without creating circular module requires.
]]

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
