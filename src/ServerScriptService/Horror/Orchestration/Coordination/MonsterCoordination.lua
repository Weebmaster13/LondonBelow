--!strict
-- Builds approval-only monster pressure recommendations.

local MonsterCoordination = {}

function MonsterCoordination.build(action: string, request: any)
	if action == "PrepareChase" then
		return {
			{
				target = "MonsterDirector",
				recommendation = "PrepareChaseOnly",
				approvalOnly = true,
			},
			{
				target = "MonsterIntelligence",
				recommendation = "HoldIntentForFutureAI",
				approvalOnly = true,
			},
		}
	end
	if action == "Silence" or action == "Delay" then
		return {
			{ target = "MonsterIntelligence", recommendation = "Wait", approvalOnly = true },
		}
	end
	if action == "CoordinateMonster" then
		return {
			{
				target = "MonsterDirector",
				recommendation = "ReviewMonsterPressure",
				approvalOnly = true,
			},
		}
	end
	return {
		{
			target = "Monster",
			recommendation = "NoAction",
			approvalOnly = true,
			zoneId = request.zoneId,
		},
	}
end

return MonsterCoordination
