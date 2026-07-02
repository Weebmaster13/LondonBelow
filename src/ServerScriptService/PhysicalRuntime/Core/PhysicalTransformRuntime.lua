--!strict
-- Transform schemas for physical objects. These are data records, not CFrame execution.

local Validation = require(script.Parent.PhysicalValidation)

local Transform = {}

function Transform.setTransform(
	state: any,
	physicalObjectId: string,
	transformSchema: any
): (boolean, string?)
	if not Validation.id(physicalObjectId) then
		return false, "physicalObjectId is required"
	end
	if not state.exists(physicalObjectId) then
		return false, "unknown physicalObjectId"
	end
	if type(transformSchema) ~= "table" then
		return false, "transformSchema must be a table"
	end
	local safe, reason = Validation.safePayload(transformSchema)
	if not safe then
		return false, reason
	end
	state.setTransform(physicalObjectId, transformSchema)
	return true, nil
end

return Transform
