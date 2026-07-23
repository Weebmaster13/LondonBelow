--!strict

local Sessions = require(script.Parent.RobloxRenderingSessionRegistry)
local Types = require(script.Parent.PresentationTypes)

local Validation = {}

function Validation.validate(): (boolean, string?)
	for _, session in ipairs(Sessions.inspect()) do
		if session.platform ~= Types.RobloxRenderingPlatform then
			return false, "session platform mismatch"
		end
		if not Types.isRobloxRenderingSessionState(session.sessionState) then
			return false, "invalid session state"
		end
		if not Types.isRobloxRendererReservationState(session.reservationState) then
			return false, "invalid reservation state"
		end
		if not Types.isRobloxRendererSchedulingState(session.schedulingState) then
			return false, "invalid scheduling state"
		end
	end
	return true, nil
end

return Validation
