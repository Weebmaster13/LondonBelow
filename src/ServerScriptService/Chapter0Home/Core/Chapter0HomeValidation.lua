--!strict

local Types = require(script.Parent.Chapter0HomeTypes)

local Validation = {}

local definitionFields = {
	chapterId = true,
	displayName = true,
	spawnPosition = true,
	rooms = true,
	interactions = true,
	completionInteractionIds = true,
	atmosphericFeedback = true,
}

local roomFields = {
	roomId = true,
	displayName = true,
	kind = true,
	position = true,
	size = true,
	connections = true,
}

local interactionFields = {
	interactionId = true,
	roomId = true,
	kind = true,
	prompt = true,
	position = true,
	size = true,
	requiredForCompletion = true,
	metadata = true,
}

local feedbackFields = {
	feedbackId = true,
	interactionId = true,
	kind = true,
	instructionId = true,
	intensity = true,
	duration = true,
	order = true,
	metadata = true,
}

local function isLowerCamelCase(value: string): boolean
	return string.match(value, "^[a-z][A-Za-z0-9]*$") ~= nil
end

local function isNonEmptyString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function isFiniteVector3(value: any): boolean
	return typeof(value) == "Vector3"
		and isFiniteNumber(value.X)
		and isFiniteNumber(value.Y)
		and isFiniteNumber(value.Z)
end

local function isBoundedPosition(value: any): boolean
	if not isFiniteVector3(value) then
		return false
	end

	return math.abs(value.X) <= Types.Limits.MaxCoordinateMagnitude
		and math.abs(value.Y) <= Types.Limits.MaxCoordinateMagnitude
		and math.abs(value.Z) <= Types.Limits.MaxCoordinateMagnitude
end

local function isBoundedSize(value: any, limit: number): boolean
	if not isFiniteVector3(value) then
		return false
	end

	return value.X > 0
		and value.Y > 0
		and value.Z > 0
		and value.X <= limit
		and value.Y <= limit
		and value.Z <= limit
end

local function hasOnlyFields(value: any, allowed: { [string]: boolean }): boolean
	if type(value) ~= "table" then
		return false
	end

	for key in pairs(value) do
		if type(key) ~= "string" or allowed[key] ~= true then
			return false
		end
	end

	return true
end

local function hasDuplicate(values: { string }): boolean
	local seen = {}

	for _, value in ipairs(values) do
		if seen[value] then
			return true
		end

		seen[value] = true
	end

	return false
end

local function isDenseArray(value: any): boolean
	if type(value) ~= "table" then
		return false
	end

	local length = #value
	local numericCount = 0

	for key in pairs(value) do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 then
			return false
		end

		numericCount += 1
	end

	if numericCount ~= length then
		return false
	end

	for index = 1, length do
		if value[index] == nil then
			return false
		end
	end

	return true
end

local function hasUnsafePayload(value: any, depth: number?, seen: { [any]: boolean }?): boolean
	local currentDepth = depth or 0
	local visited = seen or {}

	if currentDepth > Types.Limits.MaxMetadataDepth then
		return true
	end

	if
		type(value) == "function"
		or type(value) == "thread"
		or typeof(value) == "Instance"
		or typeof(value) == "RBXScriptConnection"
	then
		return true
	end

	if type(value) ~= "table" then
		return false
	end

	if visited[value] then
		return true
	end

	visited[value] = true

	for key, child in pairs(value) do
		if type(key) == "string" then
			local lowered = string.lower(key)

			if
				string.find(lowered, "datastore", 1, true)
				or string.find(lowered, "http", 1, true)
				or string.find(lowered, "messagingservice", 1, true)
				or string.find(lowered, "telemetry", 1, true)
				or string.find(lowered, "analytics", 1, true)
				or string.find(lowered, "remote", 1, true)
				or string.find(lowered, "clientauthority", 1, true)
				or string.find(lowered, "clientowned", 1, true)
				or string.find(lowered, "authoritytoken", 1, true)
			then
				return true
			end
		end

		if hasUnsafePayload(child, currentDepth + 1, visited) then
			visited[value] = nil
			return true
		end
	end

	visited[value] = nil
	return false
end

local function metadataKeyCount(value: { [string]: any }): number
	local count = 0

	for _ in pairs(value) do
		count += 1
	end

	return count
end

function Validation.validateDefinition(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, "definition must be a table"
	end

	if not hasOnlyFields(definition, definitionFields) then
		return false, "definition contains unsupported fields"
	end

	if definition.chapterId ~= Types.ChapterId then
		return false, "invalid chapterId"
	end

	if not isNonEmptyString(definition.displayName) then
		return false, "displayName is required"
	end

	if not isBoundedPosition(definition.spawnPosition) then
		return false, "spawnPosition must be a finite bounded Vector3"
	end

	if not isDenseArray(definition.rooms) or #definition.rooms == 0 then
		return false, "rooms are required"
	end

	if #definition.rooms > Types.Limits.MaxRooms then
		return false, "room limit exceeded"
	end

	if not isDenseArray(definition.interactions) or #definition.interactions == 0 then
		return false, "interactions are required"
	end

	if #definition.interactions > Types.Limits.MaxInteractables then
		return false, "interactable limit exceeded"
	end

	local roomIds = {}
	local rooms = {}

	for _, room in ipairs(definition.rooms) do
		if not hasOnlyFields(room, roomFields) then
			return false, "room contains unsupported fields"
		end

		if not isNonEmptyString(room.roomId) then
			return false, "roomId is required"
		end

		if rooms[room.roomId] then
			return false, "duplicate roomId"
		end

		if not isNonEmptyString(room.displayName) then
			return false, "room displayName is required"
		end

		if not isNonEmptyString(room.kind) or Types.RoomKind[room.kind] ~= room.kind then
			return false, "invalid room kind"
		end

		if not isBoundedPosition(room.position) then
			return false, "room position must be a finite bounded Vector3"
		end

		if not isBoundedSize(room.size, Types.Limits.MaxRoomDimension) then
			return false, "room size must be finite positive bounded Vector3"
		end

		if not isDenseArray(room.connections) then
			return false, "room connections must be an array"
		end

		if #room.connections > Types.Limits.MaxRoomConnections then
			return false, "room connection limit exceeded"
		end

		if hasDuplicate(room.connections) then
			return false, "duplicate room connections"
		end

		for _, connectionId in ipairs(room.connections) do
			if not isNonEmptyString(connectionId) then
				return false, "room connection id is required"
			end

			if connectionId == room.roomId then
				return false, "self-referential room connections are unsupported"
			end
		end

		rooms[room.roomId] = true
		table.insert(roomIds, room.roomId)
	end

	if hasDuplicate(roomIds) then
		return false, "duplicate room ids"
	end

	for _, room in ipairs(definition.rooms) do
		for _, connectionId in ipairs(room.connections) do
			if not rooms[connectionId] then
				return false, "room connection references unknown room"
			end
		end
	end

	local interactionIds = {}
	local requiredByInteraction = {}

	for _, interaction in ipairs(definition.interactions) do
		if not hasOnlyFields(interaction, interactionFields) then
			return false, "interaction contains unsupported fields"
		end

		if not isNonEmptyString(interaction.interactionId) then
			return false, "interactionId is required"
		end

		if not rooms[interaction.roomId] then
			return false, "interaction references unknown room"
		end

		if
			not isNonEmptyString(interaction.kind)
			or Types.InteractionKind[interaction.kind] ~= interaction.kind
		then
			return false, "invalid interaction kind"
		end

		if not isNonEmptyString(interaction.prompt) then
			return false, "interaction prompt is required"
		end

		if not isBoundedPosition(interaction.position) then
			return false, "interaction position must be a finite bounded Vector3"
		end

		if not isBoundedSize(interaction.size, Types.Limits.MaxInteractionDimension) then
			return false, "interaction size must be finite positive bounded Vector3"
		end

		if type(interaction.requiredForCompletion) ~= "boolean" then
			return false, "requiredForCompletion must be boolean"
		end

		if type(interaction.metadata) ~= "table" then
			return false, "interaction metadata must be a table"
		end

		if hasUnsafePayload(interaction.metadata) then
			return false, "unsafe interaction metadata"
		end

		table.insert(interactionIds, interaction.interactionId)
		requiredByInteraction[interaction.interactionId] = interaction.requiredForCompletion
	end

	if hasDuplicate(interactionIds) then
		return false, "duplicate interaction ids"
	end

	if
		not isDenseArray(definition.completionInteractionIds)
		or #definition.completionInteractionIds == 0
	then
		return false, "completion interactions are required"
	end

	if hasDuplicate(definition.completionInteractionIds) then
		return false, "duplicate completion interaction ids"
	end

	for _, requiredId in ipairs(definition.completionInteractionIds) do
		local found = false

		for _, interactionId in ipairs(interactionIds) do
			if interactionId == requiredId then
				found = true
				break
			end
		end

		if not found then
			return false, "completion interaction references unknown interaction"
		end

		if requiredByInteraction[requiredId] ~= true then
			return false, "completion interaction references optional interaction"
		end
	end

	for _, interaction in ipairs(definition.interactions) do
		if interaction.requiredForCompletion then
			local listed = false

			for _, requiredId in ipairs(definition.completionInteractionIds) do
				if requiredId == interaction.interactionId then
					listed = true
					break
				end
			end

			if not listed then
				return false, "required interaction missing from completion list"
			end
		end
	end

	if not isDenseArray(definition.atmosphericFeedback) then
		return false, "atmosphericFeedback must be an array"
	end

	if #definition.atmosphericFeedback > Types.Limits.MaxFeedbackDefinitions then
		return false, "atmospheric feedback limit exceeded"
	end

	local feedbackIds = {}
	local feedbackOrders = {}
	local lastOrder = 0

	for _, feedbackDefinition in ipairs(definition.atmosphericFeedback) do
		if not hasOnlyFields(feedbackDefinition, feedbackFields) then
			return false, "feedback contains unsupported fields"
		end

		if not isNonEmptyString(feedbackDefinition.feedbackId) then
			return false, "feedbackId is required"
		end

		if not isNonEmptyString(feedbackDefinition.interactionId) then
			return false, "feedback interactionId is required"
		end

		local interactionFound = false

		for _, interactionId in ipairs(interactionIds) do
			if interactionId == feedbackDefinition.interactionId then
				interactionFound = true
				break
			end
		end

		if not interactionFound then
			return false, "feedback references unknown interaction"
		end

		if
			not isNonEmptyString(feedbackDefinition.kind)
			or Types.FeedbackKind[feedbackDefinition.kind] ~= feedbackDefinition.kind
		then
			return false, "invalid feedback kind"
		end

		if
			not isNonEmptyString(feedbackDefinition.instructionId)
			or #feedbackDefinition.instructionId > Types.Limits.MaxFeedbackInstructionIdLength
		then
			return false, "feedback instructionId is invalid"
		end

		if
			not isFiniteNumber(feedbackDefinition.intensity)
			or feedbackDefinition.intensity < 0
			or feedbackDefinition.intensity > 1
		then
			return false, "feedback intensity must be between 0 and 1"
		end

		if
			feedbackDefinition.duration ~= nil
			and (
				not isFiniteNumber(feedbackDefinition.duration)
				or feedbackDefinition.duration <= 0
				or feedbackDefinition.duration > 10
			)
		then
			return false, "feedback duration is invalid"
		end

		if
			type(feedbackDefinition.order) ~= "number"
			or feedbackDefinition.order % 1 ~= 0
			or feedbackDefinition.order <= 0
		then
			return false, "feedback order is invalid"
		end

		if feedbackDefinition.order <= lastOrder then
			return false, "feedback ordering must be deterministic"
		end

		lastOrder = feedbackDefinition.order

		if feedbackOrders[feedbackDefinition.order] then
			return false, "duplicate feedback order"
		end

		feedbackOrders[feedbackDefinition.order] = true

		if type(feedbackDefinition.metadata) ~= "table" then
			return false, "feedback metadata must be a table"
		end

		if metadataKeyCount(feedbackDefinition.metadata) > Types.Limits.MaxFeedbackMetadataKeys then
			return false, "feedback metadata limit exceeded"
		end

		for key in pairs(feedbackDefinition.metadata) do
			if type(key) ~= "string" or not isLowerCamelCase(key) then
				return false, "feedback metadata keys must be lowerCamelCase"
			end
		end

		if hasUnsafePayload(feedbackDefinition.metadata) then
			return false, "unsafe feedback metadata"
		end

		table.insert(feedbackIds, feedbackDefinition.feedbackId)
	end

	if hasDuplicate(feedbackIds) then
		return false, "duplicate feedback ids"
	end

	return true, nil
end

return Validation
