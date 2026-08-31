--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local RunState = {}
local state = {
	runId = "blackwater-" .. tostring(ProductionConfig.RunSeed),
	seed = ProductionConfig.RunSeed,
	difficulty = "Standard",
	stage = "Dormant",
	generation = 0,
	pressure = 0,
	bailiffState = "Unspawned",
	endingId = "undecided",
	discoveries = {},
	relics = {},
	objectives = {},
	hintsUsed = 0,
	deaths = 0,
	rescues = 0,
	huntsSurvived = 0,
	noise = {},
	exposure = {},
	hiding = {},
	failures = {},
	audit = {},
}

local function copyArray(source: { any })
	local result = {}
	for index, value in ipairs(source) do
		if type(value) == "table" then
			result[index] = table.clone(value)
		else
			result[index] = value
		end
	end
	return result
end

local function append(target: { any }, value: any, limit: number)
	if #target >= limit then
		table.remove(target, 1)
	end
	target[#target + 1] = table.freeze(value)
end

local function audit(kind: string, detail: { [string]: any }?)
	state.generation += 1
	append(state.audit, {
		generation = state.generation,
		kind = kind,
		detail = detail or {},
		at = os.clock(),
	}, 1024)
end

function RunState.initialize(difficulty: string?)
	state.runId = "blackwater-" .. tostring(ProductionConfig.RunSeed)
	state.seed = ProductionConfig.RunSeed
	state.difficulty = difficulty or "Standard"
	state.stage = "Initialized"
	state.generation = 0
	state.pressure = 0
	state.bailiffState = "Dormant"
	state.endingId = "undecided"
	state.discoveries = {}
	state.relics = {}
	state.objectives = {}
	state.hintsUsed = 0
	state.deaths = 0
	state.rescues = 0
	state.huntsSurvived = 0
	state.noise = {}
	state.exposure = {}
	state.hiding = {}
	state.failures = {}
	state.audit = {}
	audit("RunInitialized", { difficulty = state.difficulty, seed = state.seed })
end

function RunState.setStage(stage: string)
	state.stage = stage
	audit("StageChanged", { stage = stage })
end

function RunState.setPressure(pressure: number)
	state.pressure = math.clamp(pressure, 0, 1)
	audit("PressureChanged", { pressure = state.pressure })
end

function RunState.getPressure(): number
	return state.pressure
end

function RunState.setBailiffState(value: string, reason: string?)
	state.bailiffState = value
	audit("BailiffStateChanged", { bailiffState = value, reason = reason or "unspecified" })
end

function RunState.getBailiffState(): string
	return state.bailiffState
end

function RunState.recordDiscovery(discoveryId: string)
	state.discoveries[discoveryId] = true
	audit("DiscoveryRecorded", { discoveryId = discoveryId })
end

function RunState.hasDiscovery(discoveryId: string): boolean
	return state.discoveries[discoveryId] == true
end

function RunState.recordRelic(relicId: string)
	state.relics[relicId] = true
	audit("RelicRecorded", { relicId = relicId })
end

function RunState.hasRelic(relicId: string): boolean
	return state.relics[relicId] == true
end

function RunState.recordObjective(objectiveId: string)
	state.objectives[objectiveId] = true
	audit("ObjectiveRecorded", { objectiveId = objectiveId })
end

function RunState.recordNoise(userId: number, magnitude: number, category: string, radius: number)
	state.noise[userId] = {
		magnitude = math.clamp(magnitude, 0, 1),
		category = category,
		radius = math.clamp(radius, 0, 120),
		at = os.clock(),
	}
	audit("NoiseRecorded", { userId = userId, category = category, magnitude = magnitude })
end

function RunState.recordExposure(userId: number, value: number)
	state.exposure[userId] = math.clamp(value, 0, 1)
end

function RunState.setHiding(userId: number, hidingId: string?)
	state.hiding[userId] = hidingId
	audit("HidingChanged", { userId = userId, hidingId = hidingId or "none" })
end

function RunState.recordDeath()
	state.deaths += 1
	audit("DeathRecorded", { deaths = state.deaths })
end

function RunState.recordRescue()
	state.rescues += 1
	audit("RescueRecorded", { rescues = state.rescues })
end

function RunState.recordHuntSurvived()
	state.huntsSurvived += 1
	audit("HuntSurvived", { huntsSurvived = state.huntsSurvived })
end

function RunState.useHint()
	state.hintsUsed += 1
	audit("HintUsed", { hintsUsed = state.hintsUsed })
end

function RunState.chooseEnding(): string
	local optionalCount = 0
	for _ in pairs(state.discoveries) do
		optionalCount += 1
	end
	if optionalCount >= #ProductionConfig.OptionalEvidence then
		state.endingId = "free_the_presence"
	elseif state.relics.glass_heart then
		state.endingId = "escape_with_heart"
	else
		state.endingId = "seal_the_heart"
	end
	audit("EndingChosen", { endingId = state.endingId })
	return state.endingId
end

function RunState.recordFailure(code: string, detail: { [string]: any }?)
	append(state.failures, {
		code = code,
		detail = detail or {},
		at = os.clock(),
	}, 256)
end

function RunState.inspect()
	local discoveryCount = 0
	for _ in pairs(state.discoveries) do
		discoveryCount += 1
	end
	local relicCount = 0
	for _ in pairs(state.relics) do
		relicCount += 1
	end
	local objectiveCount = 0
	for _ in pairs(state.objectives) do
		objectiveCount += 1
	end
	return {
		runId = state.runId,
		seed = state.seed,
		difficulty = state.difficulty,
		stage = state.stage,
		generation = state.generation,
		pressure = state.pressure,
		bailiffState = state.bailiffState,
		endingId = state.endingId,
		discoveryCount = discoveryCount,
		relicCount = relicCount,
		objectiveCount = objectiveCount,
		hintsUsed = state.hintsUsed,
		deaths = state.deaths,
		rescues = state.rescues,
		huntsSurvived = state.huntsSurvived,
		noise = table.clone(state.noise),
		exposure = table.clone(state.exposure),
		hiding = table.clone(state.hiding),
		failures = copyArray(state.failures),
		audit = copyArray(state.audit),
	}
end

function RunState.clear()
	RunState.initialize("Standard")
	state.stage = "Shutdown"
end

return RunState
