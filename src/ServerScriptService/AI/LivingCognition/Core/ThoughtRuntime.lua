--!strict
-- Thoughts are promoted hypotheses, not goals or actions.

local Config = require(script.Parent.LivingCognitionConfiguration)
local Serialization = require(script.Parent.LivingCognitionSerialization)
local Validation = require(script.Parent.LivingCognitionValidation)

local ThoughtRuntime = {}

function ThoughtRuntime.promote(hypothesis: any)
	if hypothesis.confidence < Config.HypothesisPromotionThreshold then
		return nil, "hypothesis confidence below thought promotion threshold"
	end
	local now = os.clock()
	return {
		thoughtId = "thought:" .. hypothesis.hypothesisId,
		entityId = hypothesis.entityId,
		hypothesisId = hypothesis.hypothesisId,
		state = "Born",
		confidence = math.clamp(hypothesis.confidence, 0, Config.AbsoluteCertaintyThreshold),
		transitions = {
			{
				from = "None",
				to = "Born",
				reason = "hypothesis promoted",
				createdAt = now,
			},
		},
		traceId = hypothesis.traceId,
		createdAt = now,
		updatedAt = now,
	},
		nil
end

function ThoughtRuntime.transition(thought: any, nextState: string, reason: string)
	local ok, validationReason = Validation.thoughtTransition(thought.state, nextState)
	if not ok then
		return nil, validationReason
	end
	local updated = Serialization.deepCopy(thought)
	table.insert(updated.transitions, {
		from = thought.state,
		to = nextState,
		reason = reason,
		createdAt = os.clock(),
	})
	updated.state = nextState
	updated.updatedAt = os.clock()
	return updated, nil
end

function ThoughtRuntime.decay(thought: any, deltaSeconds: number)
	local updated = Serialization.deepCopy(thought)
	updated.confidence = math.clamp(
		updated.confidence - Config.ConfidenceDecayPerSecond * math.max(0, deltaSeconds),
		0,
		Config.AbsoluteCertaintyThreshold
	)
	updated.state = if updated.confidence <= 0.05 then "Archived" else "Decaying"
	updated.updatedAt = os.clock()
	return updated
end

return ThoughtRuntime
