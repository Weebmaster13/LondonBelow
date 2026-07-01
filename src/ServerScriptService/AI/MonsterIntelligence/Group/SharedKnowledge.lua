--!strict
-- Shared believed facts for future monster cooperation.

local Config = require(script.Parent.Parent.Core.MonsterConfig)

local SharedKnowledge = {}

local facts: { any } = {}

local function trim()
	while #facts > Config.MaxSharedFacts do
		table.remove(facts, 1)
	end
end

function SharedKnowledge.share(fact: any): (boolean, string?)
	if type(fact) ~= "table" or type(fact.id) ~= "string" or fact.id == "" then
		return false, "shared fact requires id"
	end
	table.insert(facts, {
		id = fact.id,
		sourceMonsterId = fact.sourceMonsterId,
		state = fact.state or "Shared",
		confidence = if type(fact.confidence) == "number"
			then math.clamp(fact.confidence, 0, 1)
			else 0.5,
		createdAt = fact.createdAt or os.clock(),
		metadata = if type(fact.metadata) == "table" then table.clone(fact.metadata) else {},
	})
	trim()
	return true, nil
end

function SharedKnowledge.clear()
	table.clear(facts)
end

function SharedKnowledge.inspect()
	return {
		sharedFactCount = #facts,
		limit = Config.MaxSharedFacts,
		recentFacts = table.clone(facts),
	}
end

return SharedKnowledge
