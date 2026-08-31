--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local Runtime = {}
local initialized = false
local beats = {}

local beatByObjective = {
	ignite_lantern = "The party crosses the threshold because Constable Vale's last report named Blackwater House as a witness.",
	read_ledger = "Vale discovered the house was preserving testimony, not haunting at random.",
	take_seal = "The brass seal belongs to the office that buried the Blackwater family crimes.",
	ward_west = "The western ward admits that law was used as theater.",
	ward_east = "The eastern ward exposes the family's bargains with memory.",
	ward_crypt = "The buried ward wakes the Bailiff because judgment has been challenged.",
	open_archive = "The archive proves every disappearance was administratively erased.",
	take_heart = "The Glass Heart holds the only unaltered memory of the house.",
	escape_gate = "The ending records what truth the party carried into dawn.",
}

function Runtime.initialize()
	initialized = true
	beats = {}
end

function Runtime.recordObjective(objectiveId: string): string
	local beat = beatByObjective[objectiveId] or "Blackwater House changes its testimony."
	beats[#beats + 1] = { objectiveId = objectiveId, beat = beat }
	return beat
end

function Runtime.endingText(endingId: string): string
	for _, ending in ipairs(ProductionConfig.Endings) do
		if ending.id == endingId then
			return ending.title .. ": " .. ending.consequence
		end
	end
	return "Dawn arrives with an undecided truth."
end

function Runtime.inspect()
	return { initialized = initialized, beatCount = #beats, beats = table.clone(beats) }
end

function Runtime.runSelfChecks()
	Runtime.initialize()
	local beat = Runtime.recordObjective("take_heart")
	local ending = Runtime.endingText("escape_with_heart")
	return {
		ok = string.find(beat, "Glass Heart") ~= nil and string.find(ending, "Heart") ~= nil,
		beatCount = #beats,
	}
end

function Runtime.shutdown()
	initialized = false
	beats = {}
end

return Runtime
