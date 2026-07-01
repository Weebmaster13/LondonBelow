--!strict

local PuzzleDiagnostics = {}

function PuzzleDiagnostics.capture(dependencies: { [string]: any })
	return {
		registry = dependencies.PuzzleRegistry.inspect(),
		state = dependencies.PuzzleState.inspect(),
		hints = dependencies.PuzzleHintService.inspect(),
		health = {
			healthy = true,
			status = "Ready",
			message = "Puzzle Runtime validates graph-based puzzles without content.",
		},
	}
end

return PuzzleDiagnostics
