--!strict

local PuzzleState = require(script.Parent.PuzzleState)

local PuzzleHintService = {}

local hintCooldowns: { [string]: number } = {}
local MinHintDelaySeconds = 20

function PuzzleHintService.requestHint(
	puzzleId: string,
	definition: any,
	now: number
): (boolean, string, string?)
	PuzzleState.recordHintRequest(puzzleId)
	local lastShown = hintCooldowns[puzzleId] or 0
	if now - lastShown < MinHintDelaySeconds then
		return false, "hint delay has not elapsed", nil
	end
	local status = PuzzleState.get(puzzleId)
	local nextIndex = if status ~= nil then status.hintsShown + 1 else 1
	local hint = definition.hints[nextIndex]
	if hint == nil then
		return false, "no progressive hint is available", nil
	end
	hintCooldowns[puzzleId] = now
	PuzzleState.recordHint(puzzleId)
	return true, "hint approved for presentation hook", hint
end

function PuzzleHintService.inspect()
	local count = 0
	for _ in pairs(hintCooldowns) do
		count += 1
	end
	return {
		hintCooldownCount = count,
		hintCooldowns = table.clone(hintCooldowns),
	}
end

function PuzzleHintService.clear()
	table.clear(hintCooldowns)
end

return PuzzleHintService
