--!strict
-- Computes search priority from stale but meaningful information.

local SearchModel = {}

function SearchModel.score(input: any): (number, { string })
	local memoryAge = if type(input) == "table"
			and type(input.memoryAgeSeconds) == "number"
		then math.max(0, input.memoryAgeSeconds)
		else 999
	local confidence = if type(input) == "table"
			and type(input.memoryConfidence) == "number"
		then input.memoryConfidence
		else 0
	local falseLeadPenalty = if type(input) == "table"
			and type(input.falseLeadCount) == "number"
		then input.falseLeadCount * 8
		else 0

	local freshness = math.max(0, 60 - memoryAge) / 60
	local score = freshness * confidence * 100 - falseLeadPenalty
	local reasons = { "search:memory-freshness" }
	if falseLeadPenalty > 0 then
		table.insert(reasons, "search:false-lead-penalty")
	end
	return math.clamp(score, 0, 100), reasons
end

return SearchModel
