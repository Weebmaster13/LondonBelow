--!strict
--[[
	Server-authoritative interaction runtime orchestrator.

	Owns the interaction request pipeline and delegates focused responsibilities
	to registry, validator, state, diagnostics, object handlers, feedback, and
	ObservationService. It does not own final UI, inventory persistence, puzzle
	answers, Chapter 1 content, Monster AI, or horror pacing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local Logger = require(Core.Logger)

local ObservationService = require(ServerScriptService.Horror.Observation.ObservationService)
local Types = require(ReplicatedStorage.Shared.PlayerExperienceTypes)

local FeedbackService = require(script.Parent.FeedbackService)
local InteractionDiagnostics = require(script.Parent.InteractionDiagnostics)
local InteractionRegistry = require(script.Parent.InteractionRegistry)
local InteractionState = require(script.Parent.InteractionState)
local InteractionValidator = require(script.Parent.InteractionValidator)
local ObjectInteractionHandlers = require(script.Parent.ObjectInteractionHandlers)

local InteractionService = {}

type InteractionDescriptor = Types.InteractionDescriptor
type InteractionResult = Types.InteractionResult

local ResultCode = Types.ResultCode
local log = Logger.scope("InteractionService")

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

local function observe(
	player: Player,
	id: string,
	descriptor: InteractionDescriptor?,
	extra: { [string]: any }?
)
	local metadata = if descriptor ~= nil then observationMetadata(descriptor) else {}

	if extra ~= nil then
		for key, value in pairs(extra) do
			metadata[key] = value
		end
	end

	local ok, code = ObservationService.observe({
		id = id,
		player = player,
		source = "InteractionService",
		metadata = metadata,
	})

	if not ok then
		log.withContext("WARN", "Interaction observation rejected", {
			interactionId = if descriptor ~= nil then descriptor.id else nil,
			observationId = id,
			code = code,
		})
	end
end

local function reject(
	player: Player,
	code: string,
	message: string,
	descriptor: InteractionDescriptor?
): InteractionResult
	local rejected = result(false, code, message, descriptor, {})
	InteractionState.recordRejected(player, rejected)
	observe(player, "Interaction.Fail", descriptor, {
		code = code,
		message = message,
	})

	return rejected
end

local function emitConfiguredObservation(player: Player, descriptor: InteractionDescriptor)
	if descriptor.observationId == nil or descriptor.observationId == "" then
		return
	end

	observe(player, descriptor.observationId, descriptor, nil)
end

function InteractionService.requestInteraction(player: Player, payload: any): InteractionResult
	local request = InteractionValidator.sanitizeRequest(payload)

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

	local valid, code, message = InteractionValidator.validateDescriptor(player, descriptor)

	if not valid then
		return reject(player, code, message, descriptor)
	end

	observe(player, "Interaction.Begin", descriptor, {
		inputKind = request.inputKind,
		requestId = request.requestId,
	})

	local ok, handlerErr, feedback = ObjectInteractionHandlers.execute(player, descriptor)

	if not ok then
		return reject(
			player,
			ResultCode.ServerError,
			handlerErr or "Interaction failed.",
			descriptor
		)
	end

	emitConfiguredObservation(player, descriptor)
	observe(player, "Interaction.Complete", descriptor, nil)
	FeedbackService.send(player, feedback)

	local accepted = result(true, ResultCode.Ok, "Interaction accepted.", descriptor, feedback)
	InteractionState.recordCompleted(player, accepted)

	return accepted
end

function InteractionService.cancelInteraction(player: Player, interactionId: string?)
	local cancelled = result(false, "CANCELLED", "Interaction cancelled.", nil, {})
	InteractionState.recordCancelled(player, cancelled)
	observe(player, "Interaction.Cancel", nil, {
		interactionId = interactionId,
	})

	return cancelled
end

function InteractionService.requestFocus(player: Player, payload: any): InteractionDescriptor?
	InteractionState.recordFocusRequest()

	if type(payload) ~= "table" or typeof(payload.target) ~= "Instance" then
		return nil
	end

	local descriptor = InteractionRegistry.getForInstance(payload.target)

	if descriptor == nil or not descriptor.enabled then
		return nil
	end

	if not InteractionValidator.inRange(player, descriptor) then
		return nil
	end

	if not InteractionValidator.hasLineOfSight(player, descriptor) then
		return nil
	end

	return descriptor
end

function InteractionService.refreshRegistry()
	InteractionRegistry.refreshTagged()
end

function InteractionService.handlePlayerRemoving(player: Player)
	InteractionState.removePlayer(player)
end

function InteractionService.inspect()
	return InteractionDiagnostics.capture({
		InteractionState = InteractionState,
		InteractionRegistry = InteractionRegistry,
		FeedbackService = FeedbackService,
	})
end

function InteractionService.validate(): (boolean, string?)
	return InteractionDiagnostics.validate({
		InteractionRegistry = InteractionRegistry,
		InteractionValidator = InteractionValidator,
		ObjectInteractionHandlers = ObjectInteractionHandlers,
	})
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
	InteractionState.clear()
end

return InteractionService
