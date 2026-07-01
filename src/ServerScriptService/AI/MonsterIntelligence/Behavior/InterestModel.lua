--!strict
-- Scores attention-worthy signals without creating actions.

local InterestModel = {}

local WEIGHTS: { [string]: number } = {
	noise = 18,
	movement = 14,
	light = 16,
	identity = 24,
	memory = 22,
	door = 12,
	journal = 20,
	hesitation = 10,
	groupSeparation = 18,
	objective = 14,
}

function InterestModel.score(input: any): (number, { string })
	local reasons = {}
	local score = 0
	local signals = if type(input) == "table" and type(input.signals) == "table"
		then input.signals
		else {}

	for kind, weight in pairs(WEIGHTS) do
		local value = signals[kind]
		if type(value) == "number" and value > 0 then
			score += math.clamp(value, 0, 1) * weight
			table.insert(reasons, "interest:" .. kind)
		end
	end

	return math.clamp(score, 0, 100), reasons
end

return InterestModel
