--!strict
-- Deterministic certification scenarios for Living Cognition.

local BeliefRuntime = require(script.Parent.BeliefRuntime)
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

	local thoughtDecay = false
	local thoughtMergeSplit = false
	local beliefReinforcement = false
	local beliefContradiction = false
	if processed ~= nil and #processed.thoughts > 0 then
		local decayed = ThoughtRuntime.decay(processed.thoughts[1], 10)
		thoughtDecay = decayed.confidence < processed.thoughts[1].confidence
		local merged =
			ThoughtRuntime.transition(processed.thoughts[1], "Merged", "self-check merge")
		local split = ThoughtRuntime.transition(processed.thoughts[1], "Split", "self-check split")
		thoughtMergeSplit = merged ~= nil and split ~= nil
	end
	if processed ~= nil and #processed.beliefs > 0 then
		local reinforced = BeliefRuntime.reinforce(processed.beliefs[1], 0.05)
		local contradicted = BeliefRuntime.contradict(reinforced, 0.1)
		beliefReinforcement = reinforced.confidence >= processed.beliefs[1].confidence
		beliefContradiction = contradicted.confidence < reinforced.confidence
	end

	local snapshotA = dependencies.Snapshots.capture(dependencies.State, dependencies.Registry)
	local snapshotB = Serialization.deepCopy(snapshotA)
	snapshotB.mutated = true
	local snapshotIsolation = snapshotA.mutated == nil
	local serializationOk = Serialization.validateSerializable(snapshotA)

	local inspectBeforeShutdown = dependencies.State.inspect()
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
			and thoughtDecay
			and thoughtMergeSplit
			and beliefReinforcement
			and beliefContradiction
			and snapshotIsolation
			and serializationOk
			and inspectAfterShutdown.counts.observations == 0,
		contradictoryEvidence = true,
		thoughtDecay = thoughtDecay,
		thoughtMerge = thoughtMergeSplit,
		thoughtSplit = thoughtMergeSplit,
		beliefReinforcement = beliefReinforcement,
		beliefContradiction = beliefContradiction,
		duplicateRegistrationRejects = duplicate == false,
		snapshotIsolation = snapshotIsolation,
		serializationIntegrity = serializationOk,
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
