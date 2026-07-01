--!strict
-- Configuration for the Living Cognition Runtime.

local Config = {}

Config.Mode = "CognitionOnly"
Config.MaxEntities = 64
Config.MaxObservationsPerEntity = 160
Config.MaxEvidencePerEntity = 160
Config.MaxHypothesesPerEntity = 120
Config.MaxThoughtsPerEntity = 120
Config.MaxBeliefsPerEntity = 96
Config.MaxTraceHistory = 240
Config.MaxValidationFailures = 120
Config.MaxDiagnosticsHistory = 160
Config.MaxPayloadDepth = 8
Config.MaxPayloadNodes = 240
Config.MaxPayloadStringLength = 512

Config.ConfidenceDecayPerSecond = 0.01
Config.EvidenceFreshnessDecayPerSecond = 0.015
Config.HypothesisPromotionThreshold = 0.62
Config.BeliefPromotionThreshold = 0.78
Config.AbsoluteCertaintyThreshold = 0.98

Config.ValidThoughtStates = {
	Born = true,
	Dormant = true,
	Competing = true,
	Reinforced = true,
	Contradicted = true,
	Decaying = true,
	Merged = true,
	Split = true,
	Archived = true,
	Resurrected = true,
}

Config.ForbiddenFields = {
	"workspace",
	"instance",
	"remote",
	"client",
	"movement",
	"pathfinding",
	"navigation",
	"damage",
	"animation",
	"sound",
	"lighting",
	"gameplay",
}

return Config
