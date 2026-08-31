--!strict

local Runtime = {}
local initialized = false
local active = false
local chaseId = 0
local targetUserId: number? = nil
local counters = { started = 0, escaped = 0, deaths = 0, cancelled = 0 }

function Runtime.initialize()
	initialized = true
	active = false
	chaseId = 0
	targetUserId = nil
	counters.started = 0
	counters.escaped = 0
	counters.deaths = 0
	counters.cancelled = 0
end

function Runtime.start(target: Player?, reason: string): (boolean, string?)
	if active then
		return false, "ChaseAlreadyActive"
	end
	if target == nil then
		return false, "MissingTarget"
	end
	chaseId += 1
	active = true
	targetUserId = target.UserId
	counters.started += 1
	return true, reason
end

function Runtime.resolve(kind: string)
	if not active then
		return
	end
	if kind == "escaped" then
		counters.escaped += 1
	elseif kind == "death" then
		counters.deaths += 1
	else
		counters.cancelled += 1
	end
	active = false
	targetUserId = nil
end

function Runtime.inspect()
	return {
		initialized = initialized,
		active = active,
		chaseId = chaseId,
		targetUserId = targetUserId,
		counters = table.clone(counters),
		readableReactionWindow = true,
		routeDecisions = { "foyer_loop", "service_cutthrough", "gallery_drop", "street_escape" },
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize()
	local fakePlayer = { UserId = -1 } :: any
	local started = Runtime.start(fakePlayer, "self_check")
	Runtime.resolve("escaped")
	local missing = Runtime.start(nil, "self_check")
	return {
		ok = started == true and missing == false and counters.escaped == 1,
		counters = table.clone(counters),
	}
end

function Runtime.shutdown()
	active = false
	targetUserId = nil
	initialized = false
end

return Runtime
