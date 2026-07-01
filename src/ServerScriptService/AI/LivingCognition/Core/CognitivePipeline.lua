--!strict
-- Trusted observation -> evidence -> hypotheses -> thoughts -> beliefs.

local Config = require(script.Parent.LivingCognitionConfiguration)
local BeliefRuntime = require(script.Parent.BeliefRuntime)
local EvidenceRuntime = require(script.Parent.EvidenceRuntime)
local HypothesisRuntime = require(script.Parent.HypothesisRuntime)
local ObservationIntake = require(script.Parent.ObservationIntake)
local ThoughtRuntime = require(script.Parent.ThoughtRuntime)

local Pipeline = {}

function Pipeline.process(rawObservation: any, dependencies: { [string]: any })
	local observation, observationReason = ObservationIntake.normalize(rawObservation)
	if observation == nil then
		return nil, observationReason
	end
	if not dependencies.Registry.exists(observation.entityId) then
		return nil, "unknown cognitive entity"
	end

	local evidence = EvidenceRuntime.fromObservation(observation)
	local hypotheses = HypothesisRuntime.generate(evidence)
	local rankedHypotheses = HypothesisRuntime.rank(hypotheses)
	local promotedThoughts = {}
	local beliefs = {}

	dependencies.State.addObservation(observation)
	dependencies.State.addEvidence(evidence)

	for _, hypothesis in ipairs(rankedHypotheses) do
		dependencies.State.addHypothesis(hypothesis)
		local thought = ThoughtRuntime.promote(hypothesis)
		if thought ~= nil then
			table.insert(promotedThoughts, thought)
			dependencies.State.addThought(thought)
			if thought.confidence >= Config.BeliefPromotionThreshold then
				local belief = BeliefRuntime.fromThought(thought, hypothesis)
				if belief ~= nil then
					table.insert(beliefs, belief)
					dependencies.State.addBelief(belief)
				end
			end
		end
	end

	return {
		observation = observation,
		evidence = evidence,
		hypotheses = rankedHypotheses,
		thoughts = promotedThoughts,
		beliefs = beliefs,
		traceId = observation.traceId,
	},
		nil
end

return Pipeline
