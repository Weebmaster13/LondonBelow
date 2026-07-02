--!strict
-- Reservation and execution lock records for physical schemas.

local Validation = require(script.Parent.PhysicalValidation)

local Reservation = {}

function Reservation.reserve(
	state: any,
	physicalObjectId: string,
	reservationId: string,
	ownerSystem: string
): (boolean, string?)
	local ok, reason = Validation.reservation(physicalObjectId, reservationId, ownerSystem)
	if not ok then
		return false, reason
	end
	if not state.exists(physicalObjectId) then
		return false, "unknown physicalObjectId"
	end
	if state.hasReservation(reservationId) then
		return false, "duplicate reservationId"
	end
	state.addReservation(physicalObjectId, reservationId, ownerSystem)
	return true, nil
end

function Reservation.release(state: any, reservationId: string): (boolean, string?)
	if not Validation.id(reservationId) then
		return false, "reservationId is required"
	end
	if not state.hasReservation(reservationId) then
		return false, "unknown reservationId"
	end
	state.releaseReservation(reservationId)
	return true, nil
end

return Reservation
