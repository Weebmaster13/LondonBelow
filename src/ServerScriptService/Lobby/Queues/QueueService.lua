--!strict
-- Server-side launch queue tracking for lobby parties.

local ServerScriptService = game:GetService("ServerScriptService")

local Core = ServerScriptService.Core
local EventBus = require(Core.EventBus)
local Logger = require(Core.Logger)

local QueueService = {}

export type QueueEntry = {
	partyId: string,
	chapterId: string,
	leaderUserId: number,
	queuedAt: number,
	state: string,
}

local log = Logger.scope("QueueService")
local entries: { [string]: QueueEntry } = {}

function QueueService.enqueue(
	partyId: string,
	chapterId: string,
	leaderUserId: number
): (boolean, string?)
	if entries[partyId] ~= nil then
		return false, "Party is already queued."
	end

	entries[partyId] = {
		partyId = partyId,
		chapterId = chapterId,
		leaderUserId = leaderUserId,
		queuedAt = os.clock(),
		state = "Queued",
	}

	EventBus.publishDeferred("Lobby.QueueChanged", {
		partyId = partyId,
		chapterId = chapterId,
		state = "Queued",
	})

	return true, nil
end

function QueueService.setState(partyId: string, state: string)
	local entry = entries[partyId]

	if entry == nil then
		return
	end

	entry.state = state

	EventBus.publishDeferred("Lobby.QueueChanged", {
		partyId = partyId,
		chapterId = entry.chapterId,
		state = state,
	})
end

function QueueService.complete(partyId: string)
	entries[partyId] = nil

	EventBus.publishDeferred("Lobby.QueueChanged", {
		partyId = partyId,
		state = "Complete",
	})
end

function QueueService.fail(partyId: string, reason: string)
	local entry = entries[partyId]

	entries[partyId] = nil

	log.withContext("WARN", "Queue failed", {
		partyId = partyId,
		reason = reason,
		chapterId = if entry ~= nil then entry.chapterId else nil,
	})

	EventBus.publishDeferred("Lobby.QueueChanged", {
		partyId = partyId,
		state = "Failed",
		reason = reason,
	})
end

function QueueService.isQueued(partyId: string): boolean
	return entries[partyId] ~= nil
end

function QueueService.inspect()
	return {
		count = QueueService.count(),
		entries = table.clone(entries),
	}
end

function QueueService.count(): number
	local count = 0

	for _ in pairs(entries) do
		count += 1
	end

	return count
end

function QueueService.validate(): (boolean, string?)
	for partyId, entry in pairs(entries) do
		if entry.partyId ~= partyId then
			return false, "Queue entry party id mismatch"
		end
	end

	return true, nil
end

return QueueService
