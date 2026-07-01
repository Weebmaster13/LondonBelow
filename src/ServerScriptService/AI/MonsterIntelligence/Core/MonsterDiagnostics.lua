--!strict
-- Aggregates inspectable Monster Intelligence health.

local MonsterDiagnostics = {}

function MonsterDiagnostics.capture(state: any, dependencies: { [string]: any })
	local registry = dependencies.Registry.inspect()
	local runtimeState = dependencies.State.inspect()
	local memory = dependencies.Memory.inspect()
	local knowledge = dependencies.Knowledge.inspect()
	local group = dependencies.Group.inspect()

	return {
		initialized = state.initialized,
		started = state.started,
		mode = state.mode,
		monsterCount = registry.monsterCount,
		memoryCount = memory.memoryCount,
		knowledgeCount = knowledge.knowledgeCount,
		interestCount = runtimeState.interestCount,
		claimCount = group.claims.claimCount,
		sharedFactCount = group.sharedKnowledge.sharedFactCount,
		validationFailures = runtimeState.counters.validationFailures,
		decisionCount = runtimeState.counters.intents,
		recentDecisions = runtimeState.recentDecisions,
		registry = registry,
		state = runtimeState,
		memory = memory,
		knowledge = knowledge,
		group = group,
		selfChecks = state.lastSelfChecks,
		health = {
			healthy = state.initialized and state.mode == "IntentOnly",
			status = if not state.initialized
				then "NotInitialized"
				elseif state.started then "Running"
				else "Ready",
			message = "Monster Intelligence is intent-only and performs no physical Monster AI execution.",
		},
	}
end

function MonsterDiagnostics.validate(dependencies: { [string]: any }): (boolean, string?)
	local registry = dependencies.Registry.inspect()
	if registry.monsterCount > dependencies.Config.MaxMonsters then
		return false, "monster registry exceeded limit"
	end
	return dependencies.Validator.validate()
end

return MonsterDiagnostics
