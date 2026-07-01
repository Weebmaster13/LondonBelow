--!strict
-- Patience decides whether watching, waiting, returning, or leaving is plausible.

local PatienceModel = {}

function PatienceModel.score(input: any): (number, { string })
	local base = if type(input) == "table" and type(input.basePatience) == "number"
		then input.basePatience
		else 55
	local failures = if type(input) == "table"
			and type(input.investigationFailures) == "number"
		then input.investigationFailures
		else 0
	local pressure = if type(input) == "table" and type(input.pressure) == "number"
		then input.pressure
		else 0

	local score = base - failures * 8 - pressure * 0.2
	local reasons = { "patience:baseline" }
	if failures > 0 then
		table.insert(reasons, "patience:failed-investigations")
	end
	if pressure > 60 then
		table.insert(reasons, "patience:high-pressure")
	end
	return math.clamp(score, 0, 100), reasons
end

return PatienceModel
