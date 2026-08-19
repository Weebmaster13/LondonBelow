--!strict

local Types = require(script.Parent.RobloxGuiInteractionTypes)

local Budget = {}
local windowStartedAt = 0
local used = 0
local rejected = 0

function Budget.consume(now: number): boolean
	if windowStartedAt == 0 or now - windowStartedAt >= 1 then
		windowStartedAt = now
		used = 0
	end
	if used >= Types.Limits.maxReconciliationsPerWindow then
		rejected += 1
		return false
	end
	used += 1
	return true
end

function Budget.inspect()
	return {
		windowStartedAt = windowStartedAt,
		used = used,
		rejected = rejected,
		limit = Types.Limits.maxReconciliationsPerWindow,
	}
end

function Budget.reset()
	windowStartedAt = 0
	used = 0
	rejected = 0
end

return Budget
