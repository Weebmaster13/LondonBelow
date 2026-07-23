--!strict

local Evidence = require(script.Parent.RobloxRenderingSessionEvidence)
local Metrics = require(script.Parent.RobloxRenderingSessionMetrics)
local Ownership = require(script.Parent.RobloxRendererOwnership)
local Serialization = require(script.Parent.PresentationSerialization)
local Sessions = require(script.Parent.RobloxRenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Reservation = {}
local records = {}

function Reservation.reserve(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	local current = records[session.rendererId]
	if
		current ~= nil
		and current.state ~= Types.RobloxRendererReservationState.Released
		and current.state ~= Types.RobloxRendererReservationState.Expired
	then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.ReservationConflict,
			message = "renderer reservation conflict",
		}
	end
	local ownership = Ownership.claim(sessionId)
	if not ownership.ok then
		return ownership
	end
	local record = {
		rendererId = session.rendererId,
		robloxRenderingSessionId = sessionId,
		owner = session.owner,
		state = Types.RobloxRendererReservationState.Reserved,
		reservationPriority = session.runtimePriority,
	}
	records[session.rendererId] = record
	Sessions.update(sessionId, {
		reservationState = Types.RobloxRendererReservationState.Reserved,
		sessionState = Types.RobloxRenderingSessionState.Reserved,
		lifecycleState = Types.RobloxRenderingSessionState.Reserved,
	})
	Metrics.increment("reservationCount")
	Evidence.record("renderer reserved", record)
	return { ok = true, code = "Ok", reservation = Serialization.deepCopy(record) }
end

function Reservation.activate(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	local record = records[session.rendererId]
	if record == nil or record.robloxRenderingSessionId ~= sessionId then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.ReservationConflict,
			message = "renderer reservation conflict",
		}
	end
	record.state = Types.RobloxRendererReservationState.Active
	Sessions.update(sessionId, { reservationState = Types.RobloxRendererReservationState.Active })
	return { ok = true, code = "Ok", reservation = Serialization.deepCopy(record) }
end

function Reservation.release(sessionId: string)
	local session = Sessions.get(sessionId)
	if session == nil then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.UnknownSession,
			message = "unknown session",
		}
	end
	local record = records[session.rendererId]
	if record == nil or record.robloxRenderingSessionId ~= sessionId then
		return {
			ok = false,
			code = Types.RobloxRenderingSessionFailureType.ReservationConflict,
			message = "renderer reservation conflict",
		}
	end
	record.state = Types.RobloxRendererReservationState.Released
	Sessions.update(sessionId, {
		reservationState = Types.RobloxRendererReservationState.Released,
		sessionState = Types.RobloxRenderingSessionState.Released,
		lifecycleState = Types.RobloxRenderingSessionState.Released,
	})
	Ownership.release(sessionId)
	Metrics.decrement("reservationCount")
	Evidence.record("reservation released", record)
	return { ok = true, code = "Ok", reservation = Serialization.deepCopy(record) }
end

function Reservation.inspect()
	local result = {}
	for _, record in pairs(records) do
		result[#result + 1] = Serialization.deepCopy(record)
	end
	table.sort(result, function(left, right)
		return left.rendererId < right.rendererId
	end)
	return result
end

function Reservation.clear()
	table.clear(records)
end

return Reservation
