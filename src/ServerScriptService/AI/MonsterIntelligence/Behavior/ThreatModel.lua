--!strict
-- Threat is pressure relevance, not aggression or attack permission.

local ThreatModel = {}

function ThreatModel.score(input: any): (number, { string })
	local interest = if type(input) == "table" and type(input.interest) == "number"
		then input.interest
		else 0
	local memoryConfidence = if type(input) == "table"
			and type(input.memoryConfidence) == "number"
		then input.memoryConfidence
		else 0
	local identityExposure = if type(input) == "table"
			and type(input.identityExposure) == "number"
		then input.identityExposure
		else 0
	local groupSplit = if type(input) == "table" and input.groupSplit == true then 12 else 0

	local score = interest * 0.45 + memoryConfidence * 25 + identityExposure * 30 + groupSplit
	local reasons = { "threat:interest" }
	if memoryConfidence > 0.5 then
		table.insert(reasons, "threat:remembered-target")
	end
	if identityExposure > 0.4 then
		table.insert(reasons, "threat:identity-exposure")
	end
	if groupSplit > 0 then
		table.insert(reasons, "threat:party-split")
	end
	return math.clamp(score, 0, 100), reasons
end

return ThreatModel
