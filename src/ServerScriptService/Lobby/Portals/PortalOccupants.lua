--!strict
-- Occupant and serialization helpers for lobby portals.

local Players = game:GetService("Players")

local PortalConfig = require(script.Parent.PortalConfig)
local PortalTypes = require(script.Parent.PortalTypes)

local PortalOccupants = {}

type PortalDefinition = PortalTypes.PortalDefinition
type PortalRuntime = PortalTypes.PortalRuntime

local function now(): number
	return os.clock()
end

function PortalOccupants.count(portal: PortalRuntime): number
	local count = 0

	for _ in pairs(portal.occupants) do
		count += 1
	end

	return count
end

function PortalOccupants.getPortal(
	portals: { [string]: PortalRuntime },
	portalId: string?
): PortalRuntime?
	return portals[portalId or PortalConfig.DefaultPortalId]
end

function PortalOccupants.getPayloadPortalId(payload: any): string
	if type(payload) == "table" and type(payload.portalId) == "string" then
		return payload.portalId
	end

	return PortalConfig.DefaultPortalId
end

function PortalOccupants.getPlayers(portal: PortalRuntime): { Player }
	local players = {}

	for userId in pairs(portal.occupants) do
		local player = Players:GetPlayerByUserId(userId)

		if player ~= nil then
			table.insert(players, player)
		end
	end

	return players
end

function PortalOccupants.serialize(portal: PortalRuntime)
	local occupants = {}

	for userId, enteredAt in pairs(portal.occupants) do
		local player = Players:GetPlayerByUserId(userId)

		table.insert(occupants, {
			userId = userId,
			name = if player ~= nil then player.Name else "Unknown",
			enteredAt = enteredAt,
			isLeader = portal.leaderUserId == userId,
		})
	end

	table.sort(occupants, function(left, right)
		return left.enteredAt < right.enteredAt
	end)

	return {
		id = portal.id,
		displayName = portal.definition.displayName,
		portalType = portal.definition.portalType,
		chapterId = portal.definition.chapterId,
		state = portal.state,
		occupants = occupants,
		occupantCount = #occupants,
		maxPlayers = portal.definition.maxPlayers,
		leaderUserId = portal.leaderUserId,
		partyId = portal.partyId,
		countdownRemaining = portal.countdownRemaining,
		cooldownRemaining = math.max(0, portal.cooldownUntil - now()),
		lastFailure = portal.lastFailure,
		stateEnteredAt = portal.stateEnteredAt,
		launchToken = portal.launchToken,
		updatedAt = portal.updatedAt,
	}
end

function PortalOccupants.clearPartyIfEmpty(portal: PortalRuntime)
	if PortalOccupants.count(portal) > 0 then
		return
	end

	portal.partyId = nil
	portal.leaderUserId = nil
	portal.lastFailure = nil
	portal.countdownRemaining = 0
end

function PortalOccupants.initializePortals(): { [string]: PortalRuntime }
	local portals: { [string]: PortalRuntime } = {}

	for portalId, definition in pairs(PortalConfig.Portals) do
		portals[portalId] = {
			id = portalId,
			definition = definition :: PortalDefinition,
			state = PortalConfig.PortalStates.Idle,
			occupants = {},
			leaderUserId = nil,
			partyId = nil,
			countdownRemaining = 0,
			cooldownUntil = 0,
			lastFailure = nil,
			stateEnteredAt = now(),
			launchToken = 0,
			updatedAt = now(),
		}
	end

	return portals
end

return PortalOccupants
