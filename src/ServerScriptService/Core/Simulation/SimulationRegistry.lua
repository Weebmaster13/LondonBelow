--!strict

local Config = require(script.Parent.SimulationConfig)
local Fixtures = require(script.Parent.SimulationFixtures)
local Types = require(script.Parent.SimulationTypes)

local SimulationRegistry = {}

type SimulationScenario = Types.SimulationScenario

local factories: { [string]: () -> SimulationScenario } = {
	IdleSilence = Fixtures.idleSilence,
	SpeedrunnerPressure = Fixtures.speedrunnerPressure,
	LanternOveruse = Fixtures.lanternOveruse,
	NoteIgnorer = Fixtures.noteIgnorer,
	PartySplit = Fixtures.partySplit,
	ExecutionBridgeFailure = Fixtures.executionBridgeFailure,
	InvalidObservation = Fixtures.invalidObservation,
	StaleZoneCleanup = Fixtures.staleZoneCleanup,
}

function SimulationRegistry.get(id: string): SimulationScenario?
	local factory = factories[id]

	if factory == nil then
		return nil
	end

	return factory()
end

function SimulationRegistry.getAll(): { SimulationScenario }
	local scenarios = {}

	for _, id in ipairs(Config.RequiredScenarioIds) do
		local scenario = SimulationRegistry.get(id)

		if scenario ~= nil then
			table.insert(scenarios, scenario)
		end
	end

	return scenarios
end

function SimulationRegistry.validate(): (boolean, string?)
	for _, id in ipairs(Config.RequiredScenarioIds) do
		local scenario = SimulationRegistry.get(id)

		if scenario == nil then
			return false, "Missing simulation scenario: " .. id
		end

		if scenario.id ~= id then
			return false, "Scenario id mismatch: " .. id
		end
	end

	return true, nil
end

return SimulationRegistry
