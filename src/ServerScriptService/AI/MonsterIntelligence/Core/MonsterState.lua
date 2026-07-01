--!strict
--[[
	Runtime state for Monster Intelligence.

	Stores abstract state and decision records only. It never stores Roblox
	Instances, paths, humanoids, animations, sounds, or physical targets.
]]

local Config = require(script.Parent.MonsterConfig)
local Validator = require(script.Parent.MonsterValidator)

local MonsterState = {}

local states: { [string]: string } = {}
local interests: { [string]: { any } } = {}
local decisions: { any } = {}
local counters = {
	registered = 0,
	stateTransitions = 0,
	intents = 0,
	rejected = 0,
	validationFailures = 0,
}

local function now(): number
	return os.clock()
end

local function trim(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

function MonsterState.registerMonster(monsterId: string)
	states[monsterId] = "Dormant"
	interests[monsterId] = interests[monsterId] or {}
	counters.registered += 1
end

function MonsterState.getState(monsterId: string): string
	return states[monsterId] or "Dormant"
end

function MonsterState.transition(monsterId: string, nextState: string): (boolean, string?)
	local currentState = MonsterState.getState(monsterId)
	local ok, reason = Validator.validateStateTransition(currentState, nextState)
	if not ok then
		counters.validationFailures += 1
		return false, reason
	end
	states[monsterId] = nextState
	counters.stateTransitions += 1
	return true, nil
end

function MonsterState.addInterest(signal: any): (boolean, string?)
	local ok, reason = Validator.validateInterest(signal)
	if not ok then
		counters.validationFailures += 1
		return false, reason
	end
	local list = interests[signal.monsterId]
	if list == nil then
		list = {}
		interests[signal.monsterId] = list
	end
	table.insert(list, {
		id = signal.id,
		source = signal.source,
		subjectId = signal.subjectId,
		zoneId = signal.zoneId,
		score = math.clamp(signal.score, 0, 100),
		confidence = math.clamp(signal.confidence, 0, 1),
		createdAt = signal.createdAt or now(),
		reason = signal.reason,
		metadata = if type(signal.metadata) == "table" then table.clone(signal.metadata) else {},
	})
	trim(list, Config.MaxInterestEntries)
	return true, nil
end

function MonsterState.decayInterest(monsterId: string, deltaSeconds: number)
	local list = interests[monsterId]
	if list == nil then
		return
	end
	for index = #list, 1, -1 do
		local signal = list[index]
		signal.score =
			math.max(0, signal.score - (Config.InterestDecayPerSecond * deltaSeconds * 100))
		if signal.score <= 0.01 then
			table.remove(list, index)
		end
	end
end

function MonsterState.getInterest(monsterId: string): { any }
	local result = {}
	for _, signal in ipairs(interests[monsterId] or {}) do
		table.insert(result, table.clone(signal))
	end
	return result
end

function MonsterState.recordDecision(intent: any)
	counters.intents += 1
	table.insert(decisions, {
		intentId = intent.intentId,
		monsterId = intent.monsterId,
		kind = intent.kind,
		confidence = intent.confidence,
		priority = intent.priority,
		reasons = table.clone(intent.reasons or {}),
		createdAt = intent.createdAt or now(),
	})
	trim(decisions, Config.MaxDecisionHistory)
end

function MonsterState.increment(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
	end
end

function MonsterState.clear()
	table.clear(states)
	table.clear(interests)
	table.clear(decisions)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

function MonsterState.inspect()
	local stateCounts: { [string]: number } = {}
	for _, state in pairs(states) do
		stateCounts[state] = (stateCounts[state] or 0) + 1
	end
	local interestCount = 0
	for _, list in pairs(interests) do
		interestCount += #list
	end
	return {
		states = table.clone(states),
		stateCounts = stateCounts,
		interestCount = interestCount,
		interestLimit = Config.MaxInterestEntries,
		recentDecisions = table.clone(decisions),
		decisionLimit = Config.MaxDecisionHistory,
		counters = table.clone(counters),
	}
end

return MonsterState
