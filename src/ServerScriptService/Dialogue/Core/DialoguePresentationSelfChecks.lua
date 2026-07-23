--!strict

local Runtime = require(script.Parent.RuntimeDialoguePresentationContract)
local Types = require(script.Parent.DialoguePresentationTypes)

local SelfChecks = {}

local function check(results: { any }, name: string, ok: boolean, detail: string?)
	results[#results + 1] = {
		name = name,
		ok = ok,
		detail = detail,
	}
end

local function request(id: string, policy: string?)
	return {
		presentationId = id,
		executionId = "execution.phase175",
		conversationId = "conversation.phase175",
		dialogueId = "dialogue.phase175",
		nodeId = "node.line",
		speakerId = "speaker.narrator",
		presentationKind = Types.PresentationKind.DialogueLine,
		descriptor = {
			textToken = "dialogue.phase175.line",
			speakerDisplayToken = "speaker.phase175",
			portraitReference = "portrait.narrator",
			emphasisMetadata = {
				intensity = "low",
			},
		},
		synchronizationPolicy = policy or Types.SynchronizationPolicy.WaitForCompleted,
		localizationReferences = {
			textToken = "dialogue.phase175.line",
			speakerDisplayToken = "speaker.phase175",
		},
		accessibilityMetadata = {
			screenReaderLabelToken = "dialogue.phase175.accessibility",
			readingOrder = 1,
		},
		runtimeMetadata = {
			source = "self-check",
		},
	}
end

function SelfChecks.run()
	Runtime.reset()
	local results = {}

	check(results, "default contract registered", #Runtime.inspect().registeredContracts == 1, nil)

	local created = Runtime.createPresentationRequest(request("presentation.phase175.001"))
	check(results, "presentation request accepted", created.ok == true, created.message)
	check(
		results,
		"request enters pending acknowledgement",
		created.request.status == Types.RequestStatus.PendingAcknowledgement,
		created.request.status
	)
	check(
		results,
		"request visible through public getter",
		Runtime.getPresentationRequest("presentation.phase175.001") ~= nil,
		nil
	)
	check(
		results,
		"localization references registered",
		Runtime.getLocalizationReferences("presentation.phase175.001").textToken
			== "dialogue.phase175.line",
		nil
	)
	check(
		results,
		"accessibility metadata registered",
		Runtime.getAccessibilityMetadata("presentation.phase175.001").readingOrder == 1,
		nil
	)

	local duplicate = Runtime.createPresentationRequest(request("presentation.phase175.001"))
	check(
		results,
		"duplicate presentation rejects",
		duplicate.ok == false,
		duplicate.code == Types.FailureType.DuplicatePresentation and nil or duplicate.code
	)

	local invalidKind = request("presentation.phase175.invalidKind")
	invalidKind.presentationKind = "ConcreteGui"
	local invalidKindResult = Runtime.createPresentationRequest(invalidKind)
	check(
		results,
		"invalid presentation kind rejects",
		invalidKindResult.ok == false,
		invalidKindResult.code == Types.FailureType.InvalidPresentationKind and nil
			or invalidKindResult.code
	)

	local invalidPolicy = request("presentation.phase175.invalidPolicy")
	invalidPolicy.synchronizationPolicy = "WaitForWidget"
	local invalidPolicyResult = Runtime.createPresentationRequest(invalidPolicy)
	check(
		results,
		"invalid sync policy rejects",
		invalidPolicyResult.ok == false,
		invalidPolicyResult.code == Types.FailureType.InvalidSynchronizationPolicy and nil
			or invalidPolicyResult.code
	)

	local invalidDescriptor = request("presentation.phase175.invalidDescriptor")
	invalidDescriptor.descriptor = function() end
	local invalidDescriptorResult = Runtime.createPresentationRequest(invalidDescriptor)
	check(
		results,
		"invalid descriptor rejects executable payload",
		invalidDescriptorResult.ok == false,
		invalidDescriptorResult.code == Types.FailureType.InvalidDescriptor and nil
			or invalidDescriptorResult.code
	)

	local mismatch = Runtime.acknowledgePresentation({
		acknowledgementId = "ack.phase175.mismatch",
		presentationId = "presentation.phase175.001",
		executionId = "execution.other",
		acknowledgementKind = Types.AcknowledgementKind.Accepted,
		consumerId = "presentation.consumer",
	})
	check(
		results,
		"execution mismatch rejects",
		mismatch.ok == false,
		mismatch.code == Types.FailureType.ExecutionMismatch and nil or mismatch.code
	)

	local accepted = Runtime.acknowledgePresentation({
		acknowledgementId = "ack.phase175.accepted",
		presentationId = "presentation.phase175.001",
		executionId = "execution.phase175",
		acknowledgementKind = Types.AcknowledgementKind.Accepted,
		consumerId = "presentation.consumer",
	})
	check(results, "acknowledgement accepted", accepted.ok == true, accepted.message)

	local duplicateAck = Runtime.acknowledgePresentation({
		acknowledgementId = "ack.phase175.accepted",
		presentationId = "presentation.phase175.001",
		executionId = "execution.phase175",
		acknowledgementKind = Types.AcknowledgementKind.Started,
		consumerId = "presentation.consumer",
	})
	check(
		results,
		"duplicate acknowledgement rejects",
		duplicateAck.ok == false,
		duplicateAck.code == Types.FailureType.DuplicateAcknowledgement and nil or duplicateAck.code
	)

	local completed = Runtime.acknowledgePresentation({
		acknowledgementId = "ack.phase175.completed",
		presentationId = "presentation.phase175.001",
		executionId = "execution.phase175",
		acknowledgementKind = Types.AcknowledgementKind.Completed,
		consumerId = "presentation.consumer",
	})
	check(results, "completion acknowledgement accepted", completed.ok == true, completed.message)

	local sync = Runtime.resolveSynchronizationState("presentation.phase175.001")
	check(
		results,
		"synchronization completes",
		sync.ok == true and sync.synchronization.satisfied == true,
		sync.message
	)

	local nowait = Runtime.createPresentationRequest(
		request("presentation.phase175.nowait", Types.SynchronizationPolicy.NoWait)
	)
	local nowaitSync = Runtime.resolveSynchronizationState("presentation.phase175.nowait")
	check(results, "no-wait request accepted", nowait.ok == true, nowait.message)
	check(
		results,
		"no-wait synchronization satisfied",
		nowaitSync.ok == true and nowaitSync.synchronization.satisfied == true,
		nowaitSync.message
	)

	local diagnostics = Runtime.inspect()
	check(
		results,
		"provider name lowerCamelCase",
		diagnostics.providerName == Types.ProviderName,
		diagnostics.providerName
	)
	check(
		results,
		"posture key lowerCamelCase",
		diagnostics.dialoguePresentationContractPosture ~= nil,
		nil
	)
	check(results, "diagnostics report no UI rendering", diagnostics.noUiRendering == true, nil)
	check(results, "diagnostics report no networking", diagnostics.noNetworking == true, nil)
	check(
		results,
		"diagnostics report no client authority",
		diagnostics.noClientAuthority == true,
		nil
	)
	check(
		results,
		"certification remains candidate",
		diagnostics.certification.productionCertified == false,
		nil
	)

	local snapshot = Runtime.getSnapshot()
	snapshot.dialogueRuntimePresentationContractSnapshot.activePresentationRequests = {}
	check(
		results,
		"snapshot isolation",
		#Runtime.getSnapshot().dialogueRuntimePresentationContractSnapshot.activePresentationRequests
			> 0,
		nil
	)

	local ok, reason = Runtime.validate()
	check(results, "runtime validation passes", ok == true, reason)

	Runtime.shutdown()
	local blocked = Runtime.createPresentationRequest(request("presentation.phase175.shutdown"))
	check(
		results,
		"shutdown blocks new requests",
		blocked.ok == false,
		blocked.code == Types.FailureType.RuntimeShutdown and nil or blocked.code
	)

	Runtime.reset()
	check(results, "reset clears requests", #Runtime.inspect().activePresentationRequests == 0, nil)
	check(
		results,
		"reset leaves default contract",
		#Runtime.inspect().registeredContracts == 1,
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
