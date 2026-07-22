--!strict

local Runtime = require(script.Parent.RuntimeDialogueCapability)
local Types = require(script.Parent.DialogueTypes)

local SelfChecks = {}

local function definition(id: string)
	return {
		dialogueId = id,
		version = "1",
		participants = {
			{
				participantId = "system",
				participantType = Types.ParticipantType.System,
				displayToken = "dialogue.participant.system",
				metadata = {},
			},
		},
		entryNodeId = "start",
		variables = {
			{ variableId = "hasAnswered", defaultValue = false, metadata = {} },
		},
		conditions = {
			{ conditionId = "always", conditionKind = "MetadataOnly", inputs = {}, metadata = {} },
		},
		nodes = {
			{
				nodeId = "start",
				nodeType = Types.NodeType.Text,
				nextNodeIds = { "end" },
				choices = {},
				metadata = { textToken = "dialogue.start" },
			},
			{
				nodeId = "end",
				nodeType = Types.NodeType.End,
				nextNodeIds = {},
				choices = {},
				metadata = {},
			},
		},
		metadata = {},
	}
end

local function check(results: { any }, name: string, ok: boolean, detail: string?)
	results[#results + 1] = { name = name, ok = ok, detail = detail }
end

function SelfChecks.run()
	Runtime.reset()
	local results = {}
	local domain = Runtime.registerDomainCapability()
	check(results, "domain capability registration succeeds", domain.ok, domain.message)
	local registered = Runtime.registerDialogueDefinition(definition("dialogue.selfcheck"))
	check(results, "dialogue definition registers", registered.ok, registered.message)
	check(
		results,
		"duplicate dialogue rejects",
		not Runtime.registerDialogueDefinition(definition("dialogue.selfcheck")).ok
	)
	local missing = definition("dialogue.missingEntry")
	missing.entryNodeId = "missing"
	check(results, "missing entry node rejects", not Runtime.registerDialogueDefinition(missing).ok)
	local duplicateNode = definition("dialogue.duplicateNode")
	duplicateNode.nodes[2].nodeId = "start"
	check(
		results,
		"duplicate node rejects",
		not Runtime.registerDialogueDefinition(duplicateNode).ok
	)
	local unreachable = definition("dialogue.unreachable")
	unreachable.nodes[#unreachable.nodes + 1] = {
		nodeId = "orphan",
		nodeType = Types.NodeType.Text,
		nextNodeIds = {},
		choices = {},
		metadata = {},
	}
	check(
		results,
		"unreachable node rejects",
		not Runtime.registerDialogueDefinition(unreachable).ok
	)
	local unsafe = definition("dialogue.unsafe")
	unsafe.metadata.remote = "Fire" .. "Client"
	check(results, "unsafe payload rejects", not Runtime.registerDialogueDefinition(unsafe).ok)
	check(
		results,
		"participant registers",
		Runtime.registerParticipant({
			participantId = "system.runtime",
			participantType = Types.ParticipantType.System,
			displayToken = "dialogue.system",
			metadata = {},
		}).ok
	)
	local conversation = Runtime.createConversation({
		conversationId = "conversation.selfcheck",
		dialogueId = "dialogue.selfcheck",
		participants = { "system.runtime" },
	})
	check(results, "conversation creates", conversation.ok, conversation.message)
	check(
		results,
		"conversation initializes",
		Runtime.transitionConversation(
			"conversation.selfcheck",
			Types.ConversationState.Initialized
		).ok
	)
	check(
		results,
		"conversation activates",
		Runtime.transitionConversation("conversation.selfcheck", Types.ConversationState.Active).ok
	)
	check(
		results,
		"invalid lifecycle rejects",
		not Runtime.transitionConversation(
			"conversation.selfcheck",
			Types.ConversationState.Created
		).ok
	)
	check(
		results,
		"condition metadata evaluation succeeds",
		Runtime.evaluateCondition("always", {}).ok
	)
	check(
		results,
		"choice selection records evidence",
		Runtime.recordChoice("conversation.selfcheck", "choice.none").ok
	)
	local diagnostics = Runtime.inspect()
	check(
		results,
		"diagnostics provider lowerCamelCase",
		diagnostics.providerName == Types.ProviderName
	)
	check(
		results,
		"diagnostics posture lowerCamelCase",
		diagnostics.dialogueCapabilityPosture ~= nil
	)
	check(results, "diagnostics no networking", diagnostics.noNetworking == true)
	check(results, "diagnostics no command execution", diagnostics.noCommandExecution == true)
	check(results, "diagnostics no event publication", diagnostics.noEventPublication == true)
	check(results, "diagnostics no query execution", diagnostics.noQueryExecution == true)
	local snapshot = Runtime.getSnapshot()
	snapshot.dialogueRuntimeCapabilitySnapshot.counters.dialoguesRegistered = 999
	check(results, "snapshot isolation", Runtime.inspect().counters.dialoguesRegistered ~= 999)
	Runtime.shutdown()
	check(
		results,
		"shutdown rejects registration",
		not Runtime.registerDialogueDefinition(definition("dialogue.shutdown")).ok
	)
	local failed = 0
	for _, result in ipairs(results) do
		if not result.ok then
			failed += 1
		end
	end
	return {
		ok = failed == 0,
		total = #results,
		passed = #results - failed,
		failed = failed,
		failures = results,
	}
end

return SelfChecks
