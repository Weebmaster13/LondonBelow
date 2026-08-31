--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local Runtime = {}
local initialized = false
local activeSeed = ProductionConfig.WardSeeds[1]
local wardProgress = 1
local attempts = {}

function Runtime.initialize()
	initialized = true
	activeSeed = ProductionConfig.WardSeeds[1]
	wardProgress = 1
	attempts = {}
end

function Runtime.validateWard(wardId: string): (boolean, string?)
	attempts[#attempts + 1] = wardId
	local expected = activeSeed.order[wardProgress]
	if wardId ~= expected then
		return false, "IncorrectWardOrder"
	end
	wardProgress += 1
	return true, nil
end

function Runtime.isSolved(): boolean
	return wardProgress > #activeSeed.order
end

function Runtime.hintLevel(attemptCount: number, accessibilityDirect: boolean): number
	if accessibilityDirect then
		return 3
	end
	return math.clamp(math.floor(attemptCount / 2), 0, 2)
end

function Runtime.inspect()
	return {
		initialized = initialized,
		seed = activeSeed.seed,
		wardProgress = wardProgress,
		wardCount = #activeSeed.order,
		attemptCount = #attempts,
		solved = Runtime.isSolved(),
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize()
	local first = Runtime.validateWard(activeSeed.order[1])
	local wrong = Runtime.validateWard("wrong")
	local second = Runtime.validateWard(activeSeed.order[2])
	local third = Runtime.validateWard(activeSeed.order[3])
	return {
		ok = first == true
			and wrong == false
			and second == true
			and third == true
			and Runtime.isSolved(),
		attemptCount = #attempts,
	}
end

function Runtime.shutdown()
	initialized = false
	attempts = {}
end

return Runtime
