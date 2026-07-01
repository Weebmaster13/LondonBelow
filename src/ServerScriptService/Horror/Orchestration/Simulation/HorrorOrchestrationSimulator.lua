--!strict
-- Deterministic simulator for orchestration decisions.

local Simulator = {}

function Simulator.scenarios()
	local now = os.clock()
	return {
		{
			requestId = "orchestration-selfcheck-silence",
			sourceSystem = "SelfCheck",
			requestKind = "MonsterIntent",
			priority = 40,
			pressure = 60,
			createdAt = now,
			expiresAt = now + 5,
			meaning = "monster waits because silence is scarier",
			metadata = { sensoryLoad = 80, intentKind = "Waiting" },
			tags = {},
		},
		{
			requestId = "orchestration-selfcheck-safe-room",
			sourceSystem = "SelfCheck",
			requestKind = "ScareCandidate",
			priority = 50,
			pressure = 50,
			createdAt = now,
			expiresAt = now + 5,
			meaning = "safe room scare should suppress",
			metadata = { safeRoom = true },
			tags = {},
		},
		{
			requestId = "orchestration-selfcheck-release",
			sourceSystem = "SelfCheck",
			requestKind = "ReleaseRequest",
			priority = 80,
			pressure = 85,
			createdAt = now,
			expiresAt = now + 5,
			meaning = "release after heavy pressure",
			metadata = { emotionalLoad = 90 },
			tags = {},
		},
		{
			requestId = "orchestration-selfcheck-puzzle",
			sourceSystem = "SelfCheck",
			requestKind = "ScareCandidate",
			priority = 60,
			pressure = 55,
			createdAt = now,
			expiresAt = now + 5,
			meaning = "puzzle room should protect comprehension",
			metadata = { puzzleRoom = true },
			tags = {},
		},
		{
			requestId = "orchestration-selfcheck-overload",
			sourceSystem = "SelfCheck",
			requestKind = "DirectorPressure",
			priority = 70,
			pressure = 70,
			createdAt = now,
			expiresAt = now + 5,
			meaning = "overload should suppress escalation",
			metadata = { playerOverloaded = true, sensoryLoad = 90 },
			tags = {},
		},
	}
end

return Simulator
