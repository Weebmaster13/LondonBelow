--!strict
-- Scare eligibility protects Bible rules and fairness.

local Model = {}

function Model.evaluate(budget: any, request: any)
	local metadata = request.metadata or {}
	if metadata.safeRoom == true then
		return false, { "safe room suppresses scare" }
	end
	if metadata.puzzleRoom == true then
		return false, { "puzzle readability suppresses scare" }
	end
	if metadata.playerOverloaded == true or budget.sensoryLoad >= 75 then
		return false, { "player sensory load suppresses scare" }
	end
	if metadata.recentlyUsed == true then
		return false, { "scare was recently used" }
	end
	if request.meaning == nil or request.meaning == "" then
		return false, { "scare lacks narrative or emotional meaning" }
	end
	return true, { "scare is meaningful and not suppressed" }
end

return Model
