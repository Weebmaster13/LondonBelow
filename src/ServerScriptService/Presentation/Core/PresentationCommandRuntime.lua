--!strict

local Serialization = require(script.Parent.PresentationSerialization)
local Types = require(script.Parent.PresentationTypes)
local Validation = require(script.Parent.PresentationValidation)

local CommandRuntime = {}

local commands: { any } = {}
local commandIds: { [string]: boolean } = {}
local executed: { any } = {}
local expired: { any } = {}
local prompts: { [string]: any } = {}
local busyStates: { [string]: any } = {}
local audioRequests: { any } = {}
local animationRequests: { any } = {}
local messageRequests: { [string]: any } = {}
local cursorStates: { [string]: string } = {}
local highlights: { [string]: any } = {}

local function trim(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function count(map: { [string]: any }): number
	local total = 0
	for _ in pairs(map) do
		total += 1
	end
	return total
end

local function priorityRank(value: any): number
	if type(value) == "number" then
		return value
	end
	return Types.CommandPriority[value] or Types.CommandPriority.Ambient
end

local function sortQueue()
	table.sort(commands, function(left, right)
		if left.priority ~= right.priority then
			return left.priority > right.priority
		end
		if left.revision ~= right.revision then
			return left.revision > right.revision
		end
		return left.commandId < right.commandId
	end)
end

function CommandRuntime.create(rawCommand: any, currentTime: number?)
	local now = currentTime or os.clock()
	local source = if type(rawCommand) == "table" then rawCommand else {}
	local command = {
		commandId = source.commandId,
		sourceRuntime = source.sourceRuntime,
		objectId = source.objectId,
		playerId = source.playerId,
		presentationType = source.presentationType,
		priority = priorityRank(source.priority),
		revision = source.revision,
		payload = Serialization.deepCopy(source.payload or {}),
		timestamp = if type(source.timestamp) == "number" then source.timestamp else now,
		expiresAt = if type(source.expiresAt) == "number"
			then source.expiresAt
			else now + Types.Limits.DefaultExpirationSeconds,
	}
	if table.freeze ~= nil then
		table.freeze(command.payload)
		table.freeze(command)
	end
	return command
end

function CommandRuntime.enqueue(rawCommand: any): (boolean, string?, any?)
	local command = CommandRuntime.create(rawCommand)
	local ok, reason = Validation.command(command)
	if not ok then
		return false, reason, nil
	end
	if commandIds[command.commandId] == true then
		return false, "duplicate commandId", nil
	end
	if #commands >= Types.Limits.MaxCommands then
		return false, "presentation command queue is full", nil
	end
	commandIds[command.commandId] = true
	table.insert(commands, command)
	sortQueue()
	return true, nil, Serialization.deepCopy(command)
end

function CommandRuntime.expire(currentTime: number?)
	local now = currentTime or os.clock()
	for index = #commands, 1, -1 do
		local command = commands[index]
		if command.expiresAt <= now then
			table.remove(commands, index)
			commandIds[command.commandId] = nil
			table.insert(expired, command)
			trim(expired, Types.Limits.MaxExpiredCommands)
		end
	end
end

function CommandRuntime.nextCommand()
	CommandRuntime.expire()
	local command = table.remove(commands, 1)
	if command ~= nil then
		commandIds[command.commandId] = nil
	end
	return command
end

function CommandRuntime.recordExecuted(command: any, route: any)
	table.insert(executed, {
		commandId = command.commandId,
		presentationType = command.presentationType,
		objectId = command.objectId,
		route = Serialization.deepCopy(route),
		executedAt = os.clock(),
	})
	trim(executed, Types.Limits.MaxExecutedCommands)
end

function CommandRuntime.applyState(command: any)
	local payload = command.payload or {}
	if
		command.presentationType == Types.PresentationType.ShowPrompt
		or command.presentationType == Types.PresentationType.UpdatePrompt
	then
		prompts[payload.promptId or command.objectId] = Serialization.deepCopy(payload)
	elseif command.presentationType == Types.PresentationType.HidePrompt then
		prompts[payload.promptId or command.objectId] = nil
	elseif command.presentationType == Types.PresentationType.ShowInteractionBusy then
		busyStates[command.objectId] = Serialization.deepCopy(payload)
	elseif command.presentationType == Types.PresentationType.HideInteractionBusy then
		busyStates[command.objectId] = nil
	elseif
		command.presentationType == Types.PresentationType.PlayAudio
		or command.presentationType == Types.PresentationType.StopAudio
	then
		table.insert(audioRequests, {
			commandId = command.commandId,
			objectId = command.objectId,
			audioKey = payload.audioKey,
			action = command.presentationType,
		})
		trim(audioRequests, Types.Limits.MaxAudioRequests)
	elseif
		command.presentationType == Types.PresentationType.PlayAnimation
		or command.presentationType == Types.PresentationType.StopAnimation
	then
		table.insert(animationRequests, {
			commandId = command.commandId,
			objectId = command.objectId,
			animationKey = payload.animationKey,
			action = command.presentationType,
		})
		trim(animationRequests, Types.Limits.MaxAnimationRequests)
	elseif command.presentationType == Types.PresentationType.ShowMessage then
		messageRequests[payload.messageId or command.commandId] = Serialization.deepCopy(payload)
	elseif command.presentationType == Types.PresentationType.HideMessage then
		messageRequests[payload.messageId or command.objectId] = nil
	elseif command.presentationType == Types.PresentationType.UpdateCursor then
		cursorStates[tostring(command.playerId or "global")] = payload.cursorState
	elseif command.presentationType == Types.PresentationType.HighlightObject then
		highlights[command.objectId] = Serialization.deepCopy(payload)
	elseif command.presentationType == Types.PresentationType.RemoveHighlight then
		highlights[command.objectId] = nil
	end
end

function CommandRuntime.activePrompt()
	local selected = nil
	for _, prompt in pairs(prompts) do
		if
			selected == nil
			or priorityRank(prompt.priority) > priorityRank(selected.priority)
			or (
				priorityRank(prompt.priority) == priorityRank(selected.priority)
				and tostring(prompt.promptId) < tostring(selected.promptId)
			)
		then
			selected = prompt
		end
	end
	return Serialization.deepCopy(selected)
end

function CommandRuntime.inspect()
	return {
		queuedCommands = #commands,
		executedCommands = #executed,
		expiredCommands = #expired,
		promptCount = count(prompts),
		busyCount = count(busyStates),
		audioRequests = #audioRequests,
		animationRequests = #animationRequests,
		messageRequests = count(messageRequests),
		cursorUpdates = count(cursorStates),
		highlightUpdates = count(highlights),
		queue = Serialization.deepCopy(commands),
		executed = Serialization.deepCopy(executed),
		expired = Serialization.deepCopy(expired),
		prompts = Serialization.deepCopy(prompts),
		activePrompt = CommandRuntime.activePrompt(),
		activeBusyStates = Serialization.deepCopy(busyStates),
		audioRequestRecords = Serialization.deepCopy(audioRequests),
		animationRequestRecords = Serialization.deepCopy(animationRequests),
		messageRequestRecords = Serialization.deepCopy(messageRequests),
		cursorState = Serialization.deepCopy(cursorStates),
		activeHighlights = Serialization.deepCopy(highlights),
	}
end

function CommandRuntime.clear()
	table.clear(commands)
	table.clear(commandIds)
	table.clear(executed)
	table.clear(expired)
	table.clear(prompts)
	table.clear(busyStates)
	table.clear(audioRequests)
	table.clear(animationRequests)
	table.clear(messageRequests)
	table.clear(cursorStates)
	table.clear(highlights)
end

return CommandRuntime
