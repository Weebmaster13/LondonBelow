--!strict
-- Ownership records for physical schemas. Ownership is authority metadata only.

local Validation = require(script.Parent.PhysicalValidation)

local Ownership = {}

function Ownership.assign(
	state: any,
	physicalObjectId: string,
	ownerSystem: string
): (boolean, string?)
	local ok, reason = Validation.ownership(physicalObjectId, ownerSystem)
	if not ok then
		return false, reason
	end
	if not state.exists(physicalObjectId) then
		return false, "unknown physicalObjectId"
	end
	state.setOwnership(physicalObjectId, ownerSystem)
	return true, nil
end

return Ownership
