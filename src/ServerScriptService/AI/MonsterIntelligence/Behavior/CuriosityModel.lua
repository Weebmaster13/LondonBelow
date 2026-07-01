--!strict
-- Curiosity grows from novelty and decays naturally elsewhere.

local CuriosityModel = {}

function CuriosityModel.score(input: any): (number, { string })
	local score = 0
	local reasons = {}
	local novelty = if type(input) == "table" and type(input.novelty) == "table"
		then input.novelty
		else {}

	for _, key in ipairs({
		"newNoise",
		"missingMemory",
		"openedDoor",
		"missingObject",
		"unexpectedPlayerBehavior",
	}) do
		if novelty[key] == true then
			score += 16
			table.insert(reasons, "curiosity:" .. key)
		end
	end

	return math.clamp(score, 0, 100), reasons
end

return CuriosityModel
