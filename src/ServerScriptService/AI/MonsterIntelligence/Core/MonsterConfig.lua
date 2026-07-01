--!strict
--[[
	Configuration for the Monster Intelligence foundation.

	Monster Intelligence is server-only and intent-only. These limits keep
	memory, diagnostics, claims, and decision history bounded before future
	Monster AI exists.
]]

local MonsterConfig = {}

MonsterConfig.Enabled = true
MonsterConfig.DecisionMode = "IntentOnly"

MonsterConfig.MaxMonsters = 16
MonsterConfig.MaxMemoryPerMonster = 128
MonsterConfig.MaxKnowledgePerMonster = 128
MonsterConfig.MaxInterestEntries = 96
MonsterConfig.MaxDecisionHistory = 160
MonsterConfig.MaxDiagnosticsHistory = 120
MonsterConfig.MaxSharedFacts = 160
MonsterConfig.MaxClaims = 64

MonsterConfig.MemoryDecayPerSecond = 0.015
MonsterConfig.InterestDecayPerSecond = 0.05
MonsterConfig.CuriosityDecayPerSecond = 0.035
MonsterConfig.PatienceRecoveryPerSecond = 0.025
MonsterConfig.ClaimTimeoutSeconds = 12

MonsterConfig.ValidStates = {
	Dormant = true,
	Observing = true,
	Interested = true,
	Investigating = true,
	Waiting = true,
	Searching = true,
	Coordinating = true,
	Pressuring = true,
	Leaving = true,
}

MonsterConfig.ValidIntentKinds = {
	Observe = true,
	Investigate = true,
	Wait = true,
	Ignore = true,
	Prepare = true,
	Coordinate = true,
	Search = true,
	Pressure = true,
	Leave = true,
}

MonsterConfig.ValidMemoryKinds = {
	LastSeenPlayer = true,
	LastHeardPlayer = true,
	LastKnownRoom = true,
	OpenedDoor = true,
	ClosedDoor = true,
	BrokenObject = true,
	RecentPuzzle = true,
	LightSource = true,
	LanternUsage = true,
	SafeRoom = true,
	PlayerHabit = true,
	InvestigationFailure = true,
	FalseLead = true,
}

MonsterConfig.ValidKnowledgeStates = {
	Known = true,
	Suspected = true,
	Lost = true,
	False = true,
	Shared = true,
	Unknown = true,
}

MonsterConfig.DisallowedActions = {
	"Workspace mutation",
	"pathfinding",
	"navigation",
	"NPC spawning",
	"damage",
	"animation",
	"sound playback",
	"Lighting mutation",
	"client remotes",
}

return MonsterConfig
