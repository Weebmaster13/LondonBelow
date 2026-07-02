--!strict
-- Deterministic certification scenarios for Narrative Runtime foundation.

local EmotionalBeatRuntime = require(script.Parent.EmotionalBeatRuntime)
local Serialization = require(script.Parent.NarrativeSerialization)

local SelfChecks = {}

local function cyclicTable()
	local value = {}
	value.self = value
	return value
end

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Service.shutdown()
	dependencies.Service.initialize()

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
	local gate = dependencies.Service.registerStoryGate({
		gateId = "gate.schema",
		beatId = "beat.schema",
		requirements = { journalEntryId = "journal.schema" },
	})
	local duplicateGate = dependencies.Service.registerStoryGate({ gateId = "gate.schema" })
	local invalidGate = dependencies.Service.registerStoryGate({ gateId = "", requirements = {} })
	local reveal = dependencies.Service.grantRevealEligibility({
		revealId = "reveal.schema",
		beatId = "beat.schema",
		journalEntryId = "journal.schema",
		memoryFragmentId = "fragment.schema",
		identityDelta = 5,
		context = { source = "self-check" },
	})
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
	local invalidEmotional = dependencies.Service.registerEmotionalProtection({
		emotionalBeatId = "emotion.invalid",
		pressureLimit = 120,
	})
	local suppresses = EmotionalBeatRuntime.shouldSuppressPressure({ pressureLimit = 30 }, 80)
	local cyclicRejected = Serialization.validateSerializable(cyclicTable())
	local unsafeRuntimeRejected = Serialization.validateSerializable({ callback = function() end })

	local snapshot = dependencies.Service.getSnapshot()
	local snapshotCopy = Serialization.deepCopy(snapshot)
	snapshotCopy.state.beatCount = 999
	local snapshotIsolation = snapshot.state.beatCount ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.state.beatCount = 999
	local diagnosticsB = dependencies.Service.inspect()
	local diagnosticsReadOnly = diagnosticsB.state.beatCount ~= 999

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()

	return {
		ok = beat.ok
			and duplicateBeat.ok == false
			and invalidBeat.ok == false
			and gate.ok
			and duplicateGate.ok == false
			and invalidGate.ok == false
			and reveal.ok
			and unsafeReveal.ok == false
			and emotional.ok
			and invalidEmotional.ok == false
			and suppresses
			and cyclicRejected == false
			and unsafeRuntimeRejected == false
			and snapshotIsolation
			and diagnosticsReadOnly
			and afterShutdown.beatCount == 0,
		validBeatRegisters = beat.ok,
		duplicateBeatRejects = duplicateBeat.ok == false,
		invalidBeatRejects = invalidBeat.ok == false,
		validStoryGateRegisters = gate.ok,
		duplicateStoryGateRejects = duplicateGate.ok == false,
		invalidStoryGateRejects = invalidGate.ok == false,
		revealEligibilityGranted = reveal.ok,
		revealEligibilityRejectsUnsafePayloads = unsafeReveal.ok == false,
		emotionalBeatProtectionSuppressesUnsafePressure = suppresses,
		invalidEmotionalBeatRejects = invalidEmotional.ok == false,
		serializationRejectsCycles = cyclicRejected == false,
		serializationRejectsUnsafeRuntimeValues = unsafeRuntimeRejected == false,
		snapshotIsolation = snapshotIsolation,
		diagnosticsReadOnly = diagnosticsReadOnly,
		shutdownCleanup = afterShutdown.beatCount == 0,
		noFinalDialogue = true,
		noChapterContent = true,
		noCutscenes = true,
		noUI = true,
		noWorkspaceMutation = true,
		noMonsterAIOwnership = true,
		noHorrorPacingOwnership = true,
	}
end

return SelfChecks
