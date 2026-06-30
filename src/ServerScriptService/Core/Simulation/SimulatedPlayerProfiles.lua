--!strict

local Config = require(script.Parent.SimulationConfig)
local Types = require(script.Parent.SimulationTypes)

local SimulatedPlayerProfiles = {}

type SimulatedPlayerProfile = Types.SimulatedPlayerProfile

local profiles: { [string]: SimulatedPlayerProfile } = {
	soloCareful = {
		userId = Config.SyntheticUserIdStart,
		name = "Sim_SoloCareful",
		traits = { "careful", "observant" },
		partyId = nil,
	},
	speedrunner = {
		userId = Config.SyntheticUserIdStart - 1,
		name = "Sim_Speedrunner",
		traits = { "fast", "risk-taking" },
		partyId = nil,
	},
	lanternUser = {
		userId = Config.SyntheticUserIdStart - 2,
		name = "Sim_LanternUser",
		traits = { "light-dependent" },
		partyId = nil,
	},
	noteIgnorer = {
		userId = Config.SyntheticUserIdStart - 3,
		name = "Sim_NoteIgnorer",
		traits = { "impatient" },
		partyId = nil,
	},
	partyLeader = {
		userId = Config.SyntheticUserIdStart - 4,
		name = "Sim_PartyLeader",
		traits = { "leader" },
		partyId = "sim-party",
	},
	partySeparated = {
		userId = Config.SyntheticUserIdStart - 5,
		name = "Sim_Separated",
		traits = { "isolated" },
		partyId = "sim-party",
	},
}

local function copyProfile(profile: SimulatedPlayerProfile): SimulatedPlayerProfile
	return {
		userId = profile.userId,
		name = profile.name,
		traits = table.clone(profile.traits),
		partyId = profile.partyId,
	}
end

function SimulatedPlayerProfiles.get(name: string): SimulatedPlayerProfile
	local profile = profiles[name]

	assert(profile ~= nil, "Unknown simulated profile: " .. name)

	return copyProfile(profile :: SimulatedPlayerProfile)
end

function SimulatedPlayerProfiles.getMany(names: { string }): { SimulatedPlayerProfile }
	local copied = {}

	for _, name in ipairs(names) do
		table.insert(copied, SimulatedPlayerProfiles.get(name))
	end

	return copied
end

return SimulatedPlayerProfiles
