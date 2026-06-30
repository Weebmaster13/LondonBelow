--!strict

local Config = require(script.Parent.LanternConfig)
local Types = require(script.Parent.LanternTypes)

local LanternState = {}

type LanternStatus = Types.LanternStatus

local states: { [number]: LanternStatus } = {}
local recentChanges: { any } = {}
local counters = {
	equipped = 0,
	unequipped = 0,
	turnedOn = 0,
	turnedOff = 0,
	lowBattery = 0,
	overused = 0,
	rejected = 0,
}

local function remember(change: any)
	table.insert(recentChanges, change)

	while #recentChanges > 80 do
		table.remove(recentChanges, 1)
	end
end

local function cloneStatus(status: LanternStatus): LanternStatus
	return table.clone(status)
end

function LanternState.ensure(player: Player): LanternStatus
	local state = states[player.UserId]

	if state == nil then
		state = {
			userId = player.UserId,
			equipped = false,
			on = false,
			battery = Config.DefaultBattery,
			overuseScore = 0,
			lastToggleAt = 0,
			lastObservationAt = 0,
			zoneId = "unknown",
			zoneKind = "Unknown",
			protected = true,
		}
		states[player.UserId] = state
	end

	return state
end

function LanternState.get(player: Player): LanternStatus?
	local state = states[player.UserId]
	return if state ~= nil then cloneStatus(state) else nil
end

function LanternState.patch(player: Player, patch: { [string]: any }): LanternStatus
	local state = LanternState.ensure(player)

	for key, value in pairs(patch) do
		state[key] = value
	end

	remember({
		at = os.clock(),
		userId = player.UserId,
		state = cloneStatus(state),
	})

	return cloneStatus(state)
end

function LanternState.incrementCounter(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
	end
end

function LanternState.recordRejected()
	counters.rejected += 1
end

function LanternState.remove(player: Player)
	states[player.UserId] = nil
end

function LanternState.inspect()
	local copiedStates = {}
	local stateCount = 0

	for userId, state in pairs(states) do
		stateCount += 1
		copiedStates[userId] = cloneStatus(state)
	end

	return {
		states = copiedStates,
		stateCount = stateCount,
		recentChanges = table.clone(recentChanges),
		counters = table.clone(counters),
	}
end

function LanternState.clear()
	table.clear(states)
	table.clear(recentChanges)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return LanternState
