--!strict

local Config = require(script.Parent.GameplayExecutionConfig)
local Copy = require(script.Parent.Parent.Core.GameplayCopy)

local GameplayExecutionState = {}

local recordsById: { [string]: any } = {}
local recentExecutions: { any } = {}
local recentFailures: { any } = {}
local objectLocks: { [string]: any } = {}
local counters = {
	submitted = 0,
	validated = 0,
	rejected = 0,
	deferred = 0,
	applied = 0,
	failed = 0,
	expired = 0,
	cancelled = 0,
	duplicate = 0,
	dryRun = 0,
}

local function remember(list: { any }, value: any, limit: number)
	table.insert(list, Copy.dictionary(value))
	while #list > limit do
		table.remove(list, 1)
	end
end

function GameplayExecutionState.exists(executionId: string): boolean
	return recordsById[executionId] ~= nil
end

function GameplayExecutionState.record(request: any, status: string, reason: string?)
	local record = {
		request = Copy.dictionary(request),
		status = status,
		reason = reason,
		updatedAt = os.clock(),
	}
	recordsById[request.executionId] = record
	remember(recentExecutions, record, Config.RecentExecutionLimit)
	counters.submitted += if status == "Pending" then 1 else 0
	return Copy.dictionary(record)
end

function GameplayExecutionState.update(executionId: string, status: string, reason: string?)
	local record = recordsById[executionId]
	if record == nil then
		return nil
	end
	record.status = status
	record.reason = reason
	record.updatedAt = os.clock()
	remember(recentExecutions, record, Config.RecentExecutionLimit)
	if status == "Failed" or status == "Rejected" then
		remember(recentFailures, record, Config.RecentFailureLimit)
	end
	if counters[string.lower(status)] ~= nil then
		counters[string.lower(status)] += 1
	end
	return Copy.dictionary(record)
end

function GameplayExecutionState.increment(name: string)
	if counters[name] ~= nil then
		counters[name] += 1
	end
end

function GameplayExecutionState.acquireLock(
	objectId: string,
	executionId: string,
	now: number
): (boolean, string?)
	local existing = objectLocks[objectId]
	if existing ~= nil and existing.expiresAt > now and existing.executionId ~= executionId then
		return false, "target object is execution-locked"
	end
	objectLocks[objectId] = {
		executionId = executionId,
		acquiredAt = now,
		expiresAt = now + Config.ObjectLeaseSeconds,
	}
	return true, nil
end

function GameplayExecutionState.releaseLock(objectId: string, executionId: string?)
	local existing = objectLocks[objectId]
	if existing == nil then
		return
	end
	if executionId == nil or existing.executionId == executionId then
		objectLocks[objectId] = nil
	end
end

function GameplayExecutionState.cleanupExpiredLocks(now: number)
	for objectId, lock in pairs(objectLocks) do
		if lock.expiresAt <= now then
			objectLocks[objectId] = nil
		end
	end
end

function GameplayExecutionState.inspect()
	local recordCount = 0
	for _ in pairs(recordsById) do
		recordCount += 1
	end
	local lockCount = 0
	for _ in pairs(objectLocks) do
		lockCount += 1
	end
	return {
		recordCount = recordCount,
		objectLockCount = lockCount,
		locks = Copy.dictionary(objectLocks),
		recentExecutions = Copy.array(recentExecutions),
		recentFailures = Copy.array(recentFailures),
		counters = table.clone(counters),
	}
end

function GameplayExecutionState.clear()
	table.clear(recordsById)
	table.clear(recentExecutions)
	table.clear(recentFailures)
	table.clear(objectLocks)
	for key in pairs(counters) do
		counters[key] = 0
	end
end

return GameplayExecutionState
