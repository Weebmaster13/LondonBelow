--!strict
--[[
	Server-authoritative interaction framework.

	Owns request validation, range checks, line-of-sight checks, interaction
	execution handoff, observation emission, diagnostics, and snapshots.

	Does not own final UI, final object art, inventory truth, puzzle solving,
	Monster AI, Chapter 1 content, or horror pacing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Core = ServerScriptService.Core
local Logger = require(Core.Logger)

local ObservationService = require(ServerScriptService.Horror.Observation.ObservationService)
local PlayerExperienceConfig = require(ReplicatedStorage.Config.PlayerExperienceConfig)
local Types = require(ReplicatedStorage.Shared.PlayerExperienceTypes)

local FeedbackService = require(script.Parent.FeedbackService)
local InteractionRegistry = require(script.Parent.InteractionRegistry)
local ObjectInteractionHandlers = require(script.Parent.ObjectInteractionHandlers)

local InteractionService = {}

type InteractionDescriptor = Types.InteractionDescriptor
type InteractionRequest = Types.InteractionRequest
type InteractionResult = Types.InteractionResult

local ResultCode = Types.ResultCode
local log = Logger.scope("InteractionService")
local interactionsCompleted = 0
local interactionsRejected = 0
local focusRequests = 0
local lastResultByUserId: { [number]: InteractionResult } = {}

local function result(
	ok: boolean,
	code: string,
	message: string,
	interaction: InteractionDescriptor?,
	feedback: { Types.FeedbackInstruction }?
): InteractionResult
	return {
		ok = ok,
		code = code,
		message = message,
		interaction = interaction,
		feedback = feedback or {},
	}
end

local function reject(
	player: Player,
	code: string,
	message: string,
	descriptor: InteractionDescriptor?
): InteractionResult
	interactionsRejected += 1
	local rejected = result(false, code, message, descriptor, {})
	lastResultByUserId[player.UserId] = rejected

	return rejected
end

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
		local pivot = instance:GetPivot()
		return pivot.Position
	elseif instance:IsA("Attachment") then
		return instance.WorldPosition
	end

	return nil
end

local function isDescendantOfCharacter(player: Player, instance: Instance?): boolean
	local character = player.Character

	return character ~= nil and instance ~= nil and instance:IsDescendantOf(character)
end

local function hasLineOfSight(player: Player, descriptor: InteractionDescriptor): boolean
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

	local direction = target - root.Position
	local hit = Workspace:Raycast(root.Position, direction, params)

	if hit == nil then
		return true
	end

	local instance = descriptor.instance

	return instance ~= nil and (hit.Instance == instance or hit.Instance:IsDescendantOf(instance))
end

local function inRange(player: Player, descriptor: InteractionDescriptor): boolean
	local root = rootPart(player)
	local target = targetPosition(descriptor.instance)

	if root == nil or target == nil then
		return false
	end

	local maxDistance = descriptor.maxDistance + PlayerExperienceConfig.Interaction.raycastPadding

	return (root.Position - target).Magnitude <= maxDistance
end

local function observationMetadata(descriptor: InteractionDescriptor): { [string]: any }
	local metadata = table.clone(descriptor.metadata)
	metadata.interactionId = descriptor.id
	metadata.interactionKind = descriptor.kind

	if descriptor.kind == "Door" then
		metadata.doorId = descriptor.id
	elseif descriptor.kind == "Drawer" then
		metadata.drawerId = descriptor.id
	elseif descriptor.kind == "Cabinet" then
		metadata.cabinetId = descriptor.id
	elseif descriptor.kind == "Switch" then
		metadata.switchId = descriptor.id
	elseif descriptor.kind == "Lever" then
		metadata.leverId = descriptor.id
	elseif descriptor.kind == "Note" then
		metadata.noteId = descriptor.id
	elseif descriptor.kind == "Key" then
		metadata.keyId = descriptor.id
	elseif descriptor.kind == "Collectible" then
		metadata.collectibleId = descriptor.id
	end

	return metadata
end

local function emitObservation(player: Player, descriptor: InteractionDescriptor)
	if descriptor.observationId == nil or descriptor.observationId == "" then
		return
	end

	local ok, code = ObservationService.observe({
		id = descriptor.observationId,
		player = player,
		source = "InteractionService",
		metadata = observationMetadata(descriptor),
	})

	if not ok then
		log.withContext("WARN", "Interaction observation rejected", {
			interactionId = descriptor.id,
			observationId = descriptor.observationId,
			code = code,
		})
	end
end

local function sanitizeRequest(payload: any): InteractionRequest?
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

function InteractionService.requestInteraction(player: Player, payload: any): InteractionResult
	local request = sanitizeRequest(payload)

	if request == nil then
		return reject(player, ResultCode.InvalidRequest, "Interaction request is malformed.", nil)
	end

	local descriptor = InteractionRegistry.get(request.interactionId)

	if descriptor == nil and request.target ~= nil then
		descriptor = InteractionRegistry.getForInstance(request.target)
	end

	if descriptor == nil then
		return reject(player, ResultCode.UnknownInteraction, "Interaction is not registered.", nil)
	end

	if descriptor.instance ~= nil and isDescendantOfCharacter(player, descriptor.instance) then
		return reject(
			player,
			ResultCode.PermissionDenied,
			"Cannot interact with character-owned instances.",
			descriptor
		)
	end

	if not descriptor.enabled then
		return reject(
			player,
			ResultCode.InteractionDisabled,
			"Interaction is disabled.",
			descriptor
		)
	end

	if not inRange(player, descriptor) then
		return reject(player, ResultCode.OutOfRange, "Interaction is out of range.", descriptor)
	end

	if not hasLineOfSight(player, descriptor) then
		return reject(
			player,
			ResultCode.LineOfSightBlocked,
			"Interaction line of sight is blocked.",
			descriptor
		)
	end

	local ok, handlerErr, feedback = ObjectInteractionHandlers.execute(player, descriptor)

	if not ok then
		return reject(
			player,
			ResultCode.ServerError,
			handlerErr or "Interaction failed.",
			descriptor
		)
	end

	interactionsCompleted += 1
	emitObservation(player, descriptor)
	FeedbackService.send(player, feedback)

	local accepted = result(true, ResultCode.Ok, "Interaction accepted.", descriptor, feedback)
	lastResultByUserId[player.UserId] = accepted

	return accepted
end

function InteractionService.requestFocus(player: Player, payload: any): InteractionDescriptor?
	focusRequests += 1

	if type(payload) ~= "table" or typeof(payload.target) ~= "Instance" then
		return nil
	end

	local descriptor = InteractionRegistry.getForInstance(payload.target)

	if descriptor == nil or not descriptor.enabled then
		return nil
	end

	if not inRange(player, descriptor) then
		return nil
	end

	if not hasLineOfSight(player, descriptor) then
		return nil
	end

	return descriptor
end

function InteractionService.refreshRegistry()
	InteractionRegistry.refreshTagged()
end

function InteractionService.handlePlayerRemoving(player: Player)
	lastResultByUserId[player.UserId] = nil
end

function InteractionService.inspect()
	return {
		interactionsCompleted = interactionsCompleted,
		interactionsRejected = interactionsRejected,
		focusRequests = focusRequests,
		lastResultByUserId = table.clone(lastResultByUserId),
		registry = InteractionRegistry.inspect(),
		feedback = FeedbackService.inspect(),
	}
end

function InteractionService.validate(): (boolean, string?)
	local registryOk, registryErr = InteractionRegistry.validate()

	if not registryOk then
		return false, registryErr
	end

	local handlersOk, handlersErr = ObjectInteractionHandlers.validate()

	if not handlersOk then
		return false, handlersErr
	end

	return true, nil
end

function InteractionService.runSelfChecks()
	local valid, err = InteractionService.validate()

	return {
		ok = valid,
		error = err,
	}
end

function InteractionService.clear()
	InteractionRegistry.clear()
	FeedbackService.clear()
	table.clear(lastResultByUserId)
	interactionsCompleted = 0
	interactionsRejected = 0
	focusRequests = 0
end

return InteractionService
