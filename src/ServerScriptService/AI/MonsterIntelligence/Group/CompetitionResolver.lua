--!strict
-- Resolves duplicate monster interest without moving or spawning anything.

local CompetitionResolver = {}

function CompetitionResolver.chooseCandidate(candidates: { any }): any?
	local best = nil
	for _, candidate in ipairs(candidates) do
		if best == nil or (candidate.priority or 0) > (best.priority or 0) then
			best = candidate
		end
	end
	return best
end

function CompetitionResolver.resolve(candidates: { any })
	local winner = CompetitionResolver.chooseCandidate(candidates)
	return {
		winner = winner,
		deferred = if winner == nil then candidates else {},
		reason = if winner == nil then "no candidates" else "highest priority candidate selected",
	}
end

return CompetitionResolver
