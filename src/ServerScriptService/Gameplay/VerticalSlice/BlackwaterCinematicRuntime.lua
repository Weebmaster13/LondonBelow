--!strict

local Runtime = {}
local initialized = false
local activeBeat: string? = nil
local cancelled = 0
local played = {}

local cinematicByObjective = {
	ignite_lantern = "opening_street_arrival",
	read_ledger = "first_house_testimony",
	ward_crypt = "first_bailiff_reveal",
	open_archive = "archive_opening",
	take_heart = "glass_heart_reveal",
	escape_gate = "dawn_aftermath",
}

function Runtime.initialize()
	initialized = true
	activeBeat = nil
	cancelled = 0
	played = {}
end

function Runtime.playForObjective(root: Instance?, objectiveId: string, reducedMotion: boolean)
	local beat = cinematicByObjective[objectiveId]
	if not beat then
		return nil
	end
	activeBeat = beat
	played[#played + 1] = { id = beat, reducedMotion = reducedMotion, skippable = true }
	if root then
		root:SetAttribute("CinematicBeat", beat)
		root:SetAttribute("CinematicReducedMotion", reducedMotion)
	end
	return beat
end

function Runtime.cancel(reason: string)
	if activeBeat then
		cancelled += 1
		activeBeat = nil
	end
	return reason
end

function Runtime.inspect()
	return {
		initialized = initialized,
		activeBeat = activeBeat,
		playedCount = #played,
		cancelled = cancelled,
		played = table.clone(played),
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize()
	local beat = Runtime.playForObjective(nil, "take_heart", true)
	Runtime.cancel("self_check")
	return {
		ok = beat == "glass_heart_reveal" and activeBeat == nil and cancelled == 1,
		playedCount = #played,
	}
end

function Runtime.shutdown()
	Runtime.cancel("shutdown")
	initialized = false
end

return Runtime
