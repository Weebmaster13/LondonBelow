--!strict
-- Keeps gameplay coordination as requests, not truth mutation.

local GameplayCoordination = {}

function GameplayCoordination.build(action: string, request: any)
	if action == "Release" then
		return {
			{
				target = "GameplayIntelligence",
				recommendation = "ProtectRecoveryWindow",
				approvalOnly = true,
			},
		}
	end
	if request.metadata and request.metadata.puzzleRoom == true then
		return {
			{
				target = "GameplayIntelligence",
				recommendation = "ProtectPuzzleReadability",
				approvalOnly = true,
			},
		}
	end
	return {
		{ target = "Gameplay", recommendation = "NoAction", approvalOnly = true },
	}
end

return GameplayCoordination
