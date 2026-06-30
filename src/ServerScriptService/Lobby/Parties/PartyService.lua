--!strict
--[[
	PartyService owns all party truth for the London Below lobby.

	It never trusts clients, prevents duplicate membership, transfers leaders on
	disconnect/leave, destroys empty parties, and returns structured failure
	reasons for every request.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)

local PartyConfig = require(script.Parent.PartyConfig)
local PartyTypes = require(script.Parent.PartyTypes)

local PartyService = {}

type Party = PartyTypes.Party
type PartyMember = PartyTypes.PartyMember
type Result = PartyTypes.Result

local log = Logger.scope("PartyService")
local parties: { [string]: Party } = {}
local playerToParty: { [number]: string } = {}
local nextPartyNumber = 0

local function now(): number
	return os.clock()
end

local function makePartyId(): string
	nextPartyNumber += 1
	return string.format("%s-%06d", PartyConfig.PartyIdPrefix, nextPartyNumber)
end

local function memberFromPlayer(player: Player): PartyMember
	return {
		userId = player.UserId,
		name = player.Name,
		joinedAt = now(),
	}
end

local function findPartyByPlayer(player: Player): Party?
	local partyId = playerToParty[player.UserId]

	if partyId == nil then
		return nil
	end

	return parties[partyId]
end

local function touch(party: Party)
	party.updatedAt = now()
end

local function removeUserIdFromOrder(party: Party, userId: number)
	local index = table.find(party.memberOrder, userId)

	if index ~= nil then
		table.remove(party.memberOrder, index)
	end
end

local function memberCount(party: Party): number
	local count = 0

	for _ in pairs(party.members) do
		count += 1
	end

	return count
end

local function serializeParty(party: Party)
	local members = {}

	for _, userId in ipairs(party.memberOrder) do
		local member = party.members[userId]

		if member ~= nil then
			table.insert(members, {
				userId = member.userId,
				name = member.name,
				isLeader = member.userId == party.leaderUserId,
				ready = party.ready[member.userId] == true,
				joinedAt = member.joinedAt,
			})
		end
	end

	return {
		id = party.id,
		leaderUserId = party.leaderUserId,
		members = members,
		memberCount = #members,
		maxPartySize = PartyConfig.MaxPartySize,
		selectedChapterId = party.selectedChapterId,
		locked = party.locked,
		launching = party.launching,
		createdAt = party.createdAt,
		updatedAt = party.updatedAt,
	}
end

local function publishPartyChanged(party: Party, reason: string)
	EventBus.publishDeferred("Lobby.PartyChanged", {
		reason = reason,
		party = serializeParty(party),
	})
end

local function destroyParty(party: Party, reason: string)
	parties[party.id] = nil

	for userId in pairs(party.members) do
		playerToParty[userId] = nil
	end

	EventBus.publishDeferred("Lobby.PartyDestroyed", {
		reason = reason,
		partyId = party.id,
	})

	log.withContext("INFO", "Party destroyed", {
		partyId = party.id,
		reason = reason,
	})
end

local function transferLeaderIfNeeded(party: Party)
	if party.members[party.leaderUserId] ~= nil then
		return
	end

	local nextLeader = party.memberOrder[1]

	if nextLeader ~= nil then
		party.leaderUserId = nextLeader
	end
end

function PartyService.createParty(player: Player): Result
	if playerToParty[player.UserId] ~= nil then
		local party = findPartyByPlayer(player)
		return PartyTypes.err(
			PartyTypes.ResultCode.AlreadyInParty,
			"Player is already in a party.",
			if party ~= nil then serializeParty(party) else nil
		)
	end

	local partyId = makePartyId()
	local member = memberFromPlayer(player)
	local party: Party = {
		id = partyId,
		leaderUserId = player.UserId,
		members = {
			[player.UserId] = member,
		},
		memberOrder = { player.UserId },
		ready = {
			[player.UserId] = false,
		},
		selectedChapterId = PartyConfig.DefaultChapterId,
		locked = false,
		launching = false,
		createdAt = now(),
		updatedAt = now(),
	}

	parties[partyId] = party
	playerToParty[player.UserId] = partyId

	publishPartyChanged(party, "PartyCreated")

	log.withContext("SUCCESS", "Party created", {
		partyId = partyId,
		leaderUserId = player.UserId,
	})

	return PartyTypes.ok("Party created.", serializeParty(party))
end

function PartyService.joinParty(player: Player, partyId: string): Result
	if type(partyId) ~= "string" or partyId == "" then
		return PartyTypes.err(PartyTypes.ResultCode.InvalidRequest, "Party id is required.")
	end

	if playerToParty[player.UserId] ~= nil then
		local currentParty = findPartyByPlayer(player)
		return PartyTypes.err(
			PartyTypes.ResultCode.AlreadyInParty,
			"Player is already in a party.",
			if currentParty ~= nil then serializeParty(currentParty) else nil
		)
	end

	local party = parties[partyId]

	if party == nil then
		return PartyTypes.err(PartyTypes.ResultCode.PartyNotFound, "Party was not found.")
	end

	if party.locked then
		return PartyTypes.err(
			PartyTypes.ResultCode.PartyLocked,
			"Party is locked.",
			serializeParty(party)
		)
	end

	if party.launching then
		return PartyTypes.err(
			PartyTypes.ResultCode.LaunchInProgress,
			"Party is already launching.",
			serializeParty(party)
		)
	end

	if memberCount(party) >= PartyConfig.MaxPartySize then
		return PartyTypes.err(
			PartyTypes.ResultCode.PartyFull,
			"Party is full.",
			serializeParty(party)
		)
	end

	party.members[player.UserId] = memberFromPlayer(player)
	table.insert(party.memberOrder, player.UserId)
	party.ready[player.UserId] = false
	playerToParty[player.UserId] = party.id
	touch(party)
	publishPartyChanged(party, "MemberJoined")

	return PartyTypes.ok("Joined party.", serializeParty(party))
end

function PartyService.leaveParty(player: Player): Result
	local party = findPartyByPlayer(player)

	if party == nil then
		return PartyTypes.err(PartyTypes.ResultCode.NotInParty, "Player is not in a party.")
	end

	party.members[player.UserId] = nil
	party.ready[player.UserId] = nil
	playerToParty[player.UserId] = nil
	removeUserIdFromOrder(party, player.UserId)
	transferLeaderIfNeeded(party)

	if memberCount(party) == 0 then
		destroyParty(party, "PartyEmpty")
		return PartyTypes.ok("Left party.")
	end

	touch(party)
	publishPartyChanged(party, "MemberLeft")

	return PartyTypes.ok("Left party.", serializeParty(party))
end

function PartyService.kickMember(leader: Player, targetUserId: number): Result
	local party = findPartyByPlayer(leader)

	if party == nil then
		return PartyTypes.err(PartyTypes.ResultCode.NotInParty, "Leader is not in a party.")
	end

	if party.leaderUserId ~= leader.UserId then
		return PartyTypes.err(
			PartyTypes.ResultCode.NotLeader,
			"Only the party leader can kick members.",
			serializeParty(party)
		)
	end

	if targetUserId == leader.UserId then
		return PartyTypes.err(
			PartyTypes.ResultCode.CannotKickSelf,
			"Leader cannot kick themselves.",
			serializeParty(party)
		)
	end

	if party.members[targetUserId] == nil then
		return PartyTypes.err(
			PartyTypes.ResultCode.MemberNotFound,
			"Member was not found.",
			serializeParty(party)
		)
	end

	party.members[targetUserId] = nil
	party.ready[targetUserId] = nil
	playerToParty[targetUserId] = nil
	removeUserIdFromOrder(party, targetUserId)
	touch(party)
	publishPartyChanged(party, "MemberKicked")

	return PartyTypes.ok("Member kicked.", serializeParty(party), {
		targetUserId = targetUserId,
	})
end

function PartyService.transferLeader(leader: Player, targetUserId: number): Result
	local party = findPartyByPlayer(leader)

	if party == nil then
		return PartyTypes.err(PartyTypes.ResultCode.NotInParty, "Leader is not in a party.")
	end

	if party.leaderUserId ~= leader.UserId then
		return PartyTypes.err(
			PartyTypes.ResultCode.NotLeader,
			"Only the party leader can transfer leadership.",
			serializeParty(party)
		)
	end

	if party.members[targetUserId] == nil then
		return PartyTypes.err(
			PartyTypes.ResultCode.MemberNotFound,
			"Target member was not found.",
			serializeParty(party)
		)
	end

	party.leaderUserId = targetUserId
	touch(party)
	publishPartyChanged(party, "LeaderTransferred")

	return PartyTypes.ok("Leader transferred.", serializeParty(party))
end

function PartyService.setReady(player: Player, ready: boolean): Result
	local party = findPartyByPlayer(player)

	if party == nil then
		return PartyTypes.err(PartyTypes.ResultCode.NotInParty, "Player is not in a party.")
	end

	if party.launching then
		return PartyTypes.err(
			PartyTypes.ResultCode.LaunchInProgress,
			"Party is already launching.",
			serializeParty(party)
		)
	end

	party.ready[player.UserId] = ready == true
	touch(party)
	publishPartyChanged(party, "ReadyChanged")

	return PartyTypes.ok(
		if ready then "Player is ready." else "Player is not ready.",
		serializeParty(party)
	)
end

function PartyService.selectChapter(player: Player, chapterId: string): Result
	local party = findPartyByPlayer(player)

	if party == nil then
		return PartyTypes.err(PartyTypes.ResultCode.NotInParty, "Player is not in a party.")
	end

	if party.leaderUserId ~= player.UserId then
		return PartyTypes.err(
			PartyTypes.ResultCode.NotLeader,
			"Only the party leader can select chapters.",
			serializeParty(party)
		)
	end

	if not PartyConfig.isValidChapter(chapterId) then
		return PartyTypes.err(
			PartyTypes.ResultCode.InvalidChapter,
			"Chapter is not available.",
			serializeParty(party)
		)
	end

	party.selectedChapterId = chapterId
	party.ready = {}

	for userId in pairs(party.members) do
		party.ready[userId] = false
	end

	touch(party)
	publishPartyChanged(party, "ChapterSelected")

	return PartyTypes.ok("Chapter selected. Party readiness reset.", serializeParty(party))
end

function PartyService.setLocked(player: Player, locked: boolean): Result
	local party = findPartyByPlayer(player)

	if party == nil then
		return PartyTypes.err(PartyTypes.ResultCode.NotInParty, "Player is not in a party.")
	end

	if party.leaderUserId ~= player.UserId then
		return PartyTypes.err(
			PartyTypes.ResultCode.NotLeader,
			"Only the party leader can lock the party.",
			serializeParty(party)
		)
	end

	party.locked = locked == true
	touch(party)
	publishPartyChanged(party, "LockChanged")

	return PartyTypes.ok(
		if locked then "Party locked." else "Party unlocked.",
		serializeParty(party)
	)
end

function PartyService.markLaunching(partyId: string, launching: boolean): Result
	local party = parties[partyId]

	if party == nil then
		return PartyTypes.err(PartyTypes.ResultCode.PartyNotFound, "Party was not found.")
	end

	party.launching = launching
	touch(party)
	publishPartyChanged(party, "LaunchStateChanged")

	return PartyTypes.ok("Launch state updated.", serializeParty(party))
end

function PartyService.handlePlayerRemoving(player: Player)
	local result = PartyService.leaveParty(player)

	if not result.ok and result.code ~= PartyTypes.ResultCode.NotInParty then
		log.withContext("WARN", "Player removal party cleanup failed", {
			userId = player.UserId,
			code = result.code,
			message = result.message,
		})
	end
end

function PartyService.getPartyForPlayer(player: Player): Party?
	return findPartyByPlayer(player)
end

function PartyService.getPartyById(partyId: string): Party?
	return parties[partyId]
end

function PartyService.getSerializedPartyForPlayer(player: Player): any?
	local party = findPartyByPlayer(player)

	if party == nil then
		return nil
	end

	return serializeParty(party)
end

function PartyService.serializeParty(party: Party): any
	return serializeParty(party)
end

function PartyService.getMembers(party: Party): { PartyMember }
	local members = {}

	for _, userId in ipairs(party.memberOrder) do
		local member = party.members[userId]

		if member ~= nil then
			table.insert(members, member)
		end
	end

	return members
end

function PartyService.areAllReady(party: Party): boolean
	if memberCount(party) < PartyConfig.MinPartySize then
		return false
	end

	for userId in pairs(party.members) do
		if party.ready[userId] ~= true then
			return false
		end
	end

	return true
end

function PartyService.validatePartyForLaunch(party: Party): Result
	local count = memberCount(party)

	if count < PartyConfig.MinPartySize then
		return PartyTypes.err(
			PartyTypes.ResultCode.InvalidRequest,
			"Party does not have enough players.",
			serializeParty(party)
		)
	end

	if count > PartyConfig.MaxPartySize then
		return PartyTypes.err(
			PartyTypes.ResultCode.PartyFull,
			"Party is too large.",
			serializeParty(party)
		)
	end

	if party.launching then
		return PartyTypes.err(
			PartyTypes.ResultCode.LaunchInProgress,
			"Party is already launching.",
			serializeParty(party)
		)
	end

	if not PartyConfig.isValidChapter(party.selectedChapterId) then
		return PartyTypes.err(
			PartyTypes.ResultCode.InvalidChapter,
			"Selected chapter is not available.",
			serializeParty(party)
		)
	end

	if not PartyService.areAllReady(party) then
		return PartyTypes.err(
			PartyTypes.ResultCode.NotReady,
			"Every party member must be ready.",
			serializeParty(party)
		)
	end

	return PartyTypes.ok("Party can launch.", serializeParty(party))
end

function PartyService.inspect()
	local snapshot = {}

	for partyId, party in pairs(parties) do
		snapshot[partyId] = serializeParty(party)
	end

	return {
		partyCount = PartyService.count(),
		parties = snapshot,
	}
end

function PartyService.count(): number
	local count = 0

	for _ in pairs(parties) do
		count += 1
	end

	return count
end

function PartyService.validate(): (boolean, string?)
	for partyId, party in pairs(parties) do
		if party.id ~= partyId then
			return false, "Party id mismatch"
		end

		if party.members[party.leaderUserId] == nil then
			return false, "Party has missing leader"
		end

		for userId in pairs(party.members) do
			if playerToParty[userId] ~= partyId then
				return false, "Player membership index mismatch"
			end
		end
	end

	return true, nil
end

function PartyService.runSelfChecks()
	local originalParties = parties
	local originalPlayerToParty = playerToParty
	parties = {}
	playerToParty = {}

	local function fakePlayer(userId: number, name: string): Player
		return ({
			UserId = userId,
			Name = name,
		} :: any) :: Player
	end

	local leader = fakePlayer(1, "Leader")
	local member = fakePlayer(2, "Member")

	local create = PartyService.createParty(leader)
	local join = if create.party ~= nil
		then PartyService.joinParty(member, create.party.id)
		else create
	local duplicate =
		PartyService.joinParty(member, if create.party ~= nil then create.party.id else "")
	local transfer = PartyService.transferLeader(leader, member.UserId)
	local readyA = PartyService.setReady(leader, true)
	local readyB = PartyService.setReady(member, true)
	local party = PartyService.getPartyForPlayer(member)
	local launchValidation = if party ~= nil
		then PartyService.validatePartyForLaunch(party)
		else PartyTypes.err("NO_PARTY", "No party")
	local leave = PartyService.leaveParty(member)

	local ok = create.ok
		and join.ok
		and not duplicate.ok
		and transfer.ok
		and readyA.ok
		and readyB.ok
		and launchValidation.ok
		and leave.ok

	parties = originalParties
	playerToParty = originalPlayerToParty

	return {
		ok = ok,
		checks = {
			create = create,
			join = join,
			duplicate = duplicate,
			transfer = transfer,
			readyLeader = readyA,
			readyMember = readyB,
			launchValidation = launchValidation,
			leave = leave,
		},
	}
end

return PartyService
