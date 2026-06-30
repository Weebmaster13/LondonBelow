--!strict

local Types = require(script.Parent.EnvironmentDirectorTypes)
local Config = require(script.Parent.EnvironmentDirectorConfig)

local EnvironmentState = {}

type PressureState = Types.PressureState

local pressureState: PressureState = "Calm"
local buildingAttention = 0
local zonePressure: { [string]: { state: PressureState, score: number, updatedAt: number } } = {}
local reactionCooldowns: { [string]: number } = {}
local zoneCooldowns: { [string]: number } = {}

function EnvironmentState.getPressureState(): PressureState
	return pressureState
end

function EnvironmentState.setPressureState(nextState: PressureState)
	if not Types.ValidPressureStates[nextState] then
		return false
	end

	pressureState = nextState
	return true
end

function EnvironmentState.setBuildingAttention(value: number)
	buildingAttention = math.clamp(value, 0, 1)
end

function EnvironmentState.getBuildingAttention(): number
	return buildingAttention
end

function EnvironmentState.setZonePressure(
	zoneId: string,
	state: PressureState,
	score: number,
	at: number
)
	if zoneId == "" or not Types.ValidPressureStates[state] then
		return false
	end

	zonePressure[zoneId] = {
		state = state,
		score = math.clamp(score, -1, 1),
		updatedAt = at,
	}

	return true
end

function EnvironmentState.getZonePressure(zoneId: string)
	return zonePressure[zoneId]
end

function EnvironmentState.isReactionCoolingDown(reactionId: string, at: number): boolean
	local expiresAt = reactionCooldowns[reactionId]
	return expiresAt ~= nil and at < expiresAt
end

function EnvironmentState.isZoneCoolingDown(reactionId: string, zoneId: string, at: number): boolean
	local expiresAt = zoneCooldowns[reactionId .. ":" .. zoneId]
	return expiresAt ~= nil and at < expiresAt
end

function EnvironmentState.setCooldowns(
	reactionId: string,
	zoneId: string,
	reactionSeconds: number,
	zoneSeconds: number,
	at: number
)
	reactionCooldowns[reactionId] = at + reactionSeconds
	zoneCooldowns[reactionId .. ":" .. zoneId] = at + zoneSeconds
end

function EnvironmentState.pruneCooldowns(at: number)
	for reactionId, expiresAt in pairs(reactionCooldowns) do
		if at >= expiresAt then
			reactionCooldowns[reactionId] = nil
		end
	end

	for key, expiresAt in pairs(zoneCooldowns) do
		if at >= expiresAt then
			zoneCooldowns[key] = nil
		end
	end
end

function EnvironmentState.pruneZonePressure(at: number)
	for zoneId, pressure in pairs(zonePressure) do
		if at - pressure.updatedAt > Config.ZonePressureTtlSeconds then
			zonePressure[zoneId] = nil
		end
	end
end

function EnvironmentState.inspect()
	return {
		pressureState = pressureState,
		buildingAttention = buildingAttention,
		zonePressure = table.clone(zonePressure),
		reactionCooldowns = table.clone(reactionCooldowns),
		zoneCooldowns = table.clone(zoneCooldowns),
	}
end

function EnvironmentState.reset()
	pressureState = "Calm"
	buildingAttention = 0
	table.clear(zonePressure)
	table.clear(reactionCooldowns)
	table.clear(zoneCooldowns)
end

return EnvironmentState
