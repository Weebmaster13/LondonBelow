--!strict
-- Builds approval-only environmental support requests.

local EnvironmentCoordination = {}

function EnvironmentCoordination.build(action: string, request: any)
	if action == "Escalate" or action == "CoordinateEnvironment" then
		return {
			{
				target = "EnvironmentDirector",
				recommendation = "RequestSubtleWorldPressure",
				approvalOnly = true,
			},
		}
	end
	if action == "Release" then
		return {
			{
				target = "EnvironmentDirector",
				recommendation = "RequestReleaseSupport",
				approvalOnly = true,
			},
		}
	end
	return {
		{
			target = "Environment",
			recommendation = "NoAction",
			approvalOnly = true,
			zoneId = request.zoneId,
		},
	}
end

return EnvironmentCoordination
