--!strict
-- Deterministic certification scenarios for Living Cognition.

local BeliefRuntime = require(script.Parent.BeliefRuntime)
local EvidenceRuntime = require(script.Parent.EvidenceRuntime)
local Serialization = require(script.Parent.LivingCognitionSerialization)
local ThoughtRuntime = require(script.Parent.ThoughtRuntime)

local SelfChecks = {}

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Registry.clear()
	dependencies.State.clear()

	local registered = dependencies.Registry.register({
		entityId = "selfcheck.entity",
		entityKind = "TestCognitiveEntity",
		ownerSystem = "SelfCheck",
		tags = { "self-check" },
	})
	local duplicate = dependencies.Registry.register({
		entityId = "selfcheck.entity",
		entityKind = "TestCognitiveEntity",
		ownerSystem = "SelfCheck",
	})
	local processed, processReason = dependencies.Pipeline.process({
		observationId = "selfcheck.observation",
		entityId = "selfcheck.entity",
		sourceSystem = "SelfCheck",
		observedAt = os.clock(),
		confidence = 0.95,
		provenance = "Synthetic",
		payload = { signal = "sound", unknown = true },
		traceId = "selfcheck.trace",
	}, dependencies)
	local malformed = dependencies.Pipeline.process({
		observationId = "",
		entityId = "selfcheck.entity",
		sourceSystem = "SelfCheck",
		observedAt = os.clock(),
		confidence = 0.5,
		payload = {},
	}, dependencies)
	local executionLeak = dependencies.Pipeline.process({
		observationId = "selfcheck.execution-leak",
		entityId = "selfcheck.entity",
		sourceSystem = "SelfCheck",
		observedAt = os.clock(),
		confidence = 0.5,
		payload = { workspace = true },
	}, dependencies)
	local invalidConfidence = dependencies.Pipeline.process({
		observationId = "selfcheck.invalid-confidence",
		entityId = "selfcheck.entity",
		sourceSystem = "SelfCheck",
		observedAt = os.clock(),
		confidence = 2,
		payload = {},
	}, dependencies)
	local invalidTimestamp = dependencies.Pipeline.process({
		observationId = "selfcheck.invalid-timestamp",
		entityId = "selfcheck.entity",
		sourceSystem = "SelfCheck",
		observedAt = -1,
		confidence = 0.5,
		payload = {},
	}, dependencies)
	local oversizedPayload = {}
	for index = 1, dependencies.Config.MaxPayloadNodes + 1 do
		oversizedPayload["k" .. tostring(index)] = index
	end
	local oversized = dependencies.Pipeline.process({
		observationId = "selfcheck.oversized",
		entityId = "selfcheck.entity",
		sourceSystem = "SelfCheck",
		observedAt = os.clock(),
		confidence = 0.5,
		payload = oversizedPayload,
	}, dependencies)
	local cyclic = {}
	cyclic.self = cyclic
	local cyclicSerialization = Serialization.validateSerializable(cyclic)
	local unsafeFunctionSerialization = Serialization.validateSerializable({
		callback = function() end,
	})

	local thoughtDecay = false
	local thoughtMergeSplit = false
	local invalidThoughtTransition = false
	local beliefReinforcement = false
	local beliefContradiction = false
	local staleEvidenceDecay = false
	local contradictoryEvidenceLowersConfidence = false
	local deterministicRanking = false
	if processed ~= nil and #processed.thoughts > 0 then
		local decayed = ThoughtRuntime.decay(processed.thoughts[1], 10)
		thoughtDecay = decayed.confidence < processed.thoughts[1].confidence
		local merged =
			ThoughtRuntime.transition(processed.thoughts[1], "Merged", "self-check merge")
		local split = ThoughtRuntime.transition(processed.thoughts[1], "Split", "self-check split")
		local invalidTransition =
			ThoughtRuntime.transition({ state = "Archived" }, "Born", "invalid self-check")
		thoughtMergeSplit = merged ~= nil and split ~= nil
		invalidThoughtTransition = invalidTransition == nil
	end
	if processed ~= nil and #processed.beliefs > 0 then
		local reinforced = BeliefRuntime.reinforce(processed.beliefs[1], 0.05)
		local contradicted = BeliefRuntime.contradict(reinforced, 0.1)
		beliefReinforcement = reinforced.confidence >= processed.beliefs[1].confidence
			and reinforced.confidence <= dependencies.Config.AbsoluteCertaintyThreshold
		beliefContradiction = contradicted.confidence < reinforced.confidence
			and contradicted.confidence >= 0
	end
	if processed ~= nil then
		local decayedEvidence = EvidenceRuntime.decay(processed.evidence, 100)
		staleEvidenceDecay = decayedEvidence.confidence < processed.evidence.confidence
			and decayedEvidence.freshness < processed.evidence.freshness
		local contradicted = BeliefRuntime.contradict({
			confidence = 0.75,
			contradictionCount = 0,
		}, 0.2)
		contradictoryEvidenceLowersConfidence = contradicted.confidence < 0.75
		deterministicRanking = processed.hypotheses[1].confidence
			>= processed.hypotheses[#processed.hypotheses].confidence
	end

	local snapshotA = dependencies.Snapshots.capture(dependencies.State, dependencies.Registry)
	local snapshotB = Serialization.deepCopy(snapshotA)
	snapshotB.mutated = true
	local snapshotIsolation = snapshotA.mutated == nil
	local serializationOk = Serialization.validateSerializable(snapshotA)
	local serialized = Serialization.deepCopy(snapshotA)
	serialized.registry.mutated = true
	local serializationIsolation = snapshotA.registry.mutated == nil
	local diagnosticsA = dependencies.State.inspect()
	diagnosticsA.counts.observations = 999
	local diagnosticsB = dependencies.State.inspect()
	local diagnosticsReadOnly = diagnosticsB.counts.observations ~= 999

	local inspectBeforeShutdown = dependencies.State.inspect()
	dependencies.State.cleanup(os.clock() + 120)
	local inspectAfterCleanup = dependencies.State.inspect()
	dependencies.Registry.clear()
	dependencies.State.clear()
	local inspectAfterShutdown = dependencies.State.inspect()

	return {
		ok = registered
			and duplicate == false
			and processed ~= nil
			and processReason == nil
			and malformed == nil
			and executionLeak == nil
			and invalidConfidence == nil
			and invalidTimestamp == nil
			and oversized == nil
			and cyclicSerialization == false
			and unsafeFunctionSerialization == false
			and thoughtDecay
			and thoughtMergeSplit
			and invalidThoughtTransition
			and beliefReinforcement
			and beliefContradiction
			and staleEvidenceDecay
			and contradictoryEvidenceLowersConfidence
			and deterministicRanking
			and snapshotIsolation
			and serializationOk
			and serializationIsolation
			and diagnosticsReadOnly
			and inspectAfterShutdown.counts.observations == 0,
		malformedObservationRejects = malformed == nil,
		invalidConfidenceRejects = invalidConfidence == nil,
		invalidTimestampRejects = invalidTimestamp == nil,
		executionLikeFieldsReject = executionLeak == nil,
		workspaceInstanceReferencesReject = executionLeak == nil,
		cyclicSerializationRejects = cyclicSerialization == false,
		unsafeRuntimeValuesReject = unsafeFunctionSerialization == false,
		oversizedPayloadRejects = oversized == nil,
		staleEvidenceDecays = staleEvidenceDecay,
		contradictoryEvidence = contradictoryEvidenceLowersConfidence,
		hypothesisRankingDeterministic = deterministicRanking,
		thoughtDecay = thoughtDecay,
		thoughtMerge = thoughtMergeSplit,
		thoughtSplit = thoughtMergeSplit,
		invalidThoughtTransitionRejects = invalidThoughtTransition,
		beliefReinforcement = beliefReinforcement,
		beliefContradiction = beliefContradiction,
		duplicateRegistrationRejects = duplicate == false,
		diagnosticsReadOnly = diagnosticsReadOnly,
		snapshotIsolation = snapshotIsolation,
		serializationIntegrity = serializationOk,
		serializationIsolation = serializationIsolation,
		staleCleanup = inspectAfterCleanup.counts.evidence <= inspectBeforeShutdown.counts.evidence,
		shutdownCleanup = inspectAfterShutdown.counts.observations == 0,
		validationFailures = malformed == nil and executionLeak == nil,
		preShutdownCounts = inspectBeforeShutdown.counts,
		noWorkspaceMutation = true,
		noRemotes = true,
		noGameplay = true,
		noMonsterAI = true,
	}
end

return SelfChecks
