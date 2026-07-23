--!strict

local Runtime = require(script.Parent.RuntimePresentationExecution)
local Types = require(script.Parent.PresentationTypes)

local SelfChecks = {}

local function check(results: { any }, name: string, ok: boolean, detail: string?)
	results[#results + 1] = { name = name, ok = ok, detail = detail }
end

local function request(id: string, priority: number?)
	return {
		executionSessionId = id,
		presentationSessionId = id .. ".session",
		consumerId = "consumer.phase177",
		queueOrdinal = if priority == 10 then 1 else 2,
		runtimePriority = priority or 1,
		runtimeMetadata = { source = "self-check" },
	}
end

function SelfChecks.run()
	Runtime.reset()
	local results = {}

	local low = Runtime.createExecution(request("execution.phase177.low", 1))
	local high = Runtime.createExecution(request("execution.phase177.high", 10))
	check(results, "execution created", low.ok == true, low.message)
	check(results, "high execution created", high.ok == true, high.message)
	local duplicate = Runtime.createExecution(request("execution.phase177.low", 1))
	check(
		results,
		"duplicate execution rejected",
		duplicate.ok == false,
		duplicate.code == Types.ExecutionFailureType.DuplicateExecution and nil or duplicate.code
	)

	local queuedLow = Runtime.enqueueExecution("execution.phase177.low")
	local queuedHigh = Runtime.enqueueExecution("execution.phase177.high")
	check(results, "low execution queued", queuedLow.ok == true, queuedLow.message)
	check(results, "high execution queued", queuedHigh.ok == true, queuedHigh.message)
	check(
		results,
		"queue ordering deterministic",
		Runtime.inspect().executionQueue.waiting[1] == "execution.phase177.high",
		nil
	)

	local scheduled = Runtime.scheduleNext()
	check(
		results,
		"scheduler assigns highest priority",
		scheduled.ok == true and scheduled.executionId == "execution.phase177.high",
		scheduled.message
	)
	local started = Runtime.execute("execution.phase177.high")
	check(results, "execution starts", started.ok == true, started.message)
	local suspended = Runtime.suspend("execution.phase177.high")
	check(results, "execution suspends", suspended.ok == true, suspended.message)
	local resumed = Runtime.resume("execution.phase177.high")
	check(results, "execution resumes", resumed.ok == true, resumed.message)

	local accepted = Runtime.produceAcknowledgement({
		acknowledgementId = "ack.phase177.accepted",
		executionSessionId = "execution.phase177.high",
		acknowledgementKind = "Accepted",
	})
	check(results, "acknowledgement produced", accepted.ok == true, accepted.message)
	local duplicateAck = Runtime.produceAcknowledgement({
		acknowledgementId = "ack.phase177.accepted",
		executionSessionId = "execution.phase177.high",
		acknowledgementKind = "Completed",
	})
	check(
		results,
		"duplicate acknowledgement rejected",
		duplicateAck.ok == false,
		duplicateAck.code == Types.ExecutionFailureType.DuplicateAcknowledgement and nil
			or duplicateAck.code
	)

	local completedAck = Runtime.produceAcknowledgement({
		acknowledgementId = "ack.phase177.completed",
		executionSessionId = "execution.phase177.high",
		acknowledgementKind = "Completed",
	})
	local sync = Runtime.resolveSynchronization("execution.phase177.high")
	check(
		results,
		"completion acknowledgement produced",
		completedAck.ok == true,
		completedAck.message
	)
	check(
		results,
		"synchronization satisfied",
		sync.ok == true and sync.synchronization.satisfied == true,
		sync.message
	)
	local completed = Runtime.complete("execution.phase177.high")
	check(results, "execution completes", completed.ok == true, completed.message)

	local scheduledLow = Runtime.scheduleNext()
	local cancelled = Runtime.cancel("execution.phase177.low", "self-check cancel")
	check(results, "second execution scheduled", scheduledLow.ok == true, scheduledLow.message)
	check(results, "execution cancels", cancelled.ok == true, cancelled.message)

	local expiring = Runtime.createExecution(request("execution.phase177.expiring", 5))
	local queuedExpiring = Runtime.enqueueExecution("execution.phase177.expiring")
	local expired = Runtime.expire("execution.phase177.expiring", "self-check timeout")
	check(results, "expiring execution created", expiring.ok == true, expiring.message)
	check(results, "expiring execution queued", queuedExpiring.ok == true, queuedExpiring.message)
	check(results, "execution expires", expired.ok == true, expired.message)

	local illegal = Runtime.complete("execution.phase177.expiring")
	check(
		results,
		"illegal terminal transition rejected",
		illegal.ok == false,
		illegal.code == Types.ExecutionFailureType.InvalidLifecycleTransition and nil
			or illegal.code
	)

	local diagnostics = Runtime.inspect()
	check(
		results,
		"provider lowerCamelCase",
		diagnostics.providerName == Types.ExecutionProviderName,
		diagnostics.providerName
	)
	check(results, "posture present", diagnostics.presentationExecutionPosture ~= nil, nil)
	check(
		results,
		"no rendering posture",
		diagnostics.presentationExecutionPosture.noRendering == true,
		nil
	)
	check(
		results,
		"no networking posture",
		diagnostics.presentationExecutionPosture.noNetworking == true,
		nil
	)
	check(
		results,
		"no client authority posture",
		diagnostics.presentationExecutionPosture.noClientAuthority == true,
		nil
	)
	check(results, "evidence recorded", #diagnostics.evidence > 0, nil)
	check(results, "metrics recorded", diagnostics.metrics.executionsStarted >= 1, nil)
	check(results, "profiler recorded", #diagnostics.profiler > 0, nil)
	check(
		results,
		"governance present",
		diagnostics.governance.systemName == "Presentation Runtime Execution and Session Management",
		nil
	)
	check(
		results,
		"certification candidate",
		diagnostics.certification.productionCertified == false,
		nil
	)

	local snapshot = Runtime.getSnapshot()
	snapshot.presentationRuntimeExecutionSnapshot.executingSessions = {}
	check(
		results,
		"snapshot isolation",
		#Runtime.getSnapshot().presentationRuntimeExecutionSnapshot.executingSessions > 0,
		nil
	)

	local ok, reason = Runtime.validate()
	check(results, "runtime validation passes", ok == true, reason)
	local recovered = Runtime.recover()
	check(results, "recovery metadata succeeds", recovered.ok == true, recovered.message)

	Runtime.shutdown()
	local blocked = Runtime.createExecution(request("execution.phase177.shutdown", 1))
	check(
		results,
		"shutdown blocks execution creation",
		blocked.ok == false,
		blocked.code == Types.ExecutionFailureType.RuntimeShutdown and nil or blocked.code
	)

	Runtime.reset()
	check(results, "reset clears executions", #Runtime.inspect().executingSessions == 0, nil)

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
