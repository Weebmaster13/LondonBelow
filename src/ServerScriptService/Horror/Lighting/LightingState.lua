--!strict

local Config = require(script.Parent.LightingDirectorConfig)
local Types = require(script.Parent.LightingDirectorTypes)

local LightingState = {}

type LightingDecision = Types.LightingDecision
type LightingPressureState = Types.LightingPressureState

local pressureState: LightingPressureState = "Calm"
local pressureScore = 0
local recentDecisions: { LightingDecision } = {}
local recentSuppressions: { any } = {}
local cooldowns: { [string]: number } = {}
local counters = {
	observations = 0,
	requests = 0,
	approved = 0,
	rejected = 0,
	deferred = 0,
	policySuppressions = 0,
	safeRoomSuppressions = 0,
	puzzleSuppressions = 0,
	cooldownsCreated = 0,
}

local function remember<T>(bucket: { T }, value: T, limit: number)
	table.insert(bucket, value)

	while #bucket > limit do
		table.remove(bucket, 1)
	end
end

function LightingState.setPressure(score: number): LightingPressureState
	pressureScore = math.clamp(score, -1, 1)

	local thresholds = Config.PressureThresholds
	local nextState: LightingPressureState = "Calm"

	if pressureScore <= thresholds.Release then
		nextState = "Release"
	elseif pressureScore >= thresholds.Oppressive then
		nextState = "Oppressive"
	elseif pressureScore >= thresholds.Uneasy then
		nextState = "Uneasy"
	elseif pressureScore >= thresholds.Watchful then
		nextState = "Watchful"
	end

	pressureState = nextState
	return pressureState
end

function LightingState.adjustPressure(delta: number): LightingPressureState
	return LightingState.setPressure(pressureScore + delta)
end

function LightingState.getPressureState(): LightingPressureState
	return pressureState
end

function LightingState.getPressureScore(): number
	return pressureScore
end

function LightingState.isCoolingDown(definitionId: string, now: number): boolean
	local expiresAt = cooldowns[definitionId]
	return expiresAt ~= nil and expiresAt > now
end

function LightingState.setCooldown(definitionId: string, seconds: number, now: number)
	local boundedSeconds = math.clamp(seconds, Config.MinCooldownSeconds, Config.MaxCooldownSeconds)
	cooldowns[definitionId] = now + boundedSeconds
	counters.cooldownsCreated += 1

	local count = 0
	for _ in pairs(cooldowns) do
		count += 1
	end

	if count <= Config.CooldownLimit then
		return
	end

	local oldestId: string? = nil
	local oldestExpires = math.huge

	for id, expiresAt in pairs(cooldowns) do
		if expiresAt < oldestExpires then
			oldestId = id
			oldestExpires = expiresAt
		end
	end

	if oldestId ~= nil then
		cooldowns[oldestId] = nil
	end
end

function LightingState.pruneCooldowns(now: number)
	for id, expiresAt in pairs(cooldowns) do
		if expiresAt <= now then
			cooldowns[id] = nil
		end
	end
end

function LightingState.recordDecision(decision: LightingDecision)
	remember(recentDecisions, decision, Config.RecentDecisionLimit)
	counters.requests += 1

	if decision.status == "Approved" then
		counters.approved += 1
	elseif decision.status == "Rejected" then
		counters.rejected += 1
	else
		counters.deferred += 1
	end
end

function LightingState.recordSuppression(kind: string, reason: string, zoneId: string)
	remember(recentSuppressions, {
		at = os.clock(),
		kind = kind,
		reason = reason,
		zoneId = zoneId,
	}, Config.RecentSuppressionLimit)

	if kind == "Policy" then
		counters.policySuppressions += 1
	elseif kind == "SafeRoom" then
		counters.safeRoomSuppressions += 1
	elseif kind == "Puzzle" then
		counters.puzzleSuppressions += 1
	end
end

function LightingState.incrementObservation()
	counters.observations += 1
end

function LightingState.inspect()
	local cooldownCount = 0

	for _ in pairs(cooldowns) do
		cooldownCount += 1
	end

	return {
		pressureState = pressureState,
		pressureScore = pressureScore,
		recentDecisions = table.clone(recentDecisions),
		recentSuppressions = table.clone(recentSuppressions),
		cooldowns = table.clone(cooldowns),
		cooldownCount = cooldownCount,
		counters = table.clone(counters),
		health = {
			healthy = true,
			message = "Lighting Director is approval-only and has no physical execution surface.",
		},
	}
end

function LightingState.reset()
	pressureState = "Calm"
	pressureScore = 0
	table.clear(recentDecisions)
	table.clear(recentSuppressions)
	table.clear(cooldowns)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return LightingState
