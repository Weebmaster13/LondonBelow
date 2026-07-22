--!strict
local Serialization = require(script.Parent.QuerySerialization)
local Health = {}
function Health.calculate(counters: any)
	return Serialization.deepCopy({
		queueHealth = if counters.queued > 200 then "Critical" else "Healthy",
		cacheHealth = "Healthy",
		projectionHealth = "Healthy",
		executionHealth = if counters.failed > 0 then "Warning" else "Healthy",
		authorizationHealth = if counters.authorizationFailures > 0 then "Warning" else "Healthy",
	})
end
return Health
