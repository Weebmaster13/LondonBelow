--!strict
-- Explicit portal state transition rules.

local ServerScriptService = game:GetService("ServerScriptService")

local Logger = require(ServerScriptService.Core.Logger)

local PortalConfig = require(script.Parent.PortalConfig)
local PortalTypes = require(script.Parent.PortalTypes)
local PortalOccupants = require(script.Parent.PortalOccupants)

local PortalStateMachine = {}

type PortalRuntime = PortalTypes.PortalRuntime

local log = Logger.scope("PortalStateMachine")

local ALLOWED_TRANSITIONS: { [string]: { [string]: boolean } } = {
	Idle = {
		WaitingForParty = true,
		Boarding = true,
		ReadyToLaunch = true,
		Failed = true,
		Cooldown = true,
	},
	WaitingForParty = {
		Idle = true,
		Boarding = true,
		ReadyToLaunch = true,
		Failed = true,
		Cooldown = true,
	},
	Boarding = {
		Idle = true,
		WaitingForParty = true,
		ReadyToLaunch = true,
		Failed = true,
		Cooldown = true,
	},
	ReadyToLaunch = {
		Idle = true,
		WaitingForParty = true,
		Boarding = true,
		Countdown = true,
		Failed = true,
		Cooldown = true,
	},
	Countdown = {
		Failed = true,
		Transitioning = true,
	},
	Transitioning = {
		Failed = true,
		Launching = true,
	},
	Launching = {
		Failed = true,
		Launching = true,
	},
	Failed = {
		Cooldown = true,
		Idle = true,
	},
	Cooldown = {
		Idle = true,
		WaitingForParty = true,
		Boarding = true,
		ReadyToLaunch = true,
		Failed = true,
	},
}

function PortalStateMachine.setState(
	portal: PortalRuntime,
	state: PortalTypes.PortalState,
	reason: string,
	_data: any?,
	broadcastState: (PortalRuntime) -> ()
): boolean
	if portal.state == state and state ~= PortalConfig.PortalStates.Countdown then
		return false
	end

	local allowed = ALLOWED_TRANSITIONS[portal.state]

	if allowed ~= nil and not allowed[state] and portal.state ~= state then
		log.withContext("ERROR", "Rejected invalid portal state transition", {
			portalId = portal.id,
			from = portal.state,
			to = state,
			reason = reason,
		})
		return false
	end

	portal.state = state
	portal.stateEnteredAt = os.clock()
	portal.updatedAt = os.clock()

	log.withContext("INFO", "Portal state changed", {
		portalId = portal.id,
		state = state,
		reason = reason,
		partyId = portal.partyId,
		occupants = PortalOccupants.count(portal),
	})

	broadcastState(portal)

	return true
end

function PortalStateMachine.getAllowedTransitions()
	return ALLOWED_TRANSITIONS
end

return PortalStateMachine
