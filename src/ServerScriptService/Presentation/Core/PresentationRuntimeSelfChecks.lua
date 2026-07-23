--!strict

local Runtime = require(script.Parent.RuntimePresentationCapability)
local Types = require(script.Parent.PresentationTypes)

local SelfChecks = {}

local function check(results: { any }, name: string, ok: boolean, detail: string?)
	results[#results + 1] = {
		name = name,
		ok = ok,
		detail = detail,
	}
end

local function consumer(id: string)
	return {
		consumerId = id,
		runtimeCapability = Types.CapabilityId,
		supportedPresentationKinds = { "DialogueLine", "ChoiceList" },
		contractVersion = "1.0.0",
		status = Types.RuntimeConsumerStatus.Available,
	}
end

local function session(id: string, priority: number?)
	return {
		presentationSessionId = id,
		presentationId = id .. ".presentation",
		executionId = "execution.phase176",
		consumerId = "consumer.phase176",
		descriptorReference = id .. ".descriptor",
		synchronizationReference = id .. ".sync",
		priority = priority or 1,
		runtimeMetadata = {
			source = "self-check",
		},
	}
end

function SelfChecks.run()
	Runtime.reset()
	local results = {}

	check(
		results,
		"capability registered",
		Runtime.inspect().capability.capabilityId == Types.CapabilityId,
		nil
	)

	local registered = Runtime.registerConsumer(consumer("consumer.phase176"))
	check(results, "consumer registered", registered.ok == true, registered.message)
	local duplicateConsumer = Runtime.registerConsumer(consumer("consumer.phase176"))
	check(
		results,
		"duplicate consumer rejected",
		duplicateConsumer.ok == false,
		duplicateConsumer.code == Types.RuntimeFailureType.DuplicateConsumer and nil
			or duplicateConsumer.code
	)

	local created = Runtime.createSession(session("session.phase176.low", 1))
	local high = Runtime.createSession(session("session.phase176.high", 10))
	check(results, "session created", created.ok == true, created.message)
	check(results, "second session created", high.ok == true, high.message)

	local duplicate = Runtime.createSession(session("session.phase176.low", 1))
	check(
		results,
		"duplicate session rejected",
		duplicate.ok == false,
		duplicate.code == Types.RuntimeFailureType.DuplicateSession and nil or duplicate.code
	)

	local unknownConsumer = session("session.phase176.unknown", 1)
	unknownConsumer.consumerId = "consumer.missing"
	local unknownConsumerResult = Runtime.createSession(unknownConsumer)
	check(
		results,
		"unknown consumer rejected",
		unknownConsumerResult.ok == false,
		unknownConsumerResult.code == Types.RuntimeFailureType.UnknownConsumer and nil
			or unknownConsumerResult.code
	)

	local queuedLow = Runtime.enqueueSession("session.phase176.low")
	local queuedHigh = Runtime.enqueueSession("session.phase176.high")
	check(results, "low session queued", queuedLow.ok == true, queuedLow.message)
	check(results, "high session queued", queuedHigh.ok == true, queuedHigh.message)
	check(
		results,
		"queue ordering deterministic",
		Runtime.inspect().queueState.queued[1] == "session.phase176.high",
		nil
	)

	local illegal =
		Runtime.transitionSession("session.phase176.low", Types.RuntimeSessionState.Ready)
	check(
		results,
		"illegal lifecycle transition rejected",
		illegal.ok == false,
		illegal.code == Types.RuntimeFailureType.InvalidLifecycleTransition and nil or illegal.code
	)

	local assigned = Runtime.assignSession("session.phase176.high")
	local preparing =
		Runtime.transitionSession("session.phase176.high", Types.RuntimeSessionState.Preparing)
	local ready =
		Runtime.transitionSession("session.phase176.high", Types.RuntimeSessionState.Ready)
	check(results, "session assigned", assigned.ok == true, assigned.message)
	check(results, "session preparing", preparing.ok == true, preparing.message)
	check(results, "session ready", ready.ok == true, ready.message)

	local accepted = Runtime.produceAcknowledgement({
		acknowledgementId = "ack.phase176.accepted",
		presentationSessionId = "session.phase176.high",
		acknowledgementKind = Types.RuntimeAcknowledgementKind.Accepted,
	})
	check(results, "acknowledgement produced", accepted.ok == true, accepted.message)
	local duplicateAck = Runtime.produceAcknowledgement({
		acknowledgementId = "ack.phase176.accepted",
		presentationSessionId = "session.phase176.high",
		acknowledgementKind = Types.RuntimeAcknowledgementKind.Completed,
	})
	check(
		results,
		"duplicate acknowledgement rejected",
		duplicateAck.ok == false,
		duplicateAck.code == Types.RuntimeFailureType.DuplicateAcknowledgement and nil
			or duplicateAck.code
	)

	local sync = Runtime.resolveSynchronization("session.phase176.high")
	check(
		results,
		"synchronization satisfied",
		sync.ok == true and sync.synchronization.satisfied == true,
		sync.message
	)

	local completed = Runtime.produceAcknowledgement({
		acknowledgementId = "ack.phase176.completed",
		presentationSessionId = "session.phase176.high",
		acknowledgementKind = Types.RuntimeAcknowledgementKind.Completed,
	})
	check(results, "completion acknowledgement produced", completed.ok == true, completed.message)

	local diagnostics = Runtime.inspect()
	check(
		results,
		"provider name lowerCamelCase",
		diagnostics.providerName == Types.ProviderName,
		diagnostics.providerName
	)
	check(results, "runtime posture present", diagnostics.presentationRuntimePosture ~= nil, nil)
	check(
		results,
		"diagnostics report no GUI",
		diagnostics.presentationRuntimePosture.noGui == true,
		nil
	)
	check(
		results,
		"diagnostics report no networking",
		diagnostics.presentationRuntimePosture.noNetworking == true,
		nil
	)
	check(
		results,
		"diagnostics report no client authority",
		diagnostics.presentationRuntimePosture.noClientAuthority == true,
		nil
	)
	check(results, "evidence recorded", diagnostics.evidence.evidenceCount > 0, nil)
	check(results, "metrics recorded", diagnostics.metrics.sessionsCreated >= 2, nil)
	check(results, "profiler recorded", #diagnostics.profiler > 0, nil)
	check(
		results,
		"governance posture present",
		diagnostics.governance.systemName == "Presentation Runtime Capability Foundation",
		nil
	)
	check(
		results,
		"certification remains candidate",
		diagnostics.certification.productionCertified == false,
		nil
	)

	local snapshot = Runtime.getSnapshot()
	snapshot.presentationRuntimeSnapshot.activeSessions = {}
	check(
		results,
		"snapshot isolation",
		#Runtime.getSnapshot().presentationRuntimeSnapshot.activeSessions > 0,
		nil
	)

	local ok, reason = Runtime.validate()
	check(results, "runtime validation passes", ok == true, reason)

	Runtime.shutdown()
	local blocked = Runtime.createSession(session("session.phase176.shutdown", 1))
	check(
		results,
		"shutdown blocks session creation",
		blocked.ok == false,
		blocked.code == Types.RuntimeFailureType.RuntimeShutdown and nil or blocked.code
	)

	Runtime.reset()
	check(results, "reset clears sessions", #Runtime.inspect().activeSessions == 0, nil)
	check(
		results,
		"reset keeps capability",
		Runtime.inspect().capability.capabilityId == Types.CapabilityId,
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
