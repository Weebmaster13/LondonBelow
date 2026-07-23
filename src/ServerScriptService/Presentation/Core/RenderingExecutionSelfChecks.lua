--!strict

local Runtime = require(script.Parent.RuntimePresentationRenderingExecution)
local Types = require(script.Parent.PresentationTypes)

local SelfChecks = {}

local function suite()
	local checks = {}
	local function expect(name: string, condition: boolean, detail: string?)
		checks[#checks + 1] = { name = name, ok = condition == true, detail = detail }
	end
	local function summarize()
		local failures = {}
		for _, check in ipairs(checks) do
			if not check.ok then
				failures[#failures + 1] = check
			end
		end
		return {
			phase = 180,
			ok = #failures == 0,
			total = #checks,
			passed = #checks - #failures,
			failed = #failures,
			failures = failures,
		}
	end
	return expect, summarize
end

function SelfChecks.run()
	Runtime.reset()
	local expect, summarize = suite()

	local low = Runtime.createExecutionSession({
		renderingExecutionSessionId = "rendering.execution.phase180.low",
		renderingSessionId = "rendering.session.phase179.low",
		renderingRequestId = "rendering.request.phase178.low",
		rendererId = "renderer.phase179.low",
		runtimePriority = 1,
		assignmentPriority = 1,
	})
	expect("low execution session created", low.ok)
	local high = Runtime.createExecutionSession({
		renderingExecutionSessionId = "rendering.execution.phase180.high",
		renderingSessionId = "rendering.session.phase179.high",
		renderingRequestId = "rendering.request.phase178.high",
		rendererId = "renderer.phase179.high",
		runtimePriority = 10,
		assignmentPriority = 10,
	})
	expect("high execution session created", high.ok)
	local duplicate = Runtime.createExecutionSession({
		renderingExecutionSessionId = "rendering.execution.phase180.high",
		renderingSessionId = "rendering.session.phase179.duplicate",
		renderingRequestId = "rendering.request.phase178.duplicate",
		rendererId = "renderer.phase179.duplicate",
	})
	expect("duplicate execution session rejected", not duplicate.ok)
	expect("low queued", Runtime.enqueueExecution("rendering.execution.phase180.low").ok)
	expect("high queued", Runtime.enqueueExecution("rendering.execution.phase180.high").ok)
	local scheduled = Runtime.scheduleNext()
	expect(
		"scheduler chooses high priority",
		scheduled.ok
			and scheduled.renderingExecutionSessionId == "rendering.execution.phase180.high"
	)
	expect("execute scheduled high", Runtime.execute("rendering.execution.phase180.high").ok)
	local illegal = Runtime.complete("rendering.execution.phase180.low")
	expect("illegal lifecycle rejected", not illegal.ok)
	expect(
		"acknowledgement accepted",
		Runtime.receiveAcknowledgement({
			acknowledgementId = "rendering.execution.ack.phase180.high",
			renderingExecutionSessionId = "rendering.execution.phase180.high",
			rendererId = "renderer.phase179.high",
			kind = Types.RenderingExecutionAcknowledgementKind.Accepted,
		}).ok
	)
	local duplicateAck = Runtime.receiveAcknowledgement({
		acknowledgementId = "rendering.execution.ack.phase180.high",
		renderingExecutionSessionId = "rendering.execution.phase180.high",
		rendererId = "renderer.phase179.high",
		kind = Types.RenderingExecutionAcknowledgementKind.Accepted,
	})
	expect("duplicate acknowledgement rejected", not duplicateAck.ok)
	local ownerMismatch = Runtime.receiveAcknowledgement({
		acknowledgementId = "rendering.execution.ack.phase180.badowner",
		renderingExecutionSessionId = "rendering.execution.phase180.high",
		rendererId = "renderer.phase179.other",
		kind = Types.RenderingExecutionAcknowledgementKind.Accepted,
	})
	expect("acknowledgement ownership mismatch rejected", not ownerMismatch.ok)
	local unsupportedAck = Runtime.receiveAcknowledgement({
		acknowledgementId = "rendering.execution.ack.phase180.unsupported",
		renderingExecutionSessionId = "rendering.execution.phase180.high",
		rendererId = "renderer.phase179.high",
		kind = "Unsupported",
	})
	expect("unsupported acknowledgement kind rejected", not unsupportedAck.ok)
	expect("complete high", Runtime.complete("rendering.execution.phase180.high").ok)
	local sync = Runtime.resolveSynchronization("rendering.execution.phase180.high")
	expect("synchronization resolved", sync.ok and sync.synchronization.satisfied)
	local scheduledLow = Runtime.scheduleNext()
	expect(
		"low scheduled second",
		scheduledLow.ok
			and scheduledLow.renderingExecutionSessionId == "rendering.execution.phase180.low"
	)
	expect("suspend low scheduled", Runtime.suspend("rendering.execution.phase180.low").ok)
	expect("resume low", Runtime.resume("rendering.execution.phase180.low").ok)
	local scheduledLowAgain = Runtime.scheduleNext()
	expect(
		"low rescheduled",
		scheduledLowAgain.ok
			and scheduledLowAgain.renderingExecutionSessionId
				== "rendering.execution.phase180.low"
	)
	expect("cancel low", Runtime.cancel("rendering.execution.phase180.low", "self-check").ok)
	local expiring = Runtime.createExecutionSession({
		renderingExecutionSessionId = "rendering.execution.phase180.expiring",
		renderingSessionId = "rendering.session.phase179.expiring",
		renderingRequestId = "rendering.request.phase178.expiring",
		rendererId = "renderer.phase179.expiring",
	})
	expect("expiring created", expiring.ok)
	expect("expiring queued", Runtime.enqueueExecution("rendering.execution.phase180.expiring").ok)
	expect(
		"expiring expired",
		Runtime.expire("rendering.execution.phase180.expiring", "timeout").ok
	)
	expect("recovery metadata", Runtime.recover().ok)

	local diagnostics = Runtime.inspect()
	expect("provider identity", diagnostics.providerName == Types.RenderingExecutionProviderName)
	expect("runtime identity", diagnostics.runtimeId == Types.RenderingExecutionRuntimeId)
	expect(
		"diagnostics immutable posture",
		diagnostics.renderingExecutionPosture.immutableDiagnostics == true
	)
	expect("no rendering posture", diagnostics.renderingExecutionPosture.noRendering == true)
	expect(
		"no client authority posture",
		diagnostics.renderingExecutionPosture.noClientAuthority == true
	)
	diagnostics.executionSessions[1].renderingExecutionSessionId = "mutated"
	expect(
		"diagnostics isolated",
		Runtime.inspect().executionSessions[1].renderingExecutionSessionId ~= "mutated"
	)
	local snapshot = Runtime.getSnapshot()
	expect(
		"snapshot provider identity",
		snapshot.providerName == Types.RenderingExecutionProviderName
	)
	snapshot.presentationRenderingExecutionSnapshot.executionSessions[1].renderingExecutionSessionId =
		"mutated"
	expect(
		"snapshot isolated",
		Runtime.getSnapshot().presentationRenderingExecutionSnapshot.executionSessions[1].renderingExecutionSessionId
			~= "mutated"
	)
	expect("evidence recorded", #Runtime.inspect().evidence > 0)
	expect("metrics recorded", Runtime.inspect().metrics.queuedSessions >= 3)
	expect("profiler recorded", #Runtime.inspect().profiler > 0)
	expect(
		"budgets exposed",
		Runtime.inspect().budgets.MaxExecutionSessions
			== Types.RenderingExecutionLimits.MaxExecutionSessions
	)
	expect(
		"governance exposed",
		Runtime.inspect().governance.systemName
			== "Presentation Rendering Runtime Execution and Renderer Session Management"
	)
	expect(
		"certification candidate",
		Runtime.inspect().certification.status == "ProductionCandidate"
	)
	local valid, reason = Runtime.validate()
	expect("validation passed", valid, reason)
	Runtime.reset()
	expect("reset clears execution sessions", #Runtime.inspect().executionSessions == 0)
	Runtime.shutdown()
	local blocked = Runtime.createExecutionSession({
		renderingExecutionSessionId = "rendering.execution.phase180.shutdown",
		renderingSessionId = "rendering.session.phase179.shutdown",
		renderingRequestId = "rendering.request.phase178.shutdown",
		rendererId = "renderer.phase179.shutdown",
	})
	expect(
		"shutdown blocks new sessions",
		not blocked.ok and blocked.code == Types.RenderingExecutionFailureType.RuntimeShutdown
	)
	expect("posture no GUI", Runtime.inspect().renderingExecutionPosture.noGui == true)
	expect(
		"posture no networking",
		Runtime.inspect().renderingExecutionPosture.noNetworking == true
	)
	expect(
		"posture no persistence",
		Runtime.inspect().renderingExecutionPosture.noPersistence == true
	)
	expect(
		"posture no Workspace mutation",
		Runtime.inspect().renderingExecutionPosture.noWorkspaceMutation == true
	)
	expect(
		"posture no gameplay execution",
		Runtime.inspect().renderingExecutionPosture.noGameplayExecution == true
	)
	expect(
		"posture no dialogue execution",
		Runtime.inspect().renderingExecutionPosture.noDialogueExecution == true
	)
	expect("posture no analytics", Runtime.inspect().renderingExecutionPosture.noAnalytics == true)
	expect("posture no telemetry", Runtime.inspect().renderingExecutionPosture.noTelemetry == true)

	return summarize()
end

return SelfChecks
