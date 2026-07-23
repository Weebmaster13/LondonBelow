--!strict

local Runtime = require(script.Parent.RuntimeRobloxRenderingSession)
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
			phase = 182,
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

	local low = Runtime.createSession({
		robloxRenderingSessionId = "roblox.rendering.session.phase182.low",
		renderingExecutionSessionId = "rendering.execution.phase180.low",
		renderingSessionId = "rendering.session.phase179.low",
		rendererId = "roblox.renderer.phase181.low",
		owner = "Presentation",
		runtimePriority = 1,
	})
	expect("low session created", low.ok)
	local high = Runtime.createSession({
		robloxRenderingSessionId = "roblox.rendering.session.phase182.high",
		renderingExecutionSessionId = "rendering.execution.phase180.high",
		renderingSessionId = "rendering.session.phase179.high",
		rendererId = "roblox.renderer.phase181.high",
		owner = "Presentation",
		runtimePriority = 10,
	})
	expect("high session created", high.ok)
	local duplicate = Runtime.createSession({
		robloxRenderingSessionId = "roblox.rendering.session.phase182.high",
		renderingExecutionSessionId = "rendering.execution.phase180.duplicate",
		renderingSessionId = "rendering.session.phase179.duplicate",
		rendererId = "roblox.renderer.phase181.duplicate",
		owner = "Presentation",
	})
	expect("duplicate session rejected", not duplicate.ok)
	expect("low mapped", Runtime.mapExecutionSession("roblox.rendering.session.phase182.low").ok)
	expect("high mapped", Runtime.mapExecutionSession("roblox.rendering.session.phase182.high").ok)
	local duplicateMappingSession = Runtime.createSession({
		robloxRenderingSessionId = "roblox.rendering.session.phase182.duplicateMapping",
		renderingExecutionSessionId = "rendering.execution.phase180.high",
		renderingSessionId = "rendering.session.phase179.other",
		rendererId = "roblox.renderer.phase181.other",
		owner = "Presentation",
	})
	expect("duplicate mapping session created", duplicateMappingSession.ok)
	local duplicateMapping =
		Runtime.mapExecutionSession("roblox.rendering.session.phase182.duplicateMapping")
	expect("duplicate mapping rejected", not duplicateMapping.ok)
	expect("low reserved", Runtime.reserveRenderer("roblox.rendering.session.phase182.low").ok)
	expect("high reserved", Runtime.reserveRenderer("roblox.rendering.session.phase182.high").ok)
	local conflictSession = Runtime.createSession({
		robloxRenderingSessionId = "roblox.rendering.session.phase182.conflict",
		renderingExecutionSessionId = "rendering.execution.phase180.conflict",
		renderingSessionId = "rendering.session.phase179.conflict",
		rendererId = "roblox.renderer.phase181.high",
		owner = "Presentation",
	})
	expect("conflict session created", conflictSession.ok)
	expect(
		"conflict session mapped",
		Runtime.mapExecutionSession("roblox.rendering.session.phase182.conflict").ok
	)
	local conflictReservation =
		Runtime.reserveRenderer("roblox.rendering.session.phase182.conflict")
	expect("reservation conflict rejected", not conflictReservation.ok)
	expect("low queued", Runtime.queueSession("roblox.rendering.session.phase182.low").ok)
	expect("high queued", Runtime.queueSession("roblox.rendering.session.phase182.high").ok)
	local scheduled = Runtime.scheduleNext()
	expect(
		"scheduling chooses high priority",
		scheduled.ok
			and scheduled.robloxRenderingSessionId == "roblox.rendering.session.phase182.high"
	)
	expect(
		"high waits execution",
		Runtime.waitForExecution("roblox.rendering.session.phase182.high").ok
	)
	expect("high released", Runtime.releaseReservation("roblox.rendering.session.phase182.high").ok)
	expect("high closed", Runtime.closeSession("roblox.rendering.session.phase182.high").ok)
	local scheduledLow = Runtime.scheduleNext()
	expect(
		"low scheduled second",
		scheduledLow.ok
			and scheduledLow.robloxRenderingSessionId == "roblox.rendering.session.phase182.low"
	)
	expect("low released", Runtime.releaseReservation("roblox.rendering.session.phase182.low").ok)
	expect("low closed", Runtime.closeSession("roblox.rendering.session.phase182.low").ok)
	local illegal = Runtime.closeSession("roblox.rendering.session.phase182.conflict")
	expect("illegal lifecycle rejected", not illegal.ok)

	local diagnostics = Runtime.inspect()
	expect(
		"provider identity",
		diagnostics.providerName == Types.RobloxRenderingSessionProviderName
	)
	expect(
		"capability identity",
		diagnostics.capabilityId == Types.RobloxRenderingSessionCapabilityId
	)
	expect("platform identity", diagnostics.platform == Types.RobloxRenderingPlatform)
	expect(
		"diagnostics immutable posture",
		diagnostics.robloxRenderingSessionPosture.immutableDiagnostics == true
	)
	expect("no rendering posture", diagnostics.robloxRenderingSessionPosture.noRendering == true)
	expect(
		"no GUI creation posture",
		diagnostics.robloxRenderingSessionPosture.noGuiCreation == true
	)
	expect(
		"no client authority posture",
		diagnostics.robloxRenderingSessionPosture.noClientAuthority == true
	)
	diagnostics.sessionRegistry[1].robloxRenderingSessionId = "mutated"
	expect(
		"diagnostics isolated",
		Runtime.inspect().sessionRegistry[1].robloxRenderingSessionId ~= "mutated"
	)
	local snapshot = Runtime.getSnapshot()
	expect(
		"snapshot provider identity",
		snapshot.providerName == Types.RobloxRenderingSessionProviderName
	)
	snapshot.robloxRenderingSessionSnapshot.sessionRegistry[1].robloxRenderingSessionId = "mutated"
	expect(
		"snapshot isolated",
		Runtime.getSnapshot().robloxRenderingSessionSnapshot.sessionRegistry[1].robloxRenderingSessionId
			~= "mutated"
	)
	expect("evidence recorded", #Runtime.inspect().evidence > 0)
	expect("metrics recorded", Runtime.inspect().metrics.mappedExecutionSessions >= 3)
	expect("profiler recorded", #Runtime.inspect().profiler > 0)
	expect(
		"budgets exposed",
		Runtime.inspect().budgets.MaxSessions == Types.RobloxRenderingSessionLimits.MaxSessions
	)
	expect(
		"governance exposed",
		Runtime.inspect().governance.systemName == "Roblox Rendering Session Runtime"
	)
	expect(
		"certification candidate",
		Runtime.inspect().certification.status == "ProductionCandidate"
	)
	local valid, reason = Runtime.validate()
	expect("validation passed", valid, reason)

	Runtime.reset()
	expect("reset clears sessions", #Runtime.inspect().sessionRegistry == 0)
	Runtime.shutdown()
	local blocked = Runtime.createSession({
		robloxRenderingSessionId = "roblox.rendering.session.phase182.shutdown",
		renderingExecutionSessionId = "rendering.execution.phase180.shutdown",
		renderingSessionId = "rendering.session.phase179.shutdown",
		rendererId = "roblox.renderer.phase181.shutdown",
		owner = "Presentation",
	})
	expect(
		"shutdown blocks session creation",
		not blocked.ok and blocked.code == Types.RobloxRenderingSessionFailureType.RuntimeShutdown
	)
	expect(
		"posture no networking",
		Runtime.inspect().robloxRenderingSessionPosture.noNetworking == true
	)
	expect(
		"posture no Workspace mutation",
		Runtime.inspect().robloxRenderingSessionPosture.noWorkspaceMutation == true
	)
	expect(
		"posture no persistence",
		Runtime.inspect().robloxRenderingSessionPosture.noPersistence == true
	)
	expect(
		"posture no gameplay execution",
		Runtime.inspect().robloxRenderingSessionPosture.noGameplayExecution == true
	)
	expect(
		"posture no dialogue execution",
		Runtime.inspect().robloxRenderingSessionPosture.noDialogueExecution == true
	)
	expect(
		"posture no analytics",
		Runtime.inspect().robloxRenderingSessionPosture.noAnalytics == true
	)
	expect(
		"posture no telemetry",
		Runtime.inspect().robloxRenderingSessionPosture.noTelemetry == true
	)

	return summarize()
end

return SelfChecks
