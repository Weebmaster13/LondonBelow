--!strict
-- Server-authoritative portal configuration.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedPortalConfig = require(ReplicatedStorage.Lobby.LobbyConfig.SharedPortalConfig)

local PortalConfig = {}

PortalConfig.DefaultPortalId = SharedPortalConfig.DefaultPortalId
PortalConfig.MaxPortalOccupants = SharedPortalConfig.MaxPortalOccupants
PortalConfig.CountdownSeconds = SharedPortalConfig.CountdownSeconds
PortalConfig.CooldownSeconds = SharedPortalConfig.CooldownSeconds
PortalConfig.RemoteRateLimitPerSecond = SharedPortalConfig.RemoteRateLimitPerSecond
PortalConfig.AutoCreateSoloPartyOnBoard = SharedPortalConfig.AutoCreateSoloPartyOnBoard
PortalConfig.AllowRemoteBoardingWithoutRegisteredZones =
	SharedPortalConfig.AllowRemoteBoardingWithoutRegisteredZones
PortalConfig.FailedStateHoldSeconds = SharedPortalConfig.FailedStateHoldSeconds
PortalConfig.PortalTypes = SharedPortalConfig.PortalTypes
PortalConfig.PortalStates = SharedPortalConfig.PortalStates
PortalConfig.AtmosphereCues = SharedPortalConfig.AtmosphereCues
PortalConfig.Portals = SharedPortalConfig.Portals

function PortalConfig.getPortal(portalId: string)
	return PortalConfig.Portals[portalId]
end

function PortalConfig.isValidPortal(portalId: string): boolean
	local portal = PortalConfig.getPortal(portalId)

	return portal ~= nil and portal.enabled == true
end

return PortalConfig
