--!strict
-- Bounded state store for interaction schemas.

local Serialization = require(script.Parent.InteractionSerialization)
local Types = require(script.Parent.InteractionTypes)

local ObjectRuntime = {}

local interactions: { [string]: any } = {}
local interactionOrder: { string } = {}
local targets: { [string]: any } = {}
local targetOrder: { string } = {}
local eligibility: { [string]: any } = {}
local intents: { any } = {}
local locks: { [string]: any } = {}
local cooldowns: { [string]: any } = {}
local sessions: { [string]: any } = {}
local sessionOrder: { string } = {}
local evidence: { any } = {}
local requestWindowsByPlayer: { [string]: { number } } = {}
local requestIdsByPlayer: { [string]: { [string]: number } } = {}
local activeSessionByInteraction: { [string]: string } = {}
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

function ObjectRuntime.targetExists(targetId: string): boolean
	return targets[targetId] ~= nil
end

function ObjectRuntime.getInteraction(interactionId: string): any?
	return Serialization.deepCopy(interactions[interactionId])
end

function ObjectRuntime.getTarget(targetId: string): any?
	return Serialization.deepCopy(targets[targetId])
end

function ObjectRuntime.add(schema: any)
	interactions[schema.interactionId] = Serialization.deepCopy(schema)
	table.insert(interactionOrder, schema.interactionId)
	eligibility[schema.interactionId] = Serialization.deepCopy(schema.eligibility or {})
	locks[schema.interactionId] = Serialization.deepCopy(schema.lockState or {})
	cooldowns[schema.interactionId] = Serialization.deepCopy(schema.cooldown or {})
	trimInteractions()
end

local function trimTargets()
	while #targetOrder > Types.Limits.MaxTargets do
		local id = table.remove(targetOrder, 1)
		if id ~= nil then
			targets[id] = nil
		end
	end
end

local function trimSessions()
	while #sessionOrder > Types.Limits.MaxSessions do
		local id = table.remove(sessionOrder, 1)
		if id ~= nil then
			sessions[id] = nil
		end
	end
end

function ObjectRuntime.addTarget(target: any)
	targets[target.targetId] = Serialization.deepCopy(target)
	table.insert(targetOrder, target.targetId)
	trimTargets()
end

function ObjectRuntime.removeInteraction(interactionId: string): boolean
	if interactions[interactionId] == nil then
		return false
	end
	removeRelated(interactionId)
	activeSessionByInteraction[interactionId] = nil
	return true
end

function ObjectRuntime.removeTarget(targetId: string): boolean
	if targets[targetId] == nil then
		return false
	end
	targets[targetId] = nil
	for index = #targetOrder, 1, -1 do
		if targetOrder[index] == targetId then
			table.remove(targetOrder, index)
		end
	end
	return true
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

function ObjectRuntime.isRateLimited(playerKey: string): boolean
	local now = os.clock()
	local window = requestWindowsByPlayer[playerKey]
	if window == nil then
		window = {}
		requestWindowsByPlayer[playerKey] = window
	end
	for index = #window, 1, -1 do
		if now - window[index] > Types.Limits.MaxRequestWindowSeconds then
			table.remove(window, index)
		end
	end
	if #window >= Types.Limits.MaxRequestsPerPlayerWindow then
		return true
	end
	table.insert(window, now)
	return false
end

function ObjectRuntime.isDuplicateRequest(playerKey: string, requestId: string): boolean
	local now = os.clock()
	local requests = requestIdsByPlayer[playerKey]
	if requests == nil then
		requests = {}
		requestIdsByPlayer[playerKey] = requests
	end
	local seenAt = requests[requestId]
	requests[requestId] = now
	for id, createdAt in pairs(requests) do
		if now - createdAt > 30 then
			requests[id] = nil
		end
	end
	return seenAt ~= nil
end

function ObjectRuntime.hasContention(interactionId: string): boolean
	return activeSessionByInteraction[interactionId] ~= nil
end

function ObjectRuntime.beginContention(interactionId: string, sessionId: string)
	activeSessionByInteraction[interactionId] = sessionId
end

function ObjectRuntime.endContention(interactionId: string, sessionId: string)
	if activeSessionByInteraction[interactionId] == sessionId then
		activeSessionByInteraction[interactionId] = nil
	end
end

function ObjectRuntime.addSession(session: any)
	sessions[session.sessionId] = Serialization.deepCopy(session)
	table.insert(sessionOrder, session.sessionId)
	trimSessions()
end

function ObjectRuntime.updateSession(sessionId: string, patch: any)
	local session = sessions[sessionId]
	if session == nil then
		return
	end
	for key, value in pairs(patch) do
		session[key] = Serialization.deepCopy(value)
	end
end

function ObjectRuntime.recordEvidence(record: any)
	table.insert(evidence, Serialization.deepCopy(record))
	trimList(evidence, Types.Limits.MaxEvidenceRecords)
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
		targetCount = countMap(targets),
		eligibilityCount = countMap(eligibility),
		intentCount = #intents,
		lockCount = countMap(locks),
		cooldownCount = countMap(cooldowns),
		sessionCount = countMap(sessions),
		evidenceCount = #evidence,
		activeContentionCount = countMap(activeSessionByInteraction),
		interactions = Serialization.deepCopy(interactions),
		targets = Serialization.deepCopy(targets),
		eligibility = Serialization.deepCopy(eligibility),
		intents = Serialization.deepCopy(intents),
		locks = Serialization.deepCopy(locks),
		cooldowns = Serialization.deepCopy(cooldowns),
		sessions = Serialization.deepCopy(sessions),
		evidence = Serialization.deepCopy(evidence),
		activeContention = Serialization.deepCopy(activeSessionByInteraction),
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
	table.clear(targets)
	table.clear(targetOrder)
	table.clear(eligibility)
	table.clear(intents)
	table.clear(locks)
	table.clear(cooldowns)
	table.clear(sessions)
	table.clear(sessionOrder)
	table.clear(evidence)
	table.clear(requestWindowsByPlayer)
	table.clear(requestIdsByPlayer)
	table.clear(activeSessionByInteraction)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return ObjectRuntime
