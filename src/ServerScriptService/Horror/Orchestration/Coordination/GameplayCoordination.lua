--!strict
-- Keeps gameplay coordination as requests, not truth mutation.

local GameplayCoordination = {}

function GameplayCoordination.build(action: string, request: any)
	if action == "Release" then
		return {
			{
				target = "GameplayIntelligence",
				request = "ProtectRecoveryWindow",
				approvalOnly = true,
			},
		}
	end
	if request.metadata and request.metadata.puzzleRoom == true then
		return {
			{
				target = "GameplayIntelligence",
				request = "ProtectPuzzleReadability",
				approvalOnly = true,
			},
		}
	end
	return {
		{ target = "Gameplay", request = "NoAction", approvalOnly = true },
	}
end

return GameplayCoordination
