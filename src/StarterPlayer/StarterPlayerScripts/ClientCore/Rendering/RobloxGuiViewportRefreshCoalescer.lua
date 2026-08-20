--!strict

local Coalescer = {}
local ticket = 0
local pending = false
local scheduled = 0
local executed = 0
local superseded = 0
local enabled = true

function Coalescer.schedule(callback: () -> ())
	enabled = true
	ticket += 1
	local ownedTicket = ticket
	scheduled += 1
	if pending then
		superseded += 1
		return
	end
	pending = true
	task.defer(function()
		if not enabled then
			return
		end
		pending = false
		if ownedTicket ~= ticket then
			superseded += 1
			Coalescer.schedule(callback)
			return
		end
		executed += 1
		callback()
	end)
end

function Coalescer.cancel()
	enabled = false
	ticket += 1
	pending = false
end

function Coalescer.inspect()
	return { pending = pending, scheduled = scheduled, executed = executed, superseded = superseded }
end

return Coalescer
