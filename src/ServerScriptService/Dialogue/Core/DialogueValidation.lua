--!strict

local Serialization = require(script.Parent.DialogueSerialization)
local Types = require(script.Parent.DialogueTypes)

local Validation = {}

local definitionFields = {
	dialogueId = true,
	version = true,
	participants = true,
	entryNodeId = true,
	variables = true,
	conditions = true,
	nodes = true,
	metadata = true,
}

local participantFields = {
	participantId = true,
	participantType = true,
	displayToken = true,
	metadata = true,
}

local nodeFields = {
	nodeId = true,
	nodeType = true,
	nextNodeIds = true,
	choices = true,
	metadata = true,
}

local choiceFields = {
	choiceId = true,
	displayToken = true,
	destinationNodeId = true,
	conditions = true,
	metadata = true,
}

local variableFields = {
	variableId = true,
	defaultValue = true,
	metadata = true,
}

local conditionFields = {
	conditionId = true,
	conditionKind = true,
	inputs = true,
	metadata = true,
}

local unsafeMarkers = {
	"analytics",
	"animation",
	"clientauthority",
	"commandexecutor",
	"datastore",
	"fireclient",
	"fireevent",
	"fireserver",
	"http",
	"inventoryinternals",
	"network",
	"npcaibehavior",
	"persistence",
	"queryexecutor",
	"remote",
	"render",
	"savewrite",
	"telemetry",
	"uiwidget",
	"voiceplayback",
	"workspace",
}

local function hasValue(set: { [string]: string }, value: string): boolean
	for _, item in pairs(set) do
		if item == value then
			return true
		end
	end
	return false
end

local function reject(code: string, message: string)
	return { ok = false, code = code, message = message }
end

local function validateString(value: any, name: string)
	if type(value) ~= "string" or value == "" or #value > Types.Limits.MaxStringLength then
		return reject(
			Types.FailureType.ValidationFailure,
			name .. " must be a bounded non-empty string"
		)
	end
	return nil
end

local function validateExactFields(record: any, allowed: { [string]: boolean }, name: string)
	if type(record) ~= "table" then
		return reject(Types.FailureType.ValidationFailure, name .. " must be a table")
	end
	for key in pairs(record) do
		if type(key) ~= "string" or not allowed[key] then
			return reject(Types.FailureType.ValidationFailure, "unknown " .. name .. " field")
		end
	end
	for key in pairs(allowed) do
		if record[key] == nil then
			return reject(
				Types.FailureType.ValidationFailure,
				"missing " .. name .. " field " .. key
			)
		end
	end
	return nil
end

local function scanUnsafe(value: any, depth: number, nodes: { count: number })
	nodes.count += 1
	if nodes.count > Types.Limits.MaxPayloadNodes then
		return reject(Types.FailureType.LimitExceeded, "payload node limit exceeded")
	end
	if depth > Types.Limits.MaxPayloadDepth then
		return reject(Types.FailureType.LimitExceeded, "payload depth limit exceeded")
	end
	local valueType = type(value)
	if valueType == "function" or valueType == "thread" or valueType == "userdata" then
		return reject(Types.FailureType.UnsafePayload, "unsafe payload value")
	end
	if valueType == "string" then
		local lowered = string.lower(value)
		if #value > Types.Limits.MaxStringLength then
			return reject(Types.FailureType.LimitExceeded, "string limit exceeded")
		end
		for _, marker in ipairs(unsafeMarkers) do
			if string.find(lowered, marker, 1, true) then
				return reject(Types.FailureType.UnsafePayload, "unsafe payload marker")
			end
		end
	end
	if valueType == "table" then
		for key, child in pairs(value) do
			local keyResult = scanUnsafe(key, depth + 1, nodes)
			if keyResult then
				return keyResult
			end
			local childResult = scanUnsafe(child, depth + 1, nodes)
			if childResult then
				return childResult
			end
		end
	end
	return nil
end

local function validateParticipant(participant: any, seen: { [string]: boolean })
	local fields = validateExactFields(participant, participantFields, "participant")
	if fields then
		return fields
	end
	local stringError = validateString(participant.participantId, "participantId")
		or validateString(participant.displayToken, "displayToken")
	if stringError then
		return stringError
	end
	if not hasValue(Types.ParticipantType, participant.participantType) then
		return reject(Types.FailureType.UnsupportedParticipantType, "unsupported participant type")
	end
	if seen[participant.participantId] then
		return reject(Types.FailureType.DuplicateParticipant, "duplicate participant")
	end
	seen[participant.participantId] = true
	return nil
end

local function validateChoice(choice: any, seenChoices: { [string]: boolean })
	local fields = validateExactFields(choice, choiceFields, "choice")
	if fields then
		return fields
	end
	local stringError = validateString(choice.choiceId, "choiceId")
		or validateString(choice.displayToken, "displayToken")
		or validateString(choice.destinationNodeId, "destinationNodeId")
	if stringError then
		return stringError
	end
	if seenChoices[choice.choiceId] then
		return reject(Types.FailureType.ValidationFailure, "duplicate choice")
	end
	seenChoices[choice.choiceId] = true
	if type(choice.conditions) ~= "table" or type(choice.metadata) ~= "table" then
		return reject(
			Types.FailureType.ValidationFailure,
			"choice conditions and metadata must be tables"
		)
	end
	return nil
end

local function validateNode(node: any, seenNodes: { [string]: boolean })
	local fields = validateExactFields(node, nodeFields, "node")
	if fields then
		return fields
	end
	local stringError = validateString(node.nodeId, "nodeId")
	if stringError then
		return stringError
	end
	if not hasValue(Types.NodeType, node.nodeType) then
		return reject(Types.FailureType.UnsupportedNodeType, "unsupported node type")
	end
	if seenNodes[node.nodeId] then
		return reject(Types.FailureType.InvalidNodeGraph, "duplicate node")
	end
	seenNodes[node.nodeId] = true
	if
		type(node.nextNodeIds) ~= "table"
		or type(node.choices) ~= "table"
		or type(node.metadata) ~= "table"
	then
		return reject(
			Types.FailureType.ValidationFailure,
			"node arrays and metadata must be tables"
		)
	end
	if #node.nextNodeIds > Types.Limits.MaxNodesPerDialogue then
		return reject(Types.FailureType.LimitExceeded, "node transition limit exceeded")
	end
	local seenChoices = {}
	for _, nextNodeId in ipairs(node.nextNodeIds) do
		local nextError = validateString(nextNodeId, "nextNodeId")
		if nextError then
			return nextError
		end
	end
	if #node.choices > Types.Limits.MaxChoicesPerNode then
		return reject(Types.FailureType.LimitExceeded, "choice limit exceeded")
	end
	for _, choice in ipairs(node.choices) do
		local choiceError = validateChoice(choice, seenChoices)
		if choiceError then
			return choiceError
		end
	end
	return nil
end

local function validateVariables(variables: any)
	if type(variables) ~= "table" or #variables > Types.Limits.MaxVariablesPerDialogue then
		return reject(Types.FailureType.ValidationFailure, "variables must be a bounded array")
	end
	local seen = {}
	for _, variable in ipairs(variables) do
		local fields = validateExactFields(variable, variableFields, "variable")
		if fields then
			return fields
		end
		local stringError = validateString(variable.variableId, "variableId")
		if stringError then
			return stringError
		end
		if seen[variable.variableId] then
			return reject(Types.FailureType.ValidationFailure, "duplicate variable")
		end
		seen[variable.variableId] = true
	end
	return nil
end

local function validateConditions(conditions: any)
	if type(conditions) ~= "table" or #conditions > Types.Limits.MaxConditionsPerDialogue then
		return reject(Types.FailureType.ValidationFailure, "conditions must be a bounded array")
	end
	local seen = {}
	for _, condition in ipairs(conditions) do
		local fields = validateExactFields(condition, conditionFields, "condition")
		if fields then
			return fields
		end
		local stringError = validateString(condition.conditionId, "conditionId")
			or validateString(condition.conditionKind, "conditionKind")
		if stringError then
			return stringError
		end
		if type(condition.inputs) ~= "table" or type(condition.metadata) ~= "table" then
			return reject(
				Types.FailureType.ValidationFailure,
				"condition inputs and metadata must be tables"
			)
		end
		if seen[condition.conditionId] then
			return reject(Types.FailureType.ValidationFailure, "duplicate condition")
		end
		seen[condition.conditionId] = true
	end
	return nil
end

local function validateGraph(definition: any)
	local nodesById = {}
	for _, node in ipairs(definition.nodes) do
		nodesById[node.nodeId] = node
	end
	if nodesById[definition.entryNodeId] == nil then
		return reject(Types.FailureType.InvalidNodeGraph, "entry node is missing")
	end
	for _, node in ipairs(definition.nodes) do
		for _, nextNodeId in ipairs(node.nextNodeIds) do
			if nodesById[nextNodeId] == nil then
				return reject(
					Types.FailureType.InvalidNodeGraph,
					"node transition target is missing"
				)
			end
		end
		for _, choice in ipairs(node.choices) do
			if nodesById[choice.destinationNodeId] == nil then
				return reject(Types.FailureType.InvalidNodeGraph, "choice destination is missing")
			end
		end
	end
	local reachable = {}
	local stack = { definition.entryNodeId }
	while #stack > 0 do
		local nodeId = table.remove(stack)
		if nodeId ~= nil and not reachable[nodeId] then
			reachable[nodeId] = true
			local node = nodesById[nodeId]
			for _, nextNodeId in ipairs(node.nextNodeIds) do
				stack[#stack + 1] = nextNodeId
			end
			for _, choice in ipairs(node.choices) do
				stack[#stack + 1] = choice.destinationNodeId
			end
		end
	end
	for _, node in ipairs(definition.nodes) do
		if not reachable[node.nodeId] then
			return reject(Types.FailureType.InvalidNodeGraph, "unreachable node")
		end
	end
	return nil
end

function Validation.validateDialogueDefinition(definition: any)
	local unsafe = scanUnsafe(definition, 0, { count = 0 })
	if unsafe then
		return unsafe
	end
	local fields = validateExactFields(definition, definitionFields, "dialogue definition")
	if fields then
		return fields
	end
	local stringError = validateString(definition.dialogueId, "dialogueId")
		or validateString(definition.version, "version")
		or validateString(definition.entryNodeId, "entryNodeId")
	if stringError then
		return stringError
	end
	if
		type(definition.participants) ~= "table"
		or #definition.participants > Types.Limits.MaxParticipants
	then
		return reject(Types.FailureType.ValidationFailure, "participants must be a bounded array")
	end
	if
		type(definition.nodes) ~= "table"
		or #definition.nodes == 0
		or #definition.nodes > Types.Limits.MaxNodesPerDialogue
	then
		return reject(
			Types.FailureType.ValidationFailure,
			"nodes must be a bounded non-empty array"
		)
	end
	local seenParticipants = {}
	for _, participant in ipairs(definition.participants) do
		local participantError = validateParticipant(participant, seenParticipants)
		if participantError then
			return participantError
		end
	end
	local seenNodes = {}
	for _, node in ipairs(definition.nodes) do
		local nodeError = validateNode(node, seenNodes)
		if nodeError then
			return nodeError
		end
	end
	local variableError = validateVariables(definition.variables)
	if variableError then
		return variableError
	end
	local conditionError = validateConditions(definition.conditions)
	if conditionError then
		return conditionError
	end
	if type(definition.metadata) ~= "table" then
		return reject(Types.FailureType.ValidationFailure, "metadata must be a table")
	end
	local graphError = validateGraph(definition)
	if graphError then
		return graphError
	end
	return { ok = true, code = "Ok", definition = Serialization.deepCopy(definition) }
end

function Validation.copy(value: any): any
	return Serialization.deepCopy(value)
end

return Validation
