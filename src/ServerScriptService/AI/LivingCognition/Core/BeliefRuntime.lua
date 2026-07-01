--!strict
-- Beliefs are stable conclusions that change slowly.

local Config = require(script.Parent.LivingCognitionConfiguration)
local Serialization = require(script.Parent.LivingCognitionSerialization)

local BeliefRuntime = {}

function BeliefRuntime.fromThought(thought: any, hypothesis: any)
	if thought.confidence < Config.BeliefPromotionThreshold then
		return nil, "thought confidence below belief promotion threshold"
	end
	local now = os.clock()
	return {
		beliefId = "belief:" .. hypothesis.hypothesisId,
		entityId = thought.entityId,
		statement = hypothesis.explanation,
		confidence = math.clamp(thought.confidence, 0, Config.AbsoluteCertaintyThreshold),
		evidenceIds = table.clone(hypothesis.evidenceIds or {}),
		contradictionCount = 0,
		traceId = thought.traceId,
		createdAt = now,
		updatedAt = now,
	},
		nil
end

function BeliefRuntime.reinforce(belief: any, amount: number)
	local updated = Serialization.deepCopy(belief)
	updated.confidence =
		math.clamp(updated.confidence + math.max(0, amount), 0, Config.AbsoluteCertaintyThreshold)
	updated.updatedAt = os.clock()
	return updated
end

function BeliefRuntime.contradict(belief: any, amount: number)
	local updated = Serialization.deepCopy(belief)
	updated.confidence = math.clamp(updated.confidence - math.max(0, amount), 0, 1)
	updated.contradictionCount += 1
	updated.updatedAt = os.clock()
	return updated
end

return BeliefRuntime
