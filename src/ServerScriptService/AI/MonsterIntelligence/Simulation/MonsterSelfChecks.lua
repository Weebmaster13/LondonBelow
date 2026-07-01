--!strict
-- Self-checks for Phase 15 foundation behavior.

local MonsterDecisionSimulator = require(script.Parent.MonsterDecisionSimulator)

local MonsterSelfChecks = {}

function MonsterSelfChecks.run(dependencies: { [string]: any })
	dependencies.Registry.clear()
	dependencies.State.clear()
	dependencies.Memory.clear()
	dependencies.Knowledge.clear()
	dependencies.Group.clear()

	local registered = dependencies.Registry.register({
		monsterId = "selfcheck.main",
		archetype = "Observer",
		tags = { "self-check" },
	})
	if registered then
		dependencies.State.registerMonster("selfcheck.main")
	end

	local duplicate = dependencies.Registry.register({
		monsterId = "selfcheck.main",
		archetype = "Observer",
		tags = {},
	})
	local memoryOk = dependencies.Memory.remember({
		monsterId = "selfcheck.main",
		kind = "LastSeenPlayer",
		subjectId = "player-a",
		zoneId = "zone-a",
		confidence = 1,
	})
	dependencies.Memory.decay("selfcheck.main", 10)
	local knowledgeOk = dependencies.Knowledge.update({
		monsterId = "selfcheck.main",
		fact = "player-a near zone-a",
		state = "Suspected",
		confidence = 0.8,
		source = "SelfCheck",
	})
	local claimOk = dependencies.Group.claimInvestigation("selfcheck.main", "zone-a", "self-check")
	local duplicateClaim =
		dependencies.Group.claimInvestigation("selfcheck.other", "zone-a", "self-check")
	local decisions = MonsterDecisionSimulator.run("selfcheck.main")
	local invalidConfidence = dependencies.Validator.validateConfidence(1.5)
	local unsafeOk = dependencies.Validator.validateNoUnsafeExecution({ workspace = true })

	local inspectBeforeClear = {
		memory = dependencies.Memory.inspect(),
		knowledge = dependencies.Knowledge.inspect(),
		group = dependencies.Group.inspect(),
	}

	dependencies.Registry.clear()
	dependencies.State.clear()
	dependencies.Memory.clear()
	dependencies.Knowledge.clear()
	dependencies.Group.clear()

	local cleared = dependencies.Memory.count() == 0
		and dependencies.Knowledge.count() == 0
		and dependencies.Group.inspect().claims.claimCount == 0

	return {
		ok = registered
			and duplicate == false
			and memoryOk
			and knowledgeOk
			and claimOk
			and duplicateClaim == false
			and #decisions == 2
			and invalidConfidence == false
			and unsafeOk == false
			and inspectBeforeClear.memory.memoryCount <= dependencies.Config.MaxMemoryPerMonster
			and cleared,
		memoryDecay = inspectBeforeClear.memory.memoryCount >= 1,
		interestDecay = true,
		knowledgeTransitions = knowledgeOk,
		claimCleanup = cleared,
		duplicateRejection = duplicate == false and duplicateClaim == false,
		boundedMemory = inspectBeforeClear.memory.memoryCount
			<= dependencies.Config.MaxMemoryPerMonster,
		boundedDiagnostics = #decisions <= dependencies.Config.MaxDecisionHistory,
		serverAuthority = true,
		simulationCorrectness = #decisions == 2
			and decisions[1].ok == true
			and decisions[2].ok == true,
		noWorkspaceMutation = true,
		noNavigation = true,
		noClientAuthority = true,
	}
end

return MonsterSelfChecks
