--!strict

local Config = require(script.Parent.DarknessConfig)
local Types = require(script.Parent.DarknessTypes)

local DarknessExposureTracker = {}

type ExposureState = Types.ExposureState

local states: { [number]: ExposureState } = {}
local recentEvents: { any } = {}
local counters = {
	entered = 0,
	exited = 0,
	increased = 0,
	protected = 0,
	directorRequests = 0,
}

local function cloneState(state: ExposureState): ExposureState
	return table.clone(state)
end

local function remember(event: any)
	table.insert(recentEvents, event)

	while #recentEvents > Config.RecentEventLimit do
		table.remove(recentEvents, 1)
	end
end

function DarknessExposureTracker.ensure(player: Player): ExposureState
	local state = states[player.UserId]

	if state == nil then
		state = {
			userId = player.UserId,
			inDarkness = false,
			exposure = 0,
			enteredAt = nil,
			lastUpdatedAt = os.clock(),
			zoneId = "unknown",
			zoneKind = "Unknown",
			protected = true,
		}
		states[player.UserId] = state
	end

	return state
end

function DarknessExposureTracker.enter(
	player: Player,
	zoneId: string,
	zoneKind: string,
	protected: boolean
)
	local state = DarknessExposureTracker.ensure(player)
	state.inDarkness = true
	state.enteredAt = os.clock()
	state.lastUpdatedAt = state.enteredAt
	state.zoneId = zoneId
	state.zoneKind = zoneKind
	state.protected = protected
	counters.entered += 1
	if protected then
		counters.protected += 1
	end
	remember({
		at = os.clock(),
		kind = "Entered",
		userId = player.UserId,
		state = cloneState(state),
	})
	return cloneState(state)
end

function DarknessExposureTracker.exit(player: Player)
	local state = DarknessExposureTracker.ensure(player)
	state.inDarkness = false
	state.enteredAt = nil
	state.lastUpdatedAt = os.clock()
	counters.exited += 1
	remember({ at = os.clock(), kind = "Exited", userId = player.UserId, state = cloneState(state) })
	return cloneState(state)
end

function DarknessExposureTracker.update(player: Player, intensity: number, now: number)
	local state = DarknessExposureTracker.ensure(player)
	local elapsed = math.max(0, now - state.lastUpdatedAt)
	state.lastUpdatedAt = now

	if state.inDarkness and not state.protected then
		state.exposure = math.clamp(
			state.exposure + (Config.ExposureIncreasePerSecond * intensity * elapsed),
			0,
			Config.MaxExposure
		)
		counters.increased += 1
	else
		state.exposure = math.clamp(
			state.exposure - (Config.ExposureDecayPerSecond * elapsed),
			0,
			Config.MaxExposure
		)
	end

	remember({ at = now, kind = "Updated", userId = player.UserId, state = cloneState(state) })
	return cloneState(state)
end

function DarknessExposureTracker.recordDirectorRequest()
	counters.directorRequests += 1
end

function DarknessExposureTracker.remove(player: Player)
	states[player.UserId] = nil
end

function DarknessExposureTracker.inspect()
	local copied = {}

	for userId, state in pairs(states) do
		copied[userId] = cloneState(state)
	end

	return {
		states = copied,
		recentEvents = table.clone(recentEvents),
		counters = table.clone(counters),
	}
end

function DarknessExposureTracker.clear()
	table.clear(states)
	table.clear(recentEvents)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return DarknessExposureTracker
