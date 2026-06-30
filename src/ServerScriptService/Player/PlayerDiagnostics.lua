--!strict
--[[
	Read-only diagnostics for the Player Runtime.
]]

local PlayerDiagnostics = {}

function PlayerDiagnostics.capture(state: any, dependencies: { [string]: any })
	return {
		state = state,
		playerStates = dependencies.PlayerStateService.inspect(),
		controller = dependencies.PlayerControllerService.inspect(),
	}
end

function PlayerDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	local stateOk, stateErr = dependencies.PlayerStateService.validate()

	if not stateOk then
		return false, stateErr
	end

	local controllerOk, controllerErr = dependencies.PlayerControllerService.validate()

	if not controllerOk then
		return false, controllerErr
	end

	return true, nil
end

return PlayerDiagnostics
