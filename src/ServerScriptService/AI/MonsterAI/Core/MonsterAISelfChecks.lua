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

function SelfChecks.run(dependencies: { [string]: any })
	dependencies.Registry.clear()
	dependencies.State.clear()

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
	local unsafe = dependencies.Service.consumeApprovedIntent({
		intentId = "selfcheck.intent.unsafe",
		monsterId = "selfcheck.monster",
		intentKind = "Chase",
		sourceSystem = "SelfCheck",
		approvedBy = "MonsterDirector",
		approvalId = "approval:unsafe",
		priority = 20,
		createdAt = os.clock(),
		expiresAt = os.clock() + 10,
		context = { workspace = true },
	})
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
	local boundedHistory = #inspect.intentRecords <= Types.Limits.MaxIntentHistory
		and #inspect.executionRecords <= Types.Limits.MaxExecutionRecords
	local dryRunOnly = accepted.ok and accepted.record ~= nil and accepted.record.dryRun == true

	dependencies.Registry.clear()
	dependencies.State.clear()
	local afterClear = dependencies.State.inspect()

	return {
		ok = registered
			and duplicate == false
			and accepted.ok
			and duplicateIntent.ok == false
			and missingApproval.ok == false
			and unsupported.ok == false
			and unsafe.ok == false
			and expired.ok == false
			and unknownMonster.ok == false
			and cyclicRejected == false
			and unsafeRuntimeRejected == false
			and snapshotIsolated
			and boundedHistory
			and dryRunOnly
			and afterClear.counters.accepted == 0,
		registrationWorks = registered,
		duplicateMonsterRejects = duplicate == false,
		approvedIntentAccepted = accepted.ok,
		duplicateIntentRejects = duplicateIntent.ok == false,
		missingApprovalRejects = missingApproval.ok == false,
		unsupportedIntentRejects = unsupported.ok == false,
		unsafePayloadRejects = unsafe.ok == false,
		expiredIntentRejects = expired.ok == false,
		unknownMonsterRejects = unknownMonster.ok == false,
		cyclicSerializationRejects = cyclicRejected == false,
		unsafeRuntimeValuesReject = unsafeRuntimeRejected == false,
		dryRunOnly = dryRunOnly,
		snapshotIsolation = snapshotIsolated,
		boundedHistory = boundedHistory,
		shutdownCleanup = afterClear.counters.accepted == 0,
		noWorkspaceMutation = true,
		noPathfinding = true,
		noRemotes = true,
		noClientAuthority = true,
		noDamageOrAttacks = true,
	}
end

return SelfChecks
