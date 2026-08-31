--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local Runtime = {}
local initialized = false
local occupancy: { [string]: { [number]: boolean } } = {}
local stamina: { [number]: number } = {}
local counters = { noiseEvents = 0, hidingEntries = 0, hidingRejected = 0 }

function Runtime.initialize()
	initialized = true
	occupancy = {}
	stamina = {}
	counters.noiseEvents = 0
	counters.hidingEntries = 0
	counters.hidingRejected = 0
	for _, hiding in ipairs(ProductionConfig.HidingTypes) do
		occupancy[hiding.id] = {}
	end
end

function Runtime.calculateNoise(category: string, pressure: number): (number, number)
	local base = 0.16
	if category == "sprint" then
		base = 0.58
	elseif category == "puzzle_failure" then
		base = 0.72
	elseif category == "relic_carried" then
		base = 0.46
	elseif category == "rescue" then
		base = 0.38
	elseif category == "crouch" then
		base = 0.07
	end
	local magnitude = math.clamp(base + pressure * 0.18, 0, 1)
	counters.noiseEvents += 1
	return magnitude, 18 + magnitude * 72
end

function Runtime.calculateExposure(movement: number, hidingId: string?, pressure: number): number
	local hidingReduction = if hidingId then 0.45 else 0
	return math.clamp(0.2 + movement * 0.38 + pressure * 0.3 - hidingReduction, 0, 1)
end

function Runtime.tryEnterHiding(userId: number, hidingId: string): (boolean, string?)
	local definition
	for _, item in ipairs(ProductionConfig.HidingTypes) do
		if item.id == hidingId then
			definition = item
			break
		end
	end
	if not definition then
		counters.hidingRejected += 1
		return false, "UnknownHidingType"
	end
	local occupants = occupancy[hidingId]
	local count = 0
	for _ in pairs(occupants) do
		count += 1
	end
	if count >= definition.capacity then
		counters.hidingRejected += 1
		return false, "HidingFull"
	end
	occupants[userId] = true
	counters.hidingEntries += 1
	return true, nil
end

function Runtime.exitHiding(userId: number)
	for _, occupants in pairs(occupancy) do
		occupants[userId] = nil
	end
end

function Runtime.updateStamina(userId: number, sprinting: boolean, difficulty: string): number
	local current = stamina[userId] or 1
	local profile = ProductionConfig.Difficulty[difficulty] or ProductionConfig.Difficulty.Standard
	if sprinting then
		current -= 0.12 / profile.staminaForgiveness
	else
		current += 0.08 * profile.staminaForgiveness
	end
	current = math.clamp(current, 0, 1)
	stamina[userId] = current
	return current
end

function Runtime.inspect()
	return {
		initialized = initialized,
		hidingTypes = #ProductionConfig.HidingTypes,
		counters = table.clone(counters),
		stamina = table.clone(stamina),
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize()
	local okEnter = Runtime.tryEnterHiding(-1, "wardrobe")
	local rejectFull = Runtime.tryEnterHiding(-2, "wardrobe")
	local sprint = Runtime.updateStamina(-1, true, "Standard")
	local recover = Runtime.updateStamina(-1, false, "Story")
	return {
		ok = okEnter == true and rejectFull == false and sprint < recover,
		hidingTypes = #ProductionConfig.HidingTypes,
		staminaAfterSprint = sprint,
		staminaAfterRecover = recover,
	}
end

function Runtime.shutdown()
	initialized = false
	occupancy = {}
	stamina = {}
end

return Runtime
