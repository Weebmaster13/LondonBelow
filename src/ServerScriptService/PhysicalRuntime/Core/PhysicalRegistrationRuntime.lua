--!strict
-- Physical object schema registration. This module never stores Roblox Instances.

local Types = require(script.Parent.PhysicalTypes)
local Validation = require(script.Parent.PhysicalValidation)

local Registration = {}

function Registration.register(state: any, schema: any): (boolean, string?)
	local ok, reason = Validation.objectSchema(schema)
	if not ok then
		return false, reason
	end
	if state.exists(schema.physicalObjectId) then
		return false, "duplicate physicalObjectId"
	end
	state.add({
		physicalObjectId = schema.physicalObjectId,
		objectType = schema.objectType,
		schemaVersion = schema.schemaVersion,
		ownerSystem = schema.ownerSystem,
		registeredAt = os.clock(),
		state = schema.state or {},
		reservationState = schema.reservationState or { state = Types.ReservationState.Available },
		transformSchema = schema.transformSchema or {},
		lifecycleState = Types.LifecycleState.Registered,
		tags = schema.tags or {},
		metadata = schema.metadata or {},
	})
	return true, nil
end

return Registration
