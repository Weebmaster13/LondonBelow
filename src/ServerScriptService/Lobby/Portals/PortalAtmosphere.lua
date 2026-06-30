--!strict
-- Atmosphere cue dispatch for cinematic lobby portals.

local ServerScriptService = game:GetService("ServerScriptService")

local EventBus = require(ServerScriptService.Core.EventBus)

local PortalOccupants = require(script.Parent.PortalOccupants)
local PortalTypes = require(script.Parent.PortalTypes)

local PortalAtmosphere = {}

type PortalRuntime = PortalTypes.PortalRuntime

function PortalAtmosphere.fireCue(
	portal: PortalRuntime,
	cue: string,
	data: any?,
	fireClient: (Player, any) -> ()
)
	local payload = {
		portalId = portal.id,
		portalType = portal.definition.portalType,
		cue = cue,
		data = data,
	}

	for _, player in ipairs(PortalOccupants.getPlayers(portal)) do
		fireClient(player, payload)
	end

	EventBus.publishDeferred("LobbyPortal.AtmosphereCue", payload)
end

return PortalAtmosphere
