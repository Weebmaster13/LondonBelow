--!strict

local Runtime = require(script.Parent.RuntimePresentationRenderingCapability)
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
			phase = 179,
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

	local duplicateRuntime = Runtime.registerDefaultRuntime()
	expect(
		"duplicate runtime rejected",
		not duplicateRuntime.ok
			and duplicateRuntime.code == Types.RenderingRuntimeFailureType.DuplicateRuntime
	)

	local rendererA = Runtime.registerRenderer({
		rendererId = "renderer.runtime.phase179.a",
		providerName = "phase179RendererA",
		version = "1.0.0",
		supportedRenderingKinds = { Types.RenderingKind.DialogueLine },
		supportedDescriptorVersions = { "1.0.0" },
		supportedContractVersions = { "1.0.0" },
		capacity = 2,
		priority = 10,
		status = Types.RenderingRuntimeRendererStatus.Available,
	})
	expect("renderer A registered", rendererA.ok)
	local rendererB = Runtime.registerRenderer({
		rendererId = "renderer.runtime.phase179.b",
		providerName = "phase179RendererB",
		version = "1.0.0",
		supportedRenderingKinds = { Types.RenderingKind.DialogueLine },
		capacity = 1,
		priority = 5,
		status = Types.RenderingRuntimeRendererStatus.Available,
	})
	expect("renderer B registered", rendererB.ok)
	local duplicateRenderer = Runtime.registerRenderer({
		rendererId = "renderer.runtime.phase179.a",
		providerName = "phase179RendererDuplicate",
		version = "1.0.0",
		supportedRenderingKinds = { Types.RenderingKind.DialogueLine },
		status = Types.RenderingRuntimeRendererStatus.Available,
	})
	expect("duplicate renderer rejected", not duplicateRenderer.ok)
	local invalidRenderer = Runtime.registerRenderer({
		rendererId = "renderer.runtime.phase179.invalid",
		providerName = "phase179RendererInvalid",
		version = "1.0.0",
		supportedRenderingKinds = { "BadKind" },
		status = Types.RenderingRuntimeRendererStatus.Available,
	})
	expect("invalid renderer rejected", not invalidRenderer.ok)

	local session = Runtime.intakeRenderingRequest({
		renderingSessionId = "rendering.session.phase179.primary",
		renderingRequestId = "rendering.request.phase178.primary",
		executionSessionId = "execution.phase177.primary",
		presentationSessionId = "presentation.session.phase176.primary",
		renderingKind = Types.RenderingKind.DialogueLine,
		descriptorVersion = "1.0.0",
		contractVersion = "1.0.0",
		synchronizationPolicy = Types.RenderingSynchronizationPolicy.WaitForCompleted,
		runtimePriority = 10,
	})
	expect("request intake creates session", session.ok)
	local duplicateSession = Runtime.intakeRenderingRequest({
		renderingSessionId = "rendering.session.phase179.primary",
		renderingRequestId = "rendering.request.phase178.duplicate",
		executionSessionId = "execution.phase177.duplicate",
		presentationSessionId = "presentation.session.phase176.duplicate",
		renderingKind = Types.RenderingKind.DialogueLine,
	})
	expect("duplicate session rejected", not duplicateSession.ok)
	local invalidRequest = Runtime.intakeRenderingRequest({
		renderingSessionId = "rendering.session.phase179.invalid",
		renderingRequestId = "rendering.request.phase178.invalid",
		executionSessionId = "execution.phase177.invalid",
		presentationSessionId = "presentation.session.phase176.invalid",
		renderingKind = "BadKind",
	})
	expect("invalid request rejected", not invalidRequest.ok)

	local assignment = Runtime.assignRenderer("rendering.session.phase179.primary")
	expect(
		"renderer assigned",
		assignment.ok and assignment.assignment.rendererId == "renderer.runtime.phase179.a"
	)
	expect(
		"assignment deterministic priority",
		assignment.assignment.rendererId == "renderer.runtime.phase179.a"
	)
	local assignedState = Runtime.inspect().renderingSessions[1]
	expect(
		"assignment state assigned",
		assignedState.assignmentState == Types.RenderingRuntimeAssignmentState.Assigned
	)

	local illegalTransition = Runtime.transitionLifecycle(
		"rendering.session.phase179.primary",
		Types.RenderingRuntimeLifecycleState.Completed
	)
	expect("illegal lifecycle rejected", not illegalTransition.ok)
	expect(
		"lifecycle assigned",
		Runtime.transitionLifecycle(
			"rendering.session.phase179.primary",
			Types.RenderingRuntimeLifecycleState.Preparing
		).ok
	)
	expect(
		"lifecycle preparing",
		Runtime.transitionLifecycle(
			"rendering.session.phase179.primary",
			Types.RenderingRuntimeLifecycleState.Ready
		).ok
	)
	local ackReady = Runtime.produceAcknowledgement({
		renderingAcknowledgementId = "rendering.runtime.ack.phase179.ready",
		renderingSessionId = "rendering.session.phase179.primary",
		renderingRequestId = "rendering.request.phase178.primary",
		rendererId = "renderer.runtime.phase179.a",
		kind = Types.RenderingRuntimeAcknowledgementKind.Accepted,
	})
	expect("acknowledgement produced", ackReady.ok)
	local duplicateAck = Runtime.produceAcknowledgement({
		renderingAcknowledgementId = "rendering.runtime.ack.phase179.ready",
		renderingSessionId = "rendering.session.phase179.primary",
		renderingRequestId = "rendering.request.phase178.primary",
		rendererId = "renderer.runtime.phase179.a",
		kind = Types.RenderingRuntimeAcknowledgementKind.Accepted,
	})
	expect("duplicate acknowledgement rejected", not duplicateAck.ok)
	local ownerMismatch = Runtime.produceAcknowledgement({
		renderingAcknowledgementId = "rendering.runtime.ack.phase179.badowner",
		renderingSessionId = "rendering.session.phase179.primary",
		renderingRequestId = "rendering.request.phase178.primary",
		rendererId = "renderer.runtime.phase179.b",
		kind = Types.RenderingRuntimeAcknowledgementKind.Accepted,
	})
	expect("acknowledgement ownership mismatch rejected", not ownerMismatch.ok)
	expect(
		"completed lifecycle",
		Runtime.transitionLifecycle(
			"rendering.session.phase179.primary",
			Types.RenderingRuntimeLifecycleState.Completed
		).ok
	)
	local sync = Runtime.resolveSynchronization("rendering.session.phase179.primary")
	expect("synchronization resolved", sync.ok and sync.synchronization.satisfied)

	local diagnostics = Runtime.inspect()
	expect("provider identity", diagnostics.providerName == Types.RenderingRuntimeProviderName)
	expect("runtime identity", diagnostics.runtimeId == Types.RenderingRuntimeId)
	expect(
		"runtime capability identity",
		diagnostics.capabilityId == Types.RenderingRuntimeCapabilityId
	)
	expect(
		"diagnostics immutable",
		diagnostics.renderingRuntimePosture.immutableDiagnostics == true
	)
	diagnostics.renderingSessions[1].renderingSessionId = "mutated"
	expect(
		"diagnostics isolated",
		Runtime.inspect().renderingSessions[1].renderingSessionId
			== "rendering.session.phase179.primary"
	)
	local snapshot = Runtime.getSnapshot()
	expect(
		"snapshot provider identity",
		snapshot.providerName == Types.RenderingRuntimeProviderName
	)
	snapshot.presentationRenderingRuntimeSnapshot.renderingSessions[1].renderingSessionId =
		"mutated"
	expect(
		"snapshot isolated",
		Runtime.getSnapshot().presentationRenderingRuntimeSnapshot.renderingSessions[1].renderingSessionId
			== "rendering.session.phase179.primary"
	)
	expect("evidence recorded", #Runtime.inspect().evidence > 0)
	expect("metrics recorded", Runtime.inspect().metrics.renderingSessions >= 1)
	expect("profiler recorded", #Runtime.inspect().profiler > 0)
	expect(
		"budgets exposed",
		Runtime.inspect().budgets.MaxRenderingSessions
			== Types.RenderingRuntimeLimits.MaxRenderingSessions
	)
	expect(
		"governance exposed",
		Runtime.inspect().governance.systemName
			== "Presentation Rendering Runtime Capability Foundation"
	)
	expect(
		"certification candidate",
		Runtime.inspect().certification.status == "ProductionCandidate"
	)
	local valid, reason = Runtime.validate()
	expect("validation passed", valid, reason)

	Runtime.reset()
	expect(
		"reset preserves runtime registration",
		Runtime.inspect().runtimeCapability.providerName == Types.RenderingRuntimeProviderName
	)
	Runtime.shutdown()
	local blocked = Runtime.registerRenderer({
		rendererId = "renderer.runtime.phase179.shutdown",
		providerName = "shutdown",
		version = "1.0.0",
		supportedRenderingKinds = { Types.RenderingKind.DialogueLine },
		status = Types.RenderingRuntimeRendererStatus.Available,
	})
	expect(
		"shutdown blocks renderer registration",
		not blocked.ok and blocked.code == Types.RenderingRuntimeFailureType.RuntimeShutdown
	)
	expect("posture no GUI", Runtime.inspect().renderingRuntimePosture.noGui == true)
	expect("posture no rendering", Runtime.inspect().renderingRuntimePosture.noRendering == true)
	expect("posture no networking", Runtime.inspect().renderingRuntimePosture.noNetworking == true)
	expect(
		"posture no persistence",
		Runtime.inspect().renderingRuntimePosture.noPersistence == true
	)
	expect(
		"posture no Workspace mutation",
		Runtime.inspect().renderingRuntimePosture.noWorkspaceMutation == true
	)
	expect(
		"posture no gameplay execution",
		Runtime.inspect().renderingRuntimePosture.noGameplayExecution == true
	)
	expect(
		"posture no dialogue execution",
		Runtime.inspect().renderingRuntimePosture.noDialogueExecution == true
	)
	expect(
		"posture no client authority",
		Runtime.inspect().renderingRuntimePosture.noClientAuthority == true
	)
	expect("posture no analytics", Runtime.inspect().renderingRuntimePosture.noAnalytics == true)
	expect("posture no telemetry", Runtime.inspect().renderingRuntimePosture.noTelemetry == true)

	return summarize()
end

return SelfChecks
