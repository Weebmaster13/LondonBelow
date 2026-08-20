--!strict

local Types = require(script.Parent.RobloxGuiAnimationTypes)

local Controller = {}
local starts = {}
local head = 1

local function compact(now: number)
	local cutoff = now - Types.Limits.startWindowSeconds
	while head <= #starts and starts[head] <= cutoff do
		head += 1
	end
	if head > 64 and head > (#starts / 2) then
		local retained = {}
		for index = head, #starts do
			retained[#retained + 1] = starts[index]
		end
		starts = retained
		head = 1
	end
end

function Controller.allow(now: number): (boolean, string?)
	compact(now)
	if (#starts - head + 1) >= Types.Limits.maxStartsPerWindow then
		return false, Types.FailureType.RateLimited
	end
	starts[#starts + 1] = now
	return true
end

function Controller.reset()
	starts = {}
	head = 1
end

function Controller.snapshot(now: number)
	compact(now)
	return table.freeze({
		startsInWindow = #starts - head + 1,
		limit = Types.Limits.maxStartsPerWindow,
		windowSeconds = Types.Limits.startWindowSeconds,
	})
end

return Controller
