--!strict

local Evidence = require(script.Parent.InteractionEvidence)
local PendingQueue = require(script.Parent.PendingChoiceQueue)
local Registry = require(script.Parent.InteractionSessionRegistry)
local Types = require(script.Parent.DialogueInteractionTypes)
local Validator = require(script.Parent.InteractionValidator)

local Manager = {}

function Manager.requestInteraction(request: any)
	local created = Registry.create(request)
	if not created.ok then
		return created
	end
	Registry.update(
		created.session.interactionId,
		{ status = Types.InteractionStatus.WaitingForResponse }
	)
	local queued = PendingQueue.enqueue(created.session)
	if not queued.ok then
		return queued
	end
	return { ok = true, code = "Ok", session = Registry.get(created.session.interactionId) }
end

function Manager.submitResponse(interactionId: string, response: any)
	local session = Registry.get(interactionId)
	local validation = Validator.validateResponse(session, response)
	if not validation.ok then
		Evidence.record(
			"validation failed",
			{ interactionId = interactionId, reason = validation.message }
		)
		return validation
	end
	Registry.update(
		interactionId,
		{ status = Types.InteractionStatus.ResponseReceived, response = response }
	)
	Registry.update(interactionId, { status = Types.InteractionStatus.Validated })
	PendingQueue.remove(interactionId)
	Registry.update(interactionId, { status = Types.InteractionStatus.Applied })
	Registry.update(interactionId, { status = Types.InteractionStatus.Completed })
	Evidence.record("validation passed", { interactionId = interactionId })
	Evidence.record("interaction applied", { interactionId = interactionId })
	return { ok = true, code = "Ok", session = Registry.get(interactionId) }
end

function Manager.cancel(interactionId: string, reason: string)
	local session = Registry.get(interactionId)
	if session == nil then
		return {
			ok = false,
			code = Types.FailureType.UnknownInteraction,
			message = "unknown interaction",
		}
	end
	PendingQueue.remove(interactionId)
	Registry.update(
		interactionId,
		{ status = Types.InteractionStatus.Cancelled, cancellationReason = reason }
	)
	Registry.update(interactionId, { status = Types.InteractionStatus.Closed })
	Evidence.record("interaction cancelled", { interactionId = interactionId, reason = reason })
	return { ok = true, code = "Ok" }
end

return Manager
