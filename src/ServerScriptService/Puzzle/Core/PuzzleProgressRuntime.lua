--!strict
-- Puzzle progress records. These are state schemas, not solving execution.

local Validation = require(script.Parent.PuzzleValidation)

local Progress = {}

function Progress.record(state: any, record: any): (boolean, string?)
	if type(record) ~= "table" then
		return false, "progress record must be a table"
	end
	local safe, reason = Validation.safePayload(record)
	if not safe then
		return false, reason
	end
	if not Validation.id(record.progressId) then
		return false, "progressId is required"
	end
	if not Validation.id(record.puzzleId) then
		return false, "puzzleId is required"
	end
	if not state.exists(record.puzzleId) then
		return false, "unknown puzzleId"
	end
	state.recordProgress({
		progressId = record.progressId,
		puzzleId = record.puzzleId,
		state = record.state or {},
		context = record.context or {},
		recordedAt = os.clock(),
		wouldExecutePuzzle = false,
	})
	return true, nil
end

return Progress
