--!strict
--[[
	Authoritative interaction request validator.

	Owns payload shape checks, range checks, line of sight, character-owned
	instance rejection, and cooldown checks. It does not execute interactions or
	emit observations.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InteractionConfig = require(script.Parent.InteractionConfig)
local InteractionState = require(script.Parent.InteractionState)
local SharedTypes = require(ReplicatedStorage.Shared.PlayerExperienceTypes)

local InteractionValidator = {}

type InteractionDescriptor = SharedTypes.InteractionDescriptor
type InteractionRequest = SharedTypes.InteractionRequest

local ResultCode = SharedTypes.ResultCode

local function rootPart(player: Player): BasePart?
	local character = player.Character

	if character == nil then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function targetPosition(instance: Instance?): Vector3?
	if instance == nil then
		return nil
	end

	if instance:IsA("BasePart") then
		return instance.Position
	elseif instance:IsA("Model") then
		return instance:GetPivot().Position
	elseif instance:IsA("Attachment") then
		return instance.WorldPosition
	end

	return nil
end

function InteractionValidator.sanitizeRequest(payload: any): InteractionRequest?
	if type(payload) ~= "table" then
		return nil
	end

	if type(payload.interactionId) ~= "string" or payload.interactionId == "" then
		return nil
	end

	return {
		interactionId = payload.interactionId,
		target = if typeof(payload.target) == "Instance" then payload.target else nil,
		clientFocusId = if type(payload.clientFocusId) == "string"
			then payload.clientFocusId
			else nil,
		clientDistance = if type(payload.clientDistance) == "number"
			then payload.clientDistance
			else nil,
		inputKind = if type(payload.inputKind) == "string" then payload.inputKind else nil,
		requestId = if type(payload.requestId) == "string" then payload.requestId else nil,
	}
end

function InteractionValidator.isDescendantOfCharacter(player: Player, instance: Instance?): boolean
	local character = player.Character

	return character ~= nil and instance ~= nil and instance:IsDescendantOf(character)
end

function InteractionValidator.inRange(player: Player, descriptor: InteractionDescriptor): boolean
	local root = rootPart(player)
	local target = targetPosition(descriptor.instance)

	if root == nil or target == nil then
		return false
	end

	local maxDistance = descriptor.maxDistance + InteractionConfig.RaycastPadding

	return (root.Position - target).Magnitude <= maxDistance
end

function InteractionValidator.hasLineOfSight(
	player: Player,
	descriptor: InteractionDescriptor
): boolean
	if not descriptor.requiresLineOfSight then
		return true
	end

	local root = rootPart(player)
	local target = targetPosition(descriptor.instance)

	if root == nil or target == nil then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if player.Character ~= nil then { player.Character } else {}

	local hit = Workspace:Raycast(root.Position, target - root.Position, params)

	if hit == nil then
		return true
	end

	local instance = descriptor.instance

	return instance ~= nil and (hit.Instance == instance or hit.Instance:IsDescendantOf(instance))
end

function InteractionValidator.validateDescriptor(
	player: Player,
	descriptor: InteractionDescriptor
): (boolean, string, string)
	if
		descriptor.instance ~= nil
		and InteractionValidator.isDescendantOfCharacter(player, descriptor.instance)
	then
		return false, ResultCode.PermissionDenied, "Cannot interact with character-owned instances."
	end

	if not descriptor.enabled then
		return false, ResultCode.InteractionDisabled, "Interaction is disabled."
	end

	if
		InteractionState.isOnCooldown(
			player,
			descriptor.id,
			InteractionConfig.DefaultCooldownSeconds
		)
	then
		return false, ResultCode.InvalidRequest, "Interaction is on cooldown."
	end

	if not InteractionValidator.inRange(player, descriptor) then
		return false, ResultCode.OutOfRange, "Interaction is out of range."
	end

	if not InteractionValidator.hasLineOfSight(player, descriptor) then
		return false, ResultCode.LineOfSightBlocked, "Interaction line of sight is blocked."
	end

	return true, ResultCode.Ok, "Interaction accepted."
end

function InteractionValidator.validate(): (boolean, string?)
	return true, nil
end

return InteractionValidator
