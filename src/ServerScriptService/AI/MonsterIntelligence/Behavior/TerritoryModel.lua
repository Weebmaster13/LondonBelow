--!strict
-- Territory scoring is advisory only; it never moves or blocks entities.

local TerritoryModel = {}

function TerritoryModel.score(input: any): (number, { string })
	local inTerritory = type(input) == "table" and input.inTerritory == true
	local contested = type(input) == "table" and input.contested == true
	local score = if inTerritory then 35 else 10
	local reasons = { if inTerritory then "territory:home" else "territory:outside" }

	if contested then
		score += 18
		table.insert(reasons, "territory:contested")
	end

	return math.clamp(score, 0, 100), reasons
end

return TerritoryModel
