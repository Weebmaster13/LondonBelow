--!strict

local Types = require(script.Parent.Chapter0HomeTypes)
local Serialization = require(script.Parent.Chapter0HomeSerialization)

local State = {}

local runtimeStatus = Types.PhaseStatus.NotStarted
local playerProgress: { [number]: Types.PlayerProgress } = {}
local events: { any } = {}
local validationFailures: { any } = {}
local resetCount = 0

local function trimEvents()
	while #events > Types.Limits.MaxEvents do
		table.remove(events, 1)
	end
end

local function playerProgressCount(): number
	local count = 0

	for _ in pairs(playerProgress) do
		count += 1
	end

	return count
end

local function progressFor(userId: number): Types.PlayerProgress?
	local progress = playerProgress[userId]

	if progress == nil then
		if playerProgressCount() >= Types.Limits.MaxPlayerStates then
			return nil
		end

		progress = {
			userId = userId,
			status = Types.PhaseStatus.Started,
			interactions = {},
			completedAt = nil,
		}
		playerProgress[userId] = progress
	end

	return progress
end

function State.setStatus(status: string)
	runtimeStatus = status
end

function State.getStatus(): string
	return runtimeStatus
end

function State.recordEvent(event: any)
	table.insert(events, Serialization.deepCopy(event))
	trimEvents()
end

function State.recordValidationFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.deepCopy(payload),
	})
end

function State.recordInteraction(userId: number, interactionId: string, requiredIds: { string })
	local progress = progressFor(userId)

	if progress == nil then
		State.recordEvent({
			kind = "playerProgressLimitRejected",
			userId = userId,
			interactionId = interactionId,
			completed = false,
		})

		return false
	end

	progress.interactions[interactionId] = true

	local complete = true

	for _, requiredId in ipairs(requiredIds) do
		if progress.interactions[requiredId] ~= true then
			complete = false
			break
		end
	end

	if complete and progress.status ~= Types.PhaseStatus.Completed then
		progress.status = Types.PhaseStatus.Completed
		progress.completedAt = os.clock()
	end

	State.recordEvent({
		kind = "interaction",
		userId = userId,
		interactionId = interactionId,
		completed = complete,
	})

	return progress.status == Types.PhaseStatus.Completed
end

function State.removePlayer(userId: number)
	playerProgress[userId] = nil
end

function State.snapshot()
	return {
		status = runtimeStatus,
		resetCount = resetCount,
		playerProgress = Serialization.deepCopy(playerProgress),
		events = Serialization.deepCopy(events),
		validationFailures = Serialization.deepCopy(validationFailures),
	}
end

function State.clear()
	runtimeStatus = Types.PhaseStatus.Reset
	resetCount += 1
	table.clear(playerProgress)
	table.clear(events)
	table.clear(validationFailures)
end

return State
