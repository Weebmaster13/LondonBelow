--!strict
-- Isolated snapshots for Puzzle Runtime Foundation.

local Serialization = require(script.Parent.PuzzleSerialization)
local Types = require(script.Parent.PuzzleTypes)

local Snapshots = {}

function Snapshots.capture(state: any)
	local snapshot = Serialization.deepCopy({
		mode = Types.Mode,
		capturedAt = os.clock(),
		state = state.inspect(),
	})
	state.recordSnapshot({
		capturedAt = snapshot.capturedAt,
		puzzleCount = snapshot.state.puzzleCount,
		progressCount = snapshot.state.progressCount,
	})
	return snapshot
end

return Snapshots
