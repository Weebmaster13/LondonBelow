--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local Runtime = {}
local initialized = false
local currentState = "Unspawned"
local targetUserId: number? = nil
local recentTargets: { [number]: number } = {}
local transitionCount = 0
local fairnessIncidents = {}

local allowed = {
	Unspawned = { Dormant = true, Shutdown = true },
	Dormant = { Foreshadow = true, Patrol = true, Shutdown = true },
	Foreshadow = { Patrol = true, Observe = true, Retreat = true, Shutdown = true },
	Patrol = { Stalk = true, Investigate = true, Ambush = true, Shutdown = true },
	Stalk = { Observe = true, Suspicious = true, Retreat = true, Shutdown = true },
	Observe = { Suspicious = true, Retreat = true, Shutdown = true },
	Investigate = { Suspicious = true, Search = true, Patrol = true, Shutdown = true },
	Suspicious = { Hunt = true, Search = true, Retreat = true, Shutdown = true },
	Hunt = { Search = true, Recover = true, Climax = true, Shutdown = true },
	Search = { Patrol = true, Ambush = true, Retreat = true, Shutdown = true },
	Ambush = { Hunt = true, Retreat = true, Shutdown = true },
	DoorPressure = { Search = true, Retreat = true, Shutdown = true },
	Recover = { Patrol = true, Retreat = true, Shutdown = true },
	Retreat = { Patrol = true, Dormant = true, Shutdown = true },
	Climax = { Hunt = true, Disabled = true, Shutdown = true },
	Disabled = { Shutdown = true },
	Shutdown = {},
}

local function canTransition(fromState: string, toState: string): boolean
	return allowed[fromState] ~= nil and allowed[fromState][toState] == true
end

function Runtime.initialize()
	initialized = true
	currentState = "Dormant"
	targetUserId = nil
	recentTargets = {}
	transitionCount = 0
	fairnessIncidents = {}
end

function Runtime.transition(toState: string, reason: string?): (boolean, string?)
	if not canTransition(currentState, toState) then
		fairnessIncidents[#fairnessIncidents + 1] = {
			kind = "IllegalTransition",
			from = currentState,
			to = toState,
			reason = reason or "unspecified",
		}
		return false, "IllegalTransition"
	end
	currentState = toState
	transitionCount += 1
	return true, nil
end

function Runtime.reactToObjective(objectiveId: string, pressure: number)
	if objectiveId == "ignite_lantern" then
		Runtime.transition("Foreshadow", "lantern_lit")
	elseif objectiveId == "ward_crypt" then
		Runtime.transition("Investigate", "buried_ward")
	elseif objectiveId == "open_archive" then
		Runtime.transition("Suspicious", "archive_opened")
	elseif objectiveId == "take_heart" then
		Runtime.transition("Climax", "heart_taken")
	elseif objectiveId == "escape_gate" then
		Runtime.transition("Disabled", "escaped")
	elseif pressure >= 0.5 then
		Runtime.transition("Patrol", "pressure_rising")
	end
end

function Runtime.selectTarget(candidates: { Player }, noiseByUserId: { [number]: number }): Player?
	local best: Player? = nil
	local bestScore = -1
	for _, player in ipairs(candidates) do
		local cooldown = recentTargets[player.UserId] or -1000
		local score = (noiseByUserId[player.UserId] or 0) * 10 - cooldown
		if score > bestScore then
			best = player
			bestScore = score
		end
	end
	if best then
		targetUserId = best.UserId
		recentTargets[best.UserId] = ProductionConfig.Bailiff.fairness.targetCooldown
	end
	return best
end

function Runtime.inspect()
	return {
		initialized = initialized,
		bailiffId = ProductionConfig.Bailiff.id,
		currentState = currentState,
		targetUserId = targetUserId,
		transitionCount = transitionCount,
		fairnessIncidentCount = #fairnessIncidents,
		fairnessIncidents = table.clone(fairnessIncidents),
	}
end

function Runtime.runSelfChecks()
	local stateCount = #ProductionConfig.Bailiff.states
	local legal, legalReason = Runtime.transition("Shutdown", "self_check")
	local illegal = Runtime.transition("Hunt", "self_check")
	return {
		ok = stateCount == 18 and legal == true and illegal == false,
		stateCount = stateCount,
		legalReason = legalReason,
		currentState = currentState,
	}
end

function Runtime.shutdown()
	currentState = "Shutdown"
	initialized = false
	targetUserId = nil
end

return Runtime
