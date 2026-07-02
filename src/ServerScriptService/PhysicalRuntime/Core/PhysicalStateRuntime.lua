--!strict
-- State schema updates for registered physical objects.

local Validation = require(script.Parent.PhysicalValidation)

local StateRuntime = {}

function StateRuntime.setState(
	state: any,
	physicalObjectId: string,
	objectState: any
): (boolean, string?)
	if not Validation.id(physicalObjectId) then
		return false, "physicalObjectId is required"
	end
	if not state.exists(physicalObjectId) then
		return false, "unknown physicalObjectId"
	end
	local safe, reason = Validation.safePayload(objectState or {})
	if not safe then
		return false, reason
	end
	if type(objectState) ~= "table" then
		return false, "state must be a table"
	end
	state.setState(physicalObjectId, objectState)
	return true, nil
end

return StateRuntime
