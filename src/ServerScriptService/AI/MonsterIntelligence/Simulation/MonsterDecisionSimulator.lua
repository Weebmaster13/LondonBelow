--!strict
-- Dev-only deterministic simulator for intent scoring.

local MonsterMind = require(script.Parent.Parent.Core.MonsterMind)

local MonsterDecisionSimulator = {}

function MonsterDecisionSimulator.run(monsterId: string)
	local contexts = {
		{
			id = "noise-interest",
			signals = { noise = 0.8, movement = 0.2 },
			novelty = { newNoise = true },
			memoryConfidence = 0.4,
			targetZoneId = "sim.hall",
		},
		{
			id = "identity-pressure",
			signals = { identity = 0.9, memory = 0.7, journal = 0.6 },
			identityExposure = 0.8,
			memoryConfidence = 0.7,
			targetPlayerId = "sim-player",
			groupSplit = true,
		},
	}

	local decisions = {}
	for _, context in ipairs(contexts) do
		local intent, reason = MonsterMind.decide(monsterId, context)
		table.insert(decisions, {
			scenarioId = context.id,
			ok = intent ~= nil,
			intent = intent,
			reason = reason,
		})
	end
	return decisions
end

return MonsterDecisionSimulator
