--!strict

local DialogueCoordinator = require(script.Parent.DialogueCoordinator)
local DialogueTypes = require(script.Parent.DialogueTypes)
local Runtime = require(script.Parent.RuntimeDialogueExecution)
local Types = require(script.Parent.DialogueExecutionTypes)

local SelfChecks = {}

local function definition(id: string)
	return {
		dialogueId = id,
		version = "1",
		participants = {
			{
				participantId = "system",
				participantType = DialogueTypes.ParticipantType.System,
				displayToken = "dialogue.participant.system",
				metadata = {},
			},
		},
		entryNodeId = "start",
		variables = {
			{ variableId = "flag", defaultValue = false, metadata = {} },
		},
		conditions = {
			{
				conditionId = "flagIsTrue",
				conditionKind = "VariableEquals",
				inputs = { variableId = "flag", expectedValue = true },
				metadata = {},
			},
		},
		nodes = {
			{
				nodeId = "start",
				nodeType = DialogueTypes.NodeType.Text,
				nextNodeIds = { "setFlag" },
				choices = {},
				metadata = { textToken = "dialogue.start" },
			},
			{
				nodeId = "setFlag",
				nodeType = DialogueTypes.NodeType.VariableAssignment,
				nextNodeIds = { "condition" },
				choices = {},
				metadata = { assignments = { flag = true } },
			},
			{
				nodeId = "condition",
				nodeType = DialogueTypes.NodeType.Condition,
				nextNodeIds = { "choice" },
				choices = {},
				metadata = { conditionIds = { "flagIsTrue" } },
			},
			{
				nodeId = "choice",
				nodeType = DialogueTypes.NodeType.Choice,
				nextNodeIds = {},
				choices = {
					{
						choiceId = "continue",
						displayToken = "dialogue.choice.continue",
						destinationNodeId = "end",
						conditions = {},
						metadata = {},
					},
				},
				metadata = {},
			},
			{
				nodeId = "end",
				nodeType = DialogueTypes.NodeType.End,
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
	DialogueCoordinator.registerDialogueDefinition(definition("dialogue.execution.selfcheck"))
	DialogueCoordinator.createConversation({
		conversationId = "conversation.execution.selfcheck",
		dialogueId = "dialogue.execution.selfcheck",
		participants = { "system" },
	})
	local start = Runtime.startExecution({
		executionId = "execution.selfcheck",
		conversationId = "conversation.execution.selfcheck",
		workflowReference = {},
		runtimeMetadata = {},
	})
	check(results, "execution starts and reaches choice", start.ok, start.message)
	check(
		results,
		"context waiting choice",
		Runtime.inspect().executingConversations[1].executionState
			== Types.ExecutionState.WaitingChoice
	)
	check(results, "invalid duplicate execution rejects", not Runtime.startExecution({
		executionId = "execution.selfcheck",
		conversationId = "conversation.execution.selfcheck",
	}).ok)
	check(
		results,
		"choice selection completes",
		Runtime.selectChoice("execution.selfcheck", "continue").ok
	)
	check(
		results,
		"context closes after end",
		Runtime.inspect().executingConversations[1].executionState == Types.ExecutionState.Closed
	)
	check(
		results,
		"unknown choice rejects",
		not Runtime.selectChoice("execution.selfcheck", "missing").ok
	)
	check(results, "recovery succeeds", Runtime.recoverExecution("execution.selfcheck").ok)
	check(
		results,
		"suspension succeeds",
		Runtime.suspendExecution("execution.selfcheck", "selfcheck").ok
	)
	check(results, "resumption succeeds", Runtime.resumeExecution("execution.selfcheck").ok)
	local diagnostics = Runtime.inspect()
	check(
		results,
		"diagnostics provider lowerCamelCase",
		diagnostics.providerName == Types.ProviderName
	)
	check(
		results,
		"diagnostics posture lowerCamelCase",
		diagnostics.dialogueExecutionPosture ~= nil
	)
	check(results, "diagnostics no gameplay execution", diagnostics.noGameplayExecution == true)
	check(results, "diagnostics no networking", diagnostics.noNetworking == true)
	check(results, "diagnostics no command execution", diagnostics.noCommandExecution == true)
	check(results, "diagnostics no event publication", diagnostics.noEventPublication == true)
	check(results, "diagnostics no query execution", diagnostics.noQueryExecution == true)
	local snapshot = Runtime.getSnapshot()
	snapshot.dialogueRuntimeExecutionSnapshot.counters.executionsStarted = 999
	check(results, "snapshot isolation", Runtime.inspect().counters.executionsStarted ~= 999)
	Runtime.shutdown()
	check(results, "shutdown rejects new execution", not Runtime.startExecution({
		executionId = "execution.shutdown",
		conversationId = "conversation.execution.selfcheck",
	}).ok)
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
