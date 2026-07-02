--!strict
-- Central bounded state store for Session Runtime Foundation.

local Serialization = require(script.Parent.SessionSerialization)
local Types = require(script.Parent.SessionTypes)
local Validation = require(script.Parent.SessionValidation)

local Runtime = {}

local sessions: { [string]: any } = {}
local playerSessions: { [string]: any } = {}
local parties: { [string]: any } = {}
local readiness: { [string]: any } = {}
local lifecycle: { [string]: any } = {}
local joinLeave: { [string]: any } = {}
local validationFailures: { any } = {}
local snapshotHistory: { any } = {}

local function boundedInsert(list: { any }, value: any, limit: number)
	table.insert(list, value)
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

function Runtime.hasSession(sessionId: string): boolean
	return sessions[sessionId] ~= nil
end

function Runtime.registerSession(schema: any): (boolean, string?)
	local ok, reason = Validation.session(schema)
	if not ok then
		return false, reason
	end
	if Runtime.hasSession(schema.sessionId) then
		return false, "duplicate sessionId"
	end
	if countMap(sessions) >= Types.Limits.MaxSessions then
		return false, "session limit exceeded"
	end
	sessions[schema.sessionId] = Serialization.deepCopy(schema)
	return true, nil
end

function Runtime.registerPlayerSession(record: any): (boolean, string?)
	local ok, reason = Validation.playerSession(record)
	if not ok then
		return false, reason
	end
	if playerSessions[record.playerSessionId] ~= nil then
		return false, "duplicate playerSessionId"
	end
	if countMap(playerSessions) >= Types.Limits.MaxPlayerSessions then
		return false, "player session limit exceeded"
	end
	playerSessions[record.playerSessionId] = Serialization.deepCopy(record)
	return true, nil
end

function Runtime.registerParty(schema: any): (boolean, string?)
	local ok, reason = Validation.party(schema)
	if not ok then
		return false, reason
	end
	if parties[schema.partyId] ~= nil then
		return false, "duplicate partyId"
	end
	if countMap(parties) >= Types.Limits.MaxParties then
		return false, "party limit exceeded"
	end
	parties[schema.partyId] = Serialization.deepCopy(schema)
	return true, nil
end

function Runtime.recordReadiness(record: any): (boolean, string?)
	local ok, reason = Validation.readiness(record)
	if not ok then
		return false, reason
	end
	if
		countMap(readiness) >= Types.Limits.MaxReadinessRecords
		and readiness[record.readinessId] == nil
	then
		return false, "readiness record limit exceeded"
	end
	readiness[record.readinessId] = Serialization.deepCopy(record)
	return true, nil
end

function Runtime.recordLifecycle(record: any): (boolean, string?)
	local ok, reason = Validation.lifecycle(record)
	if not ok then
		return false, reason
	end
	if
		countMap(lifecycle) >= Types.Limits.MaxLifecycleRecords
		and lifecycle[record.lifecycleId] == nil
	then
		return false, "lifecycle record limit exceeded"
	end
	lifecycle[record.lifecycleId] = Serialization.deepCopy(record)
	return true, nil
end

function Runtime.recordJoinLeave(record: any): (boolean, string?)
	local ok, reason = Validation.joinLeave(record)
	if not ok then
		return false, reason
	end
	if
		countMap(joinLeave) >= Types.Limits.MaxJoinLeaveRecords
		and joinLeave[record.joinLeaveId] == nil
	then
		return false, "join/leave record limit exceeded"
	end
	joinLeave[record.joinLeaveId] = Serialization.deepCopy(record)
	return true, nil
end

function Runtime.recordValidationFailure(reason: string, payload: any?)
	boundedInsert(validationFailures, {
		reason = reason,
		payload = Serialization.diagnosticCopy(payload),
	}, Types.Limits.MaxValidationFailures)
end

function Runtime.recordSnapshot(snapshot: any)
	boundedInsert(
		snapshotHistory,
		Serialization.diagnosticCopy(snapshot),
		Types.Limits.MaxSnapshotHistory
	)
end

function Runtime.inspect()
	return Serialization.deepCopy({
		sessions = sessions,
		playerSessions = playerSessions,
		parties = parties,
		readiness = readiness,
		lifecycle = lifecycle,
		joinLeave = joinLeave,
		validationFailures = validationFailures,
		snapshotHistory = snapshotHistory,
		counts = {
			sessions = countMap(sessions),
			playerSessions = countMap(playerSessions),
			parties = countMap(parties),
			readiness = countMap(readiness),
			lifecycle = countMap(lifecycle),
			joinLeave = countMap(joinLeave),
			validationFailures = #validationFailures,
			snapshots = #snapshotHistory,
		},
	})
end

function Runtime.clear()
	table.clear(sessions)
	table.clear(playerSessions)
	table.clear(parties)
	table.clear(readiness)
	table.clear(lifecycle)
	table.clear(joinLeave)
	table.clear(validationFailures)
	table.clear(snapshotHistory)
end

return Runtime
