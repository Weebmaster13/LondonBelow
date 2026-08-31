--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local Runtime = {}
local initialized = false
local replayGeneration = 0
local currentDifficulty = "Standard"
local summary = {}

function Runtime.initialize(difficulty: string?)
	initialized = true
	replayGeneration += 1
	currentDifficulty = difficulty or "Standard"
	summary = {}
end

function Runtime.buildSummary(runState: { [string]: any })
	summary = {
		endingId = runState.endingId,
		deaths = runState.deaths,
		rescues = runState.rescues,
		huntsSurvived = runState.huntsSurvived,
		discoveryCount = runState.discoveryCount,
		relicCount = runState.relicCount,
		difficulty = currentDifficulty,
		runSeed = ProductionConfig.RunSeed,
	}
	return table.clone(summary)
end

function Runtime.inspect()
	return {
		initialized = initialized,
		replayGeneration = replayGeneration,
		currentDifficulty = currentDifficulty,
		difficultyPresetCount = 4,
		endingCount = #ProductionConfig.Endings,
		summary = table.clone(summary),
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize("Nightmare")
	local built = Runtime.buildSummary({
		endingId = "escape_with_heart",
		deaths = 1,
		rescues = 1,
		huntsSurvived = 2,
		discoveryCount = 4,
		relicCount = 3,
	})
	return {
		ok = built.difficulty == "Nightmare" and built.runSeed == ProductionConfig.RunSeed,
		endingCount = #ProductionConfig.Endings,
	}
end

function Runtime.shutdown()
	initialized = false
end

return Runtime
