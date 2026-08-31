--!strict

local Runtime = {}
local initialized = false
local samples = {}
local counters = { samples = 0, highSuspicion = 0 }

local function clamp01(value: number): number
	return math.clamp(value, 0, 1)
end

function Runtime.initialize()
	initialized = true
	samples = {}
	counters.samples = 0
	counters.highSuspicion = 0
end

function Runtime.sample(
	userId: number,
	distance: number,
	movement: number,
	noise: number,
	exposure: number,
	pressure: number
)
	local distanceScore = 1 - math.clamp(distance / 90, 0, 1)
	local suspicion = clamp01(
		distanceScore * 0.28 + movement * 0.18 + noise * 0.24 + exposure * 0.18 + pressure * 0.12
	)
	samples[userId] = {
		distance = distance,
		movement = clamp01(movement),
		noise = clamp01(noise),
		exposure = clamp01(exposure),
		pressure = clamp01(pressure),
		suspicion = suspicion,
	}
	counters.samples += 1
	if suspicion >= 0.65 then
		counters.highSuspicion += 1
	end
	return suspicion
end

function Runtime.inspect()
	return {
		initialized = initialized,
		counters = table.clone(counters),
		samples = table.clone(samples),
	}
end

function Runtime.runSelfChecks()
	local quiet = Runtime.sample(-100, 90, 0, 0, 0, 0)
	local loud = Runtime.sample(-101, 10, 1, 1, 1, 1)
	return { ok = quiet < loud and loud <= 1, quietSuspicion = quiet, loudSuspicion = loud }
end

function Runtime.shutdown()
	initialized = false
	samples = {}
end

return Runtime
