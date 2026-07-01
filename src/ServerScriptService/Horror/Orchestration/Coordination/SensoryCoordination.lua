--!strict
-- Builds approval-only sensory support requests.

local SensoryCoordination = {}

function SensoryCoordination.build(action: string, request: any)
	if action == "Silence" or action == "Release" then
		return {
			{ target = "AudioDirector", recommendation = "HoldSilence", approvalOnly = true },
			{
				target = "LightingDirector",
				recommendation = "ProtectReadability",
				approvalOnly = true,
			},
		}
	end
	if action == "CoordinateSensory" or action == "Escalate" then
		return {
			{
				target = "AudioDirector",
				recommendation = "RequestSubtlePressure",
				approvalOnly = true,
			},
			{
				target = "LightingDirector",
				recommendation = "RequestVisibilityPressure",
				approvalOnly = true,
			},
		}
	end
	return {
		{
			target = "Sensory",
			recommendation = "NoAction",
			approvalOnly = true,
			zoneId = request.zoneId,
		},
	}
end

return SensoryCoordination
