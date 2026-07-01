--!strict
-- Chooses an investigation priority from interest, curiosity, and patience.

local InvestigationModel = {}

function InvestigationModel.score(input: any): (number, { string })
	local interest = if type(input) == "table" and type(input.interest) == "number"
		then input.interest
		else 0
	local curiosity = if type(input) == "table" and type(input.curiosity) == "number"
		then input.curiosity
		else 0
	local patience = if type(input) == "table" and type(input.patience) == "number"
		then input.patience
		else 50
	local score = interest * 0.45 + curiosity * 0.35 + patience * 0.2
	return math.clamp(score, 0, 100), { "investigation:interest-curiosity-patience" }
end

return InvestigationModel
