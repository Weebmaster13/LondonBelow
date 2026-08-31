--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local Runtime = {}
local initialized = false
local currentZone = "street"
local currentState = "quiet"
local transitions = 0

function Runtime.initialize()
	initialized = true
	currentZone = "street"
	currentState = "quiet"
	transitions = 0
end

function Runtime.apply(root: Instance?, zone: string, pressure: number, bailiffState: string)
	currentZone = zone
	if bailiffState == "Hunt" or bailiffState == "Climax" then
		currentState = "threat"
	elseif pressure >= 0.65 then
		currentState = "unstable"
	else
		currentState = "quiet"
	end
	transitions += 1
	if root then
		root:SetAttribute("AudioZone", currentZone)
		root:SetAttribute("AudioState", currentState)
		root:SetAttribute(
			"CaptionCue",
			ProductionConfig.Audio.zones[currentZone] or "house pressure"
		)
	end
end

function Runtime.inspect()
	return {
		initialized = initialized,
		currentZone = currentZone,
		currentState = currentState,
		busCount = #ProductionConfig.Audio.buses,
		transitions = transitions,
		assetSlotsRequired = true,
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize()
	Runtime.apply(nil, "archive", 0.9, "Suspicious")
	return {
		ok = currentState == "unstable" and #ProductionConfig.Audio.buses == 9,
		currentZone = currentZone,
		currentState = currentState,
	}
end

function Runtime.shutdown()
	initialized = false
	currentState = "shutdown"
end

return Runtime
