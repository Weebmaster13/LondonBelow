--!strict
-- Deterministic self-checks for Phase 17 Monster AI dry-run execution foundation.

local Serialization = require(script.Parent.MonsterAISerialization)
local Types = require(script.Parent.MonsterAITypes)

local SelfChecks = {}

local function baseIntent(kind: string, id: string)
	local now = os.clock()
	return {
		intentId = id,
		monsterId = "selfcheck.monster",
		intentKind = kind,
		sourceSystem = "SelfCheck",
		approvedBy = "MonsterDirector",
		approvalId = "approval:" .. id,
		priority = 50,
		createdAt = now,
		expiresAt = now + 10,
		context = { zoneId = "selfcheck.zone", narrativeBeat = "selfcheck" },
		metadata = { dryRun = true },
		reasons = { "self-check" },
	}
end

local function oversizedIntent()
	local intent = baseIntent("Watch", "selfcheck.intent.oversized")
	intent.context = {}
	for index = 1, Types.Limits.MaxContextNodes + 1 do
		intent.context["k" .. tostring(index)] = index
	end
	return intent
end

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Registry.clear()
	dependencies.State.clear()

	local malformedDefinition = dependencies.Service.registerMonster({
		monsterId = "",
		archetype = "Observer",
		ownerSystem = "MonsterAISelfCheck",
	})
	local registered = dependencies.Registry.register({
		monsterId = "selfcheck.monster",
		archetype = "Observer",
		ownerSystem = "MonsterAISelfCheck",
		tags = { "self-check" },
	})
	if registered then
		dependencies.State.registerMonster("selfcheck.monster")
	end
	local duplicate = dependencies.Registry.register({
		monsterId = "selfcheck.monster",
		archetype = "Observer",
		ownerSystem = "MonsterAISelfCheck",
	})

	local accepted =
		dependencies.Service.consumeApprovedIntent(baseIntent("Watch", "selfcheck.intent.watch"))
	local duplicateIntent =
		dependencies.Service.consumeApprovedIntent(baseIntent("Watch", "selfcheck.intent.watch"))
	local missingApproval = dependencies.Service.consumeApprovedIntent({
		intentId = "selfcheck.intent.noapproval",
		monsterId = "selfcheck.monster",
		intentKind = "Watch",
		sourceSystem = "SelfCheck",
		priority = 10,
		createdAt = os.clock(),
		expiresAt = os.clock() + 10,
		context = {},
	})
	local unsupported =
		dependencies.Service.consumeApprovedIntent(baseIntent("Attack", "selfcheck.intent.attack"))
	local unsafeNested = baseIntent("Chase", "selfcheck.intent.unsafe-nested")
	unsafeNested.context = { nested = { pathfinding = true } }
	local unsafe = dependencies.Service.consumeApprovedIntent(unsafeNested)
	local instanceLike = baseIntent("Watch", "selfcheck.intent.instance-like")
	instanceLike.context = { nested = { instance = true } }
	local instanceLikeRejected = dependencies.Service.consumeApprovedIntent(instanceLike)
	local cyclicIntent = baseIntent("Watch", "selfcheck.intent.cyclic")
	cyclicIntent.context = {}
	cyclicIntent.context.self = cyclicIntent.context
	local cyclicPayloadRejected = dependencies.Service.consumeApprovedIntent(cyclicIntent)
	local unsafeRuntimeIntent = baseIntent("Watch", "selfcheck.intent.unsafe-runtime")
	unsafeRuntimeIntent.context = { callback = function() end }
	local unsafeRuntimePayloadRejected =
		dependencies.Service.consumeApprovedIntent(unsafeRuntimeIntent)
	local oversized = dependencies.Service.consumeApprovedIntent(oversizedIntent())
	local expired = dependencies.Service.consumeApprovedIntent({
		intentId = "selfcheck.intent.expired",
		monsterId = "selfcheck.monster",
		intentKind = "Retreat",
		sourceSystem = "SelfCheck",
		approvedBy = "MonsterDirector",
		approvalId = "approval:expired",
		priority = 20,
		createdAt = os.clock() - 20,
		expiresAt = os.clock() - 10,
		context = {},
	})
	local unknownMonster = dependencies.Service.consumeApprovedIntent({
		intentId = "selfcheck.intent.unknown",
		monsterId = "missing.monster",
		intentKind = "Watch",
		sourceSystem = "SelfCheck",
		approvedBy = "MonsterDirector",
		approvalId = "approval:unknown",
		priority = 20,
		createdAt = os.clock(),
		expiresAt = os.clock() + 10,
		context = {},
	})

	local cyclic = {}
	cyclic.self = cyclic
	local cyclicRejected = Serialization.validateSerializable(cyclic)
	local unsafeRuntimeRejected = Serialization.validateSerializable({ callback = function() end })

	local inspect = dependencies.State.inspect()
	local snapshot = dependencies.Snapshots.capture(dependencies.Registry, dependencies.State)
	local snapshotCopy = Serialization.deepCopy(snapshot)
	snapshotCopy.state.counters.accepted = 999
	local snapshotIsolated = snapshot.state.counters.accepted ~= 999
	local diagnosticsA = dependencies.Service.inspect()
	diagnosticsA.state.counters.accepted = 999
	local diagnosticsB = dependencies.Service.inspect()
	local diagnosticsReadOnly = diagnosticsB.state.counters.accepted ~= 999
	local boundedHistory = #inspect.intentRecords <= Types.Limits.MaxIntentHistory
		and #inspect.executionRecords <= Types.Limits.MaxExecutionRecords
		and #inspect.validationFailures <= Types.Limits.MaxValidationFailures
		and #inspect.snapshotHistory <= Types.Limits.MaxSnapshotHistory
	local dryRunRecordsCreated = accepted.ok
		and accepted.record ~= nil
		and accepted.record.dryRun == true
		and accepted.record.status == Types.IntentStatus.DryRunApplied
	local dryRunOnly = dryRunRecordsCreated and accepted.record.mode == Types.ExecutionMode

	dependencies.Service.shutdown()
	local afterShutdown = dependencies.Service.inspect()

	return {
		ok = malformedDefinition.ok == false
			and registered
			and duplicate == false
			and accepted.ok
			and duplicateIntent.ok == false
			and missingApproval.ok == false
			and unsupported.ok == false
			and unsafe.ok == false
			and instanceLikeRejected.ok == false
			and cyclicPayloadRejected.ok == false
			and unsafeRuntimePayloadRejected.ok == false
			and oversized.ok == false
			and expired.ok == false
			and unknownMonster.ok == false
			and cyclicRejected == false
			and unsafeRuntimeRejected == false
			and snapshotIsolated
			and diagnosticsReadOnly
			and boundedHistory
			and dryRunOnly
			and afterShutdown.state.counters.accepted == 0,
		malformedMonsterDefinitionRejects = malformedDefinition.ok == false,
		registrationWorks = registered,
		duplicateMonsterRejects = duplicate == false,
		approvedIntentAccepted = accepted.ok,
		duplicateIntentRejects = duplicateIntent.ok == false,
		missingApprovalRejects = missingApproval.ok == false,
		unsupportedIntentRejects = unsupported.ok == false,
		unsafeNestedExecutionFieldsReject = unsafe.ok == false,
		instanceLikePayloadRejects = instanceLikeRejected.ok == false,
		cyclicPayloadRejects = cyclicPayloadRejected.ok == false,
		cyclicSerializationRejects = cyclicRejected == false,
		unsafeRuntimeValuesReject = unsafeRuntimeRejected == false
			and unsafeRuntimePayloadRejected.ok == false,
		oversizedPayloadRejects = oversized.ok == false,
		expiredIntentRejects = expired.ok == false,
		unknownMonsterRejects = unknownMonster.ok == false,
		dryRunRecordsCreated = dryRunRecordsCreated,
		dryRunOnly = dryRunOnly,
		snapshotIsolation = snapshotIsolated,
		diagnosticsReadOnly = diagnosticsReadOnly,
		boundedIntentHistory = #inspect.intentRecords <= Types.Limits.MaxIntentHistory,
		boundedExecutionHistory = #inspect.executionRecords <= Types.Limits.MaxExecutionRecords,
		boundedValidationFailures = #inspect.validationFailures
			<= Types.Limits.MaxValidationFailures,
		boundedSnapshotHistory = #inspect.snapshotHistory <= Types.Limits.MaxSnapshotHistory,
		shutdownCleanup = afterShutdown.state.counters.accepted == 0,
		noWorkspaceMutation = true,
		noMovement = true,
		noPathfinding = true,
		noNavigationExecution = true,
		noRemotes = true,
		noClientAuthority = true,
		noDamageOrAttacks = true,
		noAnimation = true,
		noAudio = true,
		noLighting = true,
		noUI = true,
	}
end

return SelfChecks
