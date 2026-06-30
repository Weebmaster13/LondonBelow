--!strict
--[[
	Read-only diagnostics for the Interaction Runtime.
]]

local InteractionDiagnostics = {}

function InteractionDiagnostics.capture(dependencies: { [string]: any })
	return {
		state = dependencies.InteractionState.inspect(),
		registry = dependencies.InteractionRegistry.inspect(),
		feedback = dependencies.FeedbackService.inspect(),
	}
end

function InteractionDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	local registryOk, registryErr = dependencies.InteractionRegistry.validate()

	if not registryOk then
		return false, registryErr
	end

	local validatorOk, validatorErr = dependencies.InteractionValidator.validate()

	if not validatorOk then
		return false, validatorErr
	end

	local handlersOk, handlersErr = dependencies.ObjectInteractionHandlers.validate()

	if not handlersOk then
		return false, handlersErr
	end

	return true, nil
end

return InteractionDiagnostics
