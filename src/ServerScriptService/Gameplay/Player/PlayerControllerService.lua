--!strict
--[[
	Server authority companion for player movement.

	Owns movement profile application, server-side movement state tracking, and
	movement observations. It does not implement client camera, final stamina,
	animation, or horror effects.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Logger = require(Core.Logger)

local ObservationService = require(ServerScriptService.Horror.Observation.ObservationService)
local PlayerExperienceConfig = require(ReplicatedStorage.Config.PlayerExperienceConfig)
local Types = require(ReplicatedStorage.Shared.PlayerExperienceTypes)

local PlayerControllerService = {}

type MovementProfile = Types.MovementProfile
type PlayerInputState = Types.PlayerInputState

local log = Logger.scope("PlayerControllerService")
local profilesByUserId: { [number]: MovementProfile } = {}
local inputByUserId: { [number]: PlayerInputState } = {}
local lastObservationByUserId: { [number]: { [string]: number } } = {}

local OBSERVATION_THROTTLE_SECONDS = 0.75

local function cloneProfile(profile: MovementProfile): MovementProfile
	return table.clone(profile) :: MovementProfile
end

local function defaultProfile(): MovementProfile
	return cloneProfile(PlayerExperienceConfig.DefaultMovementProfile)
end

local function humanoidFor(player: Player): Humanoid?
	local character = player.Character

	if character == nil then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function throttleObservation(player: Player, id: string): boolean
	local now = os.clock()
	local byId = lastObservationByUserId[player.UserId]

	if byId == nil then
		byId = {}
		lastObservationByUserId[player.UserId] = byId
	end

	local last = byId[id]

	if last ~= nil and now - last < OBSERVATION_THROTTLE_SECONDS then
		return false
	end

	byId[id] = now
	return true
end

local function observeMovement(player: Player, id: string, metadata: { [string]: any }?)
	if not throttleObservation(player, id) then
		return
	end

	ObservationService.observe({
		id = id,
		player = player,
		source = "PlayerControllerService",
		metadata = metadata or {},
	})
end

local function applyProfile(player: Player)
	local profile = profilesByUserId[player.UserId] or defaultProfile()
	local humanoid = humanoidFor(player)

	if humanoid == nil then
		return
	end

	humanoid.WalkSpeed = profile.walkSpeed
	humanoid.JumpPower = profile.jumpPower
	humanoid.UseJumpPower = true
end

local function movementModeFromState(state: PlayerInputState): Types.MovementMode
	if state.jumping then
		return "Airborne"
	elseif state.crouching then
		return "Crouch"
	elseif state.sprinting then
		return "Sprint"
	end

	return "Walk"
end

function PlayerControllerService.setMovementProfile(player: Player, profile: MovementProfile)
	profilesByUserId[player.UserId] = cloneProfile(profile)
	applyProfile(player)
end

function PlayerControllerService.getMovementProfile(player: Player): MovementProfile
	return cloneProfile(profilesByUserId[player.UserId] or defaultProfile())
end

function PlayerControllerService.updateInputState(
	player: Player,
	state: PlayerInputState
): (boolean, string?)
	local profile = profilesByUserId[player.UserId] or defaultProfile()
	local sanitized: PlayerInputState = {
		sprinting = profile.allowSprint and state.sprinting == true,
		crouching = profile.allowCrouch and state.crouching == true,
		jumping = profile.allowJump and state.jumping == true,
		movementMode = "Walk",
	}

	sanitized.movementMode = movementModeFromState(sanitized)
	inputByUserId[player.UserId] = sanitized

	local humanoid = humanoidFor(player)

	if humanoid ~= nil then
		if sanitized.crouching then
			humanoid.WalkSpeed = profile.crouchSpeed
		elseif sanitized.sprinting then
			humanoid.WalkSpeed = profile.sprintSpeed
		else
			humanoid.WalkSpeed = profile.walkSpeed
		end

		humanoid.JumpPower = if profile.allowJump then profile.jumpPower else 0
	end

	if sanitized.sprinting then
		observeMovement(player, "Movement.StartSprint", {})
	elseif sanitized.crouching then
		observeMovement(player, "Movement.Crouch", {})
	elseif sanitized.jumping then
		observeMovement(player, "Movement.Jump", {})
	else
		observeMovement(player, "Movement.Walk", {})
	end

	return true, nil
end

function PlayerControllerService.handleCharacterAdded(player: Player)
	if profilesByUserId[player.UserId] == nil then
		profilesByUserId[player.UserId] = defaultProfile()
	end

	applyProfile(player)
end

function PlayerControllerService.handlePlayerRemoving(player: Player)
	profilesByUserId[player.UserId] = nil
	inputByUserId[player.UserId] = nil
	lastObservationByUserId[player.UserId] = nil
end

function PlayerControllerService.inspect()
	return {
		profileCount = table.clone(profilesByUserId),
		inputStates = table.clone(inputByUserId),
	}
end

function PlayerControllerService.validate(): (boolean, string?)
	local profile = PlayerExperienceConfig.DefaultMovementProfile

	if profile.walkSpeed <= 0 or profile.sprintSpeed < profile.walkSpeed then
		return false, "Movement profile speeds are invalid"
	end

	if profile.crouchSpeed <= 0 or profile.crouchSpeed > profile.walkSpeed then
		return false, "Crouch speed must be positive and below walk speed"
	end

	return true, nil
end

function PlayerControllerService.runSelfChecks()
	local ok, err = PlayerControllerService.validate()

	return {
		ok = ok,
		error = err,
	}
end

log.debug("PlayerControllerService module loaded")

return PlayerControllerService
