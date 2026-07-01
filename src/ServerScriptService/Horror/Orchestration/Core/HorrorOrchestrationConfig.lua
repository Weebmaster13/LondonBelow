--!strict
-- Configuration for the Horror Orchestration Framework.

local Config = {}

Config.DefaultMode = "ApprovalOnly"
Config.MaxPressure = 100
Config.MinPressure = 0
Config.TargetPressure = 35
Config.PressureDecayPerSecond = 0.04
Config.MaxRecentPressureChanges = 80
Config.MaxRecentDecisions = 120
Config.MaxSuppressedDecisions = 80
Config.MaxCoordinationBundles = 80
Config.MaxSeenRequestIds = 240
Config.MaxQueueSize = 80
Config.DefaultRequestTtlSeconds = 10
Config.MaxRequestAgeSeconds = 30
Config.CleanupIntervalSeconds = 5
Config.MaxPressureDeltaPerRequest = 35

Config.SafeRoomSuppression = true
Config.PuzzleRoomProtection = true
Config.OverloadThreshold = 75
Config.HighPressureThreshold = 70
Config.ReleaseNeedThreshold = 65
Config.SilenceNeedThreshold = 55
Config.ChasePreparationThreshold = 82

Config.ValidRequestKinds = {
	MonsterIntent = true,
	DirectorPressure = true,
	ObservationPressure = true,
	GameplayPressure = true,
	NarrativeBeat = true,
	ReleaseRequest = true,
	ScareCandidate = true,
	ChasePreparation = true,
}

Config.ValidActions = {
	NoAction = true,
	Silence = true,
	Delay = true,
	Suppress = true,
	HoldPressure = true,
	Release = true,
	Escalate = true,
	CoordinateSensory = true,
	CoordinateEnvironment = true,
	CoordinateMonster = true,
	PrepareChase = true,
}

return Config
