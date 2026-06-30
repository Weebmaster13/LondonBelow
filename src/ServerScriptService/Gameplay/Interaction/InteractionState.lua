--!strict
--[[
	Run-local interaction state and counters.

	Owns cooldowns, last results, interaction counts, and cancellation counts.
	It does not validate requests or execute object behavior.
]]

local InteractionState = {}

local interactionsCompleted = 0
local interactionsRejected = 0
local interactionsCancelled = 0
local focusRequests = 0
local lastResultByUserId: { [number]: any } = {}
local cooldownByUserIdAndInteraction: { [number]: { [string]: number } } = {}

local function countCooldowns(): number
	local count = 0

	for _, byInteraction in pairs(cooldownByUserIdAndInteraction) do
		for _ in pairs(byInteraction) do
			count += 1
		end
	end

	return count
end

function InteractionState.recordFocusRequest()
	focusRequests += 1
end

function InteractionState.recordCompleted(player: Player, result: any)
	interactionsCompleted += 1
	lastResultByUserId[player.UserId] = result
end

function InteractionState.recordRejected(player: Player, result: any)
	interactionsRejected += 1
	lastResultByUserId[player.UserId] = result
end

function InteractionState.recordCancelled(player: Player, result: any)
	interactionsCancelled += 1
	lastResultByUserId[player.UserId] = result
end

function InteractionState.isOnCooldown(
	player: Player,
	interactionId: string,
	cooldownSeconds: number
): boolean
	local now = os.clock()
	local byInteraction = cooldownByUserIdAndInteraction[player.UserId]

	local last = if byInteraction ~= nil then byInteraction[interactionId] else nil

	if last ~= nil and now - last < cooldownSeconds then
		return true
	end

	return false
end

function InteractionState.markCooldown(player: Player, interactionId: string)
	local now = os.clock()
	local byInteraction = cooldownByUserIdAndInteraction[player.UserId]

	if byInteraction == nil then
		byInteraction = {}
		cooldownByUserIdAndInteraction[player.UserId] = byInteraction
	end

	byInteraction[interactionId] = now
end

function InteractionState.removePlayer(player: Player)
	lastResultByUserId[player.UserId] = nil
	cooldownByUserIdAndInteraction[player.UserId] = nil
end

function InteractionState.clear()
	interactionsCompleted = 0
	interactionsRejected = 0
	interactionsCancelled = 0
	focusRequests = 0
	table.clear(lastResultByUserId)
	table.clear(cooldownByUserIdAndInteraction)
end

function InteractionState.inspect()
	return {
		interactionsCompleted = interactionsCompleted,
		interactionsRejected = interactionsRejected,
		interactionsCancelled = interactionsCancelled,
		focusRequests = focusRequests,
		lastResultByUserId = table.clone(lastResultByUserId),
		cooldownCount = countCooldowns(),
	}
end

return InteractionState
