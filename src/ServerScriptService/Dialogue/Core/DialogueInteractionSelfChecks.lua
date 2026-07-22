--!strict

local Runtime = require(script.Parent.RuntimeDialogueInteraction)
local Types = require(script.Parent.DialogueInteractionTypes)

local SelfChecks = {}

local function check(results: { any }, name: string, ok: boolean, detail: string?)
	results[#results + 1] = {
		name = name,
		ok = ok,
		detail = detail,
	}
end

local function request(id: string, expected: string?)
	return {
		interactionId = id,
		executionId = "execution.phase174",
		conversationId = "conversation.phase174",
		currentNodeId = "node.choice",
		expectedResponse = expected or "ChoiceResponse",
		timeoutDuration = 30,
		priority = 10,
		metadata = {
			source = "self-check",
		},
	}
end

function SelfChecks.run()
	Runtime.reset()
	local results = {}

	local created = Runtime.requestInteraction(request("interaction.phase174.001"))
	check(results, "interaction request accepted", created.ok == true, created.message)
	check(
		results,
		"pending interaction registered",
		#Runtime.inspect().pendingInteractions == 1,
		nil
	)
	check(results, "pending choice queued", #Runtime.inspect().activeWaits == 1, nil)
	check(
		results,
		"runtime event queue captures waiting state",
		#Runtime.inspect().runtimeQueue >= 2,
		nil
	)

	local duplicate = Runtime.requestInteraction(request("interaction.phase174.001"))
	check(
		results,
		"duplicate interaction rejects",
		duplicate.ok == false,
		duplicate.code == Types.FailureType.DuplicateInteraction and nil or duplicate.code
	)

	local invalid = Runtime.submitResponse("interaction.phase174.001", { kind = "InvalidResponse" })
	check(
		results,
		"invalid response rejects",
		invalid.ok == false,
		invalid.code == Types.FailureType.InvalidResponse and nil or invalid.code
	)
	check(
		results,
		"failed validation leaves interaction waiting",
		Runtime.inspect().pendingInteractions[1].status
			== Types.InteractionStatus.WaitingForResponse,
		nil
	)

	local submitted = Runtime.submitResponse(
		"interaction.phase174.001",
		{ kind = "ChoiceResponse", choiceId = "choice.open" }
	)
	check(results, "valid response accepted", submitted.ok == true, submitted.message)
	check(
		results,
		"response completes interaction",
		Runtime.inspect().pendingInteractions[1].status == Types.InteractionStatus.Completed,
		nil
	)
	check(
		results,
		"completed interaction removed from queue",
		#Runtime.inspect().activeWaits == 0,
		nil
	)

	local cancelledRequest = Runtime.requestInteraction(request("interaction.phase174.cancel"))
	local cancelled = Runtime.cancelInteraction("interaction.phase174.cancel", "self-check cancel")
	check(
		results,
		"cancel request setup accepted",
		cancelledRequest.ok == true,
		cancelledRequest.message
	)
	check(results, "cancelled interaction closes", cancelled.ok == true, cancelled.message)

	local expiredRequest = Runtime.requestInteraction(request("interaction.phase174.expire"))
	local expired = Runtime.expireInteraction("interaction.phase174.expire", "self-check timeout")
	check(
		results,
		"timeout request setup accepted",
		expiredRequest.ok == true,
		expiredRequest.message
	)
	check(results, "expired interaction closes", expired.ok == true, expired.message)
	check(
		results,
		"timeout state isolated",
		Runtime.inspect().timeoutState[1].reason == "self-check timeout",
		nil
	)

	local interrupted = Runtime.interruptExecution("execution.phase174", "nested wait", 2)
	local resumed = Runtime.resumeExecution("execution.phase174")
	check(results, "interruption accepted", interrupted.ok == true, interrupted.message)
	check(results, "resume accepted", resumed.ok == true, resumed.message)

	local nested = Runtime.enterNestedConversation(
		"execution.phase174",
		"execution.phase174.child",
		"return.node",
		1
	)
	local nestedExit = Runtime.exitNestedConversation("execution.phase174.child")
	check(results, "nested conversation accepted", nested.ok == true, nested.message)
	check(results, "nested conversation exits", nestedExit.ok == true, nestedExit.message)

	local diagnostics = Runtime.inspect()
	check(
		results,
		"provider name lowerCamelCase",
		diagnostics.providerName == Types.ProviderName,
		diagnostics.providerName
	)
	check(results, "posture key lowerCamelCase", diagnostics.dialogueInteractionPosture ~= nil, nil)
	check(results, "diagnostics report no networking", diagnostics.noNetworking == true, nil)
	check(
		results,
		"diagnostics report no client authority",
		diagnostics.noClientAuthority == true,
		nil
	)

	local snapshot = Runtime.getSnapshot()
	snapshot.dialogueRuntimeInteractionSnapshot.pendingInteractions = {}
	check(
		results,
		"snapshot isolation",
		#Runtime.getSnapshot().dialogueRuntimeInteractionSnapshot.pendingInteractions > 0,
		nil
	)

	local ok, reason = Runtime.validate()
	check(results, "runtime validation passes", ok == true, reason)

	Runtime.shutdown()
	local blocked = Runtime.requestInteraction(request("interaction.phase174.shutdown"))
	check(
		results,
		"shutdown blocks new requests",
		blocked.ok == false,
		blocked.code == Types.FailureType.RuntimeShutdown and nil or blocked.code
	)

	Runtime.reset()
	check(
		results,
		"shutdown cleanup clears sessions",
		#Runtime.inspect().pendingInteractions == 0,
		nil
	)
	check(results, "shutdown cleanup clears queue", #Runtime.inspect().activeWaits == 0, nil)
	check(
		results,
		"shutdown cleanup clears evidence",
		#Runtime.inspect().interactionEvidence == 0,
		nil
	)

	local failures = {}
	for _, result in ipairs(results) do
		if not result.ok then
			failures[#failures + 1] = result
		end
	end

	return {
		ok = #failures == 0,
		total = #results,
		passed = #results - #failures,
		failed = #failures,
		failures = failures,
		results = results,
	}
end

return SelfChecks
