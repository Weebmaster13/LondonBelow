--!strict

local Controller = {}
local starts = {}
local head = 1
local MAX_STARTS = 32
local WINDOW_SECONDS = 1

local function compact(now: number)
	local cutoff = now - WINDOW_SECONDS
	while head <= #starts and starts[head] <= cutoff do
		head += 1
	end
	if head > 64 then
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
	if #starts - head + 1 >= MAX_STARTS then
		return false, "GuiThemeRateLimited"
	end
	starts[#starts + 1] = now
	return true, nil
end

function Controller.snapshot(now: number)
	compact(now)
	return {
		startsInWindow = math.max(0, #starts - head + 1),
		maxStartsPerWindow = MAX_STARTS,
		startWindowSeconds = WINDOW_SECONDS,
	}
end
function Controller.reset()
	starts = {}
	head = 1
end

return Controller
