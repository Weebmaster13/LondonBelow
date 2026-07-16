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
	environmentalReactions = true,
	atmosphericProgressionStages = true,
	atmosphericProgressionTransitions = true,
	observationFacts = true,
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

local reactionFields = {
	reactionId = true,
	interactionId = true,
	kind = true,
	targetKind = true,
	targetId = true,
	order = true,
	intensity = true,
	metadata = true,
}

local progressionStageFields = {
	stageId = true,
	order = true,
	initial = true,
	intensity = true,
	completionRelevant = true,
	metadata = true,
}

local progressionTransitionFields = {
	transitionId = true,
	interactionId = true,
	fromStageId = true,
	toStageId = true,
	order = true,
	requiredInteractionIds = true,
	feedbackId = true,
	reactionId = true,
	optionalModifier = true,
	completionRelevant = true,
	intensity = true,
	metadata = true,
}

local observationFactFields = {
	factId = true,
	observationId = true,
	chapterId = true,
	sourceRuntime = true,
	contractVersion = true,
	authority = true,
	kind = true,
	interactionId = true,
	stageId = true,
	feedbackId = true,
	reactionId = true,
	order = true,
	intensity = true,
	completionRelevant = true,
	optionalModifier = true,
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

local function contains(values: { string }, value: string): boolean
	for _, item in ipairs(values) do
		if item == value then
			return true
		end
	end

	return false
end

local function metadataMatches(actual: { [string]: any }, expected: { [string]: any }): boolean
	if metadataKeyCount(actual) ~= metadataKeyCount(expected) then
		return false
	end

	for key, expectedValue in pairs(expected) do
		if actual[key] ~= expectedValue then
			return false
		end
	end

	return true
end

local function orderedStringsMatch(actual: { string }, expected: { string }): boolean
	if #actual ~= #expected then
		return false
	end

	for index, expectedValue in ipairs(expected) do
		if actual[index] ~= expectedValue then
			return false
		end
	end

	return true
end

local function validateExactAtmosphericProgression(definition: any): (boolean, string?)
	if
		#definition.atmosphericProgressionStages
		~= #Types.CanonicalAtmosphericProgressionStageDefinitions
	then
		return false, "canonical atmospheric progression stage count drift"
	end

	for index, expectedStage in ipairs(Types.CanonicalAtmosphericProgressionStageDefinitions) do
		local actualStage = definition.atmosphericProgressionStages[index]

		if actualStage.stageId ~= expectedStage.stageId then
			return false, "canonical atmospheric progression stage id drift"
		end

		if actualStage.order ~= expectedStage.order then
			return false, "canonical atmospheric progression stage order drift"
		end

		if actualStage.initial ~= expectedStage.initial then
			return false, "canonical atmospheric progression initial stage drift"
		end

		if actualStage.intensity ~= expectedStage.intensity then
			return false, "canonical atmospheric progression stage intensity drift"
		end

		if actualStage.completionRelevant ~= expectedStage.completionRelevant then
			return false, "canonical atmospheric progression stage completion drift"
		end

		if not metadataMatches(actualStage.metadata, expectedStage.metadata) then
			return false, "canonical atmospheric progression stage metadata drift"
		end
	end

	if
		definition.atmosphericProgressionStages[1].stageId
		~= Types.InitialAtmosphericProgressionStageId
	then
		return false, "canonical atmospheric progression initial stage id drift"
	end

	if
		#definition.atmosphericProgressionTransitions
		~= #Types.CanonicalAtmosphericProgressionTransitionDefinitions
	then
		return false, "canonical atmospheric progression transition count drift"
	end

	for index, expectedTransition in
		ipairs(Types.CanonicalAtmosphericProgressionTransitionDefinitions)
	do
		local actualTransition = definition.atmosphericProgressionTransitions[index]

		if actualTransition.transitionId ~= expectedTransition.transitionId then
			return false, "canonical atmospheric progression transition id drift"
		end

		if actualTransition.order ~= expectedTransition.order then
			return false, "canonical atmospheric progression transition order drift"
		end

		if actualTransition.interactionId ~= expectedTransition.interactionId then
			return false, "canonical atmospheric progression interaction reference drift"
		end

		if actualTransition.fromStageId ~= expectedTransition.fromStageId then
			return false, "canonical atmospheric progression from-stage reference drift"
		end

		if actualTransition.toStageId ~= expectedTransition.toStageId then
			return false, "canonical atmospheric progression to-stage reference drift"
		end

		if actualTransition.feedbackId ~= expectedTransition.feedbackId then
			return false, "canonical atmospheric progression feedback reference drift"
		end

		if actualTransition.reactionId ~= expectedTransition.reactionId then
			return false, "canonical atmospheric progression reaction reference drift"
		end

		if actualTransition.optionalModifier ~= expectedTransition.optionalModifier then
			return false, "canonical atmospheric progression optional modifier drift"
		end

		if actualTransition.completionRelevant ~= expectedTransition.completionRelevant then
			return false, "canonical atmospheric progression transition completion drift"
		end

		if actualTransition.intensity ~= expectedTransition.intensity then
			return false, "canonical atmospheric progression transition intensity drift"
		end

		if
			not orderedStringsMatch(
				actualTransition.requiredInteractionIds,
				expectedTransition.requiredInteractionIds
			)
		then
			return false, "canonical atmospheric progression requirement sequence drift"
		end

		if not metadataMatches(actualTransition.metadata, expectedTransition.metadata) then
			return false, "canonical atmospheric progression transition metadata drift"
		end
	end

	return true, nil
end

local function validateExactObservationFacts(definition: any): (boolean, string?)
	if #definition.observationFacts ~= #Types.CanonicalObservationFactDefinitions then
		return false, "canonical observation fact count drift"
	end

	for index, expectedFact in ipairs(Types.CanonicalObservationFactDefinitions) do
		local actualFact = definition.observationFacts[index]

		if actualFact.factId ~= expectedFact.factId then
			return false, "canonical observation fact id drift"
		end

		if actualFact.observationId ~= expectedFact.observationId then
			return false, "canonical observation runtime id drift"
		end

		if actualFact.chapterId ~= expectedFact.chapterId then
			return false, "canonical observation chapter reference drift"
		end

		if actualFact.sourceRuntime ~= expectedFact.sourceRuntime then
			return false, "canonical observation source runtime drift"
		end

		if actualFact.contractVersion ~= expectedFact.contractVersion then
			return false, "canonical observation contract version drift"
		end

		if actualFact.authority ~= expectedFact.authority then
			return false, "canonical observation authority drift"
		end

		if actualFact.kind ~= expectedFact.kind then
			return false, "canonical observation kind drift"
		end

		if actualFact.interactionId ~= expectedFact.interactionId then
			return false, "canonical observation interaction reference drift"
		end

		if actualFact.stageId ~= expectedFact.stageId then
			return false, "canonical observation stage reference drift"
		end

		if actualFact.feedbackId ~= expectedFact.feedbackId then
			return false, "canonical observation feedback reference drift"
		end

		if actualFact.reactionId ~= expectedFact.reactionId then
			return false, "canonical observation reaction reference drift"
		end

		if actualFact.order ~= expectedFact.order then
			return false, "canonical observation order drift"
		end

		if actualFact.intensity ~= expectedFact.intensity then
			return false, "canonical observation intensity drift"
		end

		if actualFact.completionRelevant ~= expectedFact.completionRelevant then
			return false, "canonical observation completion relevance drift"
		end

		if actualFact.optionalModifier ~= expectedFact.optionalModifier then
			return false, "canonical observation optional modifier drift"
		end

		if metadataKeyCount(actualFact.metadata) ~= #Types.ObservationMetadataSchemaKeys then
			return false, "canonical observation metadata schema drift"
		end

		for _, metadataKey in ipairs(Types.ObservationMetadataSchemaKeys) do
			if type(actualFact.metadata[metadataKey]) ~= "string" then
				return false, "canonical observation metadata schema drift"
			end
		end

		if not metadataMatches(actualFact.metadata, expectedFact.metadata) then
			return false, "canonical observation metadata drift"
		end
	end

	return true, nil
end

local function validateOrderedIds(
	definitions: { any },
	idField: string,
	orderField: string
): (boolean, string?)
	local ids = {}
	local orders = {}
	local lastOrder = 0

	for _, item in ipairs(definitions) do
		if not isNonEmptyString(item[idField]) then
			return false, idField .. " is required"
		end

		if
			type(item[orderField]) ~= "number"
			or item[orderField] % 1 ~= 0
			or item[orderField] <= 0
		then
			return false, orderField .. " is invalid"
		end

		if item[orderField] <= lastOrder then
			return false, orderField .. " must be deterministic"
		end

		lastOrder = item[orderField]

		if orders[item[orderField]] then
			return false, "duplicate " .. orderField
		end

		orders[item[orderField]] = true
		table.insert(ids, item[idField])
	end

	if hasDuplicate(ids) then
		return false, "duplicate " .. idField .. "s"
	end

	return true, nil
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

	local feedbackOrderOk, feedbackOrderReason =
		validateOrderedIds(definition.atmosphericFeedback, "feedbackId", "order")

	if not feedbackOrderOk then
		return false,
			string.gsub(
				feedbackOrderReason or "feedback ordering invalid",
				"feedbackIds",
				"feedback ids"
			)
	end

	if not isDenseArray(definition.environmentalReactions) then
		return false, "environmentalReactions must be an array"
	end

	if #definition.environmentalReactions > Types.Limits.MaxEnvironmentalReactionDefinitions then
		return false, "environmental reaction limit exceeded"
	end

	local reactionIds = {}

	for _, reactionDefinition in ipairs(definition.environmentalReactions) do
		if not hasOnlyFields(reactionDefinition, reactionFields) then
			return false, "environmental reaction contains unsupported fields"
		end

		if not isNonEmptyString(reactionDefinition.interactionId) then
			return false, "reaction interactionId is required"
		end

		local interactionFound = false

		for _, interactionId in ipairs(interactionIds) do
			if interactionId == reactionDefinition.interactionId then
				interactionFound = true
				break
			end
		end

		if not interactionFound then
			return false, "environmental reaction references unknown interaction"
		end

		if
			not isNonEmptyString(reactionDefinition.kind)
			or Types.EnvironmentalReactionKind[reactionDefinition.kind]
				~= reactionDefinition.kind
		then
			return false, "invalid environmental reaction kind"
		end

		if
			not isNonEmptyString(reactionDefinition.targetKind)
			or Types.EnvironmentalReactionTargetKind[reactionDefinition.targetKind]
				~= reactionDefinition.targetKind
		then
			return false, "invalid environmental reaction target kind"
		end

		if not isNonEmptyString(reactionDefinition.targetId) then
			return false, "environmental reaction targetId is required"
		end

		if reactionDefinition.targetKind == Types.EnvironmentalReactionTargetKind.Room then
			if not rooms[reactionDefinition.targetId] then
				return false, "environmental reaction references unknown room"
			end
		elseif
			reactionDefinition.targetKind == Types.EnvironmentalReactionTargetKind.Interaction
		then
			local targetFound = false

			for _, interactionId in ipairs(interactionIds) do
				if interactionId == reactionDefinition.targetId then
					targetFound = true
					break
				end
			end

			if not targetFound then
				return false, "environmental reaction references unknown target interaction"
			end
		elseif reactionDefinition.targetId ~= Types.RootFolderName then
			return false, "environmental reaction root target is invalid"
		end

		if
			not isFiniteNumber(reactionDefinition.intensity)
			or reactionDefinition.intensity < 0
			or reactionDefinition.intensity > 1
		then
			return false, "environmental reaction intensity must be between 0 and 1"
		end

		if type(reactionDefinition.metadata) ~= "table" then
			return false, "environmental reaction metadata must be a table"
		end

		if
			metadataKeyCount(reactionDefinition.metadata)
			> Types.Limits.MaxEnvironmentalReactionMetadataKeys
		then
			return false, "environmental reaction metadata limit exceeded"
		end

		for key in pairs(reactionDefinition.metadata) do
			if type(key) ~= "string" or not isLowerCamelCase(key) then
				return false, "environmental reaction metadata keys must be lowerCamelCase"
			end
		end

		if hasUnsafePayload(reactionDefinition.metadata) then
			return false, "unsafe environmental reaction metadata"
		end

		table.insert(reactionIds, reactionDefinition.reactionId)
	end

	local reactionOrderOk, reactionOrderReason =
		validateOrderedIds(definition.environmentalReactions, "reactionId", "order")

	if not reactionOrderOk then
		return false, reactionOrderReason or "environmental reaction ordering invalid"
	end

	if not isDenseArray(definition.atmosphericProgressionStages) then
		return false, "atmosphericProgressionStages must be an array"
	end

	if #definition.atmosphericProgressionStages > Types.Limits.MaxAtmosphericProgressionStages then
		return false, "atmospheric progression stage limit exceeded"
	end

	local stageIds = {}
	local stages = {}
	local initialStageCount = 0

	for _, stageDefinition in ipairs(definition.atmosphericProgressionStages) do
		if not hasOnlyFields(stageDefinition, progressionStageFields) then
			return false, "atmospheric progression stage contains unsupported fields"
		end

		if not isNonEmptyString(stageDefinition.stageId) then
			return false, "progression stageId is required"
		end

		if stages[stageDefinition.stageId] then
			return false, "duplicate progression stageId"
		end

		if type(stageDefinition.initial) ~= "boolean" then
			return false, "progression stage initial must be boolean"
		end

		if stageDefinition.initial then
			initialStageCount += 1
		end

		if type(stageDefinition.completionRelevant) ~= "boolean" then
			return false, "progression stage completionRelevant must be boolean"
		end

		if
			not isFiniteNumber(stageDefinition.intensity)
			or stageDefinition.intensity < 0
			or stageDefinition.intensity > 1
		then
			return false, "progression stage intensity must be between 0 and 1"
		end

		if type(stageDefinition.metadata) ~= "table" then
			return false, "progression stage metadata must be a table"
		end

		if
			metadataKeyCount(stageDefinition.metadata)
			> Types.Limits.MaxAtmosphericProgressionMetadataKeys
		then
			return false, "progression stage metadata limit exceeded"
		end

		for key in pairs(stageDefinition.metadata) do
			if type(key) ~= "string" or not isLowerCamelCase(key) then
				return false, "progression stage metadata keys must be lowerCamelCase"
			end
		end

		if hasUnsafePayload(stageDefinition.metadata) then
			return false, "unsafe progression stage metadata"
		end

		stages[stageDefinition.stageId] = stageDefinition
		table.insert(stageIds, stageDefinition.stageId)
	end

	if initialStageCount == 0 then
		return false, "missing initial progression stage"
	elseif initialStageCount > 1 then
		return false, "multiple initial progression stages"
	end

	local stageOrderOk, stageOrderReason =
		validateOrderedIds(definition.atmosphericProgressionStages, "stageId", "order")

	if not stageOrderOk then
		return false, stageOrderReason or "progression stage ordering invalid"
	end

	if not isDenseArray(definition.atmosphericProgressionTransitions) then
		return false, "atmosphericProgressionTransitions must be an array"
	end

	if
		#definition.atmosphericProgressionTransitions
		> Types.Limits.MaxAtmosphericProgressionTransitions
	then
		return false, "atmospheric progression transition limit exceeded"
	end

	local transitionIds = {}
	local reachableStages = {
		[Types.InitialAtmosphericProgressionStageId] = true,
	}
	local lastProgressionOrder = 0

	for _, transitionDefinition in ipairs(definition.atmosphericProgressionTransitions) do
		if not hasOnlyFields(transitionDefinition, progressionTransitionFields) then
			return false, "atmospheric progression transition contains unsupported fields"
		end

		if not isNonEmptyString(transitionDefinition.transitionId) then
			return false, "progression transitionId is required"
		end

		if contains(transitionIds, transitionDefinition.transitionId) then
			return false, "duplicate progression transitionId"
		end

		table.insert(transitionIds, transitionDefinition.transitionId)

		if
			type(transitionDefinition.order) ~= "number"
			or transitionDefinition.order % 1 ~= 0
			or transitionDefinition.order <= 0
			or transitionDefinition.order <= lastProgressionOrder
		then
			return false, "progression transition ordering invalid"
		end

		lastProgressionOrder = transitionDefinition.order

		if not stages[transitionDefinition.fromStageId] then
			return false, "progression transition references unknown from stage"
		end

		if type(transitionDefinition.optionalModifier) ~= "boolean" then
			return false, "progression transition optionalModifier must be boolean"
		end

		if transitionDefinition.optionalModifier then
			if transitionDefinition.toStageId ~= nil then
				return false, "optional progression modifiers must not advance stages"
			end
		elseif not stages[transitionDefinition.toStageId] then
			return false, "progression transition references unknown to stage"
		end

		if transitionDefinition.toStageId == transitionDefinition.fromStageId then
			return false, "cyclic atmospheric progression is unsupported"
		end

		if not contains(interactionIds, transitionDefinition.interactionId) then
			return false, "progression transition references unknown interaction"
		end

		if
			transitionDefinition.optionalModifier
			and requiredByInteraction[transitionDefinition.interactionId]
		then
			return false, "required interactions cannot be optional progression modifiers"
		end

		if
			not transitionDefinition.optionalModifier
			and requiredByInteraction[transitionDefinition.interactionId] ~= true
		then
			return false, "optional interactions cannot be mandatory progression gates"
		end

		if
			not contains(definition.completionInteractionIds, transitionDefinition.interactionId)
			and transitionDefinition.completionRelevant
		then
			return false, "optional interactions cannot be completion relevant progression"
		end

		if not contains(feedbackIds, transitionDefinition.feedbackId) then
			return false, "progression transition references unknown feedback"
		end

		if not contains(reactionIds, transitionDefinition.reactionId) then
			return false, "progression transition references unknown reaction"
		end

		if not isDenseArray(transitionDefinition.requiredInteractionIds) then
			return false, "progression transition requirements must be an array"
		end

		if
			#transitionDefinition.requiredInteractionIds
			> Types.Limits.MaxAtmosphericProgressionTransitionRequirements
		then
			return false, "progression transition requirement limit exceeded"
		end

		if hasDuplicate(transitionDefinition.requiredInteractionIds) then
			return false, "duplicate progression transition requirements"
		end

		if
			not contains(
				transitionDefinition.requiredInteractionIds,
				transitionDefinition.interactionId
			)
		then
			return false, "progression transition requirements must include interaction"
		end

		for _, requiredId in ipairs(transitionDefinition.requiredInteractionIds) do
			if not contains(interactionIds, requiredId) then
				return false, "progression transition references unknown required interaction"
			end
		end

		if type(transitionDefinition.completionRelevant) ~= "boolean" then
			return false, "progression transition completionRelevant must be boolean"
		end

		if
			not isFiniteNumber(transitionDefinition.intensity)
			or transitionDefinition.intensity < 0
			or transitionDefinition.intensity > 1
		then
			return false, "progression transition intensity must be between 0 and 1"
		end

		if type(transitionDefinition.metadata) ~= "table" then
			return false, "progression transition metadata must be a table"
		end

		if
			metadataKeyCount(transitionDefinition.metadata)
			> Types.Limits.MaxAtmosphericProgressionMetadataKeys
		then
			return false, "progression transition metadata limit exceeded"
		end

		for key in pairs(transitionDefinition.metadata) do
			if type(key) ~= "string" or not isLowerCamelCase(key) then
				return false, "progression transition metadata keys must be lowerCamelCase"
			end
		end

		if hasUnsafePayload(transitionDefinition.metadata) then
			return false, "unsafe progression transition metadata"
		end

		if not transitionDefinition.optionalModifier then
			if reachableStages[transitionDefinition.fromStageId] ~= true then
				return false, "unreachable atmospheric progression stage"
			end

			local toStageId = transitionDefinition.toStageId

			if type(toStageId) ~= "string" then
				return false, "progression transition toStageId is required"
			end

			reachableStages[toStageId] = true
		elseif reachableStages[transitionDefinition.fromStageId] ~= true then
			return false, "unreachable atmospheric progression modifier"
		end
	end

	local transitionOrderOk, transitionOrderReason =
		validateOrderedIds(definition.atmosphericProgressionTransitions, "transitionId", "order")

	if not transitionOrderOk then
		return false, transitionOrderReason or "progression transition ordering invalid"
	end

	for _, stageId in ipairs(stageIds) do
		if not reachableStages[stageId] then
			return false, "unreachable atmospheric progression stage"
		end
	end

	local exactProgressionOk, exactProgressionReason =
		validateExactAtmosphericProgression(definition)

	if not exactProgressionOk then
		return false, exactProgressionReason
	end

	if not isDenseArray(definition.observationFacts) then
		return false, "observationFacts must be an array"
	end

	if #definition.observationFacts > Types.Limits.MaxObservationDefinitions then
		return false, "observation fact definition limit exceeded"
	end

	local observationFactIds = {}
	local observationRuntimeIds = {}
	local lastObservationOrder = 0

	for _, factDefinition in ipairs(definition.observationFacts) do
		if not hasOnlyFields(factDefinition, observationFactFields) then
			return false, "observation fact contains unsupported fields"
		end

		if not isNonEmptyString(factDefinition.factId) then
			return false, "observation factId is required"
		end

		if contains(observationFactIds, factDefinition.factId) then
			return false, "duplicate observation factId"
		end

		table.insert(observationFactIds, factDefinition.factId)

		if not isNonEmptyString(factDefinition.observationId) then
			return false, "observationId is required"
		end

		if contains(observationRuntimeIds, factDefinition.observationId) then
			return false, "duplicate observationId"
		end

		table.insert(observationRuntimeIds, factDefinition.observationId)

		if factDefinition.chapterId ~= Types.ChapterId then
			return false, "observation fact chapterId is invalid"
		end

		if factDefinition.sourceRuntime ~= Types.ObservationSourceRuntime then
			return false, "observation fact source runtime is invalid"
		end

		if factDefinition.contractVersion ~= Types.ObservationContractVersion then
			return false, "observation contract version is invalid"
		end

		if factDefinition.authority ~= Types.ObservationAuthority then
			return false, "observation authority marker is invalid"
		end

		if
			not isNonEmptyString(factDefinition.kind)
			or Types.ObservationKind[factDefinition.kind] ~= factDefinition.kind
		then
			return false, "observation kind is invalid"
		end

		if not contains(interactionIds, factDefinition.interactionId) then
			return false, "observation fact references unknown interaction"
		end

		if not contains(stageIds, factDefinition.stageId) then
			return false, "observation fact references unknown stage"
		end

		if not contains(feedbackIds, factDefinition.feedbackId) then
			return false, "observation fact references unknown feedback"
		end

		if not contains(reactionIds, factDefinition.reactionId) then
			return false, "observation fact references unknown reaction"
		end

		if
			type(factDefinition.order) ~= "number"
			or factDefinition.order % 1 ~= 0
			or factDefinition.order <= 0
			or factDefinition.order <= lastObservationOrder
			or factDefinition.order > Types.Limits.MaxObservationSequenceValue
		then
			return false, "observation fact ordering invalid"
		end

		lastObservationOrder = factDefinition.order

		if
			not isFiniteNumber(factDefinition.intensity)
			or factDefinition.intensity < 0
			or factDefinition.intensity > 1
		then
			return false, "observation fact intensity must be between 0 and 1"
		end

		if type(factDefinition.completionRelevant) ~= "boolean" then
			return false, "observation completionRelevant must be boolean"
		end

		if type(factDefinition.optionalModifier) ~= "boolean" then
			return false, "observation optionalModifier must be boolean"
		end

		if type(factDefinition.metadata) ~= "table" then
			return false, "observation metadata must be a table"
		end

		if metadataKeyCount(factDefinition.metadata) > Types.Limits.MaxObservationMetadataKeys then
			return false, "observation metadata limit exceeded"
		end

		for key in pairs(factDefinition.metadata) do
			if type(key) ~= "string" or not isLowerCamelCase(key) then
				return false, "observation metadata keys must be lowerCamelCase"
			end
		end

		if hasUnsafePayload(factDefinition.metadata) then
			return false, "unsafe observation metadata"
		end
	end

	local exactObservationOk, exactObservationReason = validateExactObservationFacts(definition)

	if not exactObservationOk then
		return false, exactObservationReason
	end

	return true, nil
end

return Validation
