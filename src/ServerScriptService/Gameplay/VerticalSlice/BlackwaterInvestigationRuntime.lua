--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProductionConfig = require(ReplicatedStorage.Config.BlackwaterProductionConfig)

local Runtime = {}
local initialized = false
local discovered: { [string]: boolean } = {}

function Runtime.initialize()
	initialized = true
	discovered = {}
end

function Runtime.record(discoveryId: string): (boolean, string?)
	for _, evidence in ipairs(ProductionConfig.OptionalEvidence) do
		if evidence.id == discoveryId then
			discovered[discoveryId] = true
			return true, evidence.clue
		end
	end
	return false, "UnknownEvidence"
end

function Runtime.pickForObjective(objectiveId: string): string?
	local index = ((string.byte(objectiveId, 1) or 1) + ProductionConfig.RunSeed)
			% #ProductionConfig.OptionalEvidence
		+ 1
	return ProductionConfig.OptionalEvidence[index].id
end

function Runtime.inspect()
	local count = 0
	for _ in pairs(discovered) do
		count += 1
	end
	return {
		initialized = initialized,
		discoveredCount = count,
		totalEvidence = #ProductionConfig.OptionalEvidence,
		discovered = table.clone(discovered),
	}
end

function Runtime.runSelfChecks()
	Runtime.initialize()
	local valid = Runtime.record(ProductionConfig.OptionalEvidence[1].id)
	local invalid = Runtime.record("missing")
	return {
		ok = valid == true and invalid == false,
		totalEvidence = #ProductionConfig.OptionalEvidence,
	}
end

function Runtime.shutdown()
	initialized = false
	discovered = {}
end

return Runtime
