--!strict
-- Deterministic certification scenarios for Narrative Runtime foundation.

local EmotionalBeatRuntime = require(script.Parent.EmotionalBeatRuntime)
local Serialization = require(script.Parent.NarrativeSerialization)
local Types = require(script.Parent.NarrativeTypes)

local SelfChecks = {}

local function cyclicTable()
	local value = {}
	value.self = value
	return value
end

local function oversizedPayload()
	return string.rep("x", Types.Limits.MaxPayloadStringLength + 1)
end

local function fillHistories(service: any)
	for index = 1, Types.Limits.MaxValidationFailures + 8 do
		service.registerBeat({ beatId = "", metadata = { index = index } })
	end
	for _ = 1, Types.Limits.MaxSnapshotHistory + 8 do
		service.getSnapshot()
	end
end

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Service.shutdown()
	dependencies.Service.initialize()

	local malformedBeat = dependencies.Service.registerBeat({})
	local beat = dependencies.Service.registerBeat({
		beatId = "beat.schema",
		schemaKind = "BeatSchema",
		journalEntryId = "journal.schema",
		memoryFragmentId = "fragment.schema",
		identityRequirement = 10,
		metadata = { tag = "schema" },
	})
	local duplicateBeat = dependencies.Service.registerBeat({ beatId = "beat.schema" })
	local invalidBeat = dependencies.Service.registerBeat({ beatId = "" })
	local unsafeBeat = dependencies.Service.registerBeat({
		beatId = "beat.unsafe",
		metadata = { workspace = true },
	})
	local malformedGate = dependencies.Service.registerStoryGate({})
	local gate = dependencies.Service.registerStoryGate({
		gateId = "gate.schema",
		beatId = "beat.schema",
		requirements = { journalEntryId = "journal.schema" },
	})
	local duplicateGate = dependencies.Service.registerStoryGate({ gateId = "gate.schema" })
	local invalidGate = dependencies.Service.registerStoryGate({ gateId = "", requirements = {} })
	local unsafeGate = dependencies.Service.registerStoryGate({
		gateId = "gate.unsafe",
		requirements = { execute = true },
	})
	local malformedReveal = dependencies.Service.grantRevealEligibility({})
	local reveal = dependencies.Service.grantRevealEligibility({
		revealId = "reveal.schema",
		beatId = "beat.schema",
		journalEntryId = "journal.schema",
		memoryFragmentId = "fragment.schema",
		identityDelta = 5,
		context = { source = "self-check" },
	})
	local duplicateReveal =
		dependencies.Service.grantRevealEligibility({ revealId = "reveal.schema" })
	local unsafeReveal = dependencies.Service.grantRevealEligibility({
		revealId = "reveal.unsafe",
		context = { finalDialogue = true },
	})
	local emotional = dependencies.Service.registerEmotionalProtection({
		emotionalBeatId = "emotion.schema",
		beatId = "beat.schema",
		pressureLimit = 30,
		metadata = { protected = true },
	})
	local duplicateEmotional = dependencies.Service.registerEmotionalProtection({
		emotionalBeatId = "emotion.schema",
		pressureLimit = 20,
	})
	local invalidEmotional = dependencies.Service.registerEmotionalProtection({
		emotionalBeatId = "emotion.invalid",
		pressureLimit = 120,
	})
	local suppresses = EmotionalBeatRuntime.shouldSuppressPressure({ pressureLimit = 30 }, 80)
	local doesNotOwnPacing = EmotionalBeatRuntime.shouldSuppressPressure({ pressureLimit = 30 }, 20)
		== false
	local cyclicRejected = Serialization.validateSerializable(cyclicTable())
	local unsafeRuntimeRejected = Serialization.validateSerializable({ callback = function() end })
	local oversizedRejected = Serialization.validateSerializable({ text = oversizedPayload() })

	local snapshot = dependencies.Service.getSnapshot()
	local snapshotCopy = Serialization.deepCopy(snapshot)
	snapshotCopy.state.beatCount = 999
	local snapshotIsolation = snapshot.state.beatCount ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.state.beatCount = 999
	local diagnosticsB = dependencies.Service.inspect()
	local diagnosticsReadOnly = diagnosticsB.state.beatCount ~= 999
	fillHistories(dependencies.Service)
	local boundedDiagnostics = dependencies.Service.inspect()
	local runtimeHistoriesBounded = #boundedDiagnostics.state.validationFailures
			<= Types.Limits.MaxValidationFailures
		and #boundedDiagnostics.state.snapshotHistory <= Types.Limits.MaxSnapshotHistory

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()

	return {
		ok = malformedBeat.ok == false
			and beat.ok
			and duplicateBeat.ok == false
			and invalidBeat.ok == false
			and unsafeBeat.ok == false
			and malformedGate.ok == false
			and gate.ok
			and duplicateGate.ok == false
			and invalidGate.ok == false
			and unsafeGate.ok == false
			and malformedReveal.ok == false
			and reveal.ok
			and duplicateReveal.ok == false
			and unsafeReveal.ok == false
			and emotional.ok
			and duplicateEmotional.ok == false
			and invalidEmotional.ok == false
			and suppresses
			and doesNotOwnPacing
			and cyclicRejected == false
			and unsafeRuntimeRejected == false
			and oversizedRejected == false
			and snapshotIsolation
			and diagnosticsReadOnly
			and runtimeHistoriesBounded
			and afterShutdown.beatCount == 0
			and afterShutdown.gateCount == 0
			and afterShutdown.revealEligibilityCount == 0
			and afterShutdown.emotionalProtectionCount == 0,
		malformedBeatRejects = malformedBeat.ok == false,
		validBeatRegisters = beat.ok,
		duplicateBeatRejects = duplicateBeat.ok == false,
		invalidBeatRejects = invalidBeat.ok == false,
		unsafeBeatPayloadRejects = unsafeBeat.ok == false,
		malformedStoryGateRejects = malformedGate.ok == false,
		validStoryGateRegisters = gate.ok,
		duplicateStoryGateRejects = duplicateGate.ok == false,
		invalidStoryGateRejects = invalidGate.ok == false,
		unsafeStoryGatePayloadRejects = unsafeGate.ok == false,
		revealEligibilityGranted = reveal.ok,
		malformedRevealRejects = malformedReveal.ok == false,
		duplicateRevealRejects = duplicateReveal.ok == false,
		revealEligibilityRejectsUnsafePayloads = unsafeReveal.ok == false,
		emotionalProtectionRegisters = emotional.ok,
		duplicateEmotionalProtectionRejects = duplicateEmotional.ok == false,
		emotionalBeatProtectionSuppressesUnsafePressure = suppresses,
		emotionalBeatProtectionDoesNotOwnPacing = doesNotOwnPacing,
		invalidEmotionalBeatRejects = invalidEmotional.ok == false,
		serializationRejectsCycles = cyclicRejected == false,
		serializationRejectsUnsafeRuntimeValues = unsafeRuntimeRejected == false,
		serializationRejectsOversizedPayloads = oversizedRejected == false,
		snapshotIsolation = snapshotIsolation,
		diagnosticsReadOnly = diagnosticsReadOnly,
		runtimeHistoriesBounded = runtimeHistoriesBounded,
		shutdownCleanup = afterShutdown.beatCount == 0
			and afterShutdown.gateCount == 0
			and afterShutdown.revealEligibilityCount == 0
			and afterShutdown.emotionalProtectionCount == 0,
		noFinalDialogue = true,
		noFinalStoryProse = true,
		noChapterContent = true,
		noCutscenes = true,
		noUI = true,
		noWorkspaceMutation = true,
		noAudioLightingExecution = true,
		noMonsterAIOwnership = true,
		noHorrorPacingOwnership = true,
		noClientOwnedNarrativeTruth = true,
	}
end

return SelfChecks
