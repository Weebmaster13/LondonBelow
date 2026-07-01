--!strict
-- Builds approval-only monster pressure recommendations.

local MonsterCoordination = {}

function MonsterCoordination.build(action: string, request: any)
	if action == "PrepareChase" then
		return {
			{ target = "MonsterDirector", request = "PrepareChaseOnly", approvalOnly = true },
			{
				target = "MonsterIntelligence",
				request = "HoldIntentForFutureAI",
				approvalOnly = true,
			},
		}
	end
	if action == "Silence" or action == "Delay" then
		return {
			{ target = "MonsterIntelligence", request = "Wait", approvalOnly = true },
		}
	end
	if action == "CoordinateMonster" then
		return {
			{ target = "MonsterDirector", request = "ReviewMonsterPressure", approvalOnly = true },
		}
	end
	return {
		{ target = "Monster", request = "NoAction", approvalOnly = true, zoneId = request.zoneId },
	}
end

return MonsterCoordination
