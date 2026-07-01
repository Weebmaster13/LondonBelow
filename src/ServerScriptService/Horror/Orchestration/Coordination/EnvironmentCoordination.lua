--!strict
-- Builds approval-only environmental support requests.

local EnvironmentCoordination = {}

function EnvironmentCoordination.build(action: string, request: any)
	if action == "Escalate" or action == "CoordinateEnvironment" then
		return {
			{
				target = "EnvironmentDirector",
				request = "RequestSubtleWorldPressure",
				approvalOnly = true,
			},
		}
	end
	if action == "Release" then
		return {
			{
				target = "EnvironmentDirector",
				request = "RequestReleaseSupport",
				approvalOnly = true,
			},
		}
	end
	return {
		{
			target = "Environment",
			request = "NoAction",
			approvalOnly = true,
			zoneId = request.zoneId,
		},
	}
end

return EnvironmentCoordination
