--!strict

local Config = require(script.Parent.LanternConfig)
local Types = require(script.Parent.LanternTypes)

local LanternState = {}

type LanternStatus = Types.LanternStatus

local states: { [number]: LanternStatus } = {}
local recentChanges: { any } = {}
local requestIdsByUserId: { [number]: { [string]: boolean } } = {}
local requestOrderByUserId: { [number]: { string } } = {}
local counters = {
	equipped = 0,
	unequipped = 0,
	turnedOn = 0,
	turnedOff = 0,
	lowBattery = 0,
	lowBatterySuppressed = 0,
	overused = 0,
	overuseSuppressed = 0,
	rejected = 0,
	replayed = 0,
	directorRequests = 0,
	directorRequestsSuppressed = 0,
}

local function remember(change: any)
	table.insert(recentChanges, change)

	while #recentChanges > Config.RecentChangeLimit do
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
			lastLowBatteryAt = 0,
			lastOveruseAt = 0,
			lastDirectorRequestAt = 0,
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

function LanternState.isReplay(player: Player, requestId: string?): boolean
	if requestId == nil or requestId == "" then
		return false
	end

	local seen = requestIdsByUserId[player.UserId]
	return seen ~= nil and seen[requestId] == true
end

function LanternState.rememberRequest(player: Player, requestId: string?)
	if requestId == nil or requestId == "" then
		return
	end

	local seen = requestIdsByUserId[player.UserId]
	local order = requestOrderByUserId[player.UserId]

	if seen == nil then
		seen = {}
		requestIdsByUserId[player.UserId] = seen
	end

	if order == nil then
		order = {}
		requestOrderByUserId[player.UserId] = order
	end

	if seen[requestId] then
		return
	end

	seen[requestId] = true
	table.insert(order, requestId)

	while #order > Config.RequestReplayLimit do
		local oldest = table.remove(order, 1)
		if oldest ~= nil then
			seen[oldest] = nil
		end
	end
end

function LanternState.recordReplay()
	counters.replayed += 1
end

function LanternState.recordDirectorRequest()
	counters.directorRequests += 1
end

function LanternState.recordDirectorRequestSuppressed()
	counters.directorRequestsSuppressed += 1
end

function LanternState.remove(player: Player)
	states[player.UserId] = nil
	requestIdsByUserId[player.UserId] = nil
	requestOrderByUserId[player.UserId] = nil
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
		replayCachePlayers = table.clone(requestOrderByUserId),
	}
end

function LanternState.clear()
	table.clear(states)
	table.clear(recentChanges)
	table.clear(requestIdsByUserId)
	table.clear(requestOrderByUserId)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return LanternState
