--!strict

local Evidence = require(script.Parent.RobloxRenderingSessionEvidence)
local Metrics = require(script.Parent.RobloxRenderingSessionMetrics)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RobloxRenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Ownership = {}
local records = {}
local nextOrdinal = 0

function Ownership.claim(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	local current = records[session.rendererId]
	if current ~= nil and current.currentSession ~= nil and current.currentSession ~= sessionId then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.OwnershipConflict,
			message = "renderer ownership conflict",
		}
	end
	nextOrdinal += 1
	records[session.rendererId] = {
		rendererId = session.rendererId,
		currentSession = sessionId,
		reservationOwner = session.owner,
		assignmentOrdinal = nextOrdinal,
		ownershipVersion = (current and current.ownershipVersion or 0) + 1,
		runtimeMetadata = Serialization.deepCopy(session.runtimeMetadata),
	}
	Metrics.increment("ownershipTransfers")
	Evidence.record("ownership transferred", records[session.rendererId])
	return {
		ok = true,
		code = "Ok",
		ownership = Serialization.deepCopy(records[session.rendererId]),
	}
end

function Ownership.release(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	local current = records[session.rendererId]
	if current == nil or current.currentSession ~= sessionId then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.OwnershipConflict,
			message = "renderer ownership conflict",
		}
	end
	current.currentSession = nil
	current.reservationOwner = nil
	current.ownershipVersion += 1
	Evidence.record("ownership transferred", current)
	return { ok = true, code = "Ok", ownership = Serialization.deepCopy(current) }
end

function Ownership.inspect()
	local result = {}
	for _, record in pairs(records) do
		result[#result + 1] = Serialization.deepCopy(record)
	end
	table.sort(result, function(left, right)
		return left.rendererId < right.rendererId
	end)
	return result
end

function Ownership.clear()
	table.clear(records)
	nextOrdinal = 0
end

return Ownership
