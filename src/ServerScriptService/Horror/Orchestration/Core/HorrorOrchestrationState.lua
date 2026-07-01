--!strict
-- Bounded runtime state for pressure, decisions, suppressions, and bundles.

local Config = require(script.Parent.HorrorOrchestrationConfig)

local State = {}

local pressureBudget = {
	currentPressure = 0,
	targetPressure = Config.TargetPressure,
	pressureDebt = 0,
	releaseNeed = 0,
	silenceNeed = 0,
	chaseReadiness = 0,
	sensoryLoad = 0,
	emotionalLoad = 0,
	multiplayerLoad = 0,
}
local recentPressureChanges: { any } = {}
local recentDecisions: { any } = {}
local suppressedDecisions: { any } = {}
local coordinationBundles: { any } = {}
local seenRequests: { [string]: boolean } = {}
local seenRequestOrder: { string } = {}
local counters = {
	submitted = 0,
	rejected = 0,
	expired = 0,
	decisions = 0,
	suppressed = 0,
	delayed = 0,
	releases = 0,
	duplicates = 0,
	validationFailures = 0,
}

local function trim(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

function State.hasRequest(requestId: string): boolean
	return seenRequests[requestId] == true
end

function State.markRequest(requestId: string)
	if seenRequests[requestId] == true then
		return
	end
	seenRequests[requestId] = true
	table.insert(seenRequestOrder, requestId)
	while #seenRequestOrder > Config.MaxSeenRequestIds do
		local removed = table.remove(seenRequestOrder, 1)
		if removed ~= nil then
			seenRequests[removed] = nil
		end
	end
end

function State.updatePressure(delta: number, reason: string)
	local previous = pressureBudget.currentPressure
	local boundedDelta =
		math.clamp(delta, -Config.MaxPressureDeltaPerRequest, Config.MaxPressureDeltaPerRequest)
	local nextPressure = math.clamp(previous + boundedDelta, Config.MinPressure, Config.MaxPressure)
	pressureBudget.currentPressure = nextPressure
	pressureBudget.pressureDebt = math.max(0, nextPressure - pressureBudget.targetPressure)
	pressureBudget.releaseNeed = math.clamp(pressureBudget.pressureDebt, 0, 100)
	pressureBudget.silenceNeed =
		math.clamp(nextPressure * 0.55 + pressureBudget.sensoryLoad * 0.25, 0, 100)
	pressureBudget.chaseReadiness =
		math.clamp(nextPressure * 0.7 + pressureBudget.emotionalLoad * 0.2, 0, 100)
	table.insert(recentPressureChanges, {
		previous = previous,
		current = nextPressure,
		delta = boundedDelta,
		reason = reason,
		createdAt = os.clock(),
	})
	trim(recentPressureChanges, Config.MaxRecentPressureChanges)
end

function State.applyLoads(sensoryLoad: number, emotionalLoad: number, multiplayerLoad: number)
	pressureBudget.sensoryLoad = math.clamp(sensoryLoad, 0, 100)
	pressureBudget.emotionalLoad = math.clamp(emotionalLoad, 0, 100)
	pressureBudget.multiplayerLoad = math.clamp(multiplayerLoad, 0, 100)
end

function State.decay(deltaSeconds: number)
	State.updatePressure(
		-Config.PressureDecayPerSecond * math.max(0, deltaSeconds) * 100,
		"pressure decay"
	)
end

function State.recordDecision(bundle: any)
	counters.decisions += 1
	if bundle.suppressed then
		counters.suppressed += 1
		table.insert(suppressedDecisions, bundle)
		trim(suppressedDecisions, Config.MaxSuppressedDecisions)
	end
	if bundle.delayed then
		counters.delayed += 1
	end
	if bundle.releasePlanned then
		counters.releases += 1
	end
	table.insert(recentDecisions, bundle)
	table.insert(coordinationBundles, bundle)
	trim(recentDecisions, Config.MaxRecentDecisions)
	trim(coordinationBundles, Config.MaxCoordinationBundles)
end

function State.increment(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
	end
end

function State.getPressureBudget()
	return table.clone(pressureBudget)
end

function State.clear()
	pressureBudget.currentPressure = 0
	pressureBudget.targetPressure = Config.TargetPressure
	pressureBudget.pressureDebt = 0
	pressureBudget.releaseNeed = 0
	pressureBudget.silenceNeed = 0
	pressureBudget.chaseReadiness = 0
	pressureBudget.sensoryLoad = 0
	pressureBudget.emotionalLoad = 0
	pressureBudget.multiplayerLoad = 0
	table.clear(recentPressureChanges)
	table.clear(recentDecisions)
	table.clear(suppressedDecisions)
	table.clear(coordinationBundles)
	table.clear(seenRequests)
	table.clear(seenRequestOrder)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

function State.inspect()
	return {
		pressureBudget = table.clone(pressureBudget),
		recentPressureChanges = table.clone(recentPressureChanges),
		recentDecisions = table.clone(recentDecisions),
		suppressedDecisions = table.clone(suppressedDecisions),
		coordinationBundles = table.clone(coordinationBundles),
		counters = table.clone(counters),
		seenRequestCount = (function()
			return #seenRequestOrder
		end)(),
		seenRequestLimit = Config.MaxSeenRequestIds,
	}
end

return State
