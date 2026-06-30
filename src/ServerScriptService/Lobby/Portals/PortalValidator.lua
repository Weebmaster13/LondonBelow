--!strict
-- Launch and party validation for lobby portals.

local ServerScriptService = game:GetService("ServerScriptService")

local PartyService = require(ServerScriptService.Lobby.Parties.PartyService)
local PartyTypes = require(ServerScriptService.Lobby.Parties.PartyTypes)

local PortalTypes = require(script.Parent.PortalTypes)

local PortalValidator = {}

type Party = PartyTypes.Party
type PortalRuntime = PortalTypes.PortalRuntime
type PortalResult = PortalTypes.PortalResult

local function serializePartyMembers(party: Party?)
	if party == nil then
		return {}
	end

	local serialized = PartyService.serializeParty(party)

	return serialized.members or {}
end

function PortalValidator.validatePartyPresence(
	portal: PortalRuntime,
	party: Party
): (boolean, string?, any?)
	local missing = {}

	for _, member in ipairs(serializePartyMembers(party)) do
		if portal.occupants[member.userId] == nil then
			table.insert(missing, member)
		end
	end

	if #missing > 0 then
		return false,
			"Every party member must be inside the portal zone.",
			{
				missing = missing,
			}
	end

	return true, nil, nil
end

function PortalValidator.validateReadyToLaunch(
	player: Player,
	portal: PortalRuntime,
	serializePortal: (PortalRuntime) -> any
): PortalResult
	if portal.cooldownUntil > os.clock() then
		return PortalTypes.err(
			PortalTypes.ResultCode.Cooldown,
			"Portal is cooling down.",
			serializePortal(portal),
			{
				remaining = portal.cooldownUntil - os.clock(),
			}
		)
	end

	if portal.occupants[player.UserId] == nil then
		return PortalTypes.err(
			PortalTypes.ResultCode.NotInPortal,
			"Player is not inside the portal.",
			serializePortal(portal)
		)
	end

	local party = PartyService.getPartyForPlayer(player)

	if party == nil then
		return PortalTypes.err(
			PortalTypes.ResultCode.NotInParty,
			"Player must be in a party before launching.",
			serializePortal(portal)
		)
	end

	if portal.partyId ~= nil and portal.partyId ~= party.id then
		return PortalTypes.err(
			PortalTypes.ResultCode.PartyMismatch,
			"Portal is already assigned to another party.",
			serializePortal(portal)
		)
	end

	if party.leaderUserId ~= player.UserId then
		return PortalTypes.err(
			PortalTypes.ResultCode.NotLeader,
			"Only the party leader can launch from a portal.",
			serializePortal(portal)
		)
	end

	if party.selectedChapterId ~= portal.definition.chapterId then
		return PortalTypes.err(
			PortalTypes.ResultCode.InvalidChapter,
			"Party selected chapter does not match this portal.",
			serializePortal(portal)
		)
	end

	local present, presenceErr, presenceData = PortalValidator.validatePartyPresence(portal, party)

	if not present then
		return PortalTypes.err(
			PortalTypes.ResultCode.PartyNotPresent,
			presenceErr or "Party is not fully inside the portal.",
			serializePortal(portal),
			presenceData
		)
	end

	local launchValidation = PartyService.validatePartyForLaunch(party)

	if not launchValidation.ok then
		local code = if launchValidation.code == PartyTypes.ResultCode.NotReady
			then PortalTypes.ResultCode.PartyNotReady
			else launchValidation.code

		return PortalTypes.err(code, launchValidation.message, serializePortal(portal), {
			party = launchValidation.party,
		})
	end

	return PortalTypes.ok("Portal can launch.", serializePortal(portal))
end

return PortalValidator
