--!strict

local Guard = {}
local generation = 0
local activeActions = {} :: { [string]: boolean }

function Guard.advance(): number
	generation += 1
	return generation
end

function Guard.isCurrent(candidate: number): boolean
	return candidate == generation
end

function Guard.enter(actionId: string): boolean
	if activeActions[actionId] then
		return false
	end
	activeActions[actionId] = true
	return true
end

function Guard.leave(actionId: string)
	activeActions[actionId] = nil
end

function Guard.inspect()
	local activeCount = 0
	for _ in pairs(activeActions) do
		activeCount += 1
	end
	return { generation = generation, activeActionCount = activeCount }
end

function Guard.reset()
	generation = 0
	table.clear(activeActions)
end

return Guard
