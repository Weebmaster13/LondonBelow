--!strict
-- Coordinates shared claims and facts for future multi-monster reasoning.

local ClaimSystem = require(script.Parent.ClaimSystem)
local CompetitionResolver = require(script.Parent.CompetitionResolver)
local SharedKnowledge = require(script.Parent.SharedKnowledge)

local MonsterGroupCoordinator = {}

function MonsterGroupCoordinator.claimInvestigation(
	monsterId: string,
	targetId: string,
	reason: string
)
	return ClaimSystem.claim(monsterId, targetId, reason)
end

function MonsterGroupCoordinator.releaseInvestigation(targetId: string): boolean
	return ClaimSystem.release(targetId)
end

function MonsterGroupCoordinator.shareFact(fact: any)
	return SharedKnowledge.share(fact)
end

function MonsterGroupCoordinator.resolveCompetition(candidates: { any })
	return CompetitionResolver.resolve(candidates)
end

function MonsterGroupCoordinator.cleanup(): number
	return ClaimSystem.cleanupExpired()
end

function MonsterGroupCoordinator.clear()
	ClaimSystem.clear()
	SharedKnowledge.clear()
end

function MonsterGroupCoordinator.inspect()
	return {
		claims = ClaimSystem.inspect(),
		sharedKnowledge = SharedKnowledge.inspect(),
	}
end

return MonsterGroupCoordinator
