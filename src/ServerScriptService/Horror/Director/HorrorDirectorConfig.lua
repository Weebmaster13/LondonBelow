--!strict
-- Safe defaults for the Psychological Horror Director.

local HorrorDirectorConfig = {}

HorrorDirectorConfig.EvaluationIntervalSeconds = 6
HorrorDirectorConfig.MinimumSecondsBetweenScares = 18
HorrorDirectorConfig.MinimumPlayerSecondsBetweenScares = 24
HorrorDirectorConfig.MinimumCategorySecondsBetweenScares = 35
HorrorDirectorConfig.SilenceChance = 0.28
HorrorDirectorConfig.OverwhelmSilenceChance = 0.75
HorrorDirectorConfig.CalmTooLongSeconds = 90
HorrorDirectorConfig.RecentScareMemoryLimit = 12
HorrorDirectorConfig.RecentDecisionLimit = 25
HorrorDirectorConfig.RouteMemoryLimit = 12
HorrorDirectorConfig.HidingSpotMemoryLimit = 8
HorrorDirectorConfig.MaxTensionScore = 100
HorrorDirectorConfig.ReleaseDecayPerEvaluation = 8
HorrorDirectorConfig.PanicSoftCap = 88

HorrorDirectorConfig.TensionThresholds = {
	Release = 12,
	Calm = 24,
	Uneasy = 44,
	Tense = 64,
	Dread = 82,
	Panic = 100,
}

HorrorDirectorConfig.ObservationWeights = {
	TimeAlone = 0.9,
	TimeWithParty = -0.25,
	Sprint = 2.5,
	Hide = 3,
	LanternUse = 1.25,
	Darkness = 1.5,
	LookBehind = 1.2,
	DoorHesitation = 2,
	PuzzleProgress = 0.4,
	ObjectiveProgress = 0.5,
	Exploration = 0.35,
	RepeatedRoute = 2,
	RepeatedHidingSpot = 2.25,
	RecentScareRelief = -10,
	RecentChaseRelief = -16,
}

return HorrorDirectorConfig
