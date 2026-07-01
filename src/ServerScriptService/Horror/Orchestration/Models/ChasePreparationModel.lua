--!strict
-- Prepares future chase recommendations without starting a chase.

local Config = require(script.Parent.Parent.Core.HorrorOrchestrationConfig)

local Model = {}

function Model.evaluate(budget: any, request: any)
	if budget.chaseReadiness < Config.ChasePreparationThreshold then
		return false, { "chase readiness below threshold" }
	end
	if
		request.metadata
		and (request.metadata.safeRoom == true or request.metadata.puzzleRoom == true)
	then
		return false, { "protected room suppresses chase preparation" }
	end
	return true, { "chase preparation may be requested for future approval" }
end

return Model
