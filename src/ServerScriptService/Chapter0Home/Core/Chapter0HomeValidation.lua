--!strict

local Types = require(script.Parent.Chapter0HomeTypes)

local Validation = {}

local function isNonEmptyString(value: any): boolean
	return type(value) == "string" and value ~= ""
end

local function isVector3(value: any): boolean
	return typeof(value) == "Vector3"
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

local function hasUnsafePayload(value: any, depth: number?): boolean
	local currentDepth = depth or 0

	if currentDepth > 4 then
		return true
	end

	if typeof(value) == "Instance" or typeof(value) == "RBXScriptConnection" then
		return true
	end

	if type(value) ~= "table" then
		return false
	end

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
			then
				return true
			end
		end

		if hasUnsafePayload(child, currentDepth + 1) then
			return true
		end
	end

	return false
end

function Validation.validateDefinition(definition: any): (boolean, string?)
	if type(definition) ~= "table" then
		return false, "definition must be a table"
	end

	if definition.chapterId ~= Types.ChapterId then
		return false, "invalid chapterId"
	end

	if not isNonEmptyString(definition.displayName) then
		return false, "displayName is required"
	end

	if not isVector3(definition.spawnPosition) then
		return false, "spawnPosition must be Vector3"
	end

	if type(definition.rooms) ~= "table" or #definition.rooms == 0 then
		return false, "rooms are required"
	end

	if #definition.rooms > Types.Limits.MaxRooms then
		return false, "room limit exceeded"
	end

	if type(definition.interactions) ~= "table" or #definition.interactions == 0 then
		return false, "interactions are required"
	end

	if #definition.interactions > Types.Limits.MaxInteractables then
		return false, "interactable limit exceeded"
	end

	local roomIds = {}
	local rooms = {}

	for _, room in ipairs(definition.rooms) do
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

		if not isVector3(room.position) or not isVector3(room.size) then
			return false, "room position and size must be Vector3"
		end

		if type(room.connections) ~= "table" then
			return false, "room connections must be an array"
		end

		rooms[room.roomId] = true
		table.insert(roomIds, room.roomId)
	end

	if hasDuplicate(roomIds) then
		return false, "duplicate room ids"
	end

	local interactionIds = {}

	for _, interaction in ipairs(definition.interactions) do
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

		if not isVector3(interaction.position) or not isVector3(interaction.size) then
			return false, "interaction position and size must be Vector3"
		end

		if type(interaction.requiredForCompletion) ~= "boolean" then
			return false, "requiredForCompletion must be boolean"
		end

		if hasUnsafePayload(interaction.metadata) then
			return false, "unsafe interaction metadata"
		end

		table.insert(interactionIds, interaction.interactionId)
	end

	if hasDuplicate(interactionIds) then
		return false, "duplicate interaction ids"
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
	end

	return true, nil
end

return Validation
