--!strict
-- Physical zone contact tracking for lobby portals.

local Players = game:GetService("Players")

local PortalTypes = require(script.Parent.PortalTypes)

local PortalZoneTracker = {}

type PortalRuntime = PortalTypes.PortalRuntime

local zoneConnections: { RBXScriptConnection } = {}
local zoneContactCounts: { [string]: { [number]: number } } = {}
local registeredZoneCounts: { [string]: number } = {}

local function getPlayerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")

	if character == nil then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

function PortalZoneTracker.hasRegisteredZones(portalId: string): boolean
	return (registeredZoneCounts[portalId] or 0) > 0
end

function PortalZoneTracker.isPlayerInsideRegisteredZone(player: Player, portalId: string): boolean
	local contacts = zoneContactCounts[portalId]

	return contacts ~= nil and (contacts[player.UserId] or 0) > 0
end

function PortalZoneTracker.registerZone(
	portal: PortalRuntime?,
	portalId: string,
	zonePart: BasePart,
	onEntered: (Player, string) -> (),
	onExited: (Player, string) -> ()
): (boolean, string?)
	if portal == nil then
		return false, "Portal was not found."
	end

	registeredZoneCounts[portalId] = (registeredZoneCounts[portalId] or 0) + 1
	zoneContactCounts[portalId] = zoneContactCounts[portalId] or {}

	table.insert(
		zoneConnections,
		zonePart.Touched:Connect(function(hit)
			local player = getPlayerFromHit(hit)

			if player == nil then
				return
			end

			local contacts = zoneContactCounts[portalId]

			if contacts ~= nil then
				contacts[player.UserId] = (contacts[player.UserId] or 0) + 1
			end

			onEntered(player, portalId)
		end)
	)

	table.insert(
		zoneConnections,
		zonePart.TouchEnded:Connect(function(hit)
			local player = getPlayerFromHit(hit)

			if player == nil then
				return
			end

			local contacts = zoneContactCounts[portalId]

			if contacts == nil then
				return
			end

			contacts[player.UserId] = math.max(0, (contacts[player.UserId] or 0) - 1)

			if contacts[player.UserId] == 0 then
				contacts[player.UserId] = nil
				onExited(player, portalId)
			end
		end)
	)

	return true, nil
end

function PortalZoneTracker.cleanup()
	for _, connection in ipairs(zoneConnections) do
		connection:Disconnect()
	end

	table.clear(zoneConnections)
	table.clear(zoneContactCounts)
	table.clear(registeredZoneCounts)
end

function PortalZoneTracker.inspect()
	return {
		registeredZoneCounts = table.clone(registeredZoneCounts),
	}
end

return PortalZoneTracker
