--!strict
-- Bounded state store for Monster AI dry-run execution records.

local Serialization = require(script.Parent.MonsterAISerialization)
local Types = require(script.Parent.MonsterAITypes)

local State = {}

local intentRecords: { any } = {}
local executionRecords: { any } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}
local seenIntentIds: { [string]: boolean } = {}
local monsterStates: { [string]: string } = {}
local counters = {
	registered = 0,
	accepted = 0,
	rejected = 0,
	expired = 0,
	planned = 0,
	dryRunApplied = 0,
	validationFailures = 0,
	observationsEmitted = 0,
}

local function trim(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

function State.registerMonster(monsterId: string)
	monsterStates[monsterId] = "Dormant"
	counters.registered += 1
end

function State.hasIntent(intentId: string): boolean
	return seenIntentIds[intentId] == true
end

function State.markIntent(intentId: string)
	seenIntentIds[intentId] = true
end

function State.recordIntent(intent: any, status: string, reason: string?)
	State.markIntent(intent.intentId)
	if status == Types.IntentStatus.Accepted then
		counters.accepted += 1
	elseif status == Types.IntentStatus.Rejected then
		counters.rejected += 1
	elseif status == Types.IntentStatus.Expired then
		counters.expired += 1
	end
	table.insert(intentRecords, {
		intentId = intent.intentId,
		monsterId = intent.monsterId,
		intentKind = intent.intentKind,
		status = status,
		reason = reason,
		approvedBy = intent.approvedBy,
		approvalId = intent.approvalId,
		sourceSystem = intent.sourceSystem,
		priority = intent.priority,
		createdAt = intent.createdAt,
		expiresAt = intent.expiresAt,
		recordedAt = os.clock(),
	})
	trim(intentRecords, Types.Limits.MaxIntentHistory)
end

function State.recordExecution(record: any)
	counters.planned += if record.status == Types.IntentStatus.Planned then 1 else 0
	counters.dryRunApplied += if record.status == Types.IntentStatus.DryRunApplied then 1 else 0
	monsterStates[record.monsterId] = record.executionKind
	table.insert(executionRecords, Serialization.deepCopy(record))
	trim(executionRecords, Types.Limits.MaxExecutionRecords)
end

function State.recordValidationFailure(reason: string, payload: any?)
	counters.validationFailures += 1
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.deepCopy(payload),
		createdAt = os.clock(),
	})
	trim(validationFailures, Types.Limits.MaxValidationFailures)
end

function State.recordSnapshot(summary: any)
	table.insert(snapshotHistory, Serialization.deepCopy(summary))
	trim(snapshotHistory, Types.Limits.MaxSnapshotHistory)
end

function State.increment(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
	end
end

function State.clear()
	table.clear(intentRecords)
	table.clear(executionRecords)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
	table.clear(seenIntentIds)
	table.clear(monsterStates)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

function State.inspect()
	return {
		monsterStates = Serialization.deepCopy(monsterStates),
		intentRecords = Serialization.deepCopy(intentRecords),
		executionRecords = Serialization.deepCopy(executionRecords),
		validationFailures = Serialization.deepCopy(validationFailures),
		snapshotHistory = Serialization.deepCopy(snapshotHistory),
		counters = table.clone(counters),
		limits = Serialization.deepCopy(Types.Limits),
	}
end

return State
