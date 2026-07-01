--!strict
-- Builds approval-only sensory support requests.

local SensoryCoordination = {}

function SensoryCoordination.build(action: string, request: any)
	if action == "Silence" or action == "Release" then
		return {
			{ target = "AudioDirector", request = "HoldSilence", approvalOnly = true },
			{ target = "LightingDirector", request = "ProtectReadability", approvalOnly = true },
		}
	end
	if action == "CoordinateSensory" or action == "Escalate" then
		return {
			{ target = "AudioDirector", request = "RequestSubtlePressure", approvalOnly = true },
			{
				target = "LightingDirector",
				request = "RequestVisibilityPressure",
				approvalOnly = true,
			},
		}
	end
	return {
		{ target = "Sensory", request = "NoAction", approvalOnly = true, zoneId = request.zoneId },
	}
end

return SensoryCoordination
