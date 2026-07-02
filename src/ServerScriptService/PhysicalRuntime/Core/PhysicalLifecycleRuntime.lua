--!strict
-- Lifecycle state records for physical schemas.

local Types = require(script.Parent.PhysicalTypes)
local Validation = require(script.Parent.PhysicalValidation)

local Lifecycle = {}

local function validLifecycle(value: any): boolean
	for _, lifecycleState in pairs(Types.LifecycleState) do
		if value == lifecycleState then
			return true
		end
	end
	return false
end

function Lifecycle.setLifecycle(
	state: any,
	physicalObjectId: string,
	lifecycleState: string
): (boolean, string?)
	if not Validation.id(physicalObjectId) then
		return false, "physicalObjectId is required"
	end
	if not validLifecycle(lifecycleState) then
		return false, "lifecycle state is invalid"
	end
	if not state.exists(physicalObjectId) then
		return false, "unknown physicalObjectId"
	end
	state.setLifecycle(physicalObjectId, lifecycleState)
	return true, nil
end

return Lifecycle
