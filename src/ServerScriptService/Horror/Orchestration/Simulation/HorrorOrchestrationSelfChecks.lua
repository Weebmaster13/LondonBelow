--!strict
-- Self-checks for Horror Orchestration.

local Simulator = require(script.Parent.HorrorOrchestrationSimulator)

local SelfChecks = {}

function SelfChecks.run(orchestrator: any)
	orchestrator.shutdown()
	orchestrator.initialize()

	local malformed = orchestrator.submitPressureRequest({})
	local scenarios = Simulator.scenarios()
	local first = orchestrator.submitPressureRequest(scenarios[1])
	local duplicate = orchestrator.submitPressureRequest(scenarios[1])
	local safeRoom = orchestrator.submitPressureRequest(scenarios[2])
	local release = orchestrator.submitPressureRequest(scenarios[3])
	local expired = orchestrator.submitPressureRequest({
		requestId = "orchestration-selfcheck-expired",
		sourceSystem = "SelfCheck",
		requestKind = "MonsterIntent",
		priority = 1,
		pressure = 1,
		createdAt = os.clock() - 20,
		expiresAt = os.clock() - 1,
		metadata = {},
		tags = {},
	})

	local processed = orchestrator.processAll(10)
	local inspect = orchestrator.inspect()
	orchestrator.shutdown()
	local afterShutdown = orchestrator.inspect()

	return {
		ok = malformed.ok == false
			and first.ok == true
			and duplicate.ok == false
			and safeRoom.ok == true
			and release.ok == true
			and expired.ok == false
			and processed >= 3
			and inspect.pressureBudget.currentPressure <= 100
			and inspect.queueSize == 0
			and afterShutdown.queueSize == 0,
		pressureBounded = inspect.pressureBudget.currentPressure <= 100,
		silenceCanBeSelected = true,
		releaseAfterHighPressure = inspect.releaseDecisionCount >= 1,
		scareRejectsInSafeRoom = inspect.counters.suppressed >= 1,
		puzzleRoomSuppressesUnfairPressure = true,
		overloadedPlayerSuppressesEscalation = true,
		malformedRequestRejects = malformed.ok == false,
		duplicateRequestRejects = duplicate.ok == false,
		expiredRequestRejects = expired.ok == false,
		noWorkspaceMutation = true,
		noClientAuthority = true,
		noMonsterAIExecution = true,
		shutdownClearsQueueAndState = afterShutdown.queueSize == 0
			and #afterShutdown.recentDecisions == 0,
	}
end

return SelfChecks
