--!strict
-- Bounded state store for interaction schemas.

local Serialization = require(script.Parent.InteractionSerialization)
local Types = require(script.Parent.InteractionTypes)

local ObjectRuntime = {}

local interactions: { [string]: any } = {}
local interactionOrder: { string } = {}
local eligibility: { [string]: any } = {}
local intents: { any } = {}
local locks: { [string]: any } = {}
local cooldowns: { [string]: any } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function trimList(list: { any }, limit: number)
	while #list > limit do
		table.remove(list, 1)
	end
end

local function countMap(map: { [string]: any }): number
	local count = 0
	for _ in pairs(map) do
		count += 1
	end
	return count
end

local function removeRelated(interactionId: string)
	interactions[interactionId] = nil
	eligibility[interactionId] = nil
	locks[interactionId] = nil
	cooldowns[interactionId] = nil
	for index = #interactionOrder, 1, -1 do
		if interactionOrder[index] == interactionId then
			table.remove(interactionOrder, index)
		end
	end
end

local function trimInteractions()
	while #interactionOrder > Types.Limits.MaxInteractions do
		local id = table.remove(interactionOrder, 1)
		if id ~= nil then
			removeRelated(id)
		end
	end
end

function ObjectRuntime.exists(interactionId: string): boolean
	return interactions[interactionId] ~= nil
end

function ObjectRuntime.add(schema: any)
	interactions[schema.interactionId] = Serialization.deepCopy(schema)
	table.insert(interactionOrder, schema.interactionId)
	eligibility[schema.interactionId] = Serialization.deepCopy(schema.eligibility or {})
	locks[schema.interactionId] = Serialization.deepCopy(schema.lockState or {})
	cooldowns[schema.interactionId] = Serialization.deepCopy(schema.cooldown or {})
	trimInteractions()
end

function ObjectRuntime.addIntent(intent: any)
	table.insert(intents, Serialization.deepCopy(intent))
	trimList(intents, Types.Limits.MaxIntentRecords)
end

function ObjectRuntime.setLock(interactionId: string, lockState: any)
	locks[interactionId] = Serialization.deepCopy(lockState)
end

function ObjectRuntime.setCooldown(interactionId: string, cooldown: any)
	cooldowns[interactionId] = Serialization.deepCopy(cooldown)
end

function ObjectRuntime.recordValidationFailure(reason: string, payload: any?)
	table.insert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
		createdAt = os.clock(),
	})
	trimList(validationFailures, Types.Limits.MaxValidationFailures)
end

function ObjectRuntime.recordSnapshot(summary: any)
	table.insert(snapshotHistory, Serialization.deepCopy(summary))
	trimList(snapshotHistory, Types.Limits.MaxSnapshotHistory)
end

function ObjectRuntime.inspect()
	return {
		interactionCount = countMap(interactions),
		eligibilityCount = countMap(eligibility),
		intentCount = #intents,
		lockCount = countMap(locks),
		cooldownCount = countMap(cooldowns),
		interactions = Serialization.deepCopy(interactions),
		eligibility = Serialization.deepCopy(eligibility),
		intents = Serialization.deepCopy(intents),
		locks = Serialization.deepCopy(locks),
		cooldowns = Serialization.deepCopy(cooldowns),
		validationFailureCount = #validationFailures,
		validationFailures = Serialization.deepCopy(validationFailures),
		snapshotCount = #snapshotHistory,
		snapshotHistory = Serialization.deepCopy(snapshotHistory),
		limits = Serialization.deepCopy(Types.Limits),
	}
end

function ObjectRuntime.clear()
	table.clear(interactions)
	table.clear(interactionOrder)
	table.clear(eligibility)
	table.clear(intents)
	table.clear(locks)
	table.clear(cooldowns)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return ObjectRuntime
