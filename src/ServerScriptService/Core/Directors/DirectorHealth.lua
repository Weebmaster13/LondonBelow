--!strict

local DirectorHealth = {}

function DirectorHealth.summarize(directorsByName: { [string]: any })
	local health = {}
	local healthy = 0
	local failed = 0

	for name, director in pairs(directorsByName) do
		local ok, result = pcall(function()
			return director:getHealth()
		end)

		if ok then
			health[name] = result

			if result.healthy then
				healthy += 1
			else
				failed += 1
			end
		else
			failed += 1
			health[name] = {
				name = name,
				status = "Failed",
				healthy = false,
				message = "Health check failed",
				uptime = 0,
				lastError = tostring(result),
			}
		end
	end

	return {
		healthyCount = healthy,
		failedCount = failed,
		byDirector = health,
	}
end

return DirectorHealth
