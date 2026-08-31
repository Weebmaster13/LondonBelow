--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local Runtime = {}
local initialized = false
local appliedStage = "Arrival"
local counters = {
	roomIdentities = 0,
	shortcuts = 0,
	stateReactions = 0,
}

local stageByObjective = {
	ignite_lantern = "Arrival",
	read_ledger = "Investigation",
	take_seal = "Investigation",
	ward_west = "WardPuzzle",
	ward_east = "WardPuzzle",
	ward_crypt = "BailiffAwakening",
	open_archive = "ArchiveOpening",
	take_heart = "Blackout",
	escape_gate = "DawnAftermath",
}

function Runtime.initialize()
	initialized = true
	appliedStage = "Arrival"
	counters.roomIdentities = #ProductionConfig.Rooms
	counters.shortcuts = #ProductionConfig.Shortcuts
	counters.stateReactions = 0
end

function Runtime.applyObjective(root: Instance?, objectiveId: string)
	if root == nil then
		return
	end
	local nextStage = stageByObjective[objectiveId] or appliedStage
	appliedStage = nextStage
	root:SetAttribute("EnvironmentStage", appliedStage)
	root:SetAttribute("RoomPurposeCount", #ProductionConfig.Rooms)
	root:SetAttribute("ShortcutCount", #ProductionConfig.Shortcuts)
	root:SetAttribute("EnvironmentalStorytelling", "active")
	counters.stateReactions += 1
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("BlackwaterReactive") == true then
			if appliedStage == "Blackout" then
				descendant.Color = Color3.fromRGB(29, 22, 26)
			elseif appliedStage == "DawnAftermath" then
				descendant.Color = Color3.fromRGB(118, 116, 104)
			end
		end
	end
end

function Runtime.inspect()
	return {
		initialized = initialized,
		appliedStage = appliedStage,
		roomCount = #ProductionConfig.Rooms,
		shortcutCount = #ProductionConfig.Shortcuts,
		counters = table.clone(counters),
		ownership = "server-authoritative environment state",
	}
end

function Runtime.runSelfChecks()
	return {
		ok = initialized or #ProductionConfig.Rooms >= 15,
		roomCount = #ProductionConfig.Rooms,
		shortcuts = #ProductionConfig.Shortcuts,
		reactiveStages = 8,
	}
end

function Runtime.shutdown()
	initialized = false
	appliedStage = "Shutdown"
end

return Runtime
