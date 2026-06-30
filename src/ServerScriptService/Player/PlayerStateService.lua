--!strict
--[[
	Authoritative run-local player state store.

	Owns lifecycle state, movement mode, ground state, locks, and room/area/
	chapter hooks. It does not persist data or decide gameplay objectives.
]]

local PlayerTypes = require(script.Parent.PlayerTypes)

local PlayerStateService = {}

type PlayerRuntimeState = PlayerTypes.PlayerRuntimeState
type PlayerStatePatch = PlayerTypes.PlayerStatePatch

local statesByUserId: { [number]: PlayerRuntimeState } = {}

local VALID_LIFECYCLE = {
	Alive = true,
	Dead = true,
	Spectating = true,
}

local VALID_GROUND = {
	Grounded = true,
	Airborne = true,
}

local VALID_MOVEMENT = {
	Walk = true,
	Sprint = true,
	Crouch = true,
	Stopped = true,
}

local function copyArray(values: { string }): { string }
	return table.clone(values)
end

local function cloneState(state: PlayerRuntimeState): PlayerRuntimeState
	return {
		userId = state.userId,
		lifecycleState = state.lifecycleState,
		groundState = state.groundState,
		movementMode = state.movementMode,
		interactionLocked = state.interactionLocked,
		cinematicLocked = state.cinematicLocked,
		currentRoomId = state.currentRoomId,
		currentAreaId = state.currentAreaId,
		currentChapterId = state.currentChapterId,
		movementRestrictions = copyArray(state.movementRestrictions),
		stamina = state.stamina,
		fear = state.fear,
		injury = state.injury,
		updatedAt = state.updatedAt,
	}
end

local function defaultState(player: Player): PlayerRuntimeState
	return {
		userId = player.UserId,
		lifecycleState = "Alive",
		groundState = "Grounded",
		movementMode = "Stopped",
		interactionLocked = false,
		cinematicLocked = false,
		currentRoomId = nil,
		currentAreaId = nil,
		currentChapterId = nil,
		movementRestrictions = {},
		stamina = nil,
		fear = nil,
		injury = nil,
		updatedAt = os.clock(),
	}
end

function PlayerStateService.ensure(player: Player): PlayerRuntimeState
	local state = statesByUserId[player.UserId]

	if state == nil then
		state = defaultState(player)
		statesByUserId[player.UserId] = state
	end

	return cloneState(state)
end

function PlayerStateService.patch(player: Player, patch: PlayerStatePatch): PlayerRuntimeState
	local state = statesByUserId[player.UserId] or defaultState(player)

	if patch.lifecycleState ~= nil then
		assert(VALID_LIFECYCLE[patch.lifecycleState], "invalid lifecycleState")
		state.lifecycleState = patch.lifecycleState
	end

	if patch.groundState ~= nil then
		assert(VALID_GROUND[patch.groundState], "invalid groundState")
		state.groundState = patch.groundState
	end

	if patch.movementMode ~= nil then
		assert(VALID_MOVEMENT[patch.movementMode], "invalid movementMode")
		state.movementMode = patch.movementMode
	end

	if patch.interactionLocked ~= nil then
		state.interactionLocked = patch.interactionLocked
	end

	if patch.cinematicLocked ~= nil then
		state.cinematicLocked = patch.cinematicLocked
	end

	if patch.currentRoomId ~= nil then
		state.currentRoomId = patch.currentRoomId
	end

	if patch.currentAreaId ~= nil then
		state.currentAreaId = patch.currentAreaId
	end

	if patch.currentChapterId ~= nil then
		state.currentChapterId = patch.currentChapterId
	end

	if patch.movementRestrictions ~= nil then
		state.movementRestrictions = copyArray(patch.movementRestrictions)
	end

	if patch.stamina ~= nil then
		state.stamina = patch.stamina
	end

	if patch.fear ~= nil then
		state.fear = patch.fear
	end

	if patch.injury ~= nil then
		state.injury = patch.injury
	end

	state.updatedAt = os.clock()
	statesByUserId[player.UserId] = state

	return cloneState(state)
end

function PlayerStateService.remove(player: Player)
	statesByUserId[player.UserId] = nil
end

function PlayerStateService.clear()
	table.clear(statesByUserId)
end

function PlayerStateService.inspect()
	local copied = {}

	for userId, state in pairs(statesByUserId) do
		copied[userId] = cloneState(state)
	end

	return {
		count = #PlayerStateService.list(),
		statesByUserId = copied,
	}
end

function PlayerStateService.list(): { PlayerRuntimeState }
	local states = {}

	for _, state in pairs(statesByUserId) do
		table.insert(states, cloneState(state))
	end

	return states
end

function PlayerStateService.validate(): (boolean, string?)
	return true, nil
end

return PlayerStateService
