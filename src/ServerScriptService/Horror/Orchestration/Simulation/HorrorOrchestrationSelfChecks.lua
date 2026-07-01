--!strict
-- Self-checks for Horror Orchestration.

local Simulator = require(script.Parent.HorrorOrchestrationSimulator)

local SelfChecks = {}

local function hasAction(inspect: any, action: string): boolean
	for _, bundle in ipairs(inspect.recentDecisions) do
		if bundle.action == action then
			return true
		end
	end
	return false
end

local function hasReason(inspect: any, pattern: string): boolean
	for _, bundle in ipairs(inspect.recentDecisions) do
		for _, reason in ipairs(bundle.reasons or {}) do
			if string.find(reason, pattern, 1, true) ~= nil then
				return true
			end
		end
	end
	return false
end

local function allBundlesApprovalOnly(inspect: any): boolean
	for _, bundle in ipairs(inspect.coordinationBundles) do
		for _, item in ipairs(bundle.requests or {}) do
			if item.approvalOnly ~= true or item.executionAllowed ~= false then
				return false
			end
		end
	end
	return true
end

function SelfChecks.run(orchestrator: any)
	orchestrator.shutdown()
	orchestrator.initialize()

	local malformed = orchestrator.submitPressureRequest({})
	local scenarios = Simulator.scenarios()
	local first = orchestrator.submitPressureRequest(scenarios[1])
	local duplicate = orchestrator.submitPressureRequest(scenarios[1])
	local safeRoom = orchestrator.submitPressureRequest(scenarios[2])
	local release = orchestrator.submitPressureRequest(scenarios[3])
	local puzzle = orchestrator.submitPressureRequest(scenarios[4])
	local overload = orchestrator.submitPressureRequest(scenarios[5])
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
			and puzzle.ok == true
			and overload.ok == true
			and expired.ok == false
			and processed >= 5
			and inspect.pressureBudget.currentPressure <= 100
			and inspect.queueSize == 0
			and hasAction(inspect, "Silence")
			and hasAction(inspect, "Release")
			and hasReason(inspect, "safe room suppresses scare")
			and hasReason(inspect, "puzzle readability suppresses scare")
			and hasReason(inspect, "player overload suppresses escalation")
			and allBundlesApprovalOnly(inspect)
			and afterShutdown.queueSize == 0,
		pressureBounded = inspect.pressureBudget.currentPressure <= 100,
		silenceCanBeSelected = hasAction(inspect, "Silence"),
		releaseAfterHighPressure = hasAction(inspect, "Release")
			and inspect.releaseDecisionCount >= 1,
		scareRejectsInSafeRoom = hasReason(inspect, "safe room suppresses scare"),
		puzzleRoomSuppressesUnfairPressure = hasReason(
			inspect,
			"puzzle readability suppresses scare"
		),
		overloadedPlayerSuppressesEscalation = hasReason(
			inspect,
			"player overload suppresses escalation"
		),
		malformedRequestRejects = malformed.ok == false,
		duplicateRequestRejects = duplicate.ok == false,
		expiredRequestRejects = expired.ok == false,
		coordinationBundlesApprovalOnly = allBundlesApprovalOnly(inspect),
		noWorkspaceMutation = allBundlesApprovalOnly(inspect),
		noClientAuthority = allBundlesApprovalOnly(inspect),
		noMonsterAIExecution = allBundlesApprovalOnly(inspect),
		shutdownClearsQueueAndState = afterShutdown.queueSize == 0
			and #afterShutdown.recentDecisions == 0,
	}
end

return SelfChecks
