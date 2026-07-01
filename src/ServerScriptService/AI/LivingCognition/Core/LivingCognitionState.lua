--!strict
-- Bounded state store for observations, evidence, hypotheses, thoughts, and beliefs.

local Config = require(script.Parent.LivingCognitionConfiguration)
local Serialization = require(script.Parent.LivingCognitionSerialization)

local State = {}

local buckets: { [string]: any } = {}
local traces: { any } = {}
local validationFailures: { any } = {}
local diagnosticsHistory: { any } = {}

local function ensure(entityId: string)
	local bucket = buckets[entityId]
	if bucket == nil then
		bucket = {
			observations = {},
			evidence = {},
			hypotheses = {},
			thoughts = {},
			beliefs = {},
		}
		buckets[entityId] = bucket
	end
	return bucket
end

local function trim(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function add(entityId: string, key: string, value: any, limit: number)
	local bucket = ensure(entityId)
	table.insert(bucket[key], Serialization.deepCopy(value))
	trim(bucket[key], limit)
end

function State.recordTrace(stage: string, entityId: string, traceId: string, details: any)
	table.insert(traces, {
		stage = stage,
		entityId = entityId,
		traceId = traceId,
		details = Serialization.deepCopy(details),
		createdAt = os.clock(),
	})
	trim(traces, Config.MaxTraceHistory)
end

function State.recordValidationFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.deepCopy(payload),
		createdAt = os.clock(),
	})
	trim(validationFailures, Config.MaxValidationFailures)
end

function State.addObservation(observation: any)
	add(observation.entityId, "observations", observation, Config.MaxObservationsPerEntity)
	State.recordTrace("Observation", observation.entityId, observation.traceId, {
		observationId = observation.observationId,
		confidence = observation.confidence,
	})
end

function State.addEvidence(evidence: any)
	add(evidence.entityId, "evidence", evidence, Config.MaxEvidencePerEntity)
	State.recordTrace("Evidence", evidence.entityId, evidence.traceId, {
		evidenceId = evidence.evidenceId,
		confidence = evidence.confidence,
	})
end

function State.addHypothesis(hypothesis: any)
	add(hypothesis.entityId, "hypotheses", hypothesis, Config.MaxHypothesesPerEntity)
	State.recordTrace("Hypothesis", hypothesis.entityId, hypothesis.traceId, {
		hypothesisId = hypothesis.hypothesisId,
		confidence = hypothesis.confidence,
	})
end

function State.addThought(thought: any)
	add(thought.entityId, "thoughts", thought, Config.MaxThoughtsPerEntity)
	State.recordTrace("Thought", thought.entityId, thought.traceId, {
		thoughtId = thought.thoughtId,
		state = thought.state,
		confidence = thought.confidence,
	})
end

function State.addBelief(belief: any)
	add(belief.entityId, "beliefs", belief, Config.MaxBeliefsPerEntity)
	State.recordTrace("Belief", belief.entityId, belief.traceId, {
		beliefId = belief.beliefId,
		confidence = belief.confidence,
	})
end

function State.cleanup(currentTime: number)
	for _, bucket in pairs(buckets) do
		for index = #bucket.evidence, 1, -1 do
			local evidence = bucket.evidence[index]
			if evidence.expiration ~= nil and evidence.expiration <= currentTime then
				table.remove(bucket.evidence, index)
			end
		end
		for index = #bucket.hypotheses, 1, -1 do
			local hypothesis = bucket.hypotheses[index]
			if hypothesis.confidence <= 0.01 or hypothesis.state == "Archived" then
				table.remove(bucket.hypotheses, index)
			end
		end
		for index = #bucket.thoughts, 1, -1 do
			local thought = bucket.thoughts[index]
			if thought.confidence <= 0.01 or thought.state == "Archived" then
				table.remove(bucket.thoughts, index)
			end
		end
	end
end

function State.recordDiagnosticsSnapshot(summary: any)
	table.insert(diagnosticsHistory, Serialization.deepCopy(summary))
	trim(diagnosticsHistory, Config.MaxDiagnosticsHistory)
end

function State.getBucket(entityId: string): any
	return Serialization.deepCopy(ensure(entityId))
end

function State.clear()
	table.clear(buckets)
	table.clear(traces)
	table.clear(validationFailures)
	table.clear(diagnosticsHistory)
end

function State.inspect()
	local counts = {
		observations = 0,
		evidence = 0,
		hypotheses = 0,
		thoughts = 0,
		beliefs = 0,
	}
	for _, bucket in pairs(buckets) do
		counts.observations += #bucket.observations
		counts.evidence += #bucket.evidence
		counts.hypotheses += #bucket.hypotheses
		counts.thoughts += #bucket.thoughts
		counts.beliefs += #bucket.beliefs
	end
	local confidenceHistory = {}
	local lifecycleTransitions = {}
	for _, trace in ipairs(traces) do
		if trace.details ~= nil and trace.details.confidence ~= nil then
			table.insert(confidenceHistory, {
				stage = trace.stage,
				entityId = trace.entityId,
				traceId = trace.traceId,
				confidence = trace.details.confidence,
				createdAt = trace.createdAt,
			})
		end
		if trace.stage == "Thought" and trace.details ~= nil then
			table.insert(lifecycleTransitions, {
				entityId = trace.entityId,
				traceId = trace.traceId,
				state = trace.details.state,
				createdAt = trace.createdAt,
			})
		end
	end
	return {
		counts = counts,
		buckets = Serialization.deepCopy(buckets),
		traces = Serialization.deepCopy(traces),
		validationFailures = Serialization.deepCopy(validationFailures),
		diagnosticsHistory = Serialization.deepCopy(diagnosticsHistory),
		confidenceHistory = confidenceHistory,
		lifecycleTransitions = lifecycleTransitions,
		limits = {
			observations = Config.MaxObservationsPerEntity,
			evidence = Config.MaxEvidencePerEntity,
			hypotheses = Config.MaxHypothesesPerEntity,
			thoughts = Config.MaxThoughtsPerEntity,
			beliefs = Config.MaxBeliefsPerEntity,
			traces = Config.MaxTraceHistory,
			diagnosticsHistory = Config.MaxDiagnosticsHistory,
		},
	}
end

return State
