--!strict

local DirectorConfig = {}

DirectorConfig.DefaultRequestExpirationSeconds = 30
DirectorConfig.TraceLimit = 200
DirectorConfig.RecentApprovalLimit = 100
DirectorConfig.ExpirationSweepSeconds = 1

DirectorConfig.RequiredDirectors = {
	"PsychologicalHorror",
	"Narrative",
	"Story",
	"Environment",
	"Lighting",
	"Audio",
	"Music",
	"Monster",
	"Puzzle",
	"Save",
	"Difficulty",
	"Performance",
}

return DirectorConfig
